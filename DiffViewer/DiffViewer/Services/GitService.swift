import Foundation

enum GitService {
    nonisolated static func fetchDiffs(for config: Config) -> [RepositoryDiff] {
        config.repositories.compactMap { path in
            let name = URL(fileURLWithPath: path).lastPathComponent
            let unstagedFiles = parseDiff(runGit(["diff", "-M"], at: path), stage: .unstaged)
            let stagedFiles = parseDiff(runGit(["diff", "--staged", "-M"], at: path), stage: .staged)
            let diffFileNames = Set((unstagedFiles + stagedFiles).map { $0.fileName })
            let deletedFiles = fetchDeletedFiles(at: path).filter { !diffFileNames.contains($0.fileName) }
            let untrackedFiles = fetchUntrackedFiles(at: path)
            let (matched, remainingDeleted, remainingNew) = matchRenames(deleted: deletedFiles, untracked: untrackedFiles, repoPath: path)
            let files = unstagedFiles + stagedFiles + matched + remainingDeleted + remainingNew
            return RepositoryDiff(name: name, path: path, files: files)
        }
    }

    nonisolated private static func fetchUntrackedFiles(at repoPath: String) -> [FileDiff] {
        let output = runGit(["ls-files", "--others", "--exclude-standard"], at: repoPath)
        guard !output.isEmpty else { return [] }

        return output.components(separatedBy: "\n").compactMap { line in
            let fileName = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fileName.isEmpty else { return nil }

            let filePath = (repoPath as NSString).appendingPathComponent(fileName)
            guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return nil }

            let contentLines = content.components(separatedBy: "\n")
            let diffLines = contentLines.enumerated().map { index, text in
                DiffLine(oldLineNumber: nil, newLineNumber: index + 1, content: text, type: .addition)
            }

            guard !diffLines.isEmpty else { return nil }
            let hunk = DiffHunk(header: "@@ -0,0 +1,\(diffLines.count) @@", lines: diffLines)
            return FileDiff(fileName: fileName, hunks: [hunk], stage: .unstaged, isNew: true, renamedFrom: nil, isDeleted: false)
        }
    }

    nonisolated private static func fetchDeletedFiles(at repoPath: String) -> [FileDiff] {
        let output = runGit(["ls-files", "--deleted"], at: repoPath)
        guard !output.isEmpty else { return [] }

        return output.components(separatedBy: "\n").compactMap { line in
            let fileName = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fileName.isEmpty else { return nil }
            return FileDiff(fileName: fileName, hunks: [], stage: .unstaged, isNew: false, renamedFrom: nil, isDeleted: true)
        }
    }

    nonisolated private static func matchRenames(deleted: [FileDiff], untracked: [FileDiff], repoPath: String) -> (matched: [FileDiff], remainingDeleted: [FileDiff], remainingNew: [FileDiff]) {
        var remainingDeleted = deleted
        var remainingNew = untracked
        var matched: [FileDiff] = []

        for newFile in untracked {
            guard let deleteIndex = remainingDeleted.firstIndex(where: {
                ($0.fileName as NSString).lastPathComponent == (newFile.fileName as NSString).lastPathComponent
            }) else { continue }

            let deletedFile = remainingDeleted[deleteIndex]
            matched.append(FileDiff(fileName: newFile.fileName, hunks: newFile.hunks, stage: .unstaged, isNew: false, renamedFrom: deletedFile.fileName, isDeleted: false))
            remainingDeleted.remove(at: deleteIndex)
            remainingNew.removeAll { $0.fileName == newFile.fileName }
        }

        return (matched, remainingDeleted, remainingNew)
    }

    nonisolated private static func runGit(_ args: [String], at path: String) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path] + args
        process.environment = ["HOME": NSHomeDirectory()]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    nonisolated private static func parseDiff(_ output: String, stage: DiffStage) -> [FileDiff] {
        guard !output.isEmpty else { return [] }

        var files: [FileDiff] = []
        var currentFileName: String?
        var currentRenamedFrom: String?
        var currentIsDeleted = false
        var currentHunks: [DiffHunk] = []
        var currentHunkHeader: String = ""
        var currentLines: [DiffLine] = []
        var oldLine = 0
        var newLine = 0

        func flushHunk() {
            if !currentLines.isEmpty {
                currentHunks.append(DiffHunk(header: currentHunkHeader, lines: currentLines))
                currentLines = []
            }
        }

        func flushFile() {
            flushHunk()
            if let fileName = currentFileName {
                if !currentHunks.isEmpty || currentRenamedFrom != nil || currentIsDeleted {
                    files.append(FileDiff(fileName: fileName, hunks: currentHunks, stage: stage, isNew: false, renamedFrom: currentRenamedFrom, isDeleted: currentIsDeleted))
                }
            }
            currentHunks = []
            currentFileName = nil
            currentRenamedFrom = nil
            currentIsDeleted = false
        }

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("diff --git") {
                flushFile()
            } else if line.hasPrefix("rename from ") {
                currentRenamedFrom = String(line.dropFirst(12))
            } else if line.hasPrefix("rename to ") {
                currentFileName = String(line.dropFirst(10))
            } else if line.hasPrefix("+++ /dev/null") {
                currentIsDeleted = true
            } else if line.hasPrefix("+++ b/") {
                currentFileName = String(line.dropFirst(6))
            } else if line.hasPrefix("--- a/") {
                if currentFileName == nil {
                    currentFileName = String(line.dropFirst(6))
                }
            } else if line.hasPrefix("--- /dev/null") {
                continue
            } else if line.hasPrefix("@@") {
                flushHunk()
                currentHunkHeader = line
                let numbers = parseHunkHeader(line)
                oldLine = numbers.oldStart
                newLine = numbers.newStart
            } else if line.hasPrefix("+") {
                currentLines.append(DiffLine(oldLineNumber: nil, newLineNumber: newLine, content: String(line.dropFirst()), type: .addition))
                newLine += 1
            } else if line.hasPrefix("-") {
                currentLines.append(DiffLine(oldLineNumber: oldLine, newLineNumber: nil, content: String(line.dropFirst()), type: .deletion))
                oldLine += 1
            } else if line.hasPrefix(" ") {
                currentLines.append(DiffLine(oldLineNumber: oldLine, newLineNumber: newLine, content: String(line.dropFirst()), type: .context))
                oldLine += 1
                newLine += 1
            }
        }

        flushFile()
        return files
    }

    nonisolated private static func parseHunkHeader(_ header: String) -> (oldStart: Int, newStart: Int) {
        let pattern = #"@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: header, range: NSRange(header.startIndex..., in: header)),
              let oldRange = Range(match.range(at: 1), in: header),
              let newRange = Range(match.range(at: 2), in: header),
              let oldStart = Int(header[oldRange]),
              let newStart = Int(header[newRange]) else {
            return (1, 1)
        }
        return (oldStart, newStart)
    }
}
