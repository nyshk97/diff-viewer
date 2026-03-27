import SwiftUI

struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(GitHubDark.textSecondary)
            Text(message)
                .font(.system(size: 16, design: .monospaced))
                .foregroundColor(GitHubDark.textSecondary)
        }
    }
}
