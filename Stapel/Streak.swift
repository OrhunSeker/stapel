import Foundation

/// Counts how many days in a row you've studied. Kept on the device only.
enum Streak {
    private static let countKey = "streakCount"
    private static let lastDayKey = "streakLastDay"

    private static var lastDay: Date? {
        UserDefaults.standard.object(forKey: lastDayKey) as? Date
    }

    /// Falls back to 0 once a whole day has been missed.
    static var current: Int {
        guard let lastDay else { return 0 }
        let calendar = Calendar.current
        guard calendar.isDateInToday(lastDay) || calendar.isDateInYesterday(lastDay) else { return 0 }
        return UserDefaults.standard.integer(forKey: countKey)
    }

    static func recordStudy() {
        if let lastDay, Calendar.current.isDateInToday(lastDay) { return }
        UserDefaults.standard.set(current + 1, forKey: countKey)
        UserDefaults.standard.set(Date.now, forKey: lastDayKey)
    }
}
