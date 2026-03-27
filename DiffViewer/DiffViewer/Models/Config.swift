import Foundation
import Carbon.HIToolbox

struct ShortcutConfig: Codable, Sendable {
    let key: String
    let modifiers: [String]

    static let `default` = ShortcutConfig(key: "d", modifiers: ["command", "control"])
}

struct Config: Codable, Sendable {
    let repositories: [String]
    let shortcut: ShortcutConfig?
}

let configPath = NSString("~/.config/diff-viewer/config.json").expandingTildeInPath

enum ConfigService {
    nonisolated static func load() throws -> Config {
        let url = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Config.self, from: data)
    }
}

enum KeyMapping {
    static func keyCode(for key: String) -> Int? {
        let map: [String: Int] = [
            "a": kVK_ANSI_A, "b": kVK_ANSI_B, "c": kVK_ANSI_C, "d": kVK_ANSI_D,
            "e": kVK_ANSI_E, "f": kVK_ANSI_F, "g": kVK_ANSI_G, "h": kVK_ANSI_H,
            "i": kVK_ANSI_I, "j": kVK_ANSI_J, "k": kVK_ANSI_K, "l": kVK_ANSI_L,
            "m": kVK_ANSI_M, "n": kVK_ANSI_N, "o": kVK_ANSI_O, "p": kVK_ANSI_P,
            "q": kVK_ANSI_Q, "r": kVK_ANSI_R, "s": kVK_ANSI_S, "t": kVK_ANSI_T,
            "u": kVK_ANSI_U, "v": kVK_ANSI_V, "w": kVK_ANSI_W, "x": kVK_ANSI_X,
            "y": kVK_ANSI_Y, "z": kVK_ANSI_Z,
            "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
            "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
            "8": kVK_ANSI_8, "9": kVK_ANSI_9,
            "space": kVK_Space, "return": kVK_Return, "tab": kVK_Tab,
            "escape": kVK_Escape, "delete": kVK_Delete,
            "up": kVK_UpArrow, "down": kVK_DownArrow,
            "left": kVK_LeftArrow, "right": kVK_RightArrow,
        ]
        return map[key.lowercased()]
    }

    static func carbonModifiers(for modifiers: [String]) -> Int {
        var flags: Int = 0
        for mod in modifiers {
            switch mod.lowercased() {
            case "command", "cmd": flags |= cmdKey
            case "control", "ctrl": flags |= controlKey
            case "option", "alt": flags |= optionKey
            case "shift": flags |= shiftKey
            default: break
            }
        }
        return flags
    }
}
