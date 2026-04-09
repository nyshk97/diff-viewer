import Foundation
import Observation

@Observable
class DiffViewModel {
    var repositories: [RepositoryDiff] = []
    var isLoading = false
    var errorMessage: String?
    var selectedRepositoryId: UUID?

    var repositoriesWithChanges: [RepositoryDiff] {
        repositories.filter(\.hasChanges)
    }

    var selectedRepository: RepositoryDiff? {
        guard let id = selectedRepositoryId else { return repositoriesWithChanges.first }
        return repositoriesWithChanges.first { $0.id == id }
    }

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
                    // 選択中のリポジトリが変更なしになった場合、リセット
                    if let id = self.selectedRepositoryId,
                       !self.repositoriesWithChanges.contains(where: { $0.id == id }) {
                        self.selectedRepositoryId = nil
                    }
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
