import SwiftUI

struct FileDiffView: View {
    let file: FileDiff
    @State private var isExpanded = true
    @State private var showCopied = false

    var body: some View {
        VStack(spacing: 0) {
            // File header
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(GitHubDark.textSecondary)
                        .frame(width: 12)

                    Text(file.stage.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(file.stage == .staged ? GitHubDark.stagedBadge : GitHubDark.unstagedBadge)
                        )

                    Text(file.fileName)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(GitHubDark.text)

                    Button(action: {
                        let pathToCopy = file.fileName.replacingOccurrences(of: " (new)", with: "")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(pathToCopy, forType: .string)
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showCopied = false
                        }
                    }) {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                            .foregroundColor(showCopied ? GitHubDark.additionText : GitHubDark.textSecondary)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(GitHubDark.fileHeader)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Rectangle()
                    .fill(GitHubDark.border)
                    .frame(height: 1)

                VStack(spacing: 0) {
                    ForEach(file.hunks) { hunk in
                        SideBySideDiffView(hunk: hunk)
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(GitHubDark.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
