import AppKit
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let togglePanel = Self("togglePanel", default: .init(.d, modifiers: [.command, .control]))
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var panel: FloatingPanel?
    let viewModel = DiffViewModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let hostingView = NSHostingView(rootView: ContentView(viewModel: viewModel))
        panel = FloatingPanel(contentView: hostingView)

        applyShortcutFromConfig()

        KeyboardShortcuts.onKeyUp(for: .togglePanel) { [weak self] in
            self?.togglePanel()
        }
    }

    private func applyShortcutFromConfig() {
        guard let config = try? ConfigService.load(),
              let sc = config.shortcut,
              let keyCode = KeyMapping.keyCode(for: sc.key) else { return }

        let modifiers = KeyMapping.carbonModifiers(for: sc.modifiers)
        let shortcut = KeyboardShortcuts.Shortcut(carbonKeyCode: keyCode, carbonModifiers: modifiers)
        KeyboardShortcuts.setShortcut(shortcut, for: .togglePanel)
    }

    func togglePanel() {
        guard let panel else { return }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            viewModel.loadDiffs()
            panel.centerOnScreen()
            panel.makeKeyAndOrderFront(nil)
        }
    }
}
