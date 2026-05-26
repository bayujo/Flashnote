import SwiftUI
import SwiftData
import SDWebImage
import SDWebImagePhotosPlugin

@main
struct FlashnoteApp: App {
    @State private var notificationsGranted = false

    init() {
        // Register the Photos loader so SDWebImage can load images from the
        // Photos library using photos:// URLs (PHAsset local identifiers).
        SDImageLoadersManager.shared.loaders = [
            SDWebImageDownloader.shared,
            SDImagePhotosLoader.shared
        ]
        SDWebImageManager.defaultImageLoader = SDImageLoadersManager.shared
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GalleryView()
            }
            .preferredColorScheme(.dark)
            .modelContainer(for: FlashnoteItem.self)
            .task {
                notificationsGranted = await NotificationManager.requestAuthorization()
            }
        }
    }
}
