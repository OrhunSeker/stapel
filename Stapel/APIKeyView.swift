import SwiftUI

/// Connecting Claude: what it's for, how to get a key, and where to put it.
struct APIKeyView: View {
    @State private var key = Keychain.apiKey ?? ""
    @State private var status: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section {
                Text("Claude fixes your spelling and fills in the meaning and an example sentence when you add a word. Everything else in Stapel works without it, and you can always type a card yourself.")
            }

            Section("Get a key (about 5 minutes)") {
                Link(destination: URL(string: "https://console.anthropic.com")!) {
                    Label("1. Open the Anthropic Console", systemImage: "arrow.up.right.square")
                }
                Text("2. Sign in. A Claude chat subscription doesn't include API use, so this is separate.")
                Text("3. Under Billing, buy a small amount of credit.")
                Text("4. Under Limits, set a low monthly spend limit, so a mistake can't cost much.")
                Text("5. Under API Keys, create a key and copy it. It's only shown once.")
            }

            Section {
                SecureField("sk-ant-…", text: $key)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Save Key") { save() }
                    .disabled(key.trimmed.isEmpty)
                Button {
                    Task { await test() }
                } label: {
                    if isTesting { ProgressView() } else { Text("Test Key") }
                }
                .disabled(key.trimmed.isEmpty || isTesting)
                if Keychain.apiKey != nil {
                    Button("Remove Key", role: .destructive) {
                        Keychain.apiKey = nil
                        key = ""
                        status = "Key removed."
                    }
                }
            } header: {
                Text("Your key")
            } footer: {
                if let status { Text(status) }
            }

            Section("Cost & privacy") {
                Text("Adding a word usually costs a tiny fraction of a cent. Studying is free and works offline.")
                Text("Your key stays in this iPhone's encrypted Keychain. Only the text you type when adding a word is sent, and only to Anthropic. Never share your key or put it in code.")
            }
        }
        .navigationTitle("Claude API Key")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        Keychain.apiKey = key.trimmed
        status = "Saved in this iPhone's Keychain."
    }

    /// Makes one small real request, which costs a tiny fraction of a cent.
    private func test() async {
        save()
        isTesting = true
        defer { isTesting = false }
        do {
            _ = try await CardAssistant.draft(for: "Test")
            status = "It works! You're connected to Claude."
        } catch {
            status = error.localizedDescription
        }
    }
}
