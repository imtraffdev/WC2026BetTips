import AppTrackingTransparency
import AppsFlyerLib
import Foundation

@MainActor
final class WC2026TipsAppsFlyerAttribution: ObservableObject {
    static let shared = WC2026TipsAppsFlyerAttribution()
    static let appsFlyerDevKey = "BYbL7iQyGkW9x2ZSzbyhh7"
    static let appleAppID = "6776691072"

    private enum Keys {
        static let appsFlyerID = "WC2026Tips_apps_flyer_id"
        static let campaign = "WC2026Tips_apps_flyer_campaign"
        static let subParams = "WC2026Tips_apps_flyer_sub_params"
    }

    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var didStart = false
    private var didResolveConversion = false

    @Published private(set) var appsFlyerID: String = UserDefaults.standard.string(forKey: Keys.appsFlyerID) ?? ""
    @Published private(set) var campaign: String = UserDefaults.standard.string(forKey: Keys.campaign) ?? ""
    @Published private(set) var subParams: [String: String] = WC2026TipsAppsFlyerAttribution.restoreSubParams()

    private init() {}

    func requestTrackingAndStartIfNeeded(appDelegate: AppsFlyerLibDelegate, timeoutSeconds: TimeInterval = 5) async {
        guard !didStart else {
            await waitForConversion(timeoutSeconds: timeoutSeconds)
            return
        }
        didStart = true
        if #available(iOS 14, *) {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        configureAppsFlyer(appDelegate: appDelegate)
        await waitForConversion(timeoutSeconds: timeoutSeconds)
    }

    func attributedURL(from baseURL: URL) -> URL {
        var queryItems: [URLQueryItem] = []
        if !appsFlyerID.isEmpty {
            queryItems.append(URLQueryItem(name: "afid", value: appsFlyerID))
        }
        for key in subParams.keys.sorted(by: Self.sortSubKeys) {
            queryItems.append(URLQueryItem(name: key, value: subParams[key]))
        }
        guard !queryItems.isEmpty, var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return baseURL }
        var existingItems = components.queryItems ?? []
        let existingNames = Set(existingItems.map(\.name))
        existingItems.append(contentsOf: queryItems.filter { !existingNames.contains($0.name) })
        components.queryItems = existingItems
        return components.url ?? baseURL
    }

    func handleConversionDataSuccess(_ data: [AnyHashable: Any]) {
        let conversionCampaign = Self.campaign(from: data)
        if !conversionCampaign.isEmpty {
            campaign = conversionCampaign
            subParams = Self.subParams(from: conversionCampaign)
            UserDefaults.standard.set(campaign, forKey: Keys.campaign)
            persistSubParams(subParams)
        }
        let currentID = AppsFlyerLib.shared().getAppsFlyerUID()
        if !currentID.isEmpty {
            appsFlyerID = currentID
            UserDefaults.standard.set(currentID, forKey: Keys.appsFlyerID)
        }
        didResolveConversion = true
        resumeContinuations()
    }

    func handleConversionDataFail(_ error: Error) {
        let currentID = AppsFlyerLib.shared().getAppsFlyerUID()
        if !currentID.isEmpty {
            appsFlyerID = currentID
            UserDefaults.standard.set(currentID, forKey: Keys.appsFlyerID)
        }
        didResolveConversion = true
        resumeContinuations()
    }

    private func configureAppsFlyer(appDelegate: AppsFlyerLibDelegate) {
        AppsFlyerLib.shared().appsFlyerDevKey = Self.appsFlyerDevKey
        AppsFlyerLib.shared().appleAppID = Self.appleAppID
        AppsFlyerLib.shared().delegate = appDelegate
        AppsFlyerLib.shared().isDebug = false
        AppsFlyerLib.shared().start()
        let currentID = AppsFlyerLib.shared().getAppsFlyerUID()
        if !currentID.isEmpty {
            appsFlyerID = currentID
            UserDefaults.standard.set(currentID, forKey: Keys.appsFlyerID)
        }
    }

    private func waitForConversion(timeoutSeconds: TimeInterval) async {
        guard !didResolveConversion else { return }
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                resumeContinuations()
            }
        }
    }

    private func resumeContinuations() {
        let pending = continuations
        continuations.removeAll()
        pending.forEach { $0.resume() }
    }

    private static func campaign(from data: [AnyHashable: Any]) -> String {
        for key in ["campaign", "c", "af_campaign"] {
            if let value = data[key] as? String, !value.WC2026TipsTrimmed.isEmpty { return value }
        }
        return ""
    }

    private static func subParams(from campaign: String) -> [String: String] {
        let parts = campaign.split(separator: "_", omittingEmptySubsequences: true).map(String.init).filter { !$0.WC2026TipsTrimmed.isEmpty }
        return Dictionary(uniqueKeysWithValues: parts.enumerated().map { ("sub\($0.offset + 1)", $0.element) })
    }

    private static func restoreSubParams() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: Keys.subParams),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else { return [:] }
        return decoded
    }

    private func persistSubParams(_ params: [String: String]) {
        if let data = try? JSONEncoder().encode(params) {
            UserDefaults.standard.set(data, forKey: Keys.subParams)
        }
    }

    private static func sortSubKeys(_ lhs: String, _ rhs: String) -> Bool {
        (Int(lhs.dropFirst(3)) ?? 0) < (Int(rhs.dropFirst(3)) ?? 0)
    }
}

@MainActor
final class WC2026TipsAppsFlyerConversionDelegate: NSObject, @preconcurrency AppsFlyerLibDelegate {
    static let shared = WC2026TipsAppsFlyerConversionDelegate()

    func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        WC2026TipsAppsFlyerAttribution.shared.handleConversionDataSuccess(conversionInfo)
    }

    func onConversionDataFail(_ error: Error) {
        WC2026TipsAppsFlyerAttribution.shared.handleConversionDataFail(error)
    }

    func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        WC2026TipsAppsFlyerAttribution.shared.handleConversionDataSuccess(attributionData)
    }

    func onAppOpenAttributionFailure(_ error: Error) {
        WC2026TipsAppsFlyerAttribution.shared.handleConversionDataFail(error)
    }
}

@available(iOS 14, *)
private extension ATTrackingManager {
    static func requestTrackingAuthorization() async -> ATTrackingManager.AuthorizationStatus {
        await withCheckedContinuation { continuation in
            requestTrackingAuthorization { status in continuation.resume(returning: status) }
        }
    }
}
