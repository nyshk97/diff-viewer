import SwiftUI

struct RepositorySection: View {
    let repository: RepositoryDiff

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Repository header
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .foregroundColor(GitHubDark.textSecondary)
                Text(repository.name)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(GitHubDark.text)
                Text("\(repository.files.count) file\(repository.files.count == 1 ? "" : "s")")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(GitHubDark.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 4)

            // File diffs
            ForEach(repository.files) { file in
                FileDiffView(file: file, repoPath: repository.path)
            }
        }
    }
}
