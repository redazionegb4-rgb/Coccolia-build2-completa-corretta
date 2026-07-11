import Foundation
import UserNotifications

struct NotificationService {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    static func schedule(for event: PetEvent) async {
        guard event.reminderEnabled else { return }

        let reminderDate = AppDateTime.calendar.date(byAdding: .hour, value: -24, to: event.date) ?? event.date
        guard reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Coccolia"
        content.body = "Promemoria: \(event.title)"
        content.sound = .default

        var components = AppDateTime.calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        components.timeZone = AppDateTime.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: trigger
        )
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancel(for eventID: UUID) async {
        let identifier = eventID.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
