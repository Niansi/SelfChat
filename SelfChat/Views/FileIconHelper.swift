import SwiftUI
import UniformTypeIdentifiers

struct FileIconInfo {
    let systemName: String
    let color: Color
    let label: String
}

enum FileIconHelper {
    static func info(for fileName: String) -> FileIconInfo {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf":
            return FileIconInfo(systemName: "doc.fill", color: Color(red: 0.90, green: 0.20, blue: 0.18), label: "PDF")
        case "doc", "docx":
            return FileIconInfo(systemName: "doc.text.fill", color: Color(red: 0.16, green: 0.44, blue: 0.80), label: "Word")
        case "xls", "xlsx":
            return FileIconInfo(systemName: "tablecells.fill", color: Color(red: 0.13, green: 0.60, blue: 0.34), label: "Excel")
        case "ppt", "pptx":
            return FileIconInfo(systemName: "rectangle.on.rectangle.angled.fill", color: Color(red: 0.90, green: 0.42, blue: 0.13), label: "PPT")
        case "zip", "rar", "7z", "tar", "gz":
            return FileIconInfo(systemName: "doc.zipper", color: Color(red: 0.55, green: 0.40, blue: 0.25), label: ext.uppercased())
        case "mp3", "m4a", "wav", "aac", "flac":
            return FileIconInfo(systemName: "waveform", color: Color(red: 0.62, green: 0.18, blue: 0.80), label: "音频")
        case "mp4", "mov", "avi", "mkv":
            return FileIconInfo(systemName: "film.fill", color: Color(red: 0.15, green: 0.15, blue: 0.15), label: "视频")
        case "jpg", "jpeg", "png", "gif", "heic", "webp":
            return FileIconInfo(systemName: "photo.fill", color: Color(red: 0.20, green: 0.60, blue: 0.86), label: "图片")
        case "swift", "py", "js", "ts", "java", "kt", "cpp", "c", "h", "go", "rs":
            return FileIconInfo(systemName: "chevron.left.forwardslash.chevron.right", color: Color(red: 0.22, green: 0.22, blue: 0.22), label: "代码")
        case "txt", "md":
            return FileIconInfo(systemName: "doc.plaintext.fill", color: Color(red: 0.45, green: 0.45, blue: 0.48), label: "文本")
        case "html", "htm", "css":
            return FileIconInfo(systemName: "globe", color: Color(red: 0.92, green: 0.52, blue: 0.12), label: "网页")
        case "json", "xml", "yaml", "yml":
            return FileIconInfo(systemName: "doc.badge.gearshape.fill", color: Color(red: 0.36, green: 0.36, blue: 0.36), label: ext.uppercased())
        case "key":
            return FileIconInfo(systemName: "rectangle.on.rectangle.angled.fill", color: Color(red: 0.75, green: 0.38, blue: 0.15), label: "Keynote")
        case "numbers":
            return FileIconInfo(systemName: "tablecells.fill", color: Color(red: 0.10, green: 0.55, blue: 0.30), label: "Numbers")
        case "pages":
            return FileIconInfo(systemName: "doc.text.fill", color: Color(red: 0.96, green: 0.63, blue: 0.14), label: "Pages")
        default:
            return FileIconInfo(systemName: "doc.fill", color: Color(red: 0.55, green: 0.55, blue: 0.60), label: ext.isEmpty ? "文件" : ext.uppercased())
        }
    }
}

struct FileIconView: View {
    let fileName: String
    var size: CGFloat = 36

    var body: some View {
        let info = FileIconHelper.info(for: fileName)
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(info.color)
                .frame(width: size, height: size)
            Image(systemName: info.systemName)
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
