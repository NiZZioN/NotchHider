import AppKit
import ServiceManagement
import SwiftUI

/// Borderless window that AppKit is not allowed to push below the menu bar.
final class BarWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Settings model (UI state backed by BarSettings)

final class SettingsModel: ObservableObject {
    private let store = BarSettings()
    /// Called after any appearance-related change.
    var onChange: () -> Void = {}

    @Published var enabled: Bool { didSet { store.enabled = enabled; onChange() } }
    @Published var look: BarLook { didSet { store.look = look; onChange() } }
    @Published var glassIntensity: Double { didSet { store.glassIntensity = glassIntensity; onChange() } }
    @Published var roundCorners: Bool { didSet { store.roundCorners = roundCorners; onChange() } }
    @Published var cornerRadius: Double { didSet { store.cornerRadius = cornerRadius; onChange() } }
    @Published var showMenuBarIcon: Bool { didSet { store.showMenuBarIcon = showMenuBarIcon; onChange() } }
    @Published private(set) var loginStatus: SMAppService.Status = SMAppService.mainApp.status
    @Published var loginError: String?

    init() {
        enabled = store.enabled
        look = store.look
        glassIntensity = store.glassIntensity
        roundCorners = store.roundCorners
        cornerRadius = store.cornerRadius
        showMenuBarIcon = store.showMenuBarIcon
    }

    /// Read from the system every time, so it never drifts from System Settings → Login Items.
    var launchAtLogin: Bool {
        get { loginStatus == .enabled || loginStatus == .requiresApproval }
        set {
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                loginError = nil
            } catch {
                loginError = error.localizedDescription
            }
            refreshLoginStatus()
        }
    }

    func refreshLoginStatus() { loginStatus = SMAppService.mainApp.status }

    var hasLaunchedBefore: Bool {
        get { UserDefaults.standard.bool(forKey: "hasLaunchedBefore") }
        set { UserDefaults.standard.set(newValue, forKey: "hasLaunchedBefore") }
    }
}

// MARK: - Settings window

struct SettingsView: View {
    @ObservedObject var model: SettingsModel

    var body: some View {
        Form {
            Section {
                Toggle("Hide the notch", isOn: $model.enabled)
            }
            Section("Appearance") {
                Picker("Style", selection: $model.look) {
                    Text("Black").tag(BarLook.black)
                    Text("Blurred glass").tag(BarLook.glass)
                }
                .pickerStyle(.segmented)
                if model.look == .glass {
                    LabeledContent("Glass strength") {
                        HStack {
                            Slider(value: $model.glassIntensity, in: 1...100, step: 1)
                            Text("\(Int(model.glassIntensity))%").monospacedDigit().frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                Toggle("Round corners", isOn: $model.roundCorners).toggleStyle(.checkbox)
                if model.roundCorners {
                    LabeledContent("Corner radius") {
                        HStack {
                            Slider(value: $model.cornerRadius, in: 0...Double(BarGeometry.maxCornerRadius), step: 1)
                            Text("\(Int(model.cornerRadius)) pt").monospacedDigit().frame(width: 40, alignment: .trailing)
                        }
                    }
                }
            }
            .disabled(!model.enabled)
            Section("General") {
                Toggle("Launch at login", isOn: Binding(get: { model.launchAtLogin },
                                                        set: { model.launchAtLogin = $0 }))
                    .toggleStyle(.checkbox)
                if model.loginStatus == .requiresApproval {
                    Text("Allow Notch Hider in System Settings → General → Login Items.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                if let err = model.loginError {
                    Text(err).font(.caption).foregroundStyle(.red)
                }
                Toggle("Show icon in menu bar", isOn: $model.showMenuBarIcon).toggleStyle(.checkbox)
                if !model.showMenuBarIcon {
                    Text("To get back here, open Notch Hider again (Finder, Spotlight or Launchpad).")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                Spacer()
                Button("Quit Notch Hider") { NSApp.terminate(nil) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400)
        .fixedSize()
    }
}

// MARK: - App

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let model = SettingsModel()
    private var windows: [BarWindow] = []
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Single instance: a login-item copy plus a manual launch must not draw two strips.
        if let id = Bundle.main.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: id)
               .contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.accessory)
        model.onChange = { [weak self] in self?.settingsChanged() }
        updateStatusItem()
        rebuild()

        NotificationCenter.default.addObserver(
            self, selector: #selector(rebuild),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(rebuild), name: NSWorkspace.didWakeNotification, object: nil)
        ws.addObserver(self, selector: #selector(rebuild), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)

        if !model.hasLaunchedBefore {
            model.hasLaunchedBefore = true
            showSettings()
        }
    }

    /// Opening the app again (Finder, Spotlight, `open`) shows Settings: the way back when the icon is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func settingsChanged() {
        updateStatusItem()
        if model.enabled == windows.isEmpty {
            rebuild()       // turned on or off
        } else {
            applyStyle()    // restyle existing strips in place
        }
    }

    // MARK: Menu bar icon

    private func updateStatusItem() {
        guard model.showMenuBarIcon else {
            if let item = statusItem { NSStatusBar.system.removeStatusItem(item) }
            statusItem = nil
            return
        }
        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            item.button?.image = NSImage(systemSymbolName: "rectangle.tophalf.filled",
                                         accessibilityDescription: "Notch Hider")
            statusItem = item
        }
        let menu = NSMenu()
        let hide = NSMenuItem(title: "Hide Notch", action: #selector(toggleEnabled), keyEquivalent: "")
        hide.target = self
        hide.state = model.enabled ? .on : .off
        menu.addItem(hide)
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Notch Hider", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc private func toggleEnabled() { model.enabled.toggle() }
    @objc private func openSettings() { showSettings() }

    private func showSettings() {
        model.refreshLoginStatus()
        if settingsWindow == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            w.title = "Notch Hider"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.delegate = self
            settingsWindow = w
        }
        settingsWindow?.center()
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    // MARK: Strip windows

    @objc private func rebuild() {
        let old = windows
        windows = []
        if model.enabled {
            for screen in NSScreen.screens {
                guard let rect = BarGeometry.stripRect(screenFrame: screen.frame,
                                                       visibleFrame: screen.visibleFrame,
                                                       notchInset: screen.safeAreaInsets.top) else { continue }
                let w = BarWindow(contentRect: rect, styleMask: .borderless, backing: .buffered, defer: false)
                w.hasShadow = false
                w.ignoresMouseEvents = true
                w.isReleasedWhenClosed = false
                // Just below the menu bar, so menu items are still drawn on top.
                w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) - 1)
                w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
                w.setFrame(rect, display: false)
                windows.append(w)
            }
            applyStyle()
            windows.forEach { $0.orderFrontRegardless() }
        }
        old.forEach { $0.orderOut(nil) }   // remove old strips only after new ones are up: no flicker
    }

    private func applyStyle() {
        for w in windows {
            let radius = model.roundCorners
                ? BarGeometry.clampedRadius(CGFloat(model.cornerRadius), stripHeight: w.frame.height)
                : 0
            BarStyle.apply(look: model.look, glassIntensity: model.glassIntensity, radius: radius, to: w)
        }
    }
}

// Command-line helpers for install.sh / uninstall.sh: add or remove the login item, then exit.
if CommandLine.arguments.contains("--register-login-item") {
    do { try SMAppService.mainApp.register(); exit(0) } catch { print("Could not add login item: \(error.localizedDescription)"); exit(1) }
}
if CommandLine.arguments.contains("--unregister-login-item") {
    try? SMAppService.mainApp.unregister()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
