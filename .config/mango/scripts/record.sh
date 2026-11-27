#!/bin/sh
set -eu

PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/mango-record.pid"
STATE="$PIDFILE.path"

if [ -f "$PIDFILE" ] && pid=$(cat "$PIDFILE") && kill -0 "$pid" 2>/dev/null; then
    kill -INT "$pid"
    tail --pid="$pid" -f /dev/null
    out=$(cat "$STATE" 2>/dev/null || true)
    rm -f "$PIDFILE" "$STATE"
    notify-send "Recording stopped" "saved $out"
    exit 0
fi
rm -f "$PIDFILE" "$STATE"

geom=$(slurp -o) || exit 0
[ -n "$geom" ] || exit 0
VIDS="${XDG_VIDEOS_DIR:-$HOME/Videos}"
mkdir -p "$VIDS"
out="$VIDS/recording-$(date +%Y%m%d-%H%M%S).mp4"
printf '%s\n' "$out" > "$STATE"
wf-recorder -g "$geom" -f "$out" >/dev/null 2>&1 &
echo $! > "$PIDFILE"
notify-send "Recording started" "Super+Shift+R stops it"
