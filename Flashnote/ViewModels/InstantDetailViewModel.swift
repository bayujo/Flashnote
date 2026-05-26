import Foundation
import Observation

@Observable
final class InstantDetailViewModel {

    // MARK: - Form state
    var reminderDate: Date = Date().addingTimeInterval(3600)
    var note: String = ""

    // MARK: - Presets
    struct Preset: Identifiable {
        let id = UUID()
        let label: String
        let offset: TimeInterval
    }

    let presets: [Preset] = [
        Preset(label: "+15m",     offset: 15 * 60),
        Preset(label: "+1h",      offset: 3600),
        Preset(label: "Tonight",  offset: InstantDetailViewModel.secondsUntilTonight()),
        Preset(label: "Tomorrow", offset: InstantDetailViewModel.secondsUntilTomorrow())
    ]

    // MARK: - Intent
    func configure(with item: FlashnoteItem) {
        reminderDate = item.reminderDate
        note = item.note
    }

    func applyPreset(_ preset: Preset) {
        reminderDate = Date().addingTimeInterval(preset.offset)
    }

    func truncateNote(limit: Int) {
        if note.count > limit { note = String(note.prefix(limit)) }
    }

    // MARK: - Preset offset helpers
    private static func secondsUntilTonight() -> TimeInterval {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 21; comps.minute = 0
        let tonight = Calendar.current.date(from: comps) ?? Date().addingTimeInterval(8 * 3600)
        let diff = tonight.timeIntervalSinceNow
        return diff > 0 ? diff : diff + 86400
    }

    private static func secondsUntilTomorrow() -> TimeInterval {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 9; comps.minute = 0
        let base = Calendar.current.date(from: comps) ?? Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: base) ?? base
        return tomorrow.timeIntervalSinceNow
    }
}
