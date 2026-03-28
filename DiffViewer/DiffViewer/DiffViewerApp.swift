import SwiftUI

@main
struct DiffViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("DiffViewer", systemImage: "chevron.left.forwardslash.chevron.right") {
            Button("Settings...") {
                let url = URL(fileURLWithPath: configPath)
                let template = Data("""
                {
                  "repositories": [
                    "/path/to/your/repo"
                  ],
                  "shortcut": {
                    "key": "d",
                    "modifiers": ["command", "control"]
                  }
                }
                """.utf8)
                try? template.write(to: url, options: .withoutOverwriting)
                NSWorkspace.shared.open(url)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
