#!/bin/sh

PID=$(pgrep swayidle)

if [ -n "$PID" ]; then
   kill $PID
   wait $PID
fi

swayidle \
    timeout 10 'swaymsg output \* dpms off' \
    resume 'swaymsg output \* dpms on & ~/.config/sway/scripts/lock.sh' \
    &

swaylock -i ~/.config/sway/assets/lock.png -f -c 000000

