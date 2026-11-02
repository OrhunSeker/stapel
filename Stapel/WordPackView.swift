import SwiftUI
import SwiftData

/// The ready-made A1–B1 lists bundled with the app.
enum WordPacks {
    /// Each entry: [term, plural, meaning, example, exampleMeaning, gap word]
    static let all: [String: [[String]]] = {
        guard let url = Bundle.main.url(forResource: "WordPacks", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [:] }
        return (try? JSONDecoder().decode([String: [[String]]].self, from: data)) ?? [:]
    }()

    /// Gap words by entry, so cards added from the packs before gaps existed get one too.
    static let clozes = Dictionary(all.values.joined().map { ($0[0], $0[5]) }) { first, _ in first }
}

/// Adds 10 random ready-made words and phrases from a level to Pile 1.
struct WordPackView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var cards: [Card]
    @State private var added: [String] = []

    private let levels = [
        ("A1", "Beginner · first words & phrases"),
        ("A2", "Elementary · everyday situations"),
        ("B1", "Intermediate · opinions & plans"),
    ]

    var body: some View {
        let existing = Set(cards.map(\.term.duplicateKey))
        NavigationStack {
            List {
                Section {
                    ForEach(levels, id: \.0) { level, description in
                        let unused = (WordPacks.all[level] ?? []).filter { !existing.contains($0[0].duplicateKey) }
                        Button {
                            add(unused)
                        } label: {
                            LabeledContent {
                                Text(unused.isEmpty ? "All added" : "\(unused.count) left")
                            } label: {
                                Text(level).font(.headline)
                                Text(description)
                            }
                        }
                        .tint(.primary)
                        .disabled(unused.isEmpty)
                    }
                } footer: {
                    Text("Adds 10 random words and everyday phrases to Pile 1. Ones you already have are skipped.")
                }

                if !added.isEmpty {
                    Section("Added to Pile 1") {
                        ForEach(added, id: \.self) { Text($0) }
                    }
                }
            }
            .navigationTitle("Add 10 Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }

    private func add(_ unused: [[String]]) {
        let picked = unused.shuffled().prefix(10)
        for e in picked {
            context.insert(Card(CardDraft(term: e[0], plural: e[1], meaning: e[2],
                                          example: e[3], exampleMeaning: e[4], cloze: e[5])))
        }
        added = picked.map { $0[0] }
    }
}
