import SwiftUI
import UIKit
import Photos
import SDWebImagePhotosPlugin

/// Wraps UIImagePickerController to provide camera/photo-library access.
/// `onCapture` delivers the UIImage and an optional `photosURL` string:
///   - For **photo library** picks, `photosURL` is a `photos://` URL string
///     (the PHAsset local identifier) that SDWebImage can load directly.
///   - For **camera** captures, `photosURL` is nil — the caller should store
///     the image in SDWebImage's cache via `ImageStorage.saveToCache`.
struct CameraView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    /// Called with the picked image and an optional photos:// URL string.
    let onCapture: (UIImage, String?) -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            guard let image = info[.originalImage] as? UIImage else {
                parent.onDismiss()
                return
            }

            // For library picks, extract the PHAsset and build a photos:// URL.
            if parent.sourceType == .photoLibrary,
               let asset = info[.phAsset] as? PHAsset {
                let photosURL = asset.sd_URLRepresentation.absoluteString
                parent.onCapture(image, photosURL)
            } else {
                // Camera capture — no PHAsset URL available
                parent.onCapture(image, nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}
