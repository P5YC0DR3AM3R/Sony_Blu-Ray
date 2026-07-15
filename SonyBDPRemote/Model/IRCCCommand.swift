import Foundation

/// IRCC (IR-like Command over IP) codes for Sony BDP-S series Blu-ray
/// players, including the BDP-S5100. Each raw value is the base64 command
/// payload sent in the `<IRCCCode>` element of the SOAP `X_SendIRCC` call.
enum IRCCCommand: String, CaseIterable, Identifiable {
    // Utility
    case power    = "AAAAAwAAHFoAAAAVAw=="
    case eject    = "AAAAAwAAHFoAAAAWAw=="
    case home     = "AAAAAwAAHFoAAABCAw=="
    case options  = "AAAAAwAAHFoAAAA/Aw=="
    case `return` = "AAAAAwAAHFoAAABDAw=="
    case display  = "AAAAAwAAHFoAAABBAw=="

    // D-pad
    case up      = "AAAAAwAAHFoAAAA5Aw=="
    case down    = "AAAAAwAAHFoAAAA6Aw=="
    case left    = "AAAAAwAAHFoAAAA7Aw=="
    case right   = "AAAAAwAAHFoAAAA8Aw=="
    case confirm = "AAAAAwAAHFoAAAA9Aw=="

    // Media transport
    case play     = "AAAAAwAAHFoAAAAaAw=="
    case pause    = "AAAAAwAAHFoAAAAZAw=="
    case stop     = "AAAAAwAAHFoAAAAYAw=="
    case previous = "AAAAAwAAHFoAAAAdAw=="
    case next     = "AAAAAwAAHFoAAAAeAw=="
    case rewind   = "AAAAAwAAHFoAAAAbAw=="
    case forward  = "AAAAAwAAHFoAAAAcAw=="

    // Disc menus
    case topMenu   = "AAAAAwAAHFoAAAAsAw=="
    case popUpMenu = "AAAAAwAAHFoAAAApAw=="

    var id: String { rawValue }

    /// Human-readable label used in UI accessibility and status messages.
    var label: String {
        switch self {
        case .power: return "Power"
        case .eject: return "Eject"
        case .home: return "Home"
        case .options: return "Options"
        case .return: return "Return"
        case .display: return "Display"
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .confirm: return "Select"
        case .play: return "Play"
        case .pause: return "Pause"
        case .stop: return "Stop"
        case .previous: return "Skip Back"
        case .next: return "Skip Forward"
        case .rewind: return "Rewind"
        case .forward: return "Fast Forward"
        case .topMenu: return "Top Menu"
        case .popUpMenu: return "Pop-Up Menu"
        }
    }
}
