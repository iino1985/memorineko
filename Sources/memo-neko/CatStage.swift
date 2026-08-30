import Cocoa

// MARK: - 猫の体型（5段階）
// 輪郭は全段階で完全固定。メモリ使用率は顔の中の「塗りの高さ」で表現する（液面メーター型）。

enum EyeStyle {
    case dot     // ● 通常
    case squint  // ﹀ 満足げ
    case cross   // × 苦しい
}

enum CatStage: Int, CaseIterable {
    case slim = 0       // 〜40%
    case normal = 1     // 40〜60%
    case chubby = 2     // 60〜75%
    case plump = 3       // 75〜90%
    case stuffed = 4    // 90%〜

    static func from(percent: Double) -> CatStage {
        switch percent {
        case ..<40: return .slim
        case ..<60: return .normal
        case ..<75: return .chubby
        case ..<90: return .plump
        default: return .stuffed
        }
    }

    // 直前の段階から大きく外れた時だけ切り替える（境界付近でのチラつき防止）
    static func from(percent: Double, previous: CatStage?) -> CatStage {
        let raw = from(percent: percent)
        guard let previous else { return raw }
        let margin = 3.0
        let lower = from(percent: max(0, percent - margin))
        let upper = from(percent: min(100, percent + margin))
        if lower == previous || upper == previous { return previous }
        return raw
    }

    var label: String {
        switch self {
        case .slim: return "シュッ"
        case .normal: return "普通"
        case .chubby: return "ちょいぽちゃ"
        case .plump: return "ぽっちゃり"
        case .stuffed: return "パンパン"
        }
    }

    // 顔の中の塗り上がり高さ（0〜1、5段階で離散的に飛ぶ）
    var fillFraction: CGFloat {
        CGFloat(rawValue + 1) / CGFloat(CatStage.allCases.count)
    }

    var eyeStyle: EyeStyle {
        switch self {
        case .slim, .normal: return .dot
        case .chubby: return .squint
        case .plump, .stuffed: return .cross
        }
    }

    // 75%未満はモノクロ（ライト/ダーク自動反転）。危険域だけ色をつけて周囲から浮かせる。
    var isDangerColor: Bool { self == .plump || self == .stuffed }

    var dangerColor: NSColor {
        switch self {
        case .plump: return NSColor(calibratedRed: 1.0, green: 0.62, blue: 0.02, alpha: 1.0)   // amber
        case .stuffed: return NSColor(calibratedRed: 0.94, green: 0.23, blue: 0.18, alpha: 1.0) // red
        default: return .black
        }
    }
}
