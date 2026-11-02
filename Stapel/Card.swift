import Foundation
import SwiftData
import SwiftUI

/// One flashcard. Which list it belongs to is just a number:
/// 1, 2, 3 are the piles, 4 means "Known".
@Model
final class Card {
    // originalName keeps cards saved before these fields had language-neutral names.
    @Attribute(originalName: "german") var term = ""
    var plural = ""
    @Attribute(originalName: "english") var meaning = ""
    @Attribute(originalName: "exampleGerman") var example = ""
    @Attribute(originalName: "exampleEnglish") var exampleMeaning = ""
    /// The word(s) to blank out in the example sentence, as written there ("gehe" for "gehen").
    var cloze = ""
    var pile = 1
    var createdAt = Date.now
    /// Set when you answer "Not yet", so missed cards come back first next session.
    var lastMissed: Date?

    init(_ draft: CardDraft) {
        update(from: draft)
    }

    func update(from draft: CardDraft) {
        term = draft.term.trimmed
        plural = draft.plural.trimmed
        meaning = draft.meaning.trimmed
        example = draft.example.trimmed
        exampleMeaning = draft.exampleMeaning.trimmed
        cloze = draft.cloze.trimmed
    }

    /// "Not yet" sends the card back to pile 1, "I knew it" moves it one step up.
    func answer(knewIt: Bool) {
        pile = knewIt ? min(pile + 1, Pile.known) : 1
        lastMissed = knewIt ? nil : .now
    }

    /// The example sentence split around the gap, or nil when no sensible gap can be found.
    var gap: (before: String, answer: String, after: String)? {
        guard !example.isEmpty else { return nil }
        let known = [cloze, WordPacks.clozes[term] ?? ""].first { !$0.isEmpty }
        guard let found = known.flatMap({ example.range(of: $0, options: .caseInsensitive) }) ?? guessedGap
        else { return nil }
        // Blank whole words only, so "Vorteil" in "Vorteile" doesn't leave "___e".
        var lower = found.lowerBound, upper = found.upperBound
        while lower > example.startIndex, example[example.index(before: lower)].isLetter {
            lower = example.index(before: lower)
        }
        while upper < example.endIndex, example[upper].isLetter {
            upper = example.index(after: upper)
        }
        return (String(example[..<lower]), String(example[lower..<upper]), String(example[upper...]))
    }

    /// For older cards without a stored gap: find a word in the sentence that starts like the entry.
    private var guessedGap: Range<String.Index>? {
        let words = term.split { !$0.isLetter }.map(String.init)
            .filter { !Language.gapSkipWords.contains($0.lowercased()) }
            .sorted { $0.count > $1.count }
        let tokens = example.split { !$0.isLetter }
        for word in words {
            let stem = word.folded.prefix(word.count <= 4 ? word.count : max(4, word.count - 2))
            if let token = tokens.first(where: { $0.folded.hasPrefix(stem) }) {
                return token.startIndex..<token.endIndex
            }
        }
        return nil
    }
}

extension [Card] {
    /// Missed cards first (longest waiting first), then the rest at random.
    func prioritized(_ count: Int) -> [Card] {
        let missed = filter { $0.lastMissed != nil }.sorted { $0.lastMissed! < $1.lastMissed! }
        let others = filter { $0.lastMissed == nil }.shuffled()
        return Array((missed + others).prefix(count)).shuffled()
    }
}

enum Pile {
    static let known = 4

    static func title(_ pile: Int) -> String {
        pile == known ? "Known Words" : "Pile \(pile)"
    }

    static func subtitle(_ pile: Int) -> String {
        switch pile {
        case 1: "New & forgotten"
        case 2: "Getting there"
        case 3: "Almost known"
        default: "You've got these"
        }
    }

    static func icon(_ pile: Int) -> String {
        switch pile {
        case 1: "sparkles"
        case 2: "arrow.triangle.2.circlepath"
        case 3: "star.fill"
        default: "checkmark.seal.fill"
        }
    }

    static func colors(_ pile: Int) -> [Color] {
        switch pile {
        case 1: [.orange, .red]
        case 2: [.cyan, .blue]
        case 3: [.purple, .pink]
        default: [.green, .teal]
        }
    }
}

extension StringProtocol {
    var folded: String { folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil) }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// Used for duplicate checks: "Der Hund!" and "hund" count as the same entry.
    var duplicateKey: String {
        var s = lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        for article in Language.articles where s.hasPrefix(article + " ") {
            s.removeFirst(article.count + 1)
        }
        return s
    }
}
