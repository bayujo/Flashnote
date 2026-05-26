import SwiftUI
import UIKit
import SwiftData
import SDWebImage

struct InstantDetailSheet: View {
    private let existingItem: FlashnoteItem?
    /// Called on save with: date, note, optional UIImage, optional photos:// URL, and imageChanged flag.
    private let onSave: (Date, String, UIImage?, String?, Bool) -> Void
    private let onDismiss: () -> Void

    @State private var viewModel = InstantDetailViewModel()
    @State private var currentImage: UIImage?
    /// The imagePath (photos:// URL or cache key) of the currently displayed image.
    /// Nil for new captures that haven't been persisted yet.
    @State private var currentImagePath: String?
    @State private var isLoadingImage: Bool
    @State private var imageChanged = false
    @State private var showImageSourcePicker = false
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary

    // MARK: - Inits

    /// New capture — starts with an image the user can clear or change.
    init(initialImage: UIImage, photosURL: String? = nil, onSave: @escaping (Date, String, UIImage?, String?, Bool) -> Void, onDismiss: @escaping () -> Void) {
        self.existingItem = nil
        self.onSave = onSave
        self.onDismiss = onDismiss
        self._currentImage = State(initialValue: initialImage)
        self._currentImagePath = State(initialValue: photosURL)
        self._isLoadingImage = State(initialValue: false)
    }

    /// Text-only note — no initial image; user can add one.
    init(onSave: @escaping (Date, String, UIImage?, String?, Bool) -> Void, onDismiss: @escaping () -> Void) {
        self.existingItem = nil
        self.onSave = onSave
        self.onDismiss = onDismiss
        self._currentImage = State(initialValue: nil)
        self._currentImagePath = State(initialValue: nil)
        self._isLoadingImage = State(initialValue: false)
    }

    /// Existing item — loads image via SDWebImage asynchronously.
    init(existingItem: FlashnoteItem, onSave: @escaping (Date, String, UIImage?, String?, Bool) -> Void, onDismiss: @escaping () -> Void) {
        self.existingItem = existingItem
        self.onSave = onSave
        self.onDismiss = onDismiss
        self._currentImage = State(initialValue: nil)
        self._currentImagePath = State(initialValue: existingItem.imagePath.isEmpty ? nil : existingItem.imagePath)
        self._isLoadingImage = State(initialValue: !existingItem.imagePath.isEmpty)
    }

    // MARK: - Computed

    private var isTextOnly: Bool { !isLoadingImage && currentImage == nil }
    private var noteLimit: Int { isTextOnly ? 500 : 100 }

    // MARK: - Body

    var body: some View {
        @Bindable var vm = viewModel

        ScrollView {
            VStack(spacing: 20) {
                // Image section
                imageSection
                    .padding(.top, 20)

                // Quick presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.presets) { preset in
                            Button(preset.label) {
                                viewModel.applyPreset(preset)
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.glass)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Date/Time picker
                DatePicker(
                    "Remind me at",
                    selection: $vm.reminderDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(.white)
                .colorScheme(.dark)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Note field
                noteField

                // Save button
                Button {
                    onSave(viewModel.reminderDate, viewModel.note, currentImage, currentImagePath, imageChanged)
                } label: {
                    Text("Set Visual Note")
                        .font(.title3.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                .buttonStyle(.glassProminent)

                Button("Cancel") { onDismiss() }
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.bottom, 20)
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { sheetBackground }
        .safeAreaPadding(.bottom)
        .task {
            if let item = existingItem {
                viewModel.configure(with: item)
                guard !item.imagePath.isEmpty else { return }
                let path = item.imagePath

                // Load via SDWebImage (handles both photos:// and cache keys)
                if ImageStorage.isPhotosURL(path) {
                    guard let url = ImageStorage.url(for: path) else {
                        isLoadingImage = false
                        return
                    }
                    currentImage = await withCheckedContinuation { continuation in
                        SDWebImageManager.shared.loadImage(
                            with: url,
                            options: .highPriority,
                            progress: nil
                        ) { image, _, _, _, _, _ in
                            continuation.resume(returning: image)
                        }
                    }
                } else {
                    // Cache key — query SDImageCache directly
                    currentImage = await withCheckedContinuation { continuation in
                        SDImageCache.shared.queryImage(forKey: path, options: [], context: nil) { image, _, _ in
                            continuation.resume(returning: image)
                        }
                    }
                }
                isLoadingImage = false
            }
        }
        .confirmationDialog("Add Image", isPresented: $showImageSourcePicker, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { imagePickerSource = .camera; showImagePicker = true }
            }
            Button("Choose from Library") { imagePickerSource = .photoLibrary; showImagePicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showImagePicker) {
            CameraView(sourceType: imagePickerSource) { newImage, photosURL in
                currentImage = newImage
                currentImagePath = photosURL
                imageChanged = true
                showImagePicker = false
            } onDismiss: {
                showImagePicker = false
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var imageSection: some View {
        if isLoadingImage {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .overlay(ProgressView().tint(.white))
                .containerRelativeFrame(.vertical) { h, _ in h * 0.28 }

        } else if let img = currentImage {
            VStack(spacing: 10) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .containerRelativeFrame(.vertical) { h, _ in h * 0.28 }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 12)

                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentImage = nil
                            currentImagePath = nil
                            imageChanged = true
                        }
                    } label: {
                        Label("Remove", systemImage: "xmark.circle")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.glass)

                    Button {
                        showImageSourcePicker = true
                    } label: {
                        Label("Change", systemImage: "photo.badge.plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                }
            }

        } else {
            // Text-only — show add image prompt
            Button {
                showImageSourcePicker = true
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.45))
                    Text("Add Image")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
            }
        }
    }

    @ViewBuilder
    private var noteField: some View {
        @Bindable var vm = viewModel

        VStack(alignment: .trailing, spacing: 4) {
            TextField(
                isTextOnly ? "Write your note…" : "Quick note…",
                text: $vm.note,
                axis: .vertical
            )
            .lineLimit(isTextOnly ? 5...12 : 1...3)
            .onChange(of: vm.note) { _, new in
                viewModel.truncateNote(limit: noteLimit)
            }
            .font(isTextOnly ? .title3.weight(.medium) : .body)
            .foregroundStyle(.white)
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Text("\(vm.note.count)/\(noteLimit)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.trailing, 4)
        }
    }

    @ViewBuilder
    private var sheetBackground: some View {
        Group {
            if let img = currentImage {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 28)
                    .overlay(Color.black.opacity(0.4))
            } else {
                LinearGradient(
                    colors: [Color(white: 0.10), Color(white: 0.04)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
}
