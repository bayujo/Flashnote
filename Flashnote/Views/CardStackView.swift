import SwiftUI
import SwiftData
import UIKit
import SDWebImage

// MARK: - Card Stack

struct CardStackView: View {
    let items: [FlashnoteItem]
    let onLater: (FlashnoteItem) -> Void
    let onDone: (FlashnoteItem) -> Void
    let onTap: (FlashnoteItem) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false

    private let swipeThreshold: CGFloat = 100

    var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width - 32
            let cardHeight = min(geo.size.height * 0.78, 580)

            ZStack {
                if items.isEmpty {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ForEach(Array(items.prefix(3).enumerated().reversed()), id: \.element.id) { index, item in
                        cardLayer(
                            item: item,
                            index: index,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func cardLayer(
        item: FlashnoteItem,
        index: Int,
        cardWidth: CGFloat,
        cardHeight: CGFloat
    ) -> some View {
        let isTop = index == 0
        let dragProgress = min(1, abs(dragOffset.width) / swipeThreshold)
        let backIndex = CGFloat(index)
        let stackScale = isTop ? 1.0 : 1.0 - backIndex * 0.05 + dragProgress * backIndex * 0.025
        let stackYOffset = isTop ? dragOffset.height * 0.08 : backIndex * 16 - dragProgress * backIndex * 8
        let xOffset: CGFloat = isTop ? dragOffset.width : 0
        let rotation: Double = isTop ? Double(dragOffset.width) / 22 : 0
        let spring = Animation.interactiveSpring(response: 0.28, dampingFraction: 0.82)

        return BigFlashnoteCard(item: item)
            .frame(width: cardWidth, height: cardHeight)
            .scaleEffect(stackScale)
            .offset(x: xOffset, y: stackYOffset)
            .rotationEffect(.degrees(rotation))
            .overlay { if isTop { swipeIndicator } }
            .gesture(isTop ? topCardDragGesture(item: item, cardWidth: cardWidth) : nil)
            .onTapGesture { if isTop { onTap(item) } }
            .animation(spring, value: dragOffset)
            .animation(spring, value: isDragging)
            .zIndex(Double(3 - index))
    }

    private func topCardDragGesture(item: FlashnoteItem, cardWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                isDragging = true
                dragOffset = value.translation
            }
            .onEnded { value in
                isDragging = false
                let velocityX = value.predictedEndTranslation.width
                let swipeLeft = value.translation.width < -swipeThreshold || velocityX < -swipeThreshold * 2.5
                let swipeRight = value.translation.width > swipeThreshold || velocityX > swipeThreshold * 2.5

                if swipeLeft {
                    let exitOffset = CGSize(width: -(cardWidth + 120), height: value.translation.height * 0.5)
                    withAnimation(.easeOut(duration: 0.25)) { dragOffset = exitOffset }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDone(item)
                        dragOffset = .zero
                    }
                } else if swipeRight {
                    let exitOffset = CGSize(width: cardWidth + 120, height: value.translation.height * 0.5)
                    withAnimation(.easeOut(duration: 0.25)) { dragOffset = exitOffset }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onLater(item)
                        dragOffset = .zero
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    @ViewBuilder
    private var swipeIndicator: some View {
        let doneProgress = min(1, max(0, -dragOffset.width / 60))
        let laterProgress = min(1, max(0, dragOffset.width / 60))

        ZStack {
            // Done badge — top leading
            VStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 38, weight: .bold))
                Text("DONE")
                    .font(.callout.weight(.black))
                    .kerning(1.5)
            }
            .foregroundStyle(.green)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.green.opacity(0.55), lineWidth: 1.5))
            .opacity(doneProgress)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(20)

            // Later badge — top trailing
            VStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 38, weight: .bold))
                Text("LATER")
                    .font(.callout.weight(.black))
                    .kerning(1.5)
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.orange.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.orange.opacity(0.55), lineWidth: 1.5))
            .opacity(laterProgress)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(20)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.white.opacity(0.25))
            Text("All clear!")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text("Tap the camera to add a visual note")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.28))
        }
    }
}

// MARK: - Big Card

struct BigFlashnoteCard: View {
    let item: FlashnoteItem
    @State private var cachedImage: UIImage?
    @State private var showFullNote = false

    private var isTextOnly: Bool { item.imagePath.isEmpty }

    private static let noteColors: [Color] = [
        Color(red: 0.35, green: 0.15, blue: 0.65),
        Color(red: 0.08, green: 0.28, blue: 0.68),
        Color(red: 0.04, green: 0.44, blue: 0.54),
        Color(red: 0.12, green: 0.48, blue: 0.30),
        Color(red: 0.70, green: 0.28, blue: 0.04),
        Color(red: 0.65, green: 0.12, blue: 0.36),
        Color(red: 0.20, green: 0.16, blue: 0.58),
        Color(red: 0.50, green: 0.22, blue: 0.10),
    ]

    private var noteColor: Color {
        Self.noteColors[abs(item.id.hashValue) % Self.noteColors.count]
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if isTextOnly {
                    textOnlyCard
                } else {
                    imageCard(size: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.1), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.5), radius: 18, y: 10)
        }
        .task(id: item.imagePath) {
            guard !isTextOnly else { cachedImage = nil; return }
            cachedImage = await loadImage(for: item.imagePath)
        }
    }

    // MARK: - Text-only card

    @ViewBuilder
    private var textOnlyCard: some View {
        noteColor

        VStack(spacing: 16) {
            if item.note.isEmpty {
                Image(systemName: "text.bubble")
                    .font(.system(size: 48))
                    .foregroundStyle(.white.opacity(0.4))
            } else {
                Text(item.note)
                    .font(.title.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            CountdownLabel(date: item.reminderDate)
        }
        .padding(24)
    }

    // MARK: - Image card

    @ViewBuilder
    private func imageCard(size: CGSize) -> some View {
        // Base image + bottom gradient with countdown and note badge in one row
        ZStack(alignment: .bottom) {
            imageView(size: size)

            HStack(alignment: .center, spacing: 8) {
                CountdownLabel(date: item.reminderDate)

                if !item.note.isEmpty {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showFullNote = true }
                    } label: {
                        Text(item.note)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 130, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.black.opacity(0.55), in: Capsule())
                    }
                } else {
                    Spacer()
                }
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }

        // Full-note dim overlay
        if showFullNote {
            ZStack {
                Color.black.opacity(0.75)

                Text(item.note)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(32)
                    .allowsHitTesting(false)
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) { showFullNote = false }
            }
        }
    }

    // MARK: - Image view

    @ViewBuilder
    private func imageView(size: CGSize) -> some View {
        if let uiImage = cachedImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.18))
                .frame(width: size.width, height: size.height)
                .overlay(ProgressView().tint(.white.opacity(0.4)))
        }
    }

    // MARK: - Image loading

    /// Loads an image for the given imagePath using SDWebImage.
    /// - For `photos://` URLs: uses SDWebImageManager (SDImagePhotosLoader handles it).
    /// - For cache keys: retrieves directly from SDImageCache.
    private func loadImage(for imagePath: String) async -> UIImage? {
        if ImageStorage.isPhotosURL(imagePath) {
            guard let url = ImageStorage.url(for: imagePath) else { return nil }
            return await withCheckedContinuation { continuation in
                SDWebImageManager.shared.loadImage(
                    with: url,
                    options: .highPriority,
                    progress: nil
                ) { image, _, _, _, _, _ in
                    continuation.resume(returning: image)
                }
            }
        } else {
            // Cache key path — query SDImageCache directly
            return await withCheckedContinuation { continuation in
                SDImageCache.shared.queryImage(forKey: imagePath, options: [], context: nil) { image, _, _ in
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
