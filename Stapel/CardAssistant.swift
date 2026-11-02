import Foundation
import Security

/// The editable content of a card. Claude fills it in;
/// the user can always change every field before saving.
struct CardDraft: Codable {
    var term = ""
    var plural = ""
    var meaning = ""
    var example = ""
    var exampleMeaning = ""
    var cloze = ""
}

extension CardDraft {
    init(card: Card) {
        self.init(term: card.term, plural: card.plural, meaning: card.meaning,
                  example: card.example, exampleMeaning: card.exampleMeaning, cloze: card.cloze)
    }
}

/// Everything that talks to Claude lives in this file.
enum CardAssistant {
    struct Failure: LocalizedError {
        let errorDescription: String?
    }

    private static let instructions = """
        You turn a learner's \(Language.learning) entry into a flashcard for a \(Language.native) speaker.
        - term: the entry with spelling fixed, \(Language.termRule). Keep phrases as phrases. If it is a full sentence, only fix its spelling.
        - plural: \(Language.pluralRule).
        - meaning: the short \(Language.native) meaning.
        - example / exampleMeaning: one short, natural, everyday \(Language.learning) sentence using the entry, and its \(Language.native) translation. Empty if the entry is already a full sentence.
        - cloze: the word(s) of example that stand for the entry, copied exactly as they appear there (\(Language.clozeRule)). Empty if there is no example.
        """

    private static let fields = ["term", "plural", "meaning", "example", "exampleMeaning", "cloze"]

    static func draft(for input: String) async throws -> CardDraft {
        guard let key = Keychain.apiKey else {
            throw Failure(errorDescription: "Add your Claude API key in Settings first")
        }
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "claude-haiku-5-5",
            "max_tokens": 2048,
            "system": instructions,
            "output_config": [
                "effort": "low",
                "format": [
                    "type": "json_schema",
                    "schema": [
                        "type": "object",
                        "properties": Dictionary(uniqueKeysWithValues: fields.map { ($0, ["type": "string"]) }),
                        "required": fields,
                        "additionalProperties": false,
                    ],
                ],
            ],
            "messages": [["role": "user", "content": input]],
        ])

        let data: Data
        let status: Int
        do {
            let (body, urlResponse) = try await URLSession.shared.data(for: request)
            data = body
            status = (urlResponse as? HTTPURLResponse)?.statusCode ?? 0
        } catch {
            throw Failure(errorDescription: "Couldn't reach Claude. Check your internet connection")
        }
        if status == 401 {
            throw Failure(errorDescription: "Your API key wasn't accepted. Check it in Settings")
        }
        let response = try? JSONDecoder().decode(Response.self, from: data)
        if let error = response?.error {
            throw Failure(errorDescription: error.message)
        }
        guard let json = response?.content?.first(where: { $0.type == "text" })?.text,
              let draft = try? JSONDecoder().decode(CardDraft.self, from: Data(json.utf8)) else {
            throw Failure(errorDescription: "Claude's answer couldn't be read. Please try again")
        }
        return draft
    }

    private struct Response: Decodable {
        struct Block: Decodable { let type: String; let text: String? }
        struct APIError: Decodable { let message: String }
        let content: [Block]?
        let error: APIError?
    }
}

/// Stores the API key in the iPhone's encrypted Keychain, never in plain files.
enum Keychain {
    private static let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: "claude-api-key",
    ]

    static var apiKey: String? {
        get {
            var lookup = query
            lookup[kSecReturnData as String] = true
            var result: AnyObject?
            guard SecItemCopyMatching(lookup as CFDictionary, &result) == errSecSuccess,
                  let data = result as? Data else { return nil }
            return String(decoding: data, as: UTF8.self)
        }
        set {
            SecItemDelete(query as CFDictionary)
            guard let newValue, !newValue.isEmpty else { return }
            var item = query
            item[kSecValueData as String] = Data(newValue.utf8)
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(item as CFDictionary, nil)
        }
    }
}
