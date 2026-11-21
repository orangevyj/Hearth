#!/usr/bin/env bash
# Add Hearth to the desktop application menu. No root required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS="$DATA_HOME/applications"
ICONS="$DATA_HOME/icons/hicolor/scalable/apps"

mkdir -p "$APPS" "$ICONS"
chmod +x "$ROOT/hearth"
cp "$ROOT/web/assets/logo.svg" "$ICONS/hearth.svg"

cat > "$APPS/hearth.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Hearth
GenericName=Local AI workspace
Comment=Private, local-first text, image, video, sound and 3D
Exec=$ROOT/hearth
Path=$ROOT
Icon=hearth
Terminal=false
Categories=Development;AudioVideo;Graphics;Utility;
Keywords=AI;LLM;local;chat;image;video;3D;
StartupNotify=true
EOF

chmod 755 "$APPS/hearth.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$APPS" >/dev/null 2>&1 || true
fi

if [ "${1:-}" = "--desktop" ]; then
  if [ -d "$HOME/Desktop" ]; then
    cp "$APPS/hearth.desktop" "$HOME/Desktop/hearth.desktop"
    chmod +x "$HOME/Desktop/hearth.desktop"
    echo "Hearth: desktop shortcut created at $HOME/Desktop/hearth.desktop"
  else
    echo "Hearth: no ~/Desktop directory found; menu entry installed only."
  fi
fi

echo "Hearth: installed application menu entry at $APPS/hearth.desktop"
echo "Launch it from your application menu, or run: $ROOT/hearth"
