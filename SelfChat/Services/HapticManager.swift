import SwiftUI

enum HapticEvent {
    case sendMessage
    case tapStack
    case swipeStack
    case deleteMessage
}

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()

    private init() {
        lightImpact.prepare()
        mediumImpact.prepare()
        selection.prepare()
        notification.prepare()
    }

    func play(_ event: HapticEvent) {
        switch event {
        case .sendMessage:
            lightImpact.impactOccurred(intensity: 0.7)
            lightImpact.prepare()
        case .tapStack:
            mediumImpact.impactOccurred(intensity: 0.8)
            mediumImpact.prepare()
        case .swipeStack:
            selection.selectionChanged()
            selection.prepare()
        case .deleteMessage:
            notification.notificationOccurred(.success)
            notification.prepare()
        }
    }
}
