import AudioToolbox
import UIKit

enum NativeSound: SystemSoundID {
    case tock = 1104
    case pop = 1022
    case selection = 1157
    case sent = 1001
    case success = 1407
    case error = 1053
}

@Observable
class HapticSoundManager {
    @MainActor static let shared = HapticSoundManager()
    
    private init() {}

    @MainActor func play(_ sound: NativeSound) {
        AudioServicesPlaySystemSound(sound.rawValue)
        
        triggerHaptic(for: sound)
    }
    
    @MainActor private func triggerHaptic(for sound: NativeSound) {
        let notification = UINotificationFeedbackGenerator()
        let impact = UIImpactFeedbackGenerator(style: .medium)
        let selection = UISelectionFeedbackGenerator()
        
        switch sound {
        case .success, .sent:
            notification.notificationOccurred(.success)
        case .error:
            notification.notificationOccurred(.error)
        case .tock, .pop:
            impact.impactOccurred()
        case .selection:
            selection.selectionChanged()
        }
    }
}
