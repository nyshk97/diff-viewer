import Foundation

enum DiffStage: String {
    case unstaged = "Unstaged"
    case staged = "Staged"
}

struct DiffLine: Identifiable {
    let id = UUID()
    let oldLineNumber: Int?
    let newLineNumber: Int?
    let content: String
    let type: LineType

    enum LineType {
        case context
        case addition
        case deletion
    }
}

struct DiffHunk: Identifiable {
    let id = UUID()
    let header: String
    let lines: [DiffLine]
}

enum FileChangeType: Equatable {
    case modified
    case new
    case deleted
    case renamed(from: String)
}

struct FileDiff: Identifiable {
    let id = UUID()
    let fileName: String
    let hunks: [DiffHunk]
    let stage: DiffStage
    let changeType: FileChangeType
}

struct RepositoryDiff: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let files: [FileDiff]

    var hasChanges: Bool { !files.isEmpty }
}
