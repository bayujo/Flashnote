import UserNotifications
import UIKit

enum NotificationManager {

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification auth error: \(error)")
            return false
        }
    }

    static func schedule(for item: FlashnoteItem) {
        let center = UNUserNotificationCenter.current()

        // Cancel any existing notification for this item
        center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])

        let content = UNMutableNotificationContent()
        content.title = "Flashnote Reminder"
        content.body = item.note.isEmpty ? "You have a visual note waiting." : item.note
        content.sound = .default
        content.userInfo = ["itemID": item.id.uuidString]

        // Attach image thumbnail for rich notification (if available in SDWebImage cache)
        if !item.imagePath.isEmpty,
           let tempURL = ImageStorage.temporaryFileURL(for: item.imagePath),
           let attachment = try? UNNotificationAttachment(
               identifier: item.id.uuidString,
               url: tempURL,
               options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
           ) {
            content.attachments = [attachment]
        }

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: item.reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error { print("Notification scheduling error: \(error)") }
        }
    }

    static func cancel(for itemID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [itemID.uuidString])
    }
}
