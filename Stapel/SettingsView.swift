import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("sessionSize") private var sessionSize = 10
    @AppStorage(Reminders.toggleKey(1)) private var pile1 = true
    @AppStorage(Reminders.toggleKey(2)) private var pile2 = true
    @AppStorage(Reminders.toggleKey(3)) private var pile3 = true
    @AppStorage("gatedApp") private var gatedApp = GatedApp.instagram
    @AppStorage("didFinishIntro") private var didFinishIntro = false

    var body: some View {
        Form {
            Section("Claude") {
                NavigationLink {
                    APIKeyView()
                } label: {
                    LabeledContent("API Key", value: Keychain.apiKey == nil ? "Not set" : "Saved")
                }
            }

            Section {
                Picker("Cards per session", selection: $sessionSize) {
                    ForEach([5, 10, 15, 20], id: \.self) { Text("\($0)") }
                }
            } header: {
                Text("Study")
            } footer: {
                Text("Cards you miss come back once at the end, so a session can run up to half as long again.")
            }

            Section {
                Toggle("Flitzi · daily at 10:00, 13:00, 18:00", isOn: $pile1)
                Toggle("Grübli · every 2 days at 12:00", isOn: $pile2)
                Toggle("Chilli · Sundays at 14:00", isOn: $pile3)
            } header: {
                Text("Reminders")
            } footer: {
                Text("Empty piles stay quiet.")
            }

            Section("Earn your scrolling") {
                Picker("App to unlock", selection: $gatedApp) {
                    ForEach(GatedApp.allCases) { app in
                        Text(app == .other ? "Other" : app.name).tag(app)
                    }
                }
                NavigationLink("Set it up") { AppGateGuideView() }
            }

            Section {
                Button("Show the intro again") {
                    didFinishIntro = false
                    dismiss()
                }
            } footer: {
                Text("Your words stay on this iPhone. Stapel has no account, ads or tracking.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Done") { dismiss() }
        }
    }
}

/// How to require a quick round before an app opens, using a Shortcuts automation.
private struct AppGateGuideView: View {
    var body: some View {
        Form {
            Section {
                Text("Earn your scrolling: opening a social app first asks for a quick round of \(AppGate.roundSize) cards, up to \(AppGate.roundMaxLength) with retries. Finish it and you get a \(AppGate.passMinutes)-minute pass.")
                Text("Every \(AppGate.pile2Interval)th round comes from Pile 2 instead of Pile 1. Answers count as usual.")
            }
            Section("Set it up once (example: Instagram)") {
                Text("1. Open the Shortcuts app and go to Automation.")
                Text("2. Tap +, then choose App.")
                Text("3. Choose Instagram and tick “Is Opened”.")
                Text("4. Choose “Run Immediately”, then Next.")
                Text("5. Tap New Blank Automation, then Add Action.")
                Text("6. Search for Stapel, choose “Check App Pass”, then Done.")
            }
            Section {
                Text("Repeat these steps for each app you want to include. They share one pass.")
                Text("If your app isn't in the list above, choose Other. When the round ends, go back to your app yourself.")
                Text("If the action doesn't show up, open Stapel once, then fully close and reopen Shortcuts.")
            }
        }
        .navigationTitle("Earn Your Scrolling")
        .navigationBarTitleDisplayMode(.inline)
    }
}
