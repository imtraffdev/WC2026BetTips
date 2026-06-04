import SwiftUI
import UIKit

enum WC2026TipsTheme {
    static let turf = Color(red: 0.035, green: 0.105, blue: 0.075)
    static let pitch = Color(red: 0.055, green: 0.205, blue: 0.125)
    static let panel = Color(red: 0.075, green: 0.145, blue: 0.115)
    static let raised = Color(red: 0.105, green: 0.205, blue: 0.155)
    static let gold = Color(red: 0.950, green: 0.705, blue: 0.205)
    static let amber = Color(red: 1.000, green: 0.500, blue: 0.155)
    static let mint = Color(red: 0.450, green: 0.920, blue: 0.650)
    static let ink = Color(red: 0.020, green: 0.040, blue: 0.035)
    static let chalk = Color(red: 0.945, green: 0.975, blue: 0.940)
    static let muted = Color(red: 0.705, green: 0.810, blue: 0.745)
    static let line = Color.white.opacity(0.12)
    static let danger = Color(red: 0.980, green: 0.320, blue: 0.260)
}

struct WC2026TipsFieldBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [WC2026TipsTheme.turf, WC2026TipsTheme.pitch, WC2026TipsTheme.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
            Canvas { context, size in
                var field = Path()
                let step: CGFloat = 54
                stride(from: CGFloat(0), through: size.width, by: step).forEach { x in
                    field.move(to: CGPoint(x: x, y: 0))
                    field.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: CGFloat(0), through: size.height, by: step).forEach { y in
                    field.move(to: CGPoint(x: 0, y: y))
                    field.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(field, with: .color(Color.white.opacity(0.035)), lineWidth: 0.8)

                var route = Path()
                route.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.22))
                route.addCurve(to: CGPoint(x: size.width * 0.86, y: size.height * 0.74), control1: CGPoint(x: size.width * 0.30, y: size.height * 0.08), control2: CGPoint(x: size.width * 0.58, y: size.height * 0.82))
                context.stroke(route, with: .color(WC2026TipsTheme.gold.opacity(0.18)), style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [9, 13]))
            }
        }
        .ignoresSafeArea()
    }
}

struct WC2026TipsSplashView: View {
    var progress: Double
    var isOffline = false

    var body: some View {
        ZStack {
            WC2026TipsFieldBackground()
            VStack(spacing: 24) {
                Spacer()
                Image("WC2026Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 270)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: WC2026TipsTheme.gold.opacity(0.25), radius: 24, y: 12)
                WC2026TipsProgressBars(progress: progress)
                    .frame(width: 220)
                if isOffline {
                    Text("Offline mode")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(WC2026TipsTheme.muted)
                }
                Spacer()
            }
            .padding(28)
        }
    }
}

struct WC2026TipsProgressBars: View {
    var progress: Double

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<16, id: \.self) { index in
                Capsule()
                    .fill(Double(index) / 16.0 <= progress ? WC2026TipsTheme.gold : Color.white.opacity(0.14))
                    .frame(height: index.isMultiple(of: 4) ? 20 : 12)
            }
        }
    }
}

struct WC2026TipsPanelModifier: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [WC2026TipsTheme.panel.opacity(0.98), WC2026TipsTheme.raised.opacity(0.92)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: radius)
            )
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(WC2026TipsTheme.line, lineWidth: 0.8))
            .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
    }
}

extension View {
    func WC2026TipsPanel(radius: CGFloat = 14) -> some View {
        modifier(WC2026TipsPanelModifier(radius: radius))
    }

    func WC2026TipsInput() -> some View {
        padding(12)
            .background(WC2026TipsTheme.ink.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(WC2026TipsTheme.line, lineWidth: 0.8))
    }
}

enum WC2026TipsHaptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
