import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem { Label("Capture", systemImage: "mic.fill") }

            ApprovalQueueView()
                .tabItem { Label("Review", systemImage: "checkmark.circle.fill") }

            MemoryListView()
                .tabItem { Label("Memories", systemImage: "brain.head.profile") }

            ProjectListView()
                .tabItem { Label("Projects", systemImage: "folder.fill") }

            DailyReflectionView()
                .tabItem { Label("Reflect", systemImage: "sun.max.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
