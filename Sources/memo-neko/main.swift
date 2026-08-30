import Cocoa

// MARK: - アプリ本体

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var percentMenuItem: NSMenuItem!
    private var stageMenuItem: NSMenuItem!
    private var currentStage: CatStage?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        let menu = NSMenu()

        percentMenuItem = NSMenuItem(title: "メモリ使用率: --%", action: nil, keyEquivalent: "")
        percentMenuItem.isEnabled = false
        menu.addItem(percentMenuItem)

        stageMenuItem = NSMenuItem(title: "状態: --", action: nil, keyEquivalent: "")
        stageMenuItem.isEnabled = false
        menu.addItem(stageMenuItem)

        menu.addItem(NSMenuItem.separator())

        let activityItem = NSMenuItem(title: "アクティビティモニタを開く", action: #selector(openActivityMonitor), keyEquivalent: "")
        activityItem.target = self
        menu.addItem(activityItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "終了", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        updateStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let percent = memoryUsagePercent()
        let stage = CatStage.from(percent: percent, previous: currentStage)
        currentStage = stage

        let isDark = statusItem.button?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        statusItem.button?.image = loadCatImage(stage: stage, isDarkMenuBar: isDark)
        percentMenuItem.title = String(format: "メモリ使用率: %.0f%%", percent)
        stageMenuItem.title = "状態: \(stage.label)"
    }

    @objc private func openActivityMonitor() {
        let url = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
