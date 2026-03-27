import Foundation
import Observation

@Observable
class DiffViewModel {
    var repositories: [RepositoryDiff] = []
    var isLoading = false
    var errorMessage: String?

    func loadDiffs() {
        isLoading = true
        errorMessage = nil

        Task.detached { @Sendable in
            do {
                let config = try ConfigService.load()
                let diffs = GitService.fetchDiffs(for: config)
                await MainActor.run {
                    self.repositories = diffs
                    self.isLoading = false
                }
            } catch {
                let message = error.localizedDescription
                await MainActor.run {
                    self.errorMessage = "設定ファイルの読み込みに失敗: \(message)"
                    self.isLoading = false
                }
            }
        }
    }
}
