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
            } else if viewModel.repositoriesWithChanges.isEmpty {
                EmptyStateView(message: "変更なし")
            } else {
                VStack(spacing: 0) {
                    if viewModel.repositoriesWithChanges.count > 1 {
                        RepositoryTabBar(viewModel: viewModel)
                    }

                    ScrollView {
                        LazyVStack(spacing: 24) {
                            if let repo = viewModel.selectedRepository {
                                RepositorySection(repository: repo)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
    }
}

struct RepositoryTabBar: View {
    var viewModel: DiffViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(viewModel.repositoriesWithChanges) { repo in
                    let isSelected = viewModel.selectedRepository?.id == repo.id
                    RepositoryTab(
                        name: repo.name,
                        fileCount: repo.files.count,
                        isSelected: isSelected
                    ) {
                        viewModel.selectedRepositoryId = repo.id
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 40)
        .background(GitHubDark.surfaceBackground)
        .overlay(alignment: .bottom) {
            GitHubDark.border.frame(height: 1)
        }
    }
}

struct RepositoryTab: View {
    let name: String
    let fileCount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 11))
                Text(name)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                Text("\(fileCount)")
                    .font(.system(size: 11, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule()
                            .fill(isSelected ? GitHubDark.text.opacity(0.15) : GitHubDark.textSecondary.opacity(0.15))
                    )
            }
            .foregroundColor(isSelected ? GitHubDark.text : GitHubDark.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(alignment: .bottom) {
                if isSelected {
                    Rectangle()
                        .fill(Color(red: 210/255, green: 153/255, blue: 34/255))
                        .frame(height: 2)
                        .offset(y: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
