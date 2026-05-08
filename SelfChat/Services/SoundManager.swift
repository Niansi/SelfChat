import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()

    private init() {}

    func playSendSound() {
        // 1016 = 短信发送成功音效（清脆的"嗖"声）
        // 1117 = 锁定声（另一种清脆音）
        // 1118 = 解锁声
        // 尝试 1016 获取更接近"嗖"声的效果
        AudioServicesPlaySystemSound(1016)
    }
}
