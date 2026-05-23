import SwiftUI

@main
struct MnemoApp: App {
    @StateObject private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            Group {
                if container.isReady {
                    ContentView()
                        .environmentObject(container)
                        .transition(.opacity)
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.4), value: container.isReady)
            .task {
                await container.preload()
            }
        }
    }
}

private struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            MnemoLogo(size: .large)
                .symbolEffect(.pulse, options: .repeating)
            Text("Loading your memories\u{2026}")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
