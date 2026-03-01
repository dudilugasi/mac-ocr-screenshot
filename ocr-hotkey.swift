// ocr-hotkey.swift
// Menu bar app that registers a global hotkey (⌥⌘5) and runs the OCR script.
// Compile: swiftc ocr-hotkey.swift -o ocr-hotkey -framework Cocoa -framework Carbon
import Cocoa
import Carbon

class HotkeyDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    let scriptPath: String

    init(scriptPath: String) {
        self.scriptPath = scriptPath
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupHotkey()
    }

    // MARK: - Menu bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let icon = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "OCR Screenshot")
            icon?.isTemplate = true
            button.image = icon
        }

        let menu = NSMenu()

        let captureItem = NSMenuItem(title: "Capture && OCR  ⌘⇧1", action: #selector(runOCR), keyEquivalent: "")
        captureItem.target = self
        menu.addItem(captureItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit OCR Screenshot", action: #selector(quit), keyEquivalent: "")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Global hotkey (Carbon RegisterEventHotKey — no Accessibility permission needed)

    func setupHotkey() {
        let hotKeyID = EventHotKeyID(signature: 0x4F435253 /* 'OCRS' */, id: 1)
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                Unmanaged<HotkeyDelegate>.fromOpaque(userData!).takeUnretainedValue().runOCR()
                return noErr
            },
            1, &eventSpec, selfPtr, nil
        )

        // ⌘⇧1  →  keyCode 18, modifiers = cmdKey (256) | shiftKey (512)
        RegisterEventHotKey(
            18,
            UInt32(cmdKey | shiftKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    // MARK: - Actions

    @objc func runOCR() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = [scriptPath]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        try? task.run()
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}

// Entry point
let scriptPath = "\(NSHomeDirectory())/.local/share/ocr-screenshot/ocr-clip.sh"
let app = NSApplication.shared
app.setActivationPolicy(.accessory)   // no Dock icon
let delegate = HotkeyDelegate(scriptPath: scriptPath)
app.delegate = delegate
app.run()
