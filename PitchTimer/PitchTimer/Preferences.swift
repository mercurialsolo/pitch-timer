import Foundation
import CoreGraphics

enum OverlayPosition: Equatable {
    case left
    case right
    case custom(x: CGFloat, y: CGFloat)
}

class Preferences {
    var timerDuration: Int = 300 // 5 minutes default
    var playSoundOnComplete: Bool = true
    var showRedAlert: Bool = true
    var overlayPosition: OverlayPosition = .right
}
