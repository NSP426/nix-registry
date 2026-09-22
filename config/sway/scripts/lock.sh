#!/bin/sh

PID=$(pgrep swayidle)

if [ -n "$PID" ]; then                                                          
    kill $PID                                                                    
    wait $PID                                                                    
fi 

swayidle -w \
   timeout 300 'swaylock -i ~/.config/sway/assets/lock.png -f -c 000000' \
   timeout 310 'swaymsg output \* dpms off' \
   resume 'swaymsg output \* dpms on' \
   before-sleep 'swaylock -i ~/.config/sway/assets/lock.png -f -c 000000' \
   &

