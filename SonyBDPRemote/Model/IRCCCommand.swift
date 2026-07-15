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

    // Number pad
    case num1 = "AAAAAwAAHFoAAAAAAw=="
    case num2 = "AAAAAwAAHFoAAAABAw=="
    case num3 = "AAAAAwAAHFoAAAACAw=="
    case num4 = "AAAAAwAAHFoAAAADAw=="
    case num5 = "AAAAAwAAHFoAAAAEAw=="
    case num6 = "AAAAAwAAHFoAAAAFAw=="
    case num7 = "AAAAAwAAHFoAAAAGAw=="
    case num8 = "AAAAAwAAHFoAAAAHAw=="
    case num9 = "AAAAAwAAHFoAAAAIAw=="
    case num0 = "AAAAAwAAHFoAAAAJAw=="

    // Audio / subtitles
    case audio    = "AAAAAwAAHFoAAABkAw=="
    case subtitle = "AAAAAwAAHFoAAABjAw=="

    // Color keys
    case yellow = "AAAAAwAAHFoAAABoAw=="
    case blue   = "AAAAAwAAHFoAAABpAw=="
    case red    = "AAAAAwAAHFoAAABmAw=="
    case green  = "AAAAAwAAHFoAAABnAw=="

    // Apps
    case netflix = "AAAAAwAAHFoAAABtAw=="

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
        case .num1: return "1"
        case .num2: return "2"
        case .num3: return "3"
        case .num4: return "4"
        case .num5: return "5"
        case .num6: return "6"
        case .num7: return "7"
        case .num8: return "8"
        case .num9: return "9"
        case .num0: return "0"
        case .audio: return "Audio"
        case .subtitle: return "Subtitle"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .red: return "Red"
        case .green: return "Green"
        case .netflix: return "Netflix"
        }
    }
}
