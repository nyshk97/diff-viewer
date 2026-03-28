import SwiftUI

@main
struct DiffViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("DiffViewer", systemImage: "chevron.left.forwardslash.chevron.right") {
            Button("Settings...") {
                let url = URL(fileURLWithPath: configPath)
                if !FileManager.default.fileExists(atPath: configPath) {
                    let template = """
                    {
                      "repositories": [
                        "/path/to/your/repo"
                      ],
                      "shortcut": {
                        "key": "d",
                        "modifiers": ["command", "control"]
                      }
                    }
                    """
                    FileManager.default.createFile(atPath: configPath, contents: template.data(using: .utf8))
                }
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
