// ShareViewController.swift
// Drop this file into the FlashnoteShareExtension target.
// It reads the shared image, presents the Instant Detail sheet,
// saves the image + FlashnoteItem, schedules a notification, then closes.
//
// SETUP STEPS (one-time in Xcode):
//   1. File > New > Target > Share Extension  (name: FlashnoteShareExtension)
//   2. Add an App Group to BOTH targets: group.com.yourteam.flashnote
//      (Signing & Capabilities > App Groups)
//   3. Set NSExtensionActivationRule in the extension's Info.plist to allow images.
//   4. Add this file + ShareExtensionView.swift + ImageStorage.swift +
//      NotificationManager.swift + FlashnoteItem.swift to the extension target's
//      Compile Sources build phase.
//   5. In ImageStorage, use the shared App Group container instead of the
//      app's private Documents directory (see groupDocumentsDirectory below).

import UIKit
import SwiftUI
import UniformTypeIdentifiers
import UserNotifications
import SwiftData

final class ShareViewController: UIViewController {

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        extractImage { [weak self] image in
            DispatchQueue.main.async {
                guard let self, let image else { self?.cancel(); return }
                self.presentDetailSheet(image: image)
            }
        }
    }

    // MARK: - Image extraction

    private func extractImage(completion: @escaping (UIImage?) -> Void) {
        guard
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let provider = item.attachments?.first(where: {
                $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
            })
        else { completion(nil); return }

        provider.loadItem(forTypeIdentifier: UTType.image.identifier) { data, _ in
            switch data {
            case let image as UIImage:
                completion(image)
            case let url as URL:
                completion(UIImage(contentsOfFile: url.path))
            case let data as Data:
                completion(UIImage(data: data))
            default:
                completion(nil)
            }
        }
    }

    // MARK: - Presentation

    private func presentDetailSheet(image: UIImage) {
        let sheet = ShareExtensionView(image: image) { [weak self] date, note in
            self?.save(image: image, date: date, note: note)
        } onDismiss: { [weak self] in
            self?.cancel()
        }

        let host = UIHostingController(rootView: sheet)
        host.view.backgroundColor = .clear
        host.modalPresentationStyle = .overFullScreen

        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    // MARK: - Save & notify

    private func save(image: UIImage, date: Date, note: String) {
        // Use App Group shared container so main app can also read images
        guard let filename = saveToSharedContainer(image) else { done(); return }

        // Persist via SwiftData in the shared container
        let config = ModelConfiguration(
            schema: Schema([FlashnoteItem.self]),
            url: sharedStoreURL()
        )
        guard let container = try? ModelContainer(
            for: FlashnoteItem.self,
            configurations: config
        ) else { done(); return }

        let item = FlashnoteItem(imagePath: filename, reminderDate: date, note: note)
        container.mainContext.insert(item)
        try? container.mainContext.save()

        // Schedule notification
        scheduleNotification(for: item, imageFilename: filename)
        done()
    }

    // MARK: - Helpers

    private func saveToSharedContainer(_ image: UIImage) -> String? {
        guard
            let data = image.jpegData(compressionQuality: 0.85),
            let containerURL = sharedContainerURL()
        else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let fileURL = containerURL.appendingPathComponent(filename)
        try? data.write(to: fileURL)
        return filename
    }

    /// Replace "group.com.yourteam.flashnote" with your actual App Group identifier.
    private func sharedContainerURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourteam.flashnote")
    }

    private func sharedStoreURL() -> URL {
        (sharedContainerURL() ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("flashnote.sqlite")
    }

    private func scheduleNotification(for item: FlashnoteItem, imageFilename: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }

        let content = UNMutableNotificationContent()
        content.title = "Flashnote Reminder"
        content.body = item.note.isEmpty ? "You have a visual note waiting." : item.note
        content.sound = .default

        if let containerURL = sharedContainerURL() {
            let imageURL = containerURL.appendingPathComponent(imageFilename)
            if let attachment = try? UNNotificationAttachment(
                identifier: item.id.uuidString,
                url: imageURL,
                options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
            ) {
                content.attachments = [attachment]
            }
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
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func done() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(
            withError: NSError(domain: "FlashnoteShare", code: 0)
        )
    }
}
