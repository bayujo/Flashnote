import Foundation
import SwiftData
import UIKit
import Observation

/// Thin Identifiable wrapper so UIImage can drive fullScreenCover(item:)
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let value: UIImage
    /// Optional photos:// URL string if this image came from the Photos library.
    let photosURL: String?
}

@Observable
final class GalleryViewModel {

    // MARK: - Presentation state
    var showCamera = false
    var showPhotoPicker = false
    var showTextNote = false
    var capturedImage: IdentifiableImage?
    var pendingImage: UIImage?
    var pendingPhotosURL: String?
    var selectedItem: FlashnoteItem?

    // MARK: - Filtering
    func activeItems(from all: [FlashnoteItem]) -> [FlashnoteItem] {
        all.filter { !$0.isCompleted }.sorted { $0.reminderDate < $1.reminderDate }
    }

    func completedItems(from all: [FlashnoteItem]) -> [FlashnoteItem] {
        all.filter { $0.isCompleted }.sorted { $0.reminderDate > $1.reminderDate }
    }

    // MARK: - Actions

    /// Saves a new item. Stores a photos:// URL for library picks, or writes the
    /// image to SDWebImage's cache for camera captures.
    func saveNewItem(image: UIImage?, photosURL: String?, date: Date, note: String, context: ModelContext) {
        var imagePath = ""
        if let photosURL {
            // Library pick — store the photos:// URL directly; SDWebImage loads it.
            imagePath = photosURL
        } else if let image {
            // Camera capture — store in SDWebImage disk cache, keep the cache key.
            guard let key = ImageStorage.saveToCache(image) else { return }
            imagePath = key
        }
        let item = FlashnoteItem(imagePath: imagePath, reminderDate: date, note: note)
        context.insert(item)
        do {
            try context.save()
        } catch {
            print("[GalleryViewModel] save error: \(error)")
        }
        NotificationManager.schedule(for: item)
    }

    func markComplete(_ item: FlashnoteItem, context: ModelContext) {
        item.isCompleted = true
        try? context.save()
        NotificationManager.cancel(for: item.id)
    }

    func delete(_ item: FlashnoteItem, context: ModelContext) {
        NotificationManager.cancel(for: item.id)
        if !item.imagePath.isEmpty { ImageStorage.delete(imagePath: item.imagePath) }
        context.delete(item)
        try? context.save()
    }

    /// Pushes the item to the end of the active queue by setting its reminderDate
    /// just after the latest reminderDate among all active items.
    func snooze(_ item: FlashnoteItem, allItems: [FlashnoteItem], context: ModelContext) {
        let active = allItems.filter { !$0.isCompleted }
        let latest = active.map(\.reminderDate).max() ?? Date()
        let anchor = max(latest, Date())
        item.reminderDate = anchor.addingTimeInterval(1)
        NotificationManager.cancel(for: item.id)
        NotificationManager.schedule(for: item)
        try? context.save()
    }

    // MARK: - Layout
    /// Responsive card height proportional to column width
    func cardHeight(for item: FlashnoteItem, columnWidth: CGFloat) -> CGFloat {
        let ratios: [CGFloat] = [1.2, 1.0, 1.5]
        let seed = abs(item.id.hashValue) % 3
        return columnWidth * ratios[seed]
    }

    // MARK: - Sheet dismiss handlers
    func onCameraSheetDismiss() {
        guard let img = pendingImage else { return }
        let url = pendingPhotosURL
        pendingImage = nil
        pendingPhotosURL = nil
        capturedImage = IdentifiableImage(value: img, photosURL: url)
    }

    func onPhotoPickerDismiss() {
        guard let img = pendingImage else { return }
        let url = pendingPhotosURL
        pendingImage = nil
        pendingPhotosURL = nil
        capturedImage = IdentifiableImage(value: img, photosURL: url)
    }
}
