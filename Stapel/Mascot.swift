import SwiftUI

/// Each pile has a plush character with its own personality and lines.
struct Character {
    let name: String
    let greeting: [String]
    let knew: [String]
    let notYet: [String]
    let done: String
    let empty: String
    let reminders: [String]

    static func of(_ pile: Int) -> Character {
        switch pile {
        case 1: Character(
            name: "Flitzi",
            greeting: ["Hiii! Let's gooo! 🤩", "Words! Words! I love words!", "Ready? I'm SO ready!"],
            knew: ["Yesss! Off to Pile 2!", "You're on fire! 🔥", "Woohoo, nailed it!"],
            notYet: ["No worries, it stays with me!", "Again! Again! I love repeats!", "We'll get it next time!"],
            done: "That was AMAZING! Come back soon, okay?!",
            empty: "I'm empty! Feed me words!!",
            reminders: [
                "Hiii!! I've got SO many words waiting for you! 🤩",
                "New words! Fresh words! Come learn them with me!!",
                "I can't sit still — let's do a few cards right now! 🚀",
                "Knock knock! Your words want to meet you!",
            ])
        case 2: Character(
            name: "Grübli",
            greeting: ["Do you still remember these? I'm worried…", "Okay. Deep breath. Let's see.", "I hope you didn't forget us…"],
            knew: ["Oh! You remembered. Phew.", "Okay, I worried for nothing.", "Nice… I can relax a little."],
            notYet: ["I knew it… back to Pile 1.", "See? This is why I worry.", "It's fine. It's fine. It's fine."],
            done: "That went better than I feared. Rest now.",
            empty: "Nothing here yet… which is somehow worrying.",
            reminders: [
                "I'm pretty sure you've forgotten my words already… prove me wrong? 😟",
                "It's been two days… do you even remember us?",
                "I've been thinking. And worrying. Come check on your words?",
            ])
        default: Character(
            name: "Chilli",
            greeting: ["Yo. Show me what you got. 😎", "No pressure. Just vibes.", "Let's keep it smooth."],
            knew: ["Smooth. Straight to Known.", "Called it. 😎", "Too easy."],
            notYet: ["Happens to the best. Back to Pile 1.", "No sweat. Run it back.", "Chill. You'll get it."],
            done: "Solid session. Go chill. 😎",
            empty: "Empty. Peaceful. I like it.",
            reminders: [
                "Yo. Think you still know these? Show me. 😎",
                "Weekly check-in. No pressure… unless you forgot. 😎",
                "Come flex a little. Your Pile 3 words are waiting.",
            ])
        }
    }
}

/// A squishy plush character drawn with shapes, gently bouncing.
struct Mascot: View {
    let pile: Int
    var size: CGFloat = 80

    @State private var bounce = false

    private var colors: [Color] { Pile.colors(pile) }
    private func s(_ f: CGFloat) -> CGFloat { size * f }

    var body: some View {
        ZStack {
            // Ears and feet sit behind the body.
            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle().fill(colors[0])
                    .overlay(Circle().fill(.white.opacity(0.35)).padding(s(0.06)))
                    .frame(width: s(0.26), height: s(0.26))
                    .offset(x: side * s(0.3), y: -s(0.36))
                Capsule().fill(colors[1])
                    .frame(width: s(0.24), height: s(0.13))
                    .offset(x: side * s(0.2), y: s(0.42))
            }

            Ellipse()
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: s(0.9))
                .overlay(alignment: .topLeading) {
                    Ellipse().fill(.white.opacity(0.3))
                        .frame(width: s(0.3), height: s(0.16))
                        .rotationEffect(.degrees(-25))
                        .offset(x: s(0.14), y: s(0.12))
                }

            face
        }
        .frame(width: size, height: size)
        .scaleEffect(x: bounce ? 1.04 : 0.97, y: bounce ? 0.96 : 1.03, anchor: .bottom)
        .offset(y: pile == 1 && bounce ? -s(0.08) : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: [0.4, 1.4, 2.4][min(pile, 3) - 1]).repeatForever()) {
                bounce = true
            }
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder private var face: some View {
        if pile == 3 {
            // Sunglasses and a smirk.
            HStack(spacing: s(0.03)) {
                lens
                Capsule().frame(width: s(0.06), height: s(0.025)).offset(y: -s(0.03))
                lens
            }
            .offset(y: -s(0.06))
            Capsule().fill(.black.opacity(0.75))
                .frame(width: s(0.16), height: s(0.035))
                .rotationEffect(.degrees(-12))
                .offset(x: s(0.05), y: s(0.15))
        } else {
            ForEach([-1.0, 1.0], id: \.self) { side in
                eye.offset(x: side * s(0.17), y: -s(0.05))
                Ellipse().fill(.pink.opacity(0.55))
                    .frame(width: s(0.13), height: s(0.07))
                    .offset(x: side * s(0.29), y: s(0.08))
            }
            if pile == 1 {
                // Big open happy mouth and a sparkle.
                UnevenRoundedRectangle(bottomLeadingRadius: s(0.1), bottomTrailingRadius: s(0.1))
                    .fill(Color(red: 0.45, green: 0.1, blue: 0.15))
                    .frame(width: s(0.2), height: s(0.11))
                    .offset(y: s(0.12))
                Image(systemName: "sparkle")
                    .font(.system(size: s(0.2)))
                    .foregroundStyle(.yellow)
                    .offset(x: -s(0.42), y: -s(0.4))
            } else {
                // Worried brows, a tiny "o" mouth and a sweat drop.
                ForEach([-1.0, 1.0], id: \.self) { side in
                    Capsule().fill(.black.opacity(0.75))
                        .frame(width: s(0.15), height: s(0.035))
                        .rotationEffect(.degrees(side * 18))
                        .offset(x: side * s(0.17), y: -s(0.2))
                }
                Ellipse().stroke(.black.opacity(0.75), lineWidth: s(0.03))
                    .frame(width: s(0.08), height: s(0.09))
                    .offset(y: s(0.13))
                Image(systemName: "drop.fill")
                    .font(.system(size: s(0.15)))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(x: s(0.36), y: -s(0.28))
            }
        }
    }

    private var eye: some View {
        Circle().fill(.black.opacity(0.85))
            .frame(width: s(pile == 1 ? 0.16 : 0.12))
            .overlay(alignment: .topLeading) {
                Circle().fill(.white).frame(width: s(0.05)).offset(x: s(0.02), y: s(0.02))
            }
    }

    private var lens: some View {
        RoundedRectangle(cornerRadius: s(0.06))
            .fill(.black.opacity(0.88))
            .frame(width: s(0.27), height: s(0.17))
            .overlay(alignment: .topLeading) {
                Capsule().fill(.white.opacity(0.5))
                    .frame(width: s(0.08), height: s(0.025))
                    .offset(x: s(0.04), y: s(0.04))
            }
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach(1...3, id: \.self) { Mascot(pile: $0, size: 100) }
    }
}

/// What a character says, shown next to it.
struct SpeechBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
            .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }
}
