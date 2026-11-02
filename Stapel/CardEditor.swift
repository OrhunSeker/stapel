import SwiftUI
import SwiftData

/// Add a new card (card == nil) or edit an existing one. Same form for both.
struct CardEditor: View {
    var card: Card?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCards: [Card]

    @State private var input = ""
    @State private var draft = CardDraft()
    @State private var showFields = false
    @State private var isChecking = false
    @State private var note: String?
    @State private var duplicate: String?

    var body: some View {
        NavigationStack {
            Form {
                if card == nil {
                    Section {
                        TextField("\(Language.learning) word, phrase or sentence", text: $input, axis: .vertical)
                            .autocorrectionDisabled()
                        Button {
                            Task { await check() }
                        } label: {
                            if isChecking { ProgressView() } else { Text("Check & fill in") }
                        }
                        .disabled(input.trimmed.isEmpty || isChecking)
                        Button("Skip, I'll type it myself") {
                            draft = CardDraft(term: input.trimmed)
                            note = nil
                            showFields = true
                        }
                        .disabled(input.trimmed.isEmpty)
                    } footer: {
                        if let note { Text(note) }
                    }
                }

                if card != nil || showFields {
                    Section(Language.learning) {
                        TextField("Word, phrase or sentence", text: $draft.term, axis: .vertical)
                        if Language.showsPlural {
                            TextField("Plural (nouns only)", text: $draft.plural)
                        }
                    }
                    Section(Language.native) {
                        TextField("Meaning", text: $draft.meaning, axis: .vertical)
                    }
                    Section("Example") {
                        TextField("\(Language.learning) sentence", text: $draft.example, axis: .vertical)
                        TextField("\(Language.native) translation", text: $draft.exampleMeaning, axis: .vertical)
                    }
                }

                if let card {
                    Section {
                        if card.pile != 1 {
                            Button("Move back to Pile 1") {
                                card.pile = 1
                                dismiss()
                            }
                        }
                        Button("Delete Card", role: .destructive) {
                            context.delete(card)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(card == nil ? "Add Word" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(draft.term.trimmed.isEmpty || draft.meaning.trimmed.isEmpty)
                }
            }
            .alert("Already saved", isPresented: .constant(duplicate != nil)) {
                Button("OK") { duplicate = nil }
            } message: {
                Text(duplicate ?? "")
            }
            .onAppear {
                if let card { draft = CardDraft(card: card) }
            }
        }
    }

    private func check() async {
        let text = input.trimmed
        isChecking = true
        defer { isChecking = false }
        do {
            draft = try await CardAssistant.draft(for: text)
            note = draft.term.duplicateKey == text.duplicateKey
                ? nil
                : "Did you mean “\(draft.term)”? You typed “\(text)”. Change it below if needed."
        } catch {
            draft = CardDraft(term: text)
            note = "Couldn't fill this in automatically (\(error.localizedDescription)). Please enter the meaning yourself."
        }
        showFields = true
    }

    /// The duplicate check runs on the final (corrected) text.
    private func save() {
        let key = draft.term.duplicateKey
        if let existing = allCards.first(where: { $0 !== card && $0.term.duplicateKey == key }) {
            duplicate = "“\(existing.term)” is already in \(Pile.title(existing.pile))."
            return
        }
        if let card {
            card.update(from: draft)
        } else {
            context.insert(Card(draft))
        }
        dismiss()
    }
}
