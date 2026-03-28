# DiffViewer

A macOS app to view Git diffs across multiple local repositories at a glance.
Launcher-style diff viewer that can be summoned anytime with a global shortcut (`Cmd + Ctrl + D`).

The panel floats above all windows, including fullscreen apps — no need to switch desktops or break your workflow.

![DiffViewer Screenshot](docs/screenshot.png)

## Install

```
brew install nyshk97/tap/diff-viewer
```

## Note

When you first open DiffViewer (or after a macOS restart), you may see a warning saying **"DiffViewer.app" is not opened**. This is because the app is not signed with an Apple Developer certificate.

To allow the app to open:

1. Open **System Settings** > **Privacy & Security**
2. Scroll down to the **Security** section
3. You will see a message about DiffViewer being blocked — click **Open Anyway**
4. Confirm in the dialog that appears

This only needs to be done once (or again after a macOS update).

## Setup

Add the paths of the repositories you want to monitor to the config file.

```json
// ~/.diffviewer
{
  "repositories": [
    "/Users/you/project-a",
    "/Users/you/project-b"
  ],
  "shortcut": {
    "key": "d",
    "modifiers": ["command", "control"]
  }
}
```

The `shortcut` field is optional (defaults to `Cmd + Ctrl + D`). Available modifiers: `command`, `control`, `option`, `shift`. Changing the shortcut requires an app restart.

## Usage

1. Launch the app (it stays in the menu bar)
2. Press `Cmd + Ctrl + D` (or your custom shortcut) to show the panel
3. Press the same shortcut or `Esc` to dismiss
