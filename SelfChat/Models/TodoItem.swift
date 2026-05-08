import Foundation
import SwiftData

@Model
class TodoItem {
    var id: UUID
    var messageId: UUID
    var reminderText: String
    var reminderDate: Date?
    var isCompleted: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        messageId: UUID,
        reminderText: String,
        reminderDate: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.messageId = messageId
        self.reminderText = reminderText
        self.reminderDate = reminderDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }
}
