#!/bin/bash

VIRTUAL_OUTPUT="HEADLESS-2"

run() {
  echo "[*] Creating virtual display $VIRTUAL_OUTPUT..."
  hyprctl output create headless "$VIRTUAL_OUTPUT"
  sleep 0.2
  hyprctl keyword monitor "$VIRTUAL_OUTPUT,1920x1080@60,1920x0,1"
  sleep 0.5
  echo "[*] Starting WayVNC server..."
  nohup wayvnc --config ~/.config/wayvnc/config 0.0.0.0 5900 >/dev/null 2>&1 &
  sleep 0.5
  wayvncctl output-set "$VIRTUAL_OUTPUT"
  echo "Done"
  echo "[+] WayVNC is now running on $VIRTUAL_OUTPUT (port 5900)."
}

stop() {
  echo "[*] Stopping WayVNC..."
  pkill -x wayvnc
  echo "[*] Removing virtual display $VIRTUAL_OUTPUT..."
  hyprctl output remove "$VIRTUAL_OUTPUT"
  echo "[+] VNC server stopped and virtual display removed."
}

show_help() {
  echo "usage:"
  echo "  wayvnc option"
  echo ""
  echo "where option is one of:"
  echo "  -start    Run: start virtual display and WayVNC"
  echo "  -stop     Stop: terminate WayVNC and remove virtual display"
  echo "  -right    Rotate right"
  echo "  -left     Rotate left"
  echo "  -top      Rotate top"
  echo "  -h        Show this help message"
}

case "$1" in
-start)
  run
  ;;
-stop)
  stop
  ;;
-right)
  hyprctl keyword monitor "$VIRTUAL_OUTPUT,1920x1080@60,1920x0,1"
  ;;
-left)
  hyprctl keyword monitor "$VIRTUAL_OUTPUT,1920x1080@60,-1920x0,1"
  ;;
-top)
  hyprctl keyword monitor "$VIRTUAL_OUTPUT,1920x1080@60,0x-1080,1"
  ;;
-h | *)
  show_help
  ;;
esac
