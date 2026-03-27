import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color(nsColor: NSColor(red: 13/255, green: 17/255, blue: 23/255, alpha: 1))
            Text("Diff Viewer")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 230/255, green: 237/255, blue: 243/255))
        }
    }
}

#Preview {
    ContentView()
}
