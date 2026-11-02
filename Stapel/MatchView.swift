import SwiftUI
import SwiftData

/// Mini game: match 5 entries with their meanings.
/// Practice only — cards stay in their piles, but mix-ups come first in the next session.
struct MatchView: View {
    @Query(filter: #Predicate<Card> { $0.pile < 4 }) private var cards: [Card]
    @State private var terms: [Card] = []
    @State private var meanings: [Card] = []
    @State private var pickedTerm: Card?
    @State private var pickedMeaning: Card?
    @State private var matched: Set<PersistentIdentifier> = []
    @State private var wrong: (term: PersistentIdentifier, meaning: PersistentIdentifier)?
    @State private var mistakes = 0
    @State private var line = "Tap a word, then its meaning!"

    private var roundDone: Bool { !terms.isEmpty && matched.count == terms.count }

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Mascot(pile: 1, size: 56)
                SpeechBubble(text: line)
                Spacer(minLength: 0)
            }

            if terms.count < 2 {
                ContentUnavailableView("Not enough cards", systemImage: "square.grid.2x2",
                                       description: Text("Add a few words first."))
            } else {
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 10) { ForEach(terms) { tile($0, isTerm: true) } }
                    VStack(spacing: 10) { ForEach(meanings) { tile($0, isTerm: false) } }
                }
                if roundDone {
                    Button("Next round", systemImage: "arrow.right") { newRound() }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Match")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: matched.count)
        .sensoryFeedback(.error, trigger: mistakes)
        .onAppear { if terms.isEmpty { newRound() } }
    }

    private func tile(_ card: Card, isTerm: Bool) -> some View {
        let picked = (isTerm ? pickedTerm : pickedMeaning)?.id == card.id
        let isWrong = (isTerm ? wrong?.term : wrong?.meaning) == card.id
        let isMatched = matched.contains(card.id)
        let fill: Color = isWrong ? .red : isMatched ? .green : picked ? .indigo : Color(.secondarySystemGroupedBackground)
        return Button {
            pick(card, isTerm: isTerm)
        } label: {
            Text(isTerm ? card.term : card.meaning)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(picked || isWrong ? .white : .primary)
                .padding(10)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(fill.opacity(isMatched ? 0.25 : 1), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .opacity(isMatched ? 0.5 : 1)
    }

    private func pick(_ card: Card, isTerm: Bool) {
        if isTerm { pickedTerm = card } else { pickedMeaning = card }
        guard let term = pickedTerm, let meaning = pickedMeaning else { return }
        pickedTerm = nil
        pickedMeaning = nil
        Streak.recordStudy()
        if term.id == meaning.id {
            withAnimation(.snappy) {
                matched.insert(term.id)
                if roundDone {
                    line = mistakes == 0 ? "PERFECT round! 🤩" : "All matched! Mix-ups come first next time!"
                }
            }
        } else {
            term.lastMissed = .now
            mistakes += 1
            line = "Oops! Try again!"
            withAnimation { wrong = (term.id, meaning.id) }
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                withAnimation { wrong = nil }
            }
        }
    }

    private func newRound() {
        let round = cards.prioritized(5)
        // Shuffle the meanings so no pair starts side by side.
        var shuffled = round.shuffled()
        while round.count > 1, zip(round, shuffled).contains(where: { $0.id == $1.id }) {
            shuffled.shuffle()
        }
        withAnimation {
            terms = round
            meanings = shuffled
            matched = []
            mistakes = 0
            line = "Tap a word, then its meaning!"
        }
    }
}
