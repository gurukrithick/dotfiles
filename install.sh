#!/usr/bin/env bash
#
# Provision an Arch machine after archinstall: packages, toolchains, plugin
# managers, then stow the dotfiles. Run as your user; safe to re-run.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

readonly PACMAN_PACKAGES=(
    # shell and prompt
    zsh tmux

    # editors and terminals
    neovim kitty nano

    # cli toolbelt
    git github-cli git-delta stow man-db yazi python curl
    fzf fd ripgrep bat eza zoxide jq fastfetch btop duf
    speedtest-cli smartmontools unzip zip wget reflector

    # nvim-treesitter (main) needs the CLI to build parsers
    tree-sitter-cli

    # runtimes for mason's LSPs and formatters
    nodejs npm pnpm rustup go jdk21-openjdk

    # js and python toolchains from extra, not curl installers that edit rc files
    bun uv

    # containers
    docker docker-compose

    # zram
    zram-generator

    # coding agent
    openai-codex

    # wayland session
    noctalia noctalia-greeter greetd
    swayidle
    slurp grim wf-recorder wl-clipboard cliphist wl-clip-persist
    wlopm playerctl polkit-gnome libnotify
    xwayland-satellite xorg-xwayland
    xdg-desktop-portal-wlr xdg-desktop-portal-gtk xdg-utils
    libinput-tools brightnessctl

    # audio
    pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber
    pavucontrol libpulse sof-firmware

    # networking and bluetooth
    networkmanager network-manager-applet
    bluez bluez-utils blueman

    # powerboost
    power-profiles-daemon

    # theming (Noctalia templates expect adw-gtk3 and qt6ct)
    adw-gtk-theme papirus-icon-theme
    qt6ct
    noto-fonts-emoji ttf-nerd-fonts-symbols

    # file manager and thumbnailers
    thunar tumbler ffmpegthumbnailer poppler-glib

    # media and documents
    mpv zathura zathura-pdf-mupdf libreoffice-fresh
    gst-libav gst-plugin-pipewire

    # browsers and chat
    chromium discord

    # secrets
    gnome-keyring
)

readonly AUR_PACKAGES=(
    mangowm-git
    maplemono-nf-unhinted
    swaylock-effects-git
    zen-browser-bin
    visual-studio-code-bin
    obsidian-bin
)

readonly NPM_GLOBALS=(
    vercel
    @juliusbrussee/caveman-code
    agent-browser@0.44.0
)

readonly NPM_PREFIX="$HOME/.npm-global"
readonly AGENT_CONFIG_DIR="$HOME/agent-config"
readonly AGENT_CONFIG_REPO="https://github.com/gurukrithick/agent-config.git"

# --- helpers ----------------------------------------------------------------

log()  { printf '\n\033[1;36m==>\033[0m %s\n' "$*"; }
skip() { printf '    \033[2m%s already present, skipping\033[0m\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

clone_if_missing() {
    local repo="$1" dest="$2"
    [[ -d "$dest" ]] && return 0
    git clone --depth 1 "$repo" "$dest"
}

# --- phases -----------------------------------------------------------------

check_preconditions() {
    [[ $EUID -ne 0 ]] || die "don't run this as root — it'll sudo when it needs to"
    have pacman || die "this script only knows how to set up Arch (or an Arch derivative)"
}

install_yay() {
    if have yay; then
        skip yay
        return
    fi

    log "installing yay"
    sudo pacman -S --needed --noconfirm base-devel git

    local build_dir
    build_dir="$(mktemp -d)"
    # clear itself, or it leaks to main and trips set -u on build_dir
    trap 'rm -rf "$build_dir"; trap - RETURN' RETURN

    git clone --depth 1 https://aur.archlinux.org/yay.git "$build_dir/yay"
    (cd "$build_dir/yay" && makepkg -si --noconfirm)
}

install_packages() {
    log "installing official packages"
    sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

    log "installing AUR packages"
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

install_toolchains() {
    log "installing out-of-repo toolchains"

    # a toolchain can exist with no default set, which breaks rustc and cargo
    if rustup default >/dev/null 2>&1; then
        skip "rust toolchain"
    else
        rustup default stable
    fi

    if have claude; then
        skip "claude code"
    else
        curl -fsSL https://claude.ai/install.sh | bash
    fi

    log "installing npm globals"
    npm install -g --prefix "$NPM_PREFIX" "${NPM_GLOBALS[@]}"
}

install_plugin_managers() {
    log "fetching Oh My Zsh and shell plugins"
    local omz_dir="$HOME/.oh-my-zsh"
    local plugin_dir="${ZSH_CUSTOM:-$omz_dir/custom}/plugins"
    clone_if_missing https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
    clone_if_missing https://github.com/zsh-users/zsh-completions.git "$plugin_dir/zsh-completions"
    clone_if_missing https://github.com/zsh-users/zsh-autosuggestions.git "$plugin_dir/zsh-autosuggestions"
    clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir/zsh-syntax-highlighting"
}

# not -d "$HOME" with the repo as package: stow 2.4 silently does nothing when stow dir == target
link_dotfiles() {
    log "symlinking dotfiles into \$HOME"
    # real dirs first, or stow folds them into links to the repo
    mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/Pictures"
    stow -v -R -d "$DOTFILES_DIR" -t "$HOME" .
}

configure_agents() {
    if [[ -d "$AGENT_CONFIG_DIR" ]]; then
        skip "$AGENT_CONFIG_DIR"
    else
        log "cloning agent-config"
        if ! GIT_TERMINAL_PROMPT=0 git clone "$AGENT_CONFIG_REPO" "$AGENT_CONFIG_DIR"; then
            printf '    \033[2mcould not clone %s, skipping\033[0m\n' "$AGENT_CONFIG_REPO"
            return 0
        fi
    fi

    log "applying portable Claude Code and Codex preferences"
    python3 "$AGENT_CONFIG_DIR/deploy.py" apply --bootstrap
}

# powerboost's root-only writes run from a keybind with no tty, so they need NOPASSWD
install_powerboost_sudoers() {
    local rule=/etc/sudoers.d/powerboost

    if sudo test -f "$rule"; then
        skip "powerboost sudoers rule"
        return
    fi

    log "installing powerboost sudoers rule"
    sudo tee "$rule" >/dev/null <<EOF
$USER ALL=(root) NOPASSWD: /usr/bin/tee /sys/class/drm/card[0-9]/gt_min_freq_mhz
$USER ALL=(root) NOPASSWD: /usr/bin/sysctl -q -w vm.swappiness=[0-9]*
EOF
    sudo chmod 0440 "$rule"
    sudo visudo -cf "$rule"
}

# agents need non-interactive sudo
install_agent_sudoers() {
    local rule=/etc/sudoers.d/agent-nopasswd

    if sudo test -f "$rule"; then
        skip "passwordless sudo rule"
        return
    fi

    log "installing passwordless sudo rule for agents"
    printf '%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$USER" | sudo tee "$rule" >/dev/null
    sudo chmod 0440 "$rule"
    sudo visudo -cf "$rule" || { sudo rm -f "$rule"; die "invalid sudoers rule removed"; }
}

write_root_file() {
    local path="$1" content="$2"
    if [[ "$(sudo cat "$path" 2>/dev/null)" == "$content" ]]; then
        skip "$path"
        return
    fi
    sudo mkdir -p "$(dirname "$path")"
    printf '%s\n' "$content" | sudo tee "$path" >/dev/null
}

# 8 GB zram swap; /tmp on disk because agents fill it and tmpfs would eat RAM (applies after reboot)
configure_memory() {
    log "configuring zram and /tmp"
    write_root_file /etc/systemd/zram-generator.conf "[zram0]
zram-size = 8192
compression-algorithm = zstd"
    sudo systemctl mask tmp.mount
}

configure_base_files() {
    log "configuring pacman and address selection"
    sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
    sudo sed -i -E 's/^#(precedence ::ffff:0:0\/96[[:space:]]+100)$/\1/' /etc/gai.conf
}

# a timeout set in firmware (bootctl set-timeout) still overrides this
configure_boot_menu() {
    local conf=/boot/loader/loader.conf
    if ! sudo test -f "$conf"; then
        skip "systemd-boot menu ($conf not found)"
        return
    fi

    log "setting the boot menu timeout"
    if sudo grep -qE '^timeout[[:space:]]' "$conf"; then
        sudo sed -i -E 's/^timeout[[:space:]].*/timeout 1/' "$conf"
    else
        echo 'timeout 1' | sudo tee -a "$conf" >/dev/null
    fi
}

# docker stays off at boot; the group is root-equivalent
configure_docker() {
    log "configuring docker"
    sudo systemctl disable docker.service docker.socket containerd.service 2>/dev/null || true
    sudo groupadd --system --force docker
    sudo usermod -aG docker "$USER"
}

# iwd and systemd-networkd fight NetworkManager over Wi-Fi. iwd stays installed
# (its 80-iwd.link keeps the card named wlan0) but is masked so D-Bus can't start it.
enable_services() {
    log "enabling system services"
    sudo systemctl enable --now NetworkManager.service bluetooth.service \
        power-profiles-daemon.service fstrim.timer systemd-timesyncd.service

    log "leaving the network to NetworkManager from the next boot"
    local unit
    for unit in iwd.service systemd-networkd.service systemd-networkd.socket \
        systemd-networkd-varlink.socket systemd-networkd-varlink-metrics.socket \
        systemd-networkd-resolve-hook.socket systemd-networkd-wait-online.service; do
        # no --now: it would cut the network mid-install
        sudo systemctl disable "$unit" 2>/dev/null || true
    done
    sudo systemctl mask iwd.service
}

set_login_shell() {
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" == *"/zsh" ]]; then
        skip "zsh as login shell"
        return
    fi

    log "switching default shell to zsh"
    sudo chsh -s "$(command -v zsh)" "$USER"
}

# Noctalia login screen on greetd. no --now: it would take VT1 from a running session
configure_greeter() {
    local conf=/etc/greetd/config.toml
    local want='[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"'

    log "configuring the Noctalia greeter"
    getent passwd greeter >/dev/null ||
        sudo useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter greeter

    # first change only, so re-runs keep the distro original
    if [[ "$(sudo cat "$conf" 2>/dev/null)" != "$want" ]] && ! sudo test -e "$conf.bak"; then
        sudo cp -a "$conf" "$conf.bak" 2>/dev/null || true
    fi
    write_root_file "$conf" "$want"

    # package script: pam_systemd in /etc/pam.d/greetd, state dir, greeter.toml
    sudo bash /usr/share/noctalia-greeter/setup_greeter_system.sh >/dev/null

    # unlock gnome-keyring with the login password; after the package script, around its includes
    local pam=/etc/pam.d/greetd
    if sudo grep -q pam_gnome_keyring "$pam"; then
        skip "gnome-keyring in $pam"
    else
        sudo sed -i -E \
            -e '/^auth[[:space:]]+include[[:space:]]+system-local-login/a auth       optional     pam_gnome_keyring.so' \
            -e '/^session[[:space:]]+include[[:space:]]+system-local-login/a session    optional     pam_gnome_keyring.so auto_start' \
            "$pam"
    fi

    # greeter-sync goes through pkexec; let the hooks sync without a prompt
    write_root_file /etc/polkit-1/rules.d/50-noctalia-greeter-sync.rules "// let $USER sync the shell's look to the login greeter without a password prompt
polkit.addRule(function (action, subject) {
    if (action.id == \"org.noctalia.greeter.sync-appearance\" &&
        subject.user == \"$USER\" && subject.local && subject.active) {
        return polkit.Result.YES;
    }
});"

    sudo systemctl enable greetd
}

# last: the stub only exists once resolved runs, so linking earlier would break DNS for the
# steps above. no --now: NetworkManager picks up resolved on the next boot
configure_dns() {
    local stub=/run/systemd/resolve/stub-resolv.conf
    log "handing DNS to systemd-resolved"
    # start it first so the stub exists and DNS keeps working
    sudo systemctl enable --now systemd-resolved.service
    if [[ "$(readlink /etc/resolv.conf)" == "$stub" ]]; then
        skip "/etc/resolv.conf -> $stub"
    else
        sudo ln -sf "$stub" /etc/resolv.conf
    fi
}

print_next_steps() {
    log "done"
    cat <<'EOF'
    reboot to the Noctalia login screen and pick mango.
    once in mango, run: noctalia msg greeter-sync (later wallpaper and theme changes sync on their own).
    if Wi-Fi isn't connected after the reboot, join it once with nmtui.
    sign in yourself: gh auth login, claude, codex, and restore your SSH keys.
EOF
}

# --- entrypoint -------------------------------------------------------------

main() {
    check_preconditions
    # first, so nothing later prompts for a password
    install_agent_sudoers
    configure_base_files
    install_yay
    install_packages
    install_toolchains
    install_plugin_managers
    link_dotfiles
    configure_agents
    install_powerboost_sudoers
    configure_memory
    configure_boot_menu
    configure_docker
    enable_services
    configure_greeter
    set_login_shell
    configure_dns
    print_next_steps
}

main "$@"
