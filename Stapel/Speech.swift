import AVFoundation
import SwiftUI

/// Reads cards out loud with the iPhone's built-in voice. Free and offline.
enum Speech {
    private static let synthesizer = AVSpeechSynthesizer()

    static func say(_ text: String) {
        // .playback so it's audible even when the silent switch is on.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Language.voiceCode)
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}

/// A small 🔊 button that reads the given text.
struct SpeakButton: View {
    let text: String

    var body: some View {
        Button("Listen", systemImage: "speaker.wave.2.fill") { Speech.say(text) }
            .labelStyle(.iconOnly)
            .font(.title3)
            .padding(10)
            .contentShape(.circle)
    }
}
