import SwiftUI

/// The short intro shown on first launch, and again from Settings.
struct OnboardingView: View {
    @AppStorage("didFinishIntro") private var didFinishIntro = false
    @State private var page = 0
    @State private var showingKeySetup = false

    private let lastPage = 3

    var body: some View {
        VStack(spacing: 16) {
            TabView(selection: $page) {
                step(title: "Meet your three piles",
                     text: "Every word starts in Pile 1. Know it and it moves up. Forget it and it goes back. After Pile 3 it's yours for good.") {
                    HStack(spacing: 16) {
                        ForEach(1...3, id: \.self) { pile in
                            VStack(spacing: 8) {
                                Mascot(pile: pile, size: 84)
                                Text(Character.of(pile).name).font(.caption.weight(.semibold))
                            }
                        }
                    }
                }
                .tag(0)

                step(title: "Add words your way",
                     text: "Type a word, phrase or sentence and Claude fixes the spelling and finds the meaning and an example. Or add 10 ready-made words from A1 to B1.") {
                    icon("plus.bubble.fill", pile: 2)
                }
                .tag(1)

                step(title: "Practice in small bursts",
                     text: "Flip cards, fill the gap in a sentence and play the match game. Words you miss come back first, and your characters will remind you to return.") {
                    icon("rectangle.on.rectangle.angled.fill", pile: 3)
                }
                .tag(2)

                step(title: "Connect Claude when you're ready",
                     text: "To fill in cards automatically, add your own Claude API key. It's optional: ready-made words and typing cards yourself work without it.") {
                    Mascot(pile: 1, size: 110)
                }
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 8) {
                Button {
                    if page < lastPage {
                        withAnimation { page += 1 }
                    } else {
                        didFinishIntro = true
                    }
                } label: {
                    Text(page < lastPage ? "Next" : "Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)

                Button("Add my API key") { showingKeySetup = true }
                    .opacity(page == lastPage ? 1 : 0)
                    .disabled(page != lastPage)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingKeySetup) {
            NavigationStack {
                APIKeyView()
                    .toolbar {
                        Button("Done") { showingKeySetup = false }
                    }
            }
        }
    }

    private func step(title: String, text: String, @ViewBuilder art: () -> some View) -> some View {
        VStack(spacing: 24) {
            Spacer()
            art()
                .frame(height: 150)
            Text(title)
                .font(.title.bold())
            Text(text)
                .foregroundStyle(.secondary)
            Spacer()
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
    }

    private func icon(_ name: String, pile: Int) -> some View {
        Image(systemName: name)
            .font(.system(size: 76))
            .foregroundStyle(LinearGradient(colors: Pile.colors(pile), startPoint: .topLeading, endPoint: .bottomTrailing))
    }
}
