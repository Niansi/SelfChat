import UIKit

struct AttachmentDraft: Identifiable {
    enum Kind {
        case image(UIImage, Data)
        case video(URL, Data)
        case file(URL, String, Int64)
    }
    let id = UUID()
    let kind: Kind

    var thumbnail: UIImage? {
        switch kind {
        case .image(let img, _): return img
        default: return nil
        }
    }

    var displayName: String {
        switch kind {
        case .image: return "图片"
        case .video: return "视频"
        case .file(_, let name, _): return name
        }
    }
}
