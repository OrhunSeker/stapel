/// Everything specific to the language being learned lives here.
/// To adapt Stapel to another language, change these values and replace WordPacks.json (see the README).
enum Language {
    static let learning = "German"
    static let native = "English"
    /// The iPhone voice that reads cards aloud (a language code such as "de-DE" or "es-ES").
    static let voiceCode = "de-DE"
    /// Ignored when checking for duplicates, so "der Hund" and "Hund" count as the same card.
    static let articles = ["der", "die", "das"]
    /// Small words that shouldn't become the blank when a card has to guess its gap.
    static let gapSkipWords: Set<String> = ["der", "die", "das", "sich", "an", "um", "auf", "über", "ein", "eine"]
    /// Set to false for languages without a separate plural worth learning.
    static let showsPlural = true

    // Language-specific instructions for Claude, used in CardAssistant.
    static let termRule = "in dictionary form (verbs: infinitive; nouns: nominative singular with der/die/das)"
    static let pluralRule = "nouns only, with article (e.g. \"die Hunde\"); otherwise empty"
    static let clozeRule = "entry \"gehen\", example \"Ich gehe nach Hause.\" → \"gehe\"; for separable verbs only the conjugated part"
}
