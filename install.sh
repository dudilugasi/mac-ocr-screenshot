#!/bin/zsh
set -e

SCRIPT_DIR="${0:A:h}"
INSTALL_DIR="$HOME/.local/share/ocr-screenshot"
LAUNCH_AGENT_LABEL="com.ocr-screenshot.hotkey"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/${LAUNCH_AGENT_LABEL}.plist"

# ── 1. Build ────────────────────────────────────────────────────────────────
echo "Building OCR engine (Vision framework)..."
swiftc "$SCRIPT_DIR/ocr.swift" \
    -o "$SCRIPT_DIR/ocr" \
    -framework Vision \
    -framework AppKit
echo "  ✓ ocr"

echo "Building hotkey menu bar app..."
swiftc "$SCRIPT_DIR/ocr-hotkey.swift" \
    -o "$SCRIPT_DIR/ocr-hotkey" \
    -framework Cocoa \
    -framework Carbon
echo "  ✓ ocr-hotkey"

# ── 2. Install files ─────────────────────────────────────────────────────────
echo "Installing to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/ocr"         "$INSTALL_DIR/ocr"
cp "$SCRIPT_DIR/ocr-hotkey"  "$INSTALL_DIR/ocr-hotkey"
cp "$SCRIPT_DIR/ocr-clip.sh" "$INSTALL_DIR/ocr-clip.sh"
chmod +x "$INSTALL_DIR/ocr"
chmod +x "$INSTALL_DIR/ocr-hotkey"
chmod +x "$INSTALL_DIR/ocr-clip.sh"
echo "  ✓ Files installed"

# ── 3. Remove old Automator service (if present) ─────────────────────────────
OLD_WORKFLOW="$HOME/Library/Services/OCR Screenshot.workflow"
if [[ -d "$OLD_WORKFLOW" ]]; then
    rm -rf "$OLD_WORKFLOW"
    /System/Library/CoreServices/pbs -flush &>/dev/null || true
    echo "  ✓ Removed old Automator workflow"
fi

# ── 4. Create LaunchAgent (starts at login, keeps running) ───────────────────
echo "Creating LaunchAgent: $LAUNCH_AGENT_LABEL ..."
mkdir -p "$HOME/Library/LaunchAgents"

cat > "$LAUNCH_AGENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LAUNCH_AGENT_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${INSTALL_DIR}/ocr-hotkey</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF
echo "  ✓ LaunchAgent created"

# ── 5. Load the LaunchAgent (start it now, also survives reboots) ────────────
echo "Starting OCR Screenshot..."
# Unload first in case it was already loaded (e.g. reinstall)
launchctl unload "$LAUNCH_AGENT_PLIST" &>/dev/null || true
launchctl load "$LAUNCH_AGENT_PLIST"
echo "  ✓ Running"

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  All done! OCR Screenshot is running.                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "  Shortcut:  ⌘⇧1  (Command + Shift + 1)"
echo "  Menu bar:  look for the 'text.viewfinder' icon (⊡)"
echo ""
echo "  Draw a box around any text → it's copied to your clipboard."
echo "  Press ESC to cancel."
echo ""
echo "  First capture: macOS will ask for Screen Recording permission."
echo "  Allow it in: System Settings → Privacy & Security → Screen Recording"
echo ""
