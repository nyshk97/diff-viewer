import XCTest
@testable import DiffViewer

final class GitServiceTests: XCTestCase {
    private var repoPath: String!
    private var testFileName: String!

    override func setUpWithError() throws {
        repoPath = findDiffViewerRepoPath()
        testFileName = "テスト用ファイル_日本語.md"

        let filePath = (repoPath as NSString).appendingPathComponent(testFileName)
        FileManager.default.createFile(
            atPath: filePath,
            contents: "テスト内容\n".data(using: .utf8)
        )
    }

    override func tearDownWithError() throws {
        let filePath = (repoPath as NSString).appendingPathComponent(testFileName)
        try? FileManager.default.removeItem(atPath: filePath)
    }

    func testJapaneseFilenameNotEscaped() {
        let diffs = GitService.fetchDiffs(for: Config(repositories: [repoPath], shortcut: nil))
        guard let repo = diffs.first else {
            XCTFail("リポジトリの差分が取得できない")
            return
        }

        let file = repo.files.first { $0.fileName == testFileName }
        XCTAssertNotNil(file, "日本語ファイル名がエスケープされずに取得されるべき（取得されたファイル名: \(repo.files.map { $0.fileName })）")
    }

    func testJapaneseFileNotDetectedAsBinary() {
        let diffs = GitService.fetchDiffs(for: Config(repositories: [repoPath], shortcut: nil))
        guard let repo = diffs.first else {
            XCTFail("リポジトリの差分が取得できない")
            return
        }

        let file = repo.files.first { $0.fileName == testFileName }
        guard let file else {
            XCTFail("テスト用ファイルが見つからない")
            return
        }

        let hasBinaryContent = file.hunks.contains { hunk in
            hunk.lines.contains { $0.content == "(binary file)" }
        }
        XCTAssertFalse(hasBinaryContent, "日本語ファイル名のテキストファイルがバイナリ判定されるべきではない")
    }

    private func findDiffViewerRepoPath() -> String {
        var dir = URL(fileURLWithPath: #file).deletingLastPathComponent()
        while dir.path != "/" {
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent(".git").path) {
                return dir.path
            }
            dir = dir.deletingLastPathComponent()
        }
        fatalError("git repository not found")
    }
}
