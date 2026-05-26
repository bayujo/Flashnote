import Foundation
import SwiftData

@Model
final class FlashnoteItem {
    var id: UUID
    var imagePath: String
    var reminderDate: Date
    var isCompleted: Bool
    var note: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        imagePath: String,
        reminderDate: Date,
        isCompleted: Bool = false,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.imagePath = imagePath
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.note = note
        self.createdAt = createdAt
    }
}
