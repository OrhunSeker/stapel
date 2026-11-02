import AppIntents
import Foundation
import Observation
import SwiftData
import SwiftUI

/// "Earn your scrolling": a Shortcuts automation runs `CheckInstagramPass` whenever a chosen app opens.
/// With a valid pass nothing happens; otherwise Stapel opens a quick round first.
@Observable
final class AppGate {
    static let shared = AppGate()
    var isShowing = false

    static let passMinutes = 15
    static let roundSize = 5
    static let roundMaxLength = 10
    /// Every this-many-th round comes from Pile 2, so those words don't get rusty.
    static let pile2Interval = 10
    private static let passKey = "gatePassUntil"
    private static let roundsKey = "gateRounds"

    static var hasPass: Bool {
        UserDefaults.standard.double(forKey: passKey) > Date.now.timeIntervalSince1970
    }

    static func grantPass() {
        let until = Date.now.addingTimeInterval(Double(passMinutes) * 60)
        UserDefaults.standard.set(until.timeIntervalSince1970, forKey: passKey)
        UserDefaults.standard.set(UserDefaults.standard.integer(forKey: roundsKey) + 1, forKey: roundsKey)
    }

    static func nextPile(pile2HasCards: Bool) -> Int {
        let next = UserDefaults.standard.integer(forKey: roundsKey) + 1
        return pile2HasCards && next.isMultiple(of: pile2Interval) ? 2 : 1
    }
}

/// The app a finished round leads back to. These links are unofficial and apps can change them;
/// for "other", people simply return to their app themselves and their pass still applies.
enum GatedApp: String, CaseIterable, Identifiable {
    case instagram, x, youtube, facebook, snapchat, reddit, other

    var id: Self { self }

    var name: String {
        switch self {
        case .instagram: "Instagram"
        case .x: "X"
        case .youtube: "YouTube"
        case .facebook: "Facebook"
        case .snapchat: "Snapchat"
        case .reddit: "Reddit"
        case .other: "your app"
        }
    }

    var link: URL? {
        switch self {
        case .instagram: URL(string: "instagram://app")
        case .x: URL(string: "twitter://")
        case .youtube: URL(string: "youtube://")
        case .facebook: URL(string: "fb://")
        case .snapchat: URL(string: "snapchat://")
        case .reddit: URL(string: "reddit://")
        case .other: nil
        }
    }
}

/// The quick round shown before the chosen app. Its pile is chosen once, so it can't change mid-round.
struct AppGateRound: View {
    @Query private var cards: [Card]
    @State private var pile: Int?

    var body: some View {
        NavigationStack {
            if let pile {
                StudyView(pile: pile, forAppGate: true)
            }
        }
        .onAppear {
            if pile == nil {
                pile = AppGate.nextPile(pile2HasCards: cards.contains { $0.pile == 2 })
            }
        }
    }
}

// The type name stays as it was, because existing Shortcuts automations refer to it.
struct CheckInstagramPass: AppIntent {
    static let title: LocalizedStringResource = "Check App Pass"
    static let description = IntentDescription(
        "Opens a quick round in Stapel, unless you've earned a pass in the last 15 minutes.")
    static let supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    @MainActor
    func perform() async throws -> some IntentResult {
        guard !AppGate.hasPass else { return .result() }
        AppGate.shared.isShowing = true
        try await continueInForeground(alwaysConfirm: false)
        return .result()
    }
}

/// Lists the action under Stapel in the Shortcuts app, so it's easy to find for the automation.
struct StapelShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: CheckInstagramPass(),
                    phrases: ["Check my app pass in \(.applicationName)"],
                    shortTitle: "App Pass",
                    systemImageName: "lock.open.fill")
    }
}
