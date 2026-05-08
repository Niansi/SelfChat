import Foundation
import PhotosUI
import UniformTypeIdentifiers

class MediaStore {
    static let shared = MediaStore()

    private init() {}

    private var baseURL: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SelfChatMedia", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    func saveData(_ data: Data, fileName: String) throws -> String {
        let ext = (fileName as NSString).pathExtension
        let name = UUID().uuidString + (ext.isEmpty ? "" : ".\(ext)")
        let destination = baseURL.appendingPathComponent(name)
        try data.write(to: destination)
        return name
    }

    func importFile(from sourceURL: URL) throws -> (path: String, fileName: String, fileSize: Int64) {
        let resource = try sourceURL.resourceValues(forKeys: [.fileSizeKey, .nameKey])
        let data = try Data(contentsOf: sourceURL)
        let fileName = resource.name ?? sourceURL.lastPathComponent
        let path = try saveData(data, fileName: fileName)
        return (path, fileName, Int64(resource.fileSize ?? data.count))
    }

    func fileURL(for relativePath: String) -> URL {
        baseURL.appendingPathComponent(relativePath)
    }

    func delete(relativePath: String?) {
        guard let relativePath else { return }
        try? FileManager.default.removeItem(at: fileURL(for: relativePath))
    }
}
