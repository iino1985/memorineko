import Cocoa
import UniformTypeIdentifiers

// MARK: - アプリ本体

private let metricSourceDefaultsKey = "metricSource"
private let catBreedDefaultsKey = "catBreed"

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var percentMenuItem: NSMenuItem!
    private var stageMenuItem: NSMenuItem!
    private var currentStage: CatStage?
    private var metricMenuItems: [MetricSource: NSMenuItem] = [:]
    private var breedMenuItems: [CatBreed: NSMenuItem] = [:]
    private let cpuMonitor = CPUUsageMonitor()

    private var selectedMetric: MetricSource {
        get { MetricSource(rawValue: UserDefaults.standard.integer(forKey: metricSourceDefaultsKey)) ?? .memory }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: metricSourceDefaultsKey) }
    }

    private var selectedBreed: CatBreed {
        get { CatBreed(rawValue: UserDefaults.standard.integer(forKey: catBreedDefaultsKey)) ?? .calico }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: catBreedDefaultsKey) }
    }

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

        let metricParentItem = NSMenuItem(title: "指標を選ぶ", action: nil, keyEquivalent: "")
        let metricSubmenu = NSMenu()
        for source in MetricSource.allCases {
            let item = NSMenuItem(title: source.menuLabel, action: #selector(selectMetric(_:)), keyEquivalent: "")
            item.target = self
            item.tag = source.rawValue
            item.state = source == selectedMetric ? .on : .off
            metricSubmenu.addItem(item)
            metricMenuItems[source] = item
        }
        menu.setSubmenu(metricSubmenu, for: metricParentItem)
        menu.addItem(metricParentItem)

        let breedParentItem = NSMenuItem(title: "猫の種類を選ぶ", action: nil, keyEquivalent: "")
        let breedSubmenu = NSMenu()
        for breed in CatBreed.allCases {
            let item = NSMenuItem(title: breed.menuLabel, action: #selector(selectBreed(_:)), keyEquivalent: "")
            item.target = self
            item.tag = breed.rawValue
            item.state = breed == selectedBreed ? .on : .off
            breedSubmenu.addItem(item)
            breedMenuItems[breed] = item
        }
        breedSubmenu.addItem(NSMenuItem.separator())
        let customSetupItem = NSMenuItem(title: "カスタム画像を設定...", action: #selector(setupCustomImages), keyEquivalent: "")
        customSetupItem.target = self
        breedSubmenu.addItem(customSetupItem)

        menu.setSubmenu(breedSubmenu, for: breedParentItem)
        menu.addItem(breedParentItem)

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
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let reading = readMetric(selectedMetric, cpuMonitor: cpuMonitor)
        let stage = CatStage.from(percent: reading.stressPercent, previous: currentStage)
        currentStage = stage

        let isDark = statusItem.button?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        statusItem.button?.image = loadCatImage(breed: selectedBreed, stage: stage, isDarkMenuBar: isDark)
        percentMenuItem.title = String(format: "%@: %.0f%%", reading.displayLabel, reading.displayPercent)
        stageMenuItem.title = "状態: \(stage.label)"
    }

    @objc private func selectMetric(_ sender: NSMenuItem) {
        guard let source = MetricSource(rawValue: sender.tag) else { return }
        selectedMetric = source
        for (s, item) in metricMenuItems { item.state = (s == source) ? .on : .off }
        currentStage = nil
        updateStatus()
    }

    @objc private func selectBreed(_ sender: NSMenuItem) {
        guard let breed = CatBreed(rawValue: sender.tag) else { return }
        selectedBreed = breed
        for (b, item) in breedMenuItems { item.state = (b == breed) ? .on : .off }
        updateStatus()
    }

    // ステージごとに1枚ずつファイル選択ダイアログを出し、5枚全部揃ったらApplication Supportへコピーして
    // カスタム品種として即座に反映する。途中でキャンセルしたら何も変更しない。
    @objc private func setupCustomImages() {
        NSApp.activate(ignoringOtherApps: true)

        let intro = NSAlert()
        intro.messageText = "カスタム画像を設定"
        intro.informativeText = """
        「シュッ→普通→ちょいぽちゃ→ぽっちゃり→パンパン」の5段階ぶん、順番に画像を選びます。

        推奨サイズ・形式:
        ・正方形（1:1）
        ・200×200px前後（小さすぎるとボケます）
        ・背景は透過PNG
        ・絵柄をフレームいっぱいに描いたもの（自動では拡大しません）
        """
        intro.addButton(withTitle: "始める")
        intro.addButton(withTitle: "キャンセル")
        guard intro.runModal() == .alertFirstButtonReturn else { return }

        var pickedURLs: [CatStage: URL] = [:]
        for stage in CatStage.allCases {
            let panel = NSOpenPanel()
            panel.title = "カスタム画像を設定"
            panel.message = "「\(stage.label)」の状態に使う画像を選んでください（PNG推奨）"
            panel.prompt = "選択"
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            panel.canChooseFiles = true
            panel.allowedContentTypes = [.png, .jpeg, .tiff, .gif]

            guard panel.runModal() == .OK, let url = panel.url else {
                return // キャンセルしたら中断（それまで選んだ分も反映しない）
            }
            pickedURLs[stage] = url
        }

        do {
            let dir = try customImagesDirectory()
            for (stage, sourceURL) in pickedURLs {
                let destURL = dir.appendingPathComponent("\(stage.fileSuffix).png")
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destURL)
            }
            clearCustomImageCache()
            selectedBreed = .custom
            for (b, item) in breedMenuItems { item.state = (b == .custom) ? .on : .off }
            updateStatus()
        } catch {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "カスタム画像の保存に失敗しました"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
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
