import AppKit
import ApplicationServices

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var radialWindowManager: RadialWindowManager?
    private var statusItem: NSStatusItem?
    private var accessibilityMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        requestAccessibilityPermission()
        installStatusItem()

        radialWindowManager = RadialWindowManager()
        radialWindowManager?.startMonitoring()
    }

    func applicationWillTerminate(_ notification: Notification) {
        radialWindowManager?.stopMonitoring()
    }

    private func requestAccessibilityPermission() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        if !AXIsProcessTrustedWithOptions(options) {
            NSLog(
                "Enable Accessibility access in System Settings > Privacy & Security > Accessibility."
            )
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let logo = NSImage(named: "DonutLogo")
        logo?.isTemplate = false
        logo?.size = NSSize(width: 18, height: 18)
        item.button?.image = logo
        item.button?.imageScaling = .scaleProportionallyDown
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "Donut"

        let menu = NSMenu()
        let status = NSMenuItem(
            title: "Donut is running",
            action: nil,
            keyEquivalent: ""
        )
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let accessibility = NSMenuItem(
            title: accessibilityMenuTitle,
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        accessibility.target = self
        menu.addItem(accessibility)
        accessibilityMenuItem = accessibility

        let quit = NSMenuItem(
            title: "Quit Donut",
            action: #selector(terminate),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    private var accessibilityMenuTitle: String {
        AXIsProcessTrusted()
            ? "Accessibility: Enabled"
            : "Accessibility: Required"
    }

    @objc private func openAccessibilitySettings() {
        accessibilityMenuItem?.title = accessibilityMenuTitle
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    @objc private func terminate() {
        NSApp.terminate(nil)
    }
}
