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

    // Update check: notify only, opt-in. "Check now" works even when automatic checks are off.
    /// Called when the known update changes (the status menu shows it).
    var onUpdateStatusChange: () -> Void = {}
    @Published var checkForUpdates: Bool {
        didSet {
            store.checkForUpdates = checkForUpdates
            if checkForUpdates { check(manual: false) }
        }
    }
    @Published private(set) var pendingUpdate: AppVersion?
    /// Last check GitHub answered (not merely attempted), so "up to date" is never claimed after a failure.
    @Published private(set) var lastUpdateCheck: Date?
    @Published private(set) var updateError: String?
    @Published private(set) var isCheckingForUpdates = false
    let installChannel = InstallChannel.detect()
    let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    private lazy var updater = UpdateCheck(currentVersion: currentVersion,
                                           fetch: { [currentVersion] in try await Self.fetchLatestRelease(appVersion: currentVersion) })

    init() {
        enabled = store.enabled
        look = store.look
        glassIntensity = store.glassIntensity
        roundCorners = store.roundCorners
        cornerRadius = store.cornerRadius
        showMenuBarIcon = store.showMenuBarIcon
        checkForUpdates = store.checkForUpdates
        refreshUpdateStatus()
    }

    func refreshUpdateStatus() {
        pendingUpdate = updater.pendingUpdate
        lastUpdateCheck = updater.lastSuccessfulCheck
    }

    /// At launch and from the hourly timer: only when the user opted in and a day has passed.
    func checkIfDue() {
        if checkForUpdates && updater.isDue { check(manual: false) }
    }

    /// Automatic checks fail silently; a manual one shows its error under the button.
    func check(manual: Bool) {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        if manual { updateError = nil }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await updater.run()
            isCheckingForUpdates = false
            switch result {
            case .failed(let reason): if manual { updateError = reason }
            case .upToDate, .available: updateError = nil
            }
            let before = pendingUpdate
            refreshUpdateStatus()
            if pendingUpdate != before { onUpdateStatusChange() }
        }
    }

    /// The only network request the app makes: GitHub's "latest release" for this repository.
    private static func fetchLatestRelease(appVersion: String) async throws -> Data {
        var request = URLRequest(url: UpdateCheck.latestReleaseAPI,
                                 cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("NotchHider/\(appVersion)", forHTTPHeaderField: "User-Agent")
        let session = URLSession(configuration: .ephemeral)   // no cookies, no cache on disk
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        // URLSession doesn't throw on 403 (rate limit) or 404: treat anything but 200 as a failure.
        guard let status = (response as? HTTPURLResponse)?.statusCode, status == 200 else {
            throw UpdateFetchError(status: (response as? HTTPURLResponse)?.statusCode)
        }
        return data
    }

    var updateStatusText: String {
        guard let last = lastUpdateCheck else { return "Version \(currentVersion) · not checked yet" }
        let ago = RelativeDateTimeFormatter().localizedString(for: last, relativeTo: Date())
        return pendingUpdate == nil
            ? "Up to date (\(currentVersion)) · checked \(ago)"
            : "Running \(currentVersion) · checked \(ago)"
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

struct UpdateFetchError: LocalizedError {
    let status: Int?
    var errorDescription: String? {
        switch status {
        case 403?, 429?: return "GitHub is limiting requests right now. Try again later."
        case let code?: return "GitHub answered with HTTP \(code)."
        case nil: return "No response from GitHub."
        }
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
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: $model.checkForUpdates).toggleStyle(.checkbox)
                HStack {
                    Button("Check now") { model.check(manual: true) }
                        .disabled(model.isCheckingForUpdates)
                    if model.isCheckingForUpdates {
                        ProgressView().controlSize(.small)
                    } else {
                        Text(model.updateStatusText).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let version = model.pendingUpdate {
                    if model.installChannel == .homebrew {
                        LabeledContent("Version \(version.description) is available") {
                            Button("Copy command") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(InstallChannel.homebrewUpgradeCommand, forType: .string)
                            }
                        }
                        Text(InstallChannel.homebrewUpgradeCommand)
                            .font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    } else {
                        LabeledContent("Version \(version.description) is available") {
                            Button("Open release page") { NSWorkspace.shared.open(UpdateCheck.releasePage(for: version)) }
                        }
                    }
                }
                if let err = model.updateError {
                    Text("Could not check: \(err)").font(.caption).foregroundStyle(.red)
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
        model.onUpdateStatusChange = { [weak self] in self?.updateStatusItem() }
        updateStatusItem()
        rebuild()

        // Update check: at launch if due, then an hourly "is it due?" (robust to sleep, unlike a 24 h timer).
        model.checkIfDue()
        let timer = Timer(timeInterval: 3600, repeats: true) { [weak self] _ in self?.model.checkIfDue() }
        timer.tolerance = 300
        RunLoop.main.add(timer, forMode: .common)

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
        if let version = model.pendingUpdate {
            let update = NSMenuItem(title: "Update available: \(version.description)…", action: #selector(openSettings), keyEquivalent: "")
            update.target = self
            menu.addItem(update)
        }
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
        model.refreshUpdateStatus()
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
