import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func schedule(todoId: UUID, title: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "提醒"
        content.body = title
        content.sound = .default
        content.userInfo = ["todoId": todoId.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: todoId.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    func cancel(todoId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [todoId.uuidString])
    }
}
