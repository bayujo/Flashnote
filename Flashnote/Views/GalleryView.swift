import SwiftUI
import SwiftData

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [FlashnoteItem]
    @State private var viewModel = GalleryViewModel()

    private var activeItems: [FlashnoteItem] { viewModel.activeItems(from: allItems) }

    var body: some View {
        @Bindable var vm = viewModel

        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Swipe hint
                    swipeHint
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    // Card counter
                    if !activeItems.isEmpty {
                        Text("\(activeItems.count) note\(activeItems.count == 1 ? "" : "s")")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.bottom, 8)
                    }

                    // Card stack — takes remaining space above FAB
                    CardStackView(
                        items: activeItems,
                        onLater: { item in
                            viewModel.snooze(item, allItems: allItems, context: modelContext)
                        },
                        onDone: { item in
                            viewModel.markComplete(item, context: modelContext)
                        },
                        onTap: { item in
                            viewModel.selectedItem = item
                        }
                    )
                    .padding(.bottom, geo.safeAreaInsets.bottom + 96)
                }
            }
        }
        .navigationTitle("Flashnote")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .overlay(alignment: .bottom) {
            fabRow
        }
        // Camera sheet
        .sheet(isPresented: $vm.showCamera, onDismiss: viewModel.onCameraSheetDismiss) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                CameraView(sourceType: .camera) { image, photosURL in
                    vm.pendingImage = image
                    vm.pendingPhotosURL = photosURL
                    vm.showCamera = false
                } onDismiss: {
                    vm.showCamera = false
                }
            } else {
                CameraView(sourceType: .photoLibrary) { image, photosURL in
                    vm.pendingImage = image
                    vm.pendingPhotosURL = photosURL
                    vm.showCamera = false
                } onDismiss: {
                    vm.showCamera = false
                }
            }
        }
        // Photo picker sheet
        .sheet(isPresented: $vm.showPhotoPicker, onDismiss: viewModel.onPhotoPickerDismiss) {
            CameraView(sourceType: .photoLibrary) { image, photosURL in
                vm.pendingImage = image
                vm.pendingPhotosURL = photosURL
                vm.showPhotoPicker = false
            } onDismiss: {
                vm.showPhotoPicker = false
            }
        }
        // Edit existing item
        .fullScreenCover(item: $vm.selectedItem) { item in
            InstantDetailSheet(existingItem: item) { date, note, newImage, newPhotosURL, imageChanged in
                if imageChanged {
                    // Remove old image from cache
                    if !item.imagePath.isEmpty {
                        ImageStorage.delete(imagePath: item.imagePath)
                    }
                    // Store new image: prefer photos:// URL, then cache the UIImage
                    if let newPhotosURL {
                        item.imagePath = newPhotosURL
                    } else if let newImage, let key = ImageStorage.saveToCache(newImage) {
                        item.imagePath = key
                    } else {
                        item.imagePath = ""
                    }
                }
                item.reminderDate = date
                item.note = note
                item.isCompleted = false
                try? modelContext.save()
                NotificationManager.schedule(for: item)
                vm.selectedItem = nil
            } onDismiss: {
                vm.selectedItem = nil
            }
        }
        // New capture (camera/photo)
        .fullScreenCover(item: $vm.capturedImage) { captured in
            InstantDetailSheet(initialImage: captured.value, photosURL: captured.photosURL) { date, note, finalImage, finalPhotosURL, _ in
                viewModel.saveNewItem(image: finalImage, photosURL: finalPhotosURL, date: date, note: note, context: modelContext)
                vm.capturedImage = nil
            } onDismiss: {
                vm.capturedImage = nil
            }
        }
        // New text-only note
        .fullScreenCover(isPresented: $vm.showTextNote) {
            InstantDetailSheet { date, note, finalImage, finalPhotosURL, _ in
                viewModel.saveNewItem(image: finalImage, photosURL: finalPhotosURL, date: date, note: note, context: modelContext)
                vm.showTextNote = false
            } onDismiss: {
                vm.showTextNote = false
            }
        }
    }

    // MARK: - Sub-views

    private var swipeHint: some View {
        HStack(spacing: 0) {
            Label("Done", systemImage: "checkmark.circle")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.green.opacity(0.7))
            Spacer()
            Label("Later", systemImage: "clock.arrow.circlepath")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.orange.opacity(0.7))
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.horizontal, 28)
    }

    private var fabRow: some View {
        HStack(spacing: 16) {
            // Photo library
            Button { viewModel.showPhotoPicker = true } label: {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.glass)

            // Camera (primary)
            Button { viewModel.showCamera = true } label: {
                Image(systemName: "camera.fill")
                    .font(.title2.weight(.bold))
                    .frame(width: 68, height: 68)
            }
            .buttonStyle(.glassProminent)

            // Text-only note
            Button { viewModel.showTextNote = true } label: {
                Image(systemName: "note.text")
                    .font(.title3.weight(.semibold))
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.glass)
        }
        .padding(.bottom, 32)
    }
}

#Preview {
    NavigationStack {
        GalleryView()
    }
    .modelContainer(for: FlashnoteItem.self, inMemory: true)
}
