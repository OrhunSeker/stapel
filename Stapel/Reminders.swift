import Foundation
import UserNotifications

/// Local notifications in each pile character's voice. No server involved.
enum Reminders {
    /// Pile 1: daily at 10, 13 and 18 · Pile 2: every second day at 12 · Pile 3: Sundays at 14.
    private static func hours(for pile: Int, on date: Date) -> [Int] {
        let calendar = Calendar.current
        switch pile {
        case 1: return [10, 13, 18]
        case 2:
            let dayNumber = calendar.dateComponents([.day], from: Date(timeIntervalSince1970: 0), to: date).day ?? 0
            return dayNumber.isMultiple(of: 2) ? [12] : []
        default: return calendar.component(.weekday, from: date) == 1 ? [14] : []
        }
    }

    static func toggleKey(_ pile: Int) -> String { "remindersPile\(pile)" }

    private static func isOn(_ pile: Int) -> Bool {
        UserDefaults.standard.object(forKey: toggleKey(pile)) as? Bool ?? true
    }

    /// Plans the next two weeks. Called whenever the app opens or goes to the background,
    /// so empty piles stay quiet and the messages vary.
    static func reschedule(cardCounts: [Int: Int]) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for offset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            for pile in 1...3 where cardCounts[pile, default: 0] > 0 && isOn(pile) {
                for hour in hours(for: pile, on: day) {
                    guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                          fire > .now else { continue }
                    let character = Character.of(pile)
                    let content = UNMutableNotificationContent()
                    content.title = "\(character.name) · \(Pile.title(pile))"
                    content.body = character.reminders.randomElement() ?? ""
                    content.sound = .default
                    let trigger = UNCalendarNotificationTrigger(
                        dateMatching: calendar.dateComponents([.year, .month, .day, .hour], from: fire),
                        repeats: false)
                    try? await center.add(UNNotificationRequest(
                        identifier: "pile\(pile)-\(fire.timeIntervalSince1970)", content: content, trigger: trigger))
                }
            }
        }
    }
}
