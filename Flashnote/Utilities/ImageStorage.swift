import UIKit
import SDWebImage
import SDWebImagePhotosPlugin

/// Manages image persistence using SDWebImage's disk cache for camera captures
/// and `photos://` URL strings for Photos library picks.
///
/// `FlashnoteItem.imagePath` stores one of:
///   - A `photos://` URL string  → loaded directly by SDWebImage via SDImagePhotosLoader
///   - A UUID cache key string   → a camera capture stored in SDImageCache
enum ImageStorage {

    // MARK: - Cache key prefix to distinguish from photos:// URLs

    private static let cacheKeyPrefix = "flashnote-cache://"

    // MARK: - Save (camera captures only)

    /// Stores a UIImage in SDWebImage's disk cache and returns a cache key string.
    /// Use this for images that come from the camera (not the Photos library).
    static func saveToCache(_ image: UIImage) -> String? {
        let key = cacheKeyPrefix + UUID().uuidString
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        SDImageCache.shared.storeImageData(toDisk: data, forKey: key)
        SDImageCache.shared.store(image, forKey: key, toDisk: false, completion: nil)
        return key
    }

    // MARK: - Load (synchronous, for notification attachment)

    /// Synchronously loads a UIImage for a given imagePath.
    /// Works for both cache keys and photos:// URL strings.
    /// NOTE: For photos:// URLs this may be slow — use async loading in UI code.
    static func loadSync(imagePath: String) -> UIImage? {
        if isPhotosURL(imagePath) {
            // Attempt to load from SDWebImage's in-memory or disk cache
            return SDImageCache.shared.imageFromCache(forKey: imagePath)
        } else {
            return SDImageCache.shared.imageFromCache(forKey: imagePath)
        }
    }

    // MARK: - Delete

    /// Removes the image for the given imagePath from the SDWebImage disk cache.
    /// For photos:// URLs, only the cache entry is removed (the asset stays in Photos).
    static func delete(imagePath: String) {
        SDImageCache.shared.removeImage(forKey: imagePath, fromDisk: true, withCompletion: nil)
    }

    // MARK: - URL helpers for SDWebImage loading

    /// Returns a URL that SDWebImage can load from, for a given imagePath string.
    /// - `photos://` strings are returned as-is (SDImagePhotosLoader handles them).
    /// - Cache keys are returned as nil (load from SDImageCache directly by key).
    static func url(for imagePath: String) -> URL? {
        if isPhotosURL(imagePath) {
            return URL(string: imagePath)
        }
        return nil
    }

    /// Returns true if the imagePath is a Photos library URL.
    static func isPhotosURL(_ imagePath: String) -> Bool {
        imagePath.hasPrefix("photos://")
    }

    // MARK: - Notification attachment support

    /// Writes the image to a temporary file and returns its URL, for use with
    /// UNNotificationAttachment. Returns nil if the image is not available in cache.
    static func temporaryFileURL(for imagePath: String) -> URL? {
        guard let image = SDImageCache.shared.imageFromCache(forKey: imagePath),
              let data = image.jpegData(compressionQuality: 0.85) else { return nil }

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        try? data.write(to: tempURL)
        return tempURL
    }
}
