import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playSendSound() {
        // 1307 = 邮件发送音效，清脆的"嗖"声
        AudioServicesPlaySystemSound(1307)
    }
}
