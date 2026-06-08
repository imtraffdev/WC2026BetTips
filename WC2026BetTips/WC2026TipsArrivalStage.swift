import SwiftUI

struct WC2026TipsArrivalStage: View {
    @State private var progress = 0.0
    @State private var destination: WC2026TipsLaunchDestination?
    @State private var didStart = false
    @State private var toast: String?
    let appDelegate: WC2026TipsAppDelegate

    var body: some View {
        ZStack {
            WC2026TipsFieldBackground()

            if let destination {
                switch destination {
                case .native:
                    WC2026TipsAppShell(showToast: showToast)
                        .transition(.opacity)
                case .web(let url):
                    WC2026TipsOnlinePassage(url: url) {
                        withAnimation { self.destination = .native }
                    }
                    .transition(.opacity)
                case .offline:
                    WC2026TipsAppShell(showToast: showToast)
                        .overlay(alignment: .top) {
                            Text("Offline board")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(WC2026TipsTheme.ink)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(WC2026TipsTheme.gold, in: Capsule())
                                .padding(.top, 12)
                        }
                        .transition(.opacity)
                }
            } else {
                WC2026TipsSplashView(progress: progress)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: destination)
        .foregroundStyle(WC2026TipsTheme.chalk)
        .tint(WC2026TipsTheme.gold)
        .preferredColorScheme(.dark)
        .task { await runGate() }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(WC2026TipsTheme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(WC2026TipsTheme.gold, in: Capsule())
                    .shadow(color: .black.opacity(0.24), radius: 16, y: 8)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func runGate() async {
        guard !didStart else { return }
        didStart = true
        if ProcessInfo.processInfo.arguments.contains("-WC2026TipsForceNativeScreenshots") {
            await runSplash()
            withAnimation { destination = .native }
            return
        }
        async let splash: Void = runSplash()
        async let gate = WC2026TipsSignalGate.resolveDestination(checkURL: WC2026TipsSignalGate.checkURL)
        let result = await gate
        _ = await splash
        withAnimation { destination = result }
    }

    private func runSplash() async {
        for step in 0...24 {
            await MainActor.run { progress = Double(step) / 24.0 }
            try? await Task.sleep(nanoseconds: 58_000_000)
        }
        try? await Task.sleep(nanoseconds: 220_000_000)
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation {
                    if toast == message { toast = nil }
                }
            }
        }
    }
}
