import SwiftUI

struct ContentView: View {
    var viewModel: DiffViewModel

    var body: some View {
        ZStack {
            GitHubDark.background.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(GitHubDark.textSecondary)
            } else if let errorMessage = viewModel.errorMessage {
                EmptyStateView(message: errorMessage)
            } else if viewModel.repositories.allSatisfy({ !$0.hasChanges }) {
                EmptyStateView(message: "変更なし")
            } else {
                ScrollView {
                    LazyVStack(spacing: 24) {
                        ForEach(viewModel.repositories.filter(\.hasChanges)) { repo in
                            RepositorySection(repository: repo)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}
