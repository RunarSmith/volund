#!/bin/bash

# === Configuration ===
WSLG_MNT="/mnt/wslg"

# === check requirements ===

if [ ! -e "$WSLG_MNT/runtime-dir/pulse/native" ]; then
  echo "❌ PulseAudio WSLg socket is NOT available."
  exit 1
fi

# === Launch ! ===

echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
echo "DISPLAY=$DISPLAY"
echo "PULSE_SERVER=$PULSE_SERVER"

sudo XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR WAYLAND_DISPLAY=$WAYLAND_DISPLAY DISPLAY=$DISPLAY PULSE_SERVER=$PULSE_SERVER firefox &

echo "🚀 Firefox launched with GUI + audio (WSLg)..."


