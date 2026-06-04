import SwiftUI

final class WC2026TipsLocalStore: ObservableObject {
    private enum Keys {
        static let matches = "WC2026Tips_matches_v3"
        static let picks = "WC2026Tips_picks_v2"
        static let knowledge = "WC2026Tips_knowledge_v2"
        static let simulations = "WC2026Tips_simulations_v2"
        static let arcade = "WC2026Tips_arcade_v1"
        static let profile = "WC2026Tips_profile_v1"
    }

    @Published var matches: [WC2026TipsMatch] { didSet { persist(matches, key: Keys.matches) } }
    @Published var picks: [WC2026TipsPick] { didSet { persist(picks, key: Keys.picks) } }
    @Published var knowledgeCards: [WC2026TipsKnowledgeCard] { didSet { persist(knowledgeCards, key: Keys.knowledge) } }
    @Published var simulations: [WC2026TipsSimulationResult] { didSet { persist(simulations, key: Keys.simulations) } }
    @Published var arcadeRecord: WC2026TipsArcadeRecord { didSet { persist(arcadeRecord, key: Keys.arcade) } }
    @Published var profile: WC2026TipsProfile { didSet { persist(profile, key: Keys.profile) } }

    init() {
        matches = Self.restore([WC2026TipsMatch].self, key: Keys.matches) ?? []
        picks = Self.restore([WC2026TipsPick].self, key: Keys.picks) ?? []
        knowledgeCards = Self.restore([WC2026TipsKnowledgeCard].self, key: Keys.knowledge) ?? Self.seedKnowledge
        simulations = Self.restore([WC2026TipsSimulationResult].self, key: Keys.simulations) ?? []
        arcadeRecord = Self.restore(WC2026TipsArcadeRecord.self, key: Keys.arcade) ?? WC2026TipsArcadeRecord()
        profile = Self.restore(WC2026TipsProfile.self, key: Keys.profile) ?? WC2026TipsProfile()
    }

    var upcomingMatches: [WC2026TipsMatch] {
        matches.sorted { $0.date < $1.date }
    }

    var savedMatches: [WC2026TipsMatch] {
        matches.sorted { $0.date < $1.date }
    }

    var activePicks: [WC2026TipsPick] {
        picks.filter { $0.status == .watching }.sorted { $0.createdAt > $1.createdAt }
    }

    var settledPicks: [WC2026TipsPick] {
        picks.filter { $0.status != .watching }.sorted { $0.createdAt > $1.createdAt }
    }

    var insights: [WC2026TipsInsight] {
        let completed = knowledgeCards.filter(\.completed).count
        let wins = picks.filter { $0.status == .won }.count
        let losses = picks.filter { $0.status == .lost }.count
        let rate = wins + losses == 0 ? "New" : "\(Int((Double(wins) / Double(wins + losses)) * 100))%"
        return [
            WC2026TipsInsight(title: "Matches", value: "\(matches.count)", detail: "Added by you", icon: "calendar.badge.plus"),
            WC2026TipsInsight(title: "Active", value: "\(activePicks.count)", detail: "Tips being tracked", icon: "target"),
            WC2026TipsInsight(title: "Study", value: "\(completed)/\(knowledgeCards.count)", detail: "Cards completed", icon: "book.closed.fill"),
            WC2026TipsInsight(title: "Hit Rate", value: rate, detail: "Local settled picks", icon: "percent")
        ]
    }

    func toggleSaved(_ match: WC2026TipsMatch) {
        guard let index = matches.firstIndex(where: { $0.id == match.id }) else { return }
        matches[index].saved.toggle()
    }

    @discardableResult
    func createMatch(from draft: WC2026TipsMatchDraft) -> WC2026TipsMatch {
        let keyAngle = Self.angle(homeForm: draft.homeForm, awayForm: draft.awayForm, tempo: draft.attackTempo, pressure: draft.pressureIndex)
        let match = WC2026TipsMatch(
            home: draft.homeTeam.name,
            away: draft.awayTeam.name,
            country: draft.venue.WC2026TipsTrimmed.isEmpty ? "Custom" : draft.venue.WC2026TipsTrimmed,
            date: draft.date,
            venueNote: "\(draft.homeTeam.region) vs \(draft.awayTeam.region)",
            homeForm: draft.homeForm,
            awayForm: draft.awayForm,
            attackTempo: draft.attackTempo,
            pressureIndex: draft.pressureIndex,
            keyAngle: keyAngle,
            saved: true
        )
        matches.insert(match, at: 0)
        return match
    }

    func deleteMatch(_ match: WC2026TipsMatch) {
        matches.removeAll { $0.id == match.id }
        picks.removeAll { $0.matchID == match.id }
    }

    func draft(for match: WC2026TipsMatch) -> WC2026TipsPickDraft {
        WC2026TipsPickDraft(
            matchID: match.id,
            homeTeam: WC2026TipsTeam.named(match.home),
            awayTeam: WC2026TipsTeam.named(match.away),
            matchTitle: "\(match.home) vs \(match.away)",
            type: match.homeForm >= match.awayForm ? .homeWin : .awayWin,
            risk: profile.defaultRisk,
            confidence: min(88, max(48, 52 + abs(match.homeForm - match.awayForm) * 4 + match.pressureIndex / 8)),
            note: match.keyAngle,
            stakeUnits: max(1, min(5, profile.bankrollUnits / 20))
        )
    }

    @discardableResult
    func createPick(from draft: WC2026TipsPickDraft) -> WC2026TipsPick {
        let pick = WC2026TipsPick(
            matchID: draft.matchID,
            matchTitle: draft.matchTitle.WC2026TipsTrimmed.isEmpty ? "Custom matchup" : draft.matchTitle.WC2026TipsTrimmed,
            type: draft.type,
            risk: draft.risk,
            confidence: draft.confidence,
            note: draft.note.WC2026TipsTrimmed.isEmpty ? "Check lineup news, travel load and opening tempo before final call." : draft.note.WC2026TipsTrimmed,
            stakeUnits: draft.stakeUnits,
            status: .watching
        )
        picks.insert(pick, at: 0)
        return pick
    }

    func updatePick(_ pick: WC2026TipsPick, status: WC2026TipsPickStatus) {
        guard let index = picks.firstIndex(where: { $0.id == pick.id }) else { return }
        picks[index].status = status
    }

    func deletePick(_ pick: WC2026TipsPick) {
        picks.removeAll { $0.id == pick.id }
    }

    func deleteSimulation(_ result: WC2026TipsSimulationResult) {
        simulations.removeAll { $0.id == result.id }
    }

    func toggleKnowledge(_ card: WC2026TipsKnowledgeCard) {
        guard let index = knowledgeCards.firstIndex(where: { $0.id == card.id }) else { return }
        knowledgeCards[index].completed.toggle()
    }

    @discardableResult
    func simulate(home: String, away: String, tempo: Int, risk: WC2026TipsRiskLevel) -> WC2026TipsSimulationResult {
        let cleanHome = home.WC2026TipsTrimmed.isEmpty ? "Home XI" : home.WC2026TipsTrimmed
        let cleanAway = away.WC2026TipsTrimmed.isEmpty ? "Away XI" : away.WC2026TipsTrimmed
        let tilt = max(-2, min(2, tempo / 18 - 2))
        let homeGoals = max(0, Int.random(in: 0...3) + max(0, tilt))
        let awayGoals = max(0, Int.random(in: 0...3) + max(0, -tilt))
        let angle: String
        if homeGoals + awayGoals >= 3 {
            angle = "Fast tempo profile: compare over-goals price against live shot volume."
        } else if homeGoals == awayGoals {
            angle = "Tight game profile: draw protection and late substitutions matter most."
        } else {
            angle = "Leader profile: watch whether the trailing side creates pressure before adding exposure."
        }
        let result = WC2026TipsSimulationResult(matchup: "\(cleanHome) vs \(cleanAway)", score: "\(homeGoals)-\(awayGoals)", momentum: "\(risk.rawValue) risk, tempo \(tempo)/100", suggestedAngle: angle)
        simulations.insert(result, at: 0)
        return result
    }

    func recordArcade(score: Int) {
        arcadeRecord.lastScore = score
        arcadeRecord.bestScore = max(arcadeRecord.bestScore, score)
        arcadeRecord.sessions += 1
    }

    func updateProfile(region: String, bankroll: Int, risk: WC2026TipsRiskLevel, showHighRisk: Bool) {
        profile.regionFocus = region.WC2026TipsTrimmed.isEmpty ? "North America" : region.WC2026TipsTrimmed
        profile.bankrollUnits = bankroll
        profile.defaultRisk = risk
        profile.showHighRiskAngles = showHighRisk
    }

    func resetLocalData() {
        [Keys.matches, Keys.picks, Keys.knowledge, Keys.simulations, Keys.arcade, Keys.profile].forEach { UserDefaults.standard.removeObject(forKey: $0) }
        matches = []
        picks = []
        knowledgeCards = Self.seedKnowledge
        simulations = []
        arcadeRecord = WC2026TipsArcadeRecord()
        profile = WC2026TipsProfile()
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private static func restore<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func angle(homeForm: Int, awayForm: Int, tempo: Int, pressure: Int) -> String {
        let gap = homeForm - awayForm
        if tempo >= 76 && pressure >= 70 {
            return "High-tempo pressure profile: study over goals, both teams to score, and live shot volume before committing."
        }
        if abs(gap) >= 14 && pressure >= 64 {
            return gap > 0 ? "Home edge profile: look for home win only if lineup news confirms attacking starters." : "Away edge profile: price the away side carefully and protect against draw risk."
        }
        if tempo <= 45 {
            return "Slow-tempo profile: avoid forcing pre-match overs; wait for first-half pace and field tilt."
        }
        return "Balanced profile: build a small-stake watch tip and confirm with lineups, travel load and early tempo."
    }

    private static var seedKnowledge: [WC2026TipsKnowledgeCard] {
        [
            article(
                "Basics",
                "Turn odds into probability",
                "Compare the market price with your own estimate before calling anything a tip.",
                "The core betting skill is not predicting winners. It is deciding whether the available price is better than the real chance you assign to the event.",
                [
                    "Start with implied probability. Decimal odds of 2.00 imply 50%, 1.50 implies about 67%, and 3.00 implies about 33%. That number is not a prediction; it is the market's price tag before you adjust for bookmaker margin.",
                    "After you know the implied probability, write your own estimate. If you think an outcome is 55% likely but the market prices it around 50%, you may have a reason to continue researching. If your estimate is close to the market, the pick may still win but the edge is weak.",
                    "For football, avoid treating team names as probabilities. A famous side at a short price can be poor value if travel, rotation, heat or tactical matchup reduce their advantage. The app's match board exists to force that context into the decision."
                ],
                ["Convert the price before choosing a side.", "Write your estimated chance before saving the tip.", "Skip picks where your estimate and the market look almost identical."],
                8
            ),
            article(
                "Basics",
                "Pick vs stake",
                "Separate the quality of an idea from the amount risked on it.",
                "A good idea can still deserve a small stake when uncertainty is high.",
                [
                    "Stake is a confidence control. A matchup can point toward home win, over goals or corners, but if lineups are unknown or weather is unusual, the correct stake may still be one unit.",
                    "Think of every saved tip as a note in a long tournament, not a single dramatic call. The goal is to make results reviewable: why did you like the spot, what risk did you see, and did the match actually behave as expected?",
                    "The safest structure is to make most tips small and reserve larger stakes for cases where your read, lineup news, price and risk profile all agree."
                ],
                ["Use one unit for early reads.", "Do not increase stake because the previous pick lost.", "Let uncertainty reduce stake even when the angle looks attractive."],
                7
            ),
            article(
                "Match Reading",
                "Tempo profile",
                "Use pace and transition volume to judge goal-market interest.",
                "Tempo is often more useful than possession because it describes how quickly the match creates danger.",
                [
                    "High possession can be sterile. A team may pass for long stretches without creating box entries, cutbacks or shots. Tempo asks a different question: how quickly does the ball move into areas where goals can happen?",
                    "For over-goals or both-teams-to-score research, look for early vertical attacks, counterattacks after turnovers, fullbacks arriving high, and repeated entries into the penalty area. Those patterns create more useful evidence than possession share alone.",
                    "Low tempo does not automatically mean no goals, but it usually argues against forcing a pre-match over. In those games, live observation is stronger: wait to see whether the match opens after the first tactical adjustment."
                ],
                ["High tempo supports overs research.", "Low tempo favors patience and smaller stakes.", "Re-check tempo after kickoff before adding exposure."],
                9
            ),
            article(
                "Match Reading",
                "Pressure without goals",
                "Identify teams creating repeatable danger before the scoreboard changes.",
                "Pressure matters when it is built from multiple signals, not one isolated stat.",
                [
                    "A team can be dangerous before scoring. Repeated corners, blocked shots, recoveries near the opponent box and wide overloads can show that the defense is being stretched.",
                    "Do not overrate one noisy metric. Corners without shots can be empty pressure; shots from bad locations can exaggerate threat. The strongest read combines territory, volume and the quality of the final action.",
                    "Pressure is especially useful late in halves, when fatigue and substitutions change defensive structure. If the trailing side is creating repeatable entries, markets can lag behind the match state."
                ],
                ["Combine corners, shots and territory.", "Ignore pressure that never reaches dangerous zones.", "Watch fatigue before late-game decisions."],
                8
            ),
            article(
                "2026 Context",
                "Travel and climate",
                "Account for distance, heat, altitude and rest across the 2026 tournament.",
                "The 2026 format creates context that can matter as much as recent form.",
                [
                    "A team's baseline quality does not travel perfectly. Long flights, climate changes and short recovery windows can reduce pressing, concentration and late-game energy.",
                    "Heat often changes the shape of a match. Teams may press less aggressively, fullbacks may choose safer positions, and tempo can drop after an intense opening spell.",
                    "Use travel and climate as modifiers, not automatic picks. They should adjust your confidence, market choice and stake size rather than create a bet by themselves."
                ],
                ["Compare rest days before trusting form.", "Treat heat as a tempo modifier.", "Reduce stake when travel uncertainty is high."],
                8
            ),
            article(
                "Markets",
                "Home win checklist",
                "Decide when a favorite is actually worth backing.",
                "A home or stronger side needs a complete edge, not only a familiar name.",
                [
                    "The first check is whether the favorite can create pressure in repeatable ways. Possession is useful only if it leads to territory, shots, set pieces or forced defensive mistakes.",
                    "The second check is draw risk. Compact opponents, low tempo and tournament caution can make short home-win prices unattractive even when the favorite is clearly better.",
                    "The third check is lineup fit. If the favorite's best wide players, striker or set-piece takers are missing, a pre-match home-win angle can become a live-only watch."
                ],
                ["Check pressure paths, not only team quality.", "Respect draw risk in low-tempo profiles.", "Confirm lineup before using more than one unit."],
                8
            ),
            article(
                "Markets",
                "Both teams to score",
                "Find games where both attacks have realistic scoring paths.",
                "Both teams to score requires two credible routes to goal, not just one weak defense.",
                [
                    "The best BTTS spots usually include transition space for both sides. If only one team wants the ball and the other has no counter threat, the market can look tempting but remain fragile.",
                    "Set pieces can create a second scoring path. An underdog that struggles in open play may still be live if it has aerial strength, free-kick delivery or a matchup advantage on corners.",
                    "Be careful when one side can protect a lead comfortably. If the favorite can score first and then reduce tempo, BTTS may depend too heavily on late chaos."
                ],
                ["Look for two attacking routes.", "Include set-piece threat in the read.", "Avoid BTTS when one side can kill tempo after leading."],
                8
            ),
            article(
                "Bankroll",
                "Unit discipline",
                "Keep tournament risk consistent and reviewable.",
                "A unit system turns betting from emotional decisions into a repeatable process.",
                [
                    "Before saving tips, define what one unit means. The app uses units instead of currency so the user can focus on process and risk rather than chasing a money number.",
                    "Most tournament ideas should stay between one and two units. That does not mean they are weak; it means football has lineup variance, red cards, penalties and tactical surprises.",
                    "Review your settled tips by unit size. If larger stakes are not performing better than small ones, your confidence model needs adjustment."
                ],
                ["Define one unit before the first tip.", "Keep most tips small.", "Review whether higher-unit tips are actually better."],
                7
            ),
            article(
                "Review",
                "Post-match notes",
                "Make saved tips useful after the result.",
                "The result matters, but the quality of the read matters more for future decisions.",
                [
                    "A winning tip can be a bad read if the match never showed the angle you expected. A losing tip can still be useful if the process was sound and variance decided the outcome.",
                    "After the match, write what actually happened: did the tempo appear, did the pressure come from dangerous zones, did lineup news confirm the plan, and did the market price make sense?",
                    "Over time, your history should reveal patterns. Maybe you overrate favorites, underrate heat, or stake too much before lineups. That is the practical value of tracking tips locally."
                ],
                ["Separate result from process.", "Tag the reason a read failed.", "Use history to adjust future stake size."],
                8
            )
        ]
    }

    private static func article(_ category: String, _ title: String, _ summary: String, _ lesson: String, _ sections: [String], _ bullets: [String], _ minutes: Int) -> WC2026TipsKnowledgeCard {
        WC2026TipsKnowledgeCard(category: category, title: title, summary: summary, lesson: lesson, sections: sections, bullets: bullets, readMinutes: minutes, completed: false)
    }
}
