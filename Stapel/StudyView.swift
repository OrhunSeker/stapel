import SwiftUI
import SwiftData

/// One study session: cards from a pile, 10 by default (up to 15 with retries).
/// The quick round before a social app is the same thing with 5 cards (up to 10).
struct StudyView: View {
    let pile: Int
    var forAppGate = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Query private var cards: [Card]
    @State private var queue: [Card] = []
    @State private var index = 0
    @State private var knewCount = 0
    @State private var flipped = false
    @State private var started = false
    @State private var editing: Card?
    @State private var showingList = false
    @State private var addingPack = false
    @State private var line = ""

    /// Cards missed in this session; each comes back once at the end.
    @State private var retried: Set<PersistentIdentifier> = []
    /// Cards shown as "fill the gap" instead of a plain flashcard (about a third).
    @State private var gapCards: Set<PersistentIdentifier> = []

    @AppStorage("sessionSize") private var chosenSessionSize = 10
    @AppStorage("gatedApp") private var gatedApp = GatedApp.instagram
    private var sessionSize: Int { forAppGate ? AppGate.roundSize : chosenSessionSize }
    /// Retries included, a session never goes past this many cards.
    private var maxSessionLength: Int { forAppGate ? AppGate.roundMaxLength : chosenSessionSize * 3 / 2 }
    private var finished: Bool { started && index >= queue.count }
    private var colors: [Color] { Pile.colors(pile) }
    private var character: Character { .of(pile) }

    init(pile: Int, forAppGate: Bool = false) {
        self.pile = pile
        self.forAppGate = forAppGate
        _cards = Query(filter: #Predicate<Card> { $0.pile == pile })
    }

    var body: some View {
        Group {
            if !started {
                Color.clear
            } else if queue.isEmpty && !forAppGate {
                VStack(spacing: 20) {
                    Mascot(pile: pile, size: 120)
                    SpeechBubble(text: character.empty)
                }
            } else if index >= queue.count {
                summary
            } else {
                session(queue[index])
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(colors: [colors[0].opacity(0.18), Color(.systemGroupedBackground)],
                                   startPoint: .top, endPoint: .center))
        .navigationTitle(Pile.title(pile))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if index < queue.count {
                    Button("Edit", systemImage: "pencil") { editing = queue[index] }
                }
                Button("All Cards", systemImage: "list.bullet") { showingList = true }
            }
            if forAppGate {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .onChange(of: finished) {
            if finished && forAppGate { AppGate.grantPass() }
        }
        .sheet(isPresented: $addingPack) { WordPackView() }
        .sheet(isPresented: $showingList, onDismiss: dropDeletedCards) {
            NavigationStack { CardListView(pile: pile) }
        }
        .sheet(item: $editing, onDismiss: dropDeletedCards) {
            CardEditor(card: $0)
        }
        .sensoryFeedback(.selection, trigger: flipped)
        .sensoryFeedback(.impact(weight: .medium), trigger: index)
        .onAppear {
            guard started else {
                queue = cards.prioritized(sessionSize)
                gapCards = Set(queue.filter { $0.gap != nil && Int.random(in: 0..<3) == 0 }.map(\.id))
                line = forAppGate ? "\(sessionSize) quick cards, then \(gatedApp.name)! 📸" : character.greeting.randomElement() ?? ""
                started = true
                return
            }
            dropDeletedCards()
        }
    }

    private func session(_ card: Card) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                ProgressView(value: Double(index), total: Double(queue.count))
                    .tint(colors[1])
                Text("\(index + 1) of \(queue.count)")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Mascot(pile: pile, size: 56)
                SpeechBubble(text: line)
                    .id(line)
                    .transition(.scale(scale: 0.8, anchor: .leading).combined(with: .opacity))
                Spacer(minLength: 0)
            }

            FlashCard(card: card, flipped: flipped, colors: colors, asGap: gapCards.contains(card.id))
                .id(card.id)
                .transition(.push(from: .trailing))
                .onTapGesture {
                    withAnimation(.spring(duration: 0.45)) { flipped.toggle() }
                }

            if flipped {
                VStack(spacing: 14) {
                    Text("Did you know it?")
                        .font(.title3.bold())
                    HStack(spacing: 12) {
                        answerButton("Not yet", icon: "xmark", tint: .orange) { answer(card, knewIt: false) }
                        answerButton(pile == 3 ? "Known!" : "I knew it", icon: "checkmark", tint: .green) { answer(card, knewIt: true) }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Label("Tap the card to flip it", systemImage: "hand.tap")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var summary: some View {
        VStack(spacing: 16) {
            Mascot(pile: pile, size: 120)
            SpeechBubble(text: forAppGate ? "Earned it! Enjoy \(gatedApp.name) 📸" : character.done)
            Text(forAppGate ? "\(gatedApp.name.prefix(1).uppercased())\(gatedApp.name.dropFirst()) unlocked!" : "That's enough for now")
                .font(.title.bold())
                .padding(.top, 8)
            Text(queue.isEmpty
                 ? "This pile is empty, so this one's free."
                 : "You knew \(knewCount) of \(Set(queue.map(\.id)).count) cards on the first try."
                    + (forAppGate ? "\nYour pass lasts \(AppGate.passMinutes) minutes." : "\nTake a break and come back later."))
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if forAppGate {
                Button(gatedApp.link == nil ? "Done" : "Open \(gatedApp.name)",
                       systemImage: "arrow.up.forward.app") {
                    dismiss()
                    if let link = gatedApp.link { openURL(link) }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                .tint(colors[1])
                .padding(.top, 8)
            } else {
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .tint(colors[1])
                    .padding(.top, 8)
                Button("Add 10 more words", systemImage: "plus") { addingPack = true }
                    .tint(colors[1])
            }
        }
        .padding()
    }

    private func answerButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .tint(tint)
    }

    /// Cards can be deleted from the edit sheet or the list during a session.
    private func dropDeletedCards() {
        queue.removeAll { $0.isDeleted || $0.modelContext == nil }
    }

    /// Shows a missed card once more at the end, as long as the session stays within 15 cards.
    /// Missed cards that don't fit come first in the next session instead.
    private func retry(_ card: Card) {
        guard queue.count < maxSessionLength else { return }
        retried.insert(card.id)
        queue.append(card)
    }

    private func answer(_ card: Card, knewIt: Bool) {
        Streak.recordStudy()
        let firstTry = !retried.contains(card.id)
        card.answer(knewIt: knewIt)
        if firstTry {
            if knewIt {
                knewCount += 1
            } else {
                retry(card)
            }
        }
        withAnimation(.snappy) {
            line = (knewIt ? character.knew : character.notYet).randomElement() ?? ""
            flipped = false
            index += 1
        }
    }
}

private struct FlashCard: View {
    let card: Card
    let flipped: Bool
    let colors: [Color]
    var asGap = false

    var body: some View {
        let gap = asGap ? card.gap : nil
        ZStack {
            face(background: AnyShapeStyle(Color(.secondarySystemGroupedBackground)), tint: colors[1], speak: gap == nil ? card.term : nil) {
                Text(gap == nil ? Language.learning.uppercased() : "FILL THE GAP")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(colors[1])
                if let gap {
                    Text("\(gap.before)\(Text("_____").foregroundStyle(colors[1]))\(gap.after)")
                        .font(.title2.weight(.semibold))
                    Text(card.exampleMeaning)
                        .foregroundStyle(.secondary)
                } else {
                    Text(card.term)
                        .font(.largeTitle.bold())
                    if !card.plural.isEmpty {
                        Text("pl. \(card.plural)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .opacity(flipped ? 0 : 1)
            .allowsHitTesting(!flipped)

            face(background: AnyShapeStyle(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)),
                 tint: .white, speak: card.example.isEmpty ? card.term : card.example) {
                // For a gap card the word itself is the answer, so it gets the big spot.
                Text(gap == nil ? card.term : card.meaning)
                    .font(.subheadline.weight(.medium))
                    .opacity(0.8)
                Text(gap == nil ? card.meaning : card.term)
                    .font(.title.bold())
                if !card.example.isEmpty {
                    Divider()
                        .overlay(.white.opacity(0.5))
                        .padding(.vertical, 4)
                    if let gap {
                        Text("\(gap.before)\(Text(gap.answer).bold().underline())\(gap.after)")
                    } else {
                        Text(card.example)
                            .italic()
                    }
                    Text(card.exampleMeaning)
                        .font(.subheadline)
                        .opacity(0.8)
                }
            }
            .foregroundStyle(.white)
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(flipped ? 1 : 0)
            .allowsHitTesting(flipped)
        }
        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
    }

    private func face(background: AnyShapeStyle, tint: Color, speak: String?,
                      @ViewBuilder _ content: () -> some View) -> some View {
        VStack(spacing: 12, content: content)
            .multilineTextAlignment(.center)
            .padding(28)
            .frame(maxWidth: .infinity, minHeight: 300)
            .overlay(alignment: .topTrailing) {
                if let speak {
                    SpeakButton(text: speak)
                        .tint(tint)
                        .padding(6)
                }
            }
            .background(background, in: .rect(cornerRadius: 32))
            .shadow(color: colors[0].opacity(0.25), radius: 16, y: 8)
    }
}
