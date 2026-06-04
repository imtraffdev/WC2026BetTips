import Foundation

enum WC2026TipsLaunchDestination: Equatable {
    case native
    case web(URL)
    case offline
}

enum WC2026TipsNavigationTab: String, CaseIterable {
    case board = "Board"
    case tips = "Tips"
    case play = "Play"
    case history = "History"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .board: "calendar.badge.clock"
        case .tips: "chart.line.uptrend.xyaxis"
        case .play: "soccerball"
        case .history: "clock.arrow.circlepath"
        case .settings: "slider.horizontal.3"
        }
    }
}

enum WC2026TipsPickType: String, Codable, CaseIterable, Identifiable {
    case homeWin = "Home win"
    case draw = "Draw"
    case awayWin = "Away win"
    case overGoals = "Over 2.5 goals"
    case bothScore = "Both teams score"
    case corners = "Corner pressure"

    var id: String { rawValue }
}

enum WC2026TipsRiskLevel: String, Codable, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }
}

enum WC2026TipsPickStatus: String, Codable, CaseIterable {
    case watching = "Watching"
    case won = "Won"
    case lost = "Lost"
    case voided = "Voided"
}

struct WC2026TipsMatch: Identifiable, Codable, Equatable {
    var id = UUID()
    var home: String
    var away: String
    var country: String
    var date: Date
    var venueNote: String
    var homeForm: Int
    var awayForm: Int
    var attackTempo: Int
    var pressureIndex: Int
    var keyAngle: String
    var saved: Bool
}

struct WC2026TipsTeam: Identifiable, Codable, Equatable {
    var id: String { name }
    var name: String
    var flag: String
    var region: String

    static let catalog: [WC2026TipsTeam] = [
        WC2026TipsTeam(name: "United States", flag: "🇺🇸", region: "North America"),
        WC2026TipsTeam(name: "Canada", flag: "🇨🇦", region: "North America"),
        WC2026TipsTeam(name: "Mexico", flag: "🇲🇽", region: "North America"),
        WC2026TipsTeam(name: "Australia", flag: "🇦🇺", region: "Asia"),
        WC2026TipsTeam(name: "Iraq", flag: "🇮🇶", region: "Asia"),
        WC2026TipsTeam(name: "IR Iran", flag: "🇮🇷", region: "Asia"),
        WC2026TipsTeam(name: "Japan", flag: "🇯🇵", region: "Asia"),
        WC2026TipsTeam(name: "Jordan", flag: "🇯🇴", region: "Asia"),
        WC2026TipsTeam(name: "Korea Republic", flag: "🇰🇷", region: "Asia"),
        WC2026TipsTeam(name: "Qatar", flag: "🇶🇦", region: "Asia"),
        WC2026TipsTeam(name: "Saudi Arabia", flag: "🇸🇦", region: "Asia"),
        WC2026TipsTeam(name: "Uzbekistan", flag: "🇺🇿", region: "Asia"),
        WC2026TipsTeam(name: "Algeria", flag: "🇩🇿", region: "Africa"),
        WC2026TipsTeam(name: "Cabo Verde", flag: "🇨🇻", region: "Africa"),
        WC2026TipsTeam(name: "Congo DR", flag: "🇨🇩", region: "Africa"),
        WC2026TipsTeam(name: "Côte d'Ivoire", flag: "🇨🇮", region: "Africa"),
        WC2026TipsTeam(name: "Egypt", flag: "🇪🇬", region: "Africa"),
        WC2026TipsTeam(name: "Ghana", flag: "🇬🇭", region: "Africa"),
        WC2026TipsTeam(name: "Morocco", flag: "🇲🇦", region: "Africa"),
        WC2026TipsTeam(name: "Senegal", flag: "🇸🇳", region: "Africa"),
        WC2026TipsTeam(name: "South Africa", flag: "🇿🇦", region: "Africa"),
        WC2026TipsTeam(name: "Tunisia", flag: "🇹🇳", region: "Africa"),
        WC2026TipsTeam(name: "Curaçao", flag: "🇨🇼", region: "North America"),
        WC2026TipsTeam(name: "Haiti", flag: "🇭🇹", region: "North America"),
        WC2026TipsTeam(name: "Panama", flag: "🇵🇦", region: "North America"),
        WC2026TipsTeam(name: "Argentina", flag: "🇦🇷", region: "South America"),
        WC2026TipsTeam(name: "Brazil", flag: "🇧🇷", region: "South America"),
        WC2026TipsTeam(name: "Colombia", flag: "🇨🇴", region: "South America"),
        WC2026TipsTeam(name: "Ecuador", flag: "🇪🇨", region: "South America"),
        WC2026TipsTeam(name: "Paraguay", flag: "🇵🇾", region: "South America"),
        WC2026TipsTeam(name: "Uruguay", flag: "🇺🇾", region: "South America"),
        WC2026TipsTeam(name: "New Zealand", flag: "🇳🇿", region: "Oceania"),
        WC2026TipsTeam(name: "Austria", flag: "🇦🇹", region: "Europe"),
        WC2026TipsTeam(name: "Belgium", flag: "🇧🇪", region: "Europe"),
        WC2026TipsTeam(name: "Bosnia and Herzegovina", flag: "🇧🇦", region: "Europe"),
        WC2026TipsTeam(name: "Croatia", flag: "🇭🇷", region: "Europe"),
        WC2026TipsTeam(name: "Czechia", flag: "🇨🇿", region: "Europe"),
        WC2026TipsTeam(name: "England", flag: "🇬🇧", region: "Europe"),
        WC2026TipsTeam(name: "France", flag: "🇫🇷", region: "Europe"),
        WC2026TipsTeam(name: "Germany", flag: "🇩🇪", region: "Europe"),
        WC2026TipsTeam(name: "Netherlands", flag: "🇳🇱", region: "Europe"),
        WC2026TipsTeam(name: "Norway", flag: "🇳🇴", region: "Europe"),
        WC2026TipsTeam(name: "Portugal", flag: "🇵🇹", region: "Europe"),
        WC2026TipsTeam(name: "Scotland", flag: "🇬🇧", region: "Europe"),
        WC2026TipsTeam(name: "Spain", flag: "🇪🇸", region: "Europe"),
        WC2026TipsTeam(name: "Sweden", flag: "🇸🇪", region: "Europe"),
        WC2026TipsTeam(name: "Switzerland", flag: "🇨🇭", region: "Europe"),
        WC2026TipsTeam(name: "Türkiye", flag: "🇹🇷", region: "Europe")
    ]

    static func named(_ name: String) -> WC2026TipsTeam {
        catalog.first { $0.name == name } ?? WC2026TipsTeam(name: name, flag: "⚽", region: "Custom")
    }
}

struct WC2026TipsPick: Identifiable, Codable, Equatable {
    var id = UUID()
    var matchID: UUID?
    var matchTitle: String
    var type: WC2026TipsPickType
    var risk: WC2026TipsRiskLevel
    var confidence: Int
    var note: String
    var stakeUnits: Int
    var status: WC2026TipsPickStatus
    var createdAt = Date()
}

struct WC2026TipsKnowledgeCard: Identifiable, Codable, Equatable {
    var id = UUID()
    var category: String
    var title: String
    var summary: String
    var lesson: String
    var sections: [String] = []
    var bullets: [String]
    var readMinutes: Int
    var completed: Bool
}

struct WC2026TipsSimulationResult: Identifiable, Codable, Equatable {
    var id = UUID()
    var matchup: String
    var score: String
    var momentum: String
    var suggestedAngle: String
    var createdAt = Date()
}

struct WC2026TipsArcadeRecord: Codable, Equatable {
    var bestScore = 0
    var lastScore = 0
    var sessions = 0
}

struct WC2026TipsProfile: Codable, Equatable {
    var regionFocus = "North America"
    var bankrollUnits = 50
    var defaultRisk = WC2026TipsRiskLevel.medium
    var showHighRiskAngles = true
}

struct WC2026TipsPickDraft: Equatable {
    var matchID: UUID?
    var homeTeam = WC2026TipsTeam.named("United States")
    var awayTeam = WC2026TipsTeam.named("Mexico")
    var matchTitle = "United States vs Mexico"
    var type = WC2026TipsPickType.homeWin
    var risk = WC2026TipsRiskLevel.medium
    var confidence = 62
    var note = ""
    var stakeUnits = 2

    var hasValidTeams: Bool {
        homeTeam.name != awayTeam.name
    }

    mutating func setTeams(home: WC2026TipsTeam, away: WC2026TipsTeam) {
        homeTeam = home
        awayTeam = away
        matchID = nil
        matchTitle = "\(home.name) vs \(away.name)"
    }
}

struct WC2026TipsMatchDraft: Equatable {
    var homeTeam = WC2026TipsTeam.named("United States")
    var awayTeam = WC2026TipsTeam.named("Mexico")
    var date = Date()
    var venue = "North America"
    var homeForm = 65
    var awayForm = 65
    var attackTempo = 60
    var pressureIndex = 60

    var hasValidTeams: Bool {
        homeTeam.name != awayTeam.name
    }

    mutating func setTeams(home: WC2026TipsTeam, away: WC2026TipsTeam) {
        homeTeam = home
        awayTeam = away
    }
}

struct WC2026TipsInsight: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var value: String
    var detail: String
    var icon: String
}

extension String {
    var WC2026TipsTrimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Date {
    var WC2026TipsStamp: String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
