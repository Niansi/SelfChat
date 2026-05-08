import Foundation
import SwiftData

enum MessageType: String, Codable {
    case text
    case image
    case video
    case file
    case mixed
}

@Model
class Message {
    var id: UUID
    var type: MessageType
    var text: String?
    var mediaPaths: [String]
    var fileNames: [String]
    var fileSizes: [Int64]
    var createdAt: Date
    var isTodo: Bool

    var mediaPath: String? { mediaPaths.first }
    var fileName: String? { fileNames.first }
    var fileSize: Int64 { fileSizes.first ?? 0 }

    init(
        id: UUID = UUID(),
        type: MessageType,
        text: String? = nil,
        mediaPaths: [String] = [],
        fileNames: [String] = [],
        fileSizes: [Int64] = [],
        createdAt: Date = Date(),
        isTodo: Bool = false
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.mediaPaths = mediaPaths
        self.fileNames = fileNames
        self.fileSizes = fileSizes
        self.createdAt = createdAt
        self.isTodo = isTodo
    }
}
