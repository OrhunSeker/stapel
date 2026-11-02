import SwiftUI
import SwiftData

@main
struct StapelApp: App {
    @AppStorage("didFinishIntro") private var didFinishIntro = false

    var body: some Scene {
        WindowGroup {
            Group {
                if didFinishIntro {
                    HomeView()
                } else {
                    OnboardingView()
                }
            }
            .tint(.indigo)
        }
        .modelContainer(for: Card.self)
    }
}
