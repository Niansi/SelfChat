import SwiftUI
import SwiftData
import UserNotifications

@main
struct SelfChatApp: App {
    let modelContainer: ModelContainer

    init() {
        modelContainer = Self.makeContainer()
        requestNotificationPermission()
    }

    var body: some Scene {
        WindowGroup {
            ChatView()
        }
        .modelContainer(modelContainer)
    }

    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Message.self, TodoItem.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            do {
                return try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
