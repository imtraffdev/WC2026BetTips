import SwiftUI

struct WC2026TipsAppShell: View {
    @State private var selectedTab: WC2026TipsNavigationTab
    var showToast: (String) -> Void

    init(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
        _selectedTab = State(initialValue: Self.initialTabFromLaunchArguments())
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                WC2026TipsBoardScreen(showToast: showToast).tag(WC2026TipsNavigationTab.board)
                WC2026TipsTipsScreen(showToast: showToast).tag(WC2026TipsNavigationTab.tips)
                WC2026TipsPlayScreen(showToast: showToast).tag(WC2026TipsNavigationTab.play)
                WC2026TipsHistoryScreen(showToast: showToast).tag(WC2026TipsNavigationTab.history)
                WC2026TipsSettingsScreen(showToast: showToast).tag(WC2026TipsNavigationTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            WC2026TipsTabBar(selectedTab: $selectedTab)
        }
    }

    private static func initialTabFromLaunchArguments() -> WC2026TipsNavigationTab {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-WC2026TipsInitialTab"),
              arguments.indices.contains(index + 1),
              let tab = WC2026TipsNavigationTab(rawValue: arguments[index + 1]) else {
            return .board
        }
        return tab
    }
}

struct WC2026TipsBoardScreen: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    @State private var showAddMatch = false
    @State private var matchDraft = WC2026TipsMatchDraft()
    var showToast: (String) -> Void

    var body: some View {
        WC2026TipsScreenScroll {
            WC2026TipsHeader(title: "WC 2026 Bet Tips", subtitle: "My match board", detail: "Add matchups you want to study. The app turns your form, tempo and pressure inputs into local betting angles.")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(store.insights) { insight in
                    WC2026TipsInsightTile(insight: insight)
                }
            }

            Button {
                matchDraft = WC2026TipsMatchDraft()
                showAddMatch = true
            } label: {
                Label("Add Match To Analyze", systemImage: "plus.circle.fill")
            }
            .buttonStyle(WC2026TipsPrimaryButtonStyle())

            WC2026TipsSection("Your match watchlist")
            if store.upcomingMatches.isEmpty {
                WC2026TipsEmptyState(title: "No matches yet", detail: "Add a matchup, set form and tempo, then save the generated angle as a tip.")
            } else {
                ForEach(store.upcomingMatches) { match in
                    WC2026TipsMatchCard(match: match, showToast: showToast)
                }
            }
        }
        .sheet(isPresented: $showAddMatch) {
            WC2026TipsMatchDraftSheet(draft: $matchDraft) {
                store.createMatch(from: matchDraft)
                showAddMatch = false
                showToast("Match added")
            }
        }
    }
}

struct WC2026TipsTipsScreen: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    @State private var draft = WC2026TipsPickDraft()
    @State private var createdPick: WC2026TipsPick?
    @State private var selectedCategory = "All"
    var showToast: (String) -> Void

    private var categories: [String] {
        ["All"] + Array(Set(store.knowledgeCards.map(\.category))).sorted()
    }

    private var visibleCards: [WC2026TipsKnowledgeCard] {
        selectedCategory == "All" ? store.knowledgeCards : store.knowledgeCards.filter { $0.category == selectedCategory }
    }

    var body: some View {
        WC2026TipsScreenScroll {
            WC2026TipsHeader(title: "Tips Library", subtitle: "Betting knowledge base", detail: "Read practical football betting guides, then apply the checklist to matchups you add yourself.")

            WC2026TipsSection("Guide categories")
            WC2026TipsCategoryBar(categories: categories, selected: $selectedCategory)

            ForEach(visibleCards) { card in
                WC2026TipsKnowledgeRow(card: card)
            }

            VStack(alignment: .leading, spacing: 14) {
                WC2026TipsSection("Build from your match board")
                Menu {
                    ForEach(store.upcomingMatches) { match in
                        Button("\(match.home) vs \(match.away)") {
                            draft = store.draft(for: match)
                        }
                    }
                } label: {
                    HStack {
                        Text(store.upcomingMatches.isEmpty ? "Add a match on Board first" : draft.matchTitle)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(WC2026TipsTheme.chalk)
                    .WC2026TipsInput()
                }

                HStack(spacing: 10) {
                    WC2026TipsTeamMenu(title: "Home", selection: $draft.homeTeam, excludedTeamName: draft.awayTeam.name) {
                        draft.setTeams(home: draft.homeTeam, away: draft.awayTeam)
                    }
                    WC2026TipsTeamMenu(title: "Away", selection: $draft.awayTeam, excludedTeamName: draft.homeTeam.name) {
                        draft.setTeams(home: draft.homeTeam, away: draft.awayTeam)
                    }
                }

                Picker("Pick type", selection: $draft.type) {
                    ForEach(WC2026TipsPickType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)

                Picker("Risk", selection: $draft.risk) {
                    ForEach(WC2026TipsRiskLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading) {
                    Text("Confidence \(draft.confidence)%")
                        .font(.system(size: 13, weight: .bold))
                    Slider(value: Binding(get: { Double(draft.confidence) }, set: { draft.confidence = Int($0) }), in: 35...92, step: 1)
                }

                Stepper("Stake units: \(draft.stakeUnits)", value: $draft.stakeUnits, in: 1...10)

                TextEditor(text: $draft.note)
                    .frame(minHeight: 92)
                    .WC2026TipsInput()

                Button {
                    WC2026TipsHaptics.success()
                    draft.matchTitle = "\(draft.homeTeam.name) vs \(draft.awayTeam.name)"
                    createdPick = store.createPick(from: draft)
                    draft = WC2026TipsPickDraft(risk: store.profile.defaultRisk)
                    showToast("Tip saved")
                } label: {
                    Label("Save Tip", systemImage: "plus.circle.fill")
                }
                .buttonStyle(WC2026TipsPrimaryButtonStyle())
                .disabled(store.upcomingMatches.isEmpty || !draft.hasValidTeams)
            }
            .padding(16)
            .WC2026TipsPanel()

            if let createdPick {
                WC2026TipsPickCard(pick: createdPick, allowActions: false)
            }
        }
    }
}

struct WC2026TipsPlayScreen: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    @State private var homeTeam = WC2026TipsTeam.named("Canada")
    @State private var awayTeam = WC2026TipsTeam.named("Morocco")
    @State private var tempo = 64.0
    @State private var risk = WC2026TipsRiskLevel.medium
    @State private var latestSimulation: WC2026TipsSimulationResult?
    @State private var ballX = 0.5
    @State private var targetX = Double.random(in: 0.16...0.84)
    @State private var score = 0
    @State private var timeLeft = 20
    @State private var running = false
    @State private var timer: Timer?
    var showToast: (String) -> Void

    var body: some View {
        WC2026TipsScreenScroll {
            WC2026TipsHeader(title: "Simulator", subtitle: "Football playground", detail: "Run a lightweight match scenario, then play a timing challenge that saves your best local score.")

            VStack(alignment: .leading, spacing: 14) {
                WC2026TipsSection("Match simulation")
                HStack(spacing: 10) {
                    WC2026TipsTeamMenu(title: "Home", selection: $homeTeam, excludedTeamName: awayTeam.name)
                    WC2026TipsTeamMenu(title: "Away", selection: $awayTeam, excludedTeamName: homeTeam.name)
                }
                Picker("Risk", selection: $risk) {
                    ForEach(WC2026TipsRiskLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                VStack(alignment: .leading) {
                    Text("Tempo \(Int(tempo))/100")
                        .font(.system(size: 13, weight: .bold))
                    Slider(value: $tempo, in: 20...100, step: 1)
                }
                Button {
                    latestSimulation = store.simulate(home: homeTeam.name, away: awayTeam.name, tempo: Int(tempo), risk: risk)
                    showToast("Simulation saved")
                } label: {
                    Label("Run Simulation", systemImage: "play.fill")
                }
                .buttonStyle(WC2026TipsPrimaryButtonStyle())
                .disabled(homeTeam.name == awayTeam.name)
            }
            .padding(16)
            .WC2026TipsPanel()

            if let latestSimulation {
                WC2026TipsSimulationCard(result: latestSimulation)
            }

            VStack(alignment: .leading, spacing: 14) {
                WC2026TipsSection("Penalty timing")
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(WC2026TipsTheme.pitch)
                        Rectangle()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 2)
                            .offset(x: proxy.size.width * 0.5)
                        RoundedRectangle(cornerRadius: 7)
                            .fill(WC2026TipsTheme.gold.opacity(0.30))
                            .frame(width: 42, height: 88)
                            .offset(x: proxy.size.width * targetX - 21)
                        Circle()
                            .fill(WC2026TipsTheme.chalk)
                            .frame(width: 28, height: 28)
                            .overlay(Circle().stroke(WC2026TipsTheme.ink, lineWidth: 2))
                            .offset(x: proxy.size.width * ballX - 14)
                    }
                }
                .frame(height: 132)

                HStack {
                    WC2026TipsMiniStat(title: "Score", value: "\(score)")
                    WC2026TipsMiniStat(title: "Time", value: "\(timeLeft)s")
                    WC2026TipsMiniStat(title: "Best", value: "\(store.arcadeRecord.bestScore)")
                }

                HStack(spacing: 12) {
                    Button(running ? "Shoot" : "Start") {
                        running ? shoot() : startGame()
                    }
                    .buttonStyle(WC2026TipsPrimaryButtonStyle())
                    Button("Stop") { finishGame() }
                        .buttonStyle(WC2026TipsSecondaryButtonStyle())
                        .disabled(!running)
                }
            }
            .padding(16)
            .WC2026TipsPanel()
        }
        .onDisappear { timer?.invalidate() }
    }

    private func startGame() {
        WC2026TipsHaptics.tap()
        score = 0
        timeLeft = 20
        running = true
        targetX = Double.random(in: 0.16...0.84)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            ballX = 0.5 + sin(Date().timeIntervalSince1970 * 4.6) * 0.42
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { countdown in
            guard running else {
                countdown.invalidate()
                return
            }
            timeLeft -= 1
            if timeLeft <= 0 {
                countdown.invalidate()
                finishGame()
            }
        }
    }

    private func shoot() {
        let distance = abs(ballX - targetX)
        if distance < 0.055 {
            score += 5
            WC2026TipsHaptics.success()
        } else if distance < 0.11 {
            score += 2
            WC2026TipsHaptics.tap()
        } else {
            score = max(0, score - 1)
            WC2026TipsHaptics.warning()
        }
        targetX = Double.random(in: 0.16...0.84)
    }

    private func finishGame() {
        guard running else { return }
        running = false
        timer?.invalidate()
        store.recordArcade(score: score)
        showToast("Score recorded")
    }
}

struct WC2026TipsHistoryScreen: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    var showToast: (String) -> Void

    var body: some View {
        WC2026TipsScreenScroll {
            WC2026TipsHeader(title: "History", subtitle: "Local record", detail: "Review active tips, settle outcomes and revisit saved simulations.")

            WC2026TipsSection("Active tips")
            if store.activePicks.isEmpty {
                WC2026TipsEmptyState(title: "No active tips", detail: "Create a pick from the Tips tab or match board.")
            } else {
                ForEach(store.activePicks) { pick in
                    WC2026TipsPickCard(pick: pick, allowActions: true)
                }
            }

            WC2026TipsSection("Settled")
            if store.settledPicks.isEmpty {
                WC2026TipsEmptyState(title: "No settled tips", detail: "Mark active picks as won, lost or void when results are known.")
            } else {
                ForEach(store.settledPicks) { pick in
                    WC2026TipsPickCard(pick: pick, allowActions: false)
                }
            }

            WC2026TipsSection("Simulations")
            if store.simulations.isEmpty {
                WC2026TipsEmptyState(title: "No simulations yet", detail: "Run one from the Play tab.")
            } else {
                ForEach(store.simulations.prefix(8)) { result in
                    WC2026TipsSimulationCard(result: result)
                }
            }
        }
    }
}

struct WC2026TipsSettingsScreen: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    @State private var region = ""
    @State private var bankroll = 50
    @State private var risk = WC2026TipsRiskLevel.medium
    @State private var showHighRisk = true
    @State private var confirmReset = false
    var showToast: (String) -> Void

    var body: some View {
        WC2026TipsScreenScroll {
            WC2026TipsHeader(title: "Settings", subtitle: "Local profile", detail: "Adjust your unit plan and reset local match, tip and game data when needed.")

            VStack(alignment: .leading, spacing: 14) {
                WC2026TipsSection("Preferences")
                TextField("Region focus", text: $region)
                    .WC2026TipsInput()
                Stepper("Bankroll units: \(bankroll)", value: $bankroll, in: 10...300)
                Picker("Default risk", selection: $risk) {
                    ForEach(WC2026TipsRiskLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Show high-risk angles", isOn: $showHighRisk)
                Button {
                    store.updateProfile(region: region, bankroll: bankroll, risk: risk, showHighRisk: showHighRisk)
                    showToast("Settings saved")
                } label: {
                    Label("Save Settings", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(WC2026TipsPrimaryButtonStyle())
            }
            .padding(16)
            .WC2026TipsPanel()

            VStack(alignment: .leading, spacing: 14) {
                WC2026TipsSection("Data")
                Text("Stored locally: \(store.matches.count) matches, \(store.picks.count) tips, \(store.simulations.count) simulations, \(store.arcadeRecord.sessions) game sessions.")
                    .font(.system(size: 14))
                    .foregroundStyle(WC2026TipsTheme.muted)
                Button(role: .destructive) { confirmReset = true } label: {
                    Label("Reset Local Data", systemImage: "trash.fill")
                }
                .buttonStyle(WC2026TipsDestructiveButtonStyle())
            }
            .padding(16)
            .WC2026TipsPanel()
        }
        .onAppear {
            region = store.profile.regionFocus
            bankroll = store.profile.bankrollUnits
            risk = store.profile.defaultRisk
            showHighRisk = store.profile.showHighRiskAngles
        }
        .alert("Reset local data?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetLocalData()
                showToast("Local data reset")
            }
        } message: {
            Text("This restores starter matches and clears your local tips, simulations and game record.")
        }
    }
}

struct WC2026TipsMatchCard: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    let match: WC2026TipsMatch
    var showToast: (String) -> Void
    @State private var showDraft = false
    @State private var draft = WC2026TipsPickDraft()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(WC2026TipsTeam.named(match.home).flag) \(match.home) vs \(WC2026TipsTeam.named(match.away).flag) \(match.away)")
                        .font(.system(size: 19, weight: .black))
                    Text("\(match.country) • \(match.date.WC2026TipsStamp)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WC2026TipsTheme.gold)
                }
                Spacer()
            }
            Text("Generated angle")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(WC2026TipsTheme.gold)
            Text(match.keyAngle)
                .font(.system(size: 14))
                .foregroundStyle(WC2026TipsTheme.muted)
            HStack {
                WC2026TipsMiniStat(title: "Home form", value: "\(match.homeForm)")
                WC2026TipsMiniStat(title: "Away form", value: "\(match.awayForm)")
                WC2026TipsMiniStat(title: "Tempo", value: "\(match.attackTempo)")
            }
            Button {
                draft = store.draft(for: match)
                showDraft = true
            } label: {
                Label("Create Tip", systemImage: "plus.circle")
            }
            .buttonStyle(WC2026TipsSecondaryButtonStyle())
            Button(role: .destructive) {
                store.deleteMatch(match)
                showToast("Match deleted")
            } label: {
                Label("Delete Match", systemImage: "trash.fill")
            }
            .buttonStyle(WC2026TipsDestructiveButtonStyle())
        }
        .padding(16)
        .WC2026TipsPanel()
        .sheet(isPresented: $showDraft) {
            WC2026TipsDraftSheet(draft: $draft) {
                store.createPick(from: draft)
                showDraft = false
                showToast("Tip saved")
            }
        }
    }
}

struct WC2026TipsDraftSheet: View {
    @Binding var draft: WC2026TipsPickDraft
    var save: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Teams") {
                    WC2026TipsTeamMenu(title: "Home", selection: $draft.homeTeam, excludedTeamName: draft.awayTeam.name) {
                        draft.setTeams(home: draft.homeTeam, away: draft.awayTeam)
                    }
                    WC2026TipsTeamMenu(title: "Away", selection: $draft.awayTeam, excludedTeamName: draft.homeTeam.name) {
                        draft.setTeams(home: draft.homeTeam, away: draft.awayTeam)
                    }
                }
                Picker("Pick", selection: $draft.type) {
                    ForEach(WC2026TipsPickType.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Risk", selection: $draft.risk) {
                    ForEach(WC2026TipsRiskLevel.allCases) { Text($0.rawValue).tag($0) }
                }
                Slider(value: Binding(get: { Double(draft.confidence) }, set: { draft.confidence = Int($0) }), in: 35...92, step: 1) {
                    Text("Confidence")
                } minimumValueLabel: {
                    Text("35")
                } maximumValueLabel: {
                    Text("\(draft.confidence)%")
                }
                Stepper("Stake units: \(draft.stakeUnits)", value: $draft.stakeUnits, in: 1...10)
                TextEditor(text: $draft.note)
                    .frame(minHeight: 120)
            }
            .navigationTitle("New Tip")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.matchTitle = "\(draft.homeTeam.name) vs \(draft.awayTeam.name)"
                        save()
                    }
                    .disabled(!draft.hasValidTeams)
                }
            }
        }
    }
}

struct WC2026TipsMatchDraftSheet: View {
    @Binding var draft: WC2026TipsMatchDraft
    var save: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Teams") {
                    WC2026TipsTeamMenu(title: "Home", selection: $draft.homeTeam, excludedTeamName: draft.awayTeam.name) {
                        draft.setTeams(home: draft.homeTeam, away: draft.awayTeam)
                    }
                    WC2026TipsTeamMenu(title: "Away", selection: $draft.awayTeam, excludedTeamName: draft.homeTeam.name) {
                        draft.setTeams(home: draft.homeTeam, away: draft.awayTeam)
                    }
                }
                Section("Match context") {
                    DatePicker("Date", selection: $draft.date, displayedComponents: [.date, .hourAndMinute])
                    TextField("Venue or note", text: $draft.venue)
                }
                Section("Analyzer inputs") {
                    Stepper("Home form: \(draft.homeForm)", value: $draft.homeForm, in: 20...95)
                    Stepper("Away form: \(draft.awayForm)", value: $draft.awayForm, in: 20...95)
                    Stepper("Tempo: \(draft.attackTempo)", value: $draft.attackTempo, in: 20...100)
                    Stepper("Pressure: \(draft.pressureIndex)", value: $draft.pressureIndex, in: 20...100)
                }
            }
            .navigationTitle("Add Match")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.hasValidTeams)
                }
            }
        }
    }
}

struct WC2026TipsPickCard: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    let pick: WC2026TipsPick
    var allowActions: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pick.matchTitle)
                        .font(.system(size: 17, weight: .black))
                    Text("\(pick.type.rawValue) • \(pick.risk.rawValue) risk")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(WC2026TipsTheme.gold)
                }
                Spacer()
                WC2026TipsPill(text: pick.status.rawValue, color: pick.status == .won ? WC2026TipsTheme.mint : WC2026TipsTheme.gold)
            }
            Text(pick.note)
                .font(.system(size: 14))
                .foregroundStyle(WC2026TipsTheme.muted)
            HStack {
                WC2026TipsMiniStat(title: "Confidence", value: "\(pick.confidence)%")
                WC2026TipsMiniStat(title: "Units", value: "\(pick.stakeUnits)")
                WC2026TipsMiniStat(title: "Created", value: pick.createdAt.formatted(date: .numeric, time: .omitted))
            }
            if allowActions {
                HStack(spacing: 10) {
                    Button("Won") { store.updatePick(pick, status: .won) }
                    Button("Lost") { store.updatePick(pick, status: .lost) }
                    Button("Void") { store.updatePick(pick, status: .voided) }
                }
                .buttonStyle(.bordered)
                .tint(WC2026TipsTheme.gold)
            }
            Button(role: .destructive) {
                store.deletePick(pick)
            } label: {
                Label("Delete Tip", systemImage: "trash.fill")
            }
            .buttonStyle(WC2026TipsDestructiveButtonStyle())
        }
        .padding(16)
        .WC2026TipsPanel()
    }
}

struct WC2026TipsKnowledgeRow: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    let card: WC2026TipsKnowledgeCard
    @State private var expanded = false

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) { expanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: expanded ? "book.fill" : "book")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(WC2026TipsTheme.gold)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            WC2026TipsPill(text: card.category, color: WC2026TipsTheme.gold)
                            WC2026TipsPill(text: "\(card.readMinutes) min", color: WC2026TipsTheme.mint)
                        }
                        Text(card.title)
                            .font(.system(size: 16, weight: .black))
                        Text(card.summary)
                            .font(.system(size: 13))
                            .foregroundStyle(WC2026TipsTheme.muted)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(WC2026TipsTheme.gold)
                }
                if expanded {
                    Text(card.lesson)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(WC2026TipsTheme.chalk.opacity(0.86))
                    ForEach(card.sections, id: \.self) { section in
                        Text(section)
                            .font(.system(size: 14))
                            .foregroundStyle(WC2026TipsTheme.muted)
                            .lineSpacing(3)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(card.bullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundStyle(WC2026TipsTheme.mint)
                                    .padding(.top, 2)
                                Text(bullet)
                                    .font(.system(size: 13))
                                    .foregroundStyle(WC2026TipsTheme.muted)
                            }
                        }
                    }
                    Button {
                        store.toggleKnowledge(card)
                    } label: {
                        Label(card.completed ? "Marked Read" : "Mark As Read", systemImage: card.completed ? "checkmark.circle.fill" : "circle")
                    }
                    .buttonStyle(WC2026TipsSecondaryButtonStyle())
                }
            }
            .padding(14)
            .WC2026TipsPanel()
        }
        .buttonStyle(.plain)
    }
}

struct WC2026TipsCategoryBar: View {
    var categories: [String]
    @Binding var selected: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selected = category
                    } label: {
                        Text(category)
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(selected == category ? WC2026TipsTheme.ink : WC2026TipsTheme.chalk)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(selected == category ? WC2026TipsTheme.gold : WC2026TipsTheme.raised, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct WC2026TipsSimulationCard: View {
    @EnvironmentObject private var store: WC2026TipsLocalStore
    let result: WC2026TipsSimulationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(result.matchup)
                    .font(.system(size: 17, weight: .black))
                Spacer()
                Text(result.score)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(WC2026TipsTheme.gold)
            }
            Text(result.momentum)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(WC2026TipsTheme.muted)
            Text(result.suggestedAngle)
                .font(.system(size: 14))
            Button(role: .destructive) {
                store.deleteSimulation(result)
            } label: {
                Label("Delete Simulation", systemImage: "trash.fill")
            }
            .buttonStyle(WC2026TipsDestructiveButtonStyle())
        }
        .padding(16)
        .WC2026TipsPanel()
    }
}

struct WC2026TipsScreenScroll<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                content
            }
            .padding(18)
            .padding(.bottom, 8)
        }
    }
}

struct WC2026TipsHeader: View {
    var title: String
    var subtitle: String
    var detail: String

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("WC2026Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 25, weight: .black))
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(subtitle.uppercased())
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(WC2026TipsTheme.gold)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(WC2026TipsTheme.muted)
                    .lineSpacing(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .WC2026TipsPanel()
    }
}

struct WC2026TipsSection: View {
    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .black))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WC2026TipsInsightTile: View {
    let insight: WC2026TipsInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: insight.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(WC2026TipsTheme.gold)
            Text(insight.value)
                .font(.system(size: 26, weight: .black))
            Text(insight.title)
                .font(.system(size: 12, weight: .black))
            Text(insight.detail)
                .font(.system(size: 11))
                .foregroundStyle(WC2026TipsTheme.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .WC2026TipsPanel()
    }
}

struct WC2026TipsTeamMenu: View {
    var title: String
    @Binding var selection: WC2026TipsTeam
    var excludedTeamName: String?
    var onChange: () -> Void = {}

    var body: some View {
        Menu {
            ForEach(WC2026TipsTeam.catalog) { team in
                Button {
                    selection = team
                    onChange()
                } label: {
                    Text("\(team.flag) \(team.name)")
                }
                .disabled(team.name == excludedTeamName)
            }
        } label: {
            HStack(spacing: 10) {
                Text(selection.flag)
                    .font(.system(size: 34))
                    .frame(width: 42, height: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(WC2026TipsTheme.gold)
                    Text(selection.name)
                        .font(.system(size: 14, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                    Text(selection.region)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(WC2026TipsTheme.muted)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(WC2026TipsTheme.gold)
            }
            .foregroundStyle(WC2026TipsTheme.chalk)
            .padding(12)
            .background(WC2026TipsTheme.ink.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WC2026TipsTheme.line, lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }
}

struct WC2026TipsMiniStat: View {
    var title: String
    var value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .black))
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(WC2026TipsTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(WC2026TipsTheme.ink.opacity(0.32), in: RoundedRectangle(cornerRadius: 10))
    }
}

struct WC2026TipsPill: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
    }
}

struct WC2026TipsEmptyState: View {
    var title: String
    var detail: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 17, weight: .black))
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(WC2026TipsTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .WC2026TipsPanel()
    }
}

struct WC2026TipsTabBar: View {
    @Binding var selectedTab: WC2026TipsNavigationTab

    var body: some View {
        HStack(spacing: 7) {
            ForEach(WC2026TipsNavigationTab.allCases, id: \.self) { tab in
                Button {
                    WC2026TipsHaptics.tap()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18, weight: .bold))
                        Text(tab.rawValue)
                            .font(.system(size: 9, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                    }
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .foregroundStyle(selectedTab == tab ? WC2026TipsTheme.ink : WC2026TipsTheme.chalk.opacity(0.82))
                    .background(selectedTab == tab ? WC2026TipsTheme.gold : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(WC2026TipsTheme.line, lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
    }
}

struct WC2026TipsPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(WC2026TipsTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? WC2026TipsTheme.amber : WC2026TipsTheme.gold, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WC2026TipsSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(WC2026TipsTheme.chalk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? WC2026TipsTheme.pitch : WC2026TipsTheme.raised, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(WC2026TipsTheme.line, lineWidth: 0.8))
    }
}

struct WC2026TipsDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(WC2026TipsTheme.chalk)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(WC2026TipsTheme.danger.opacity(configuration.isPressed ? 0.70 : 0.92), in: RoundedRectangle(cornerRadius: 12))
    }
}
