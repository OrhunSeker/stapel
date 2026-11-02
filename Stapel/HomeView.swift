import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var cards: [Card]
    @State private var adding = false
    @State private var addingPack = false
    @State private var showingSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var appGate = AppGate.shared

    private func count(_ pile: Int) -> Int { cards.count { $0.pile == pile } }

    var body: some View {
        let learning = cards.count - count(Pile.known)
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    knownWords

                    NavigationLink {
                        PilePickerView(cards: cards)
                    } label: {
                        Tile(title: "Learn",
                             subtitle: learning == 0 ? "Add words to get started" : "\(learning) cards in your piles",
                             icon: "rectangle.stack.fill", colors: [.indigo, .purple], height: 130)
                    }

                    HStack(spacing: 16) {
                        Button {
                            adding = true
                        } label: {
                            Tile(title: "Add Word", subtitle: "Type it in \(Language.learning)", icon: "plus", colors: [.orange, .pink])
                        }
                        Button {
                            addingPack = true
                        } label: {
                            Tile(title: "Word Packs", subtitle: "Ready-made, A1–B1",
                                 icon: "text.book.closed.fill", colors: [.yellow, .orange])
                        }
                    }

                    Text("Your piles")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { pile in
                            VStack(spacing: 4) {
                                Mascot(pile: pile, size: 56)
                                    .padding(.bottom, 6)
                                Text("\(count(pile))")
                                    .font(.title2.bold())
                                    .foregroundStyle(Pile.colors(pile)[1])
                                Text("\(Character.of(pile).name) · \(Pile.title(pile))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 6)
                            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stapel")
            .toolbar {
                Button("Settings", systemImage: "gearshape") { showingSettings = true }
            }
            .sheet(isPresented: $showingSettings, onDismiss: planReminders) {
                NavigationStack { SettingsView() }
            }
            .sheet(isPresented: $adding) { CardEditor() }
            .sheet(isPresented: $addingPack) { WordPackView() }
            .fullScreenCover(isPresented: $appGate.isShowing) { AppGateRound() }
            .task(id: scenePhase) {
                // Re-plan reminders when the app opens or closes, so they match the piles.
                guard scenePhase != .inactive else { return }
                planReminders()
            }
        }
    }

    /// Known words and the study streak, at a glance. Tap to see the known words.
    private var knownWords: some View {
        let known = count(Pile.known)
        return NavigationLink {
            CardListView(pile: Pile.known)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: Pile.icon(Pile.known))
                    .font(.title2)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Known Words")
                        .font(.headline)
                    if known == 0 {
                        Text("Empty")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ProgressView(value: Double(known), total: Double(cards.count))
                            .tint(.green)
                        Text("\(known) of \(cards.count) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                VStack(spacing: 2) {
                    Text("🔥 \(Streak.current)")
                        .font(.title3.bold())
                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func planReminders() {
        let counts = Dictionary(grouping: cards, by: \.pile).mapValues(\.count)
        Task { await Reminders.reschedule(cardCounts: counts) }
    }
}

/// The second screen: pick which pile to study.
private struct PilePickerView: View {
    let cards: [Card]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(1...3, id: \.self) { pile in
                    NavigationLink {
                        StudyView(pile: pile)
                    } label: {
                        Tile(title: "\(Character.of(pile).name) · \(Pile.title(pile))",
                             subtitle: "\(Pile.subtitle(pile)) · \(cards.count { $0.pile == pile }) cards",
                             icon: Pile.icon(pile), colors: Pile.colors(pile), height: 120, mascot: pile)
                    }
                }
                NavigationLink {
                    MatchView()
                } label: {
                    Tile(title: "Match Game", subtitle: "Pair 5 words with their meanings",
                         icon: "square.grid.2x2.fill", colors: [.indigo, .blue], height: 100)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Learn")
    }
}

/// A colorful gradient button face, used on the home and pile screens.
struct Tile: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    var height: CGFloat = 140
    var mascot: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if mascot == nil {
                Image(systemName: icon)
                    .font(.title2.bold())
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.25), in: .circle)
            }
            Spacer(minLength: 8)
            Text(title)
                .font(.title2.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: height, alignment: .leading)
        .overlay(alignment: .trailing) {
            if let mascot {
                Mascot(pile: mascot, size: 64)
                    .padding(12)
                    .background(.white.opacity(0.9), in: .circle)
                    .padding(.trailing, 18)
            }
        }
        .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 28))
        .shadow(color: colors[0].opacity(0.35), radius: 10, y: 6)
    }
}

#Preview {
    HomeView().modelContainer(for: Card.self, inMemory: true)
}
