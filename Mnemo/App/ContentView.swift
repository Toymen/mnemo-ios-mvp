import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CaptureView()
                .tag(0)
                .tabItem { Label("Capture", systemImage: "mic.fill") }

            ApprovalQueueView()
                .tag(1)
                .tabItem { Label("Review", systemImage: "checkmark.circle.fill") }

            MemoryListView()
                .tag(2)
                .tabItem { Label("Memories", systemImage: "brain.head.profile") }

            ProjectListView()
                .tag(3)
                .tabItem { Label("Projects", systemImage: "folder.fill") }

            DailyReflectionView()
                .tag(4)
                .tabItem { Label("Reflect", systemImage: "sun.max.fill") }

            SettingsView()
                .tag(5)
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
