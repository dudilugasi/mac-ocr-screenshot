INSTALL_DIR    = $(HOME)/.local/share/ocr-screenshot
AGENT_LABEL    = com.ocr-screenshot.hotkey
AGENT_PLIST    = $(HOME)/Library/LaunchAgents/$(AGENT_LABEL).plist

.PHONY: all build install clean uninstall stop start

all: build

build: ocr ocr-hotkey

ocr: ocr.swift
	swiftc ocr.swift -o ocr -framework Vision -framework AppKit

ocr-hotkey: ocr-hotkey.swift
	swiftc ocr-hotkey.swift -o ocr-hotkey -framework Cocoa -framework Carbon

install: build
	@chmod +x install.sh
	@./install.sh

stop:
	launchctl unload "$(AGENT_PLIST)" 2>/dev/null || true

start:
	launchctl load "$(AGENT_PLIST)" 2>/dev/null || true

clean:
	rm -f ocr ocr-hotkey

uninstall: stop
	rm -rf "$(INSTALL_DIR)"
	rm -f  "$(AGENT_PLIST)"
	rm -rf "$(HOME)/Library/Services/OCR Screenshot.workflow"
	@echo "Uninstalled."
