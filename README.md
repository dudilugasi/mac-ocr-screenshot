# OCR Screenshot → Clipboard

Draw a box around any text on your screen — it gets copied to your clipboard instantly.  
Works with any app: PDFs, videos, terminal output, images, etc.

**No third-party dependencies.** Uses Apple's built-in Vision framework and Carbon hotkeys.

---

## Install

```bash
chmod +x install.sh && ./install.sh
```

This will:
1. Compile the OCR engine (`ocr`) and the hotkey app (`ocr-hotkey`)
2. Install everything to `~/.local/share/ocr-screenshot/`
3. Create and load a LaunchAgent so it starts at every login

**That's it.** The shortcut `⌥⌘5` (Option + Command + 5) is ready to use immediately.

---

## Usage

1. Press `⌥⌘5` from anywhere
2. Draw a rectangle around the text you want (crosshair cursor)
3. Press `ESC` to cancel
4. A notification confirms — paste with `⌘V`

A small icon appears in your menu bar. Click it to trigger a capture or quit.

---

## First run — Screen Recording permission

The first capture will prompt macOS for Screen Recording access.  
If nothing happens: **System Settings → Privacy & Security → Screen Recording** → enable for `zsh` or `Terminal`.

---

## How it works

| File | Role |
|------|------|
| `ocr.swift` | Feeds an image through macOS Vision OCR, prints recognized text to stdout |
| `ocr-clip.sh` | Captures a screen region with `screencapture -i`, pipes text through `ocr`, copies with `pbcopy` |
| `ocr-hotkey.swift` | Menu bar app — registers `⌥⌘5` as a global hotkey via Carbon (no Accessibility permission required) |
| `install.sh` | Builds everything and registers a LaunchAgent for login auto-start |

---

## Why not Automator / Services?

macOS Services are designed to pass selected content from the frontmost app. Even when configured for "no input", the keyboard-shortcut mechanism routes through the Services infrastructure which requires app cooperation — causing the *"There was a problem with the input to the Service"* error in many apps.

The menu bar app uses Carbon's `RegisterEventHotKey` which intercepts at the system level, bypassing Services entirely.

---

## Requirements

- macOS 10.15 Catalina or later
- Xcode Command Line Tools: `xcode-select --install`

---

## Uninstall

```bash
make uninstall
```
