import AppKit
import Carbon

enum HotkeyType {
    case startStop
    case reset
    case increaseDuration
    case decreaseDuration
    case setDuration
    case hostNetwork
    case joinNetwork
}

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed(type: HotkeyType)
}

class HotkeyManager {
    weak var delegate: HotkeyManagerDelegate?
    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?

    func registerHotkeys() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (_, event, userData) -> OSStatus in
            guard let userData = userData else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)

            switch hotKeyID.id {
            case 1:
                manager.delegate?.hotkeyPressed(type: .startStop)
            case 2:
                manager.delegate?.hotkeyPressed(type: .reset)
            case 3:
                manager.delegate?.hotkeyPressed(type: .increaseDuration)
            case 4:
                manager.delegate?.hotkeyPressed(type: .decreaseDuration)
            case 5:
                manager.delegate?.hotkeyPressed(type: .setDuration)
            case 6:
                manager.delegate?.hotkeyPressed(type: .hostNetwork)
            case 7:
                manager.delegate?.hotkeyPressed(type: .joinNetwork)
            default:
                break
            }

            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        let modifiers = UInt32(cmdKey | shiftKey)

        // Register Cmd+Shift+T for start/stop
        var startStopRef: EventHotKeyRef?
        let startStopID = EventHotKeyID(signature: OSType(0x54494D52), id: 1) // 'TIMR'
        let startStopKey = UInt32(kVK_ANSI_T)
        RegisterEventHotKey(startStopKey, modifiers, startStopID, GetApplicationEventTarget(), 0, &startStopRef)
        hotKeyRefs.append(startStopRef)

        // Register Cmd+Shift+R for reset
        var resetRef: EventHotKeyRef?
        let resetID = EventHotKeyID(signature: OSType(0x54494D52), id: 2) // 'TIMR'
        let resetKey = UInt32(kVK_ANSI_R)
        RegisterEventHotKey(resetKey, modifiers, resetID, GetApplicationEventTarget(), 0, &resetRef)
        hotKeyRefs.append(resetRef)

        // Register Cmd+Shift+UpArrow for increase duration
        var increaseRef: EventHotKeyRef?
        let increaseID = EventHotKeyID(signature: OSType(0x54494D52), id: 3) // 'TIMR'
        let increaseKey = UInt32(kVK_UpArrow)
        RegisterEventHotKey(increaseKey, modifiers, increaseID, GetApplicationEventTarget(), 0, &increaseRef)
        hotKeyRefs.append(increaseRef)

        // Register Cmd+Shift+DownArrow for decrease duration
        var decreaseRef: EventHotKeyRef?
        let decreaseID = EventHotKeyID(signature: OSType(0x54494D52), id: 4) // 'TIMR'
        let decreaseKey = UInt32(kVK_DownArrow)
        RegisterEventHotKey(decreaseKey, modifiers, decreaseID, GetApplicationEventTarget(), 0, &decreaseRef)
        hotKeyRefs.append(decreaseRef)

        // Register Cmd+Shift+D for set duration dialog
        var setDurationRef: EventHotKeyRef?
        let setDurationID = EventHotKeyID(signature: OSType(0x54494D52), id: 5) // 'TIMR'
        let setDurationKey = UInt32(kVK_ANSI_D)
        RegisterEventHotKey(setDurationKey, modifiers, setDurationID, GetApplicationEventTarget(), 0, &setDurationRef)
        hotKeyRefs.append(setDurationRef)

        // Register Cmd+Shift+H for host network
        var hostNetworkRef: EventHotKeyRef?
        let hostNetworkID = EventHotKeyID(signature: OSType(0x54494D52), id: 6) // 'TIMR'
        let hostNetworkKey = UInt32(kVK_ANSI_H)
        RegisterEventHotKey(hostNetworkKey, modifiers, hostNetworkID, GetApplicationEventTarget(), 0, &hostNetworkRef)
        hotKeyRefs.append(hostNetworkRef)

        // Register Cmd+Shift+J for join network
        var joinNetworkRef: EventHotKeyRef?
        let joinNetworkID = EventHotKeyID(signature: OSType(0x54494D52), id: 7) // 'TIMR'
        let joinNetworkKey = UInt32(kVK_ANSI_J)
        RegisterEventHotKey(joinNetworkKey, modifiers, joinNetworkID, GetApplicationEventTarget(), 0, &joinNetworkRef)
        hotKeyRefs.append(joinNetworkRef)
    }

    func unregisterHotkeys() {
        for hotKeyRef in hotKeyRefs {
            if let ref = hotKeyRef {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()

        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
