import Foundation

struct Config: Codable, Sendable {
    let repositories: [String]
}

let configPath = NSString("~/.config/diff-viewer/config.json").expandingTildeInPath

enum ConfigService {
    nonisolated static func load() throws -> Config {
        let url = URL(fileURLWithPath: configPath)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Config.self, from: data)
    }
}
