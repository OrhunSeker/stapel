import SwiftUI
import SwiftData

/// All cards in one pile (or Known Words). Tap to edit, swipe to delete.
struct CardListView: View {
    let pile: Int

    @Environment(\.modelContext) private var context
    @Query private var cards: [Card]
    @State private var editing: Card?

    init(pile: Int) {
        self.pile = pile
        _cards = Query(filter: #Predicate<Card> { $0.pile == pile }, sort: \.createdAt, order: .reverse)
    }

    var body: some View {
        List {
            ForEach(cards) { card in
                Button {
                    editing = card
                } label: {
                    VStack(alignment: .leading) {
                        Text(card.term).font(.headline)
                        Text(card.meaning).foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
            }
            .onDelete { offsets in
                for i in offsets { context.delete(cards[i]) }
            }
        }
        .overlay {
            if cards.isEmpty {
                ContentUnavailableView("Empty", systemImage: "tray", description: Text(pile == Pile.known
    ? "Words you know in Pile 3 land here."
    : "Cards will show up here as you learn."))
            }
        }
        .navigationTitle(Pile.title(pile))
        .sheet(item: $editing) { CardEditor(card: $0) }
    }
}
