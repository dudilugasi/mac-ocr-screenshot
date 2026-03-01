#!/bin/zsh
# Select a region on screen — OCR's the text and copies it to clipboard.

SCRIPT_DIR="${0:A:h}"
OCR_BIN="$SCRIPT_DIR/ocr"
TEMP_IMG=$(mktemp /tmp/ocr-XXXXXX.png)

cleanup() { rm -f "$TEMP_IMG" }
trap cleanup EXIT

notify() {
    osascript -e "display notification \"$1\" with title \"OCR Screenshot\"" &>/dev/null
}

# Interactive crosshair selection — ESC to cancel
screencapture -i "$TEMP_IMG" 2>/dev/null

# User cancelled (no file or empty file)
[[ ! -s "$TEMP_IMG" ]] && exit 0

TEXT=$("$OCR_BIN" "$TEMP_IMG" 2>/dev/null)
STATUS=$?

case $STATUS in
    0)
        printf '%s' "$TEXT" | pbcopy
        notify "Text copied to clipboard"
        ;;
    2)
        notify "No text found in selection"
        ;;
    *)
        notify "OCR failed — check Screen Recording permissions"
        ;;
esac
