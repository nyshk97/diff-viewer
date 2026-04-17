import AppKit
import Carbon.HIToolbox
import SwiftUI

class FloatingPanel: NSPanel, NSWindowDelegate {
    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        backgroundColor = NSColor(GitHubDark.background)

        self.contentView = contentView
        self.delegate = self

        centerOnScreen()
    }

    func centerOnScreen() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let width = screenFrame.width * 0.8
        let height = screenFrame.height * 0.8
        let x = screenFrame.origin.x + (screenFrame.width - width) / 2
        let y = screenFrame.origin.y + (screenFrame.height - height) / 2
        setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == kVK_Escape {
            orderOut(nil)
        } else {
            super.keyDown(with: event)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        orderOut(nil)
    }

}
