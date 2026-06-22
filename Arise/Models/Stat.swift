import SwiftUI

/// The five Hunter stats shown in the STATUS window. See SYSTEM_DESIGN.md §2.
enum StatKind: String, CaseIterable, Codable, Identifiable {
    case strength
    case agility
    case vitality
    case endurance
    case sense

    var id: String { rawValue }

    var abbreviation: String {
        switch self {
        case .strength: return "STR"
        case .agility: return "AGI"
        case .vitality: return "VIT"
        case .endurance: return "END"
        case .sense: return "SEN"
        }
    }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .agility: return "Agility"
        case .vitality: return "Vitality"
        case .endurance: return "Endurance"
        case .sense: return "Sense"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "dumbbell.fill"
        case .agility: return "figure.run"
        case .vitality: return "heart.fill"
        case .endurance: return "flame.fill"
        case .sense: return "moon.zzz.fill"
        }
    }

    var color: Color {
        switch self {
        case .strength: return Color(hex: 0xFF6B6B)
        case .agility: return Color(hex: 0x4ED2A0)
        case .vitality: return Color(hex: 0xFF4D6D)
        case .endurance: return Color(hex: 0xFF8A3D)
        case .sense: return Color(hex: 0x9B6BFF)
        }
    }

    var blurb: String {
        switch self {
        case .strength: return "Resistance training volume & lean mass."
        case .agility: return "Steps, distance & cardio output."
        case .vitality: return "Resting HR, HRV & VO₂max."
        case .endurance: return "Sustained exercise & active burn."
        case .sense: return "Sleep, SpO₂ & recovery."
        }
    }
}

struct Stat: Identifiable {
    let kind: StatKind
    let value: Int
    /// 0…1 condition component, used to size the bar (before trained bonus).
    let condition: Double

    var id: String { kind.id }
}
