// ShareExtensionView.swift
// This view is used by both the main app and the Share Extension target.
// The Share Extension's ShareViewController presents this as a UIHostingController.
import SwiftUI

/// Standalone sheet used inside the Share Extension.
/// Communicates results back via the onSave/onDismiss callbacks.
struct ShareExtensionView: View {
    let image: UIImage
    let onSave: (Date, String) -> Void
    let onDismiss: () -> Void

    @State private var reminderDate = Date().addingTimeInterval(3600)
    @State private var note: String = ""

    private struct Preset { let label: String; let offset: TimeInterval }
    private let presets: [Preset] = [
        Preset(label: "+15m",     offset: 15 * 60),
        Preset(label: "+1h",      offset: 3600),
        Preset(label: "Tonight",  offset: secondsUntilTonight()),
        Preset(label: "Tomorrow", offset: secondsUntilTomorrow())
    ]

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .blur(radius: 28)
                .overlay(Color.black.opacity(0.4))

            ScrollView {
                VStack(spacing: 24) {
                    // Handle bar
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 36, height: 4)
                        .padding(.top, 12)

                    // Preview
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(14)
                        .shadow(radius: 10)

                    // Presets
                    HStack(spacing: 10) {
                        ForEach(presets, id: \.label) { preset in
                            Button(preset.label) {
                                reminderDate = Date().addingTimeInterval(preset.offset)
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                        }
                    }

                    // Picker
                    DatePicker(
                        "Remind me at",
                        selection: $reminderDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .tint(.white)
                    .colorScheme(.dark)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Note field
                    TextField("Quick note…", text: $note)
                        .onChange(of: note) { _, new in
                            if new.count > 10 { note = String(new.prefix(10)) }
                        }
                        .font(.body)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    // Save
                    Button {
                        onSave(reminderDate, note)
                    } label: {
                        Text("Set Visual Note")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 18))
                    }
                    .padding(.horizontal)

                    Button("Cancel") { onDismiss() }
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private static func secondsUntilTonight() -> TimeInterval {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 21; c.minute = 0
        let t = Calendar.current.date(from: c) ?? Date().addingTimeInterval(8 * 3600)
        let d = t.timeIntervalSinceNow
        return d > 0 ? d : d + 86400
    }

    private static func secondsUntilTomorrow() -> TimeInterval {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = 9; c.minute = 0
        let base = Calendar.current.date(from: c) ?? Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: base) ?? base
        return tomorrow.timeIntervalSinceNow
    }
}
