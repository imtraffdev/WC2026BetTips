import Foundation
import Network
import UIKit
import WebKit

enum WC2026TipsSignalGate {
    static let checkURL = URL(string: "https://wc2026bettips.shop/server")!
    private static let timeoutSeconds: TimeInterval = 6

    static func resolveDestination(checkURL: URL = checkURL) async -> WC2026TipsLaunchDestination {
        guard await hasNetworkConnection() else { return .offline }
        do {
            let response = try await fetchFinalResponse(checkURL: checkURL)
            await syncCookies(from: response)
            return (400...599).contains(response.statusCode) ? .native : .web(checkURL)
        } catch {
            let online = await hasNetworkConnection()
            if isOffline(error) || (isTimeout(error) && !online) { return .offline }
            return .native
        }
    }

    private static func fetchFinalResponse(checkURL: URL) async throws -> HTTPURLResponse {
        try await withThrowingTaskGroup(of: HTTPURLResponse.self) { group in
            group.addTask {
                var request = URLRequest(url: checkURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeoutSeconds)
                request.httpMethod = "GET"
                request.httpShouldHandleCookies = true
                request.setValue(nativeUserAgent, forHTTPHeaderField: "User-Agent")
                let session = URLSession(configuration: sessionConfiguration, delegate: RedirectDelegate(), delegateQueue: nil)
                let (_, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                return httpResponse
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            guard let response = try await group.next() else { throw URLError(.unknown) }
            group.cancelAll()
            return response
        }
    }

    private static var sessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeoutSeconds
        configuration.timeoutIntervalForResource = timeoutSeconds
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.httpCookieStorage = .shared
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.waitsForConnectivity = false
        configuration.httpAdditionalHeaders = [
            "User-Agent": nativeUserAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": Locale.preferredLanguages.prefix(3).joined(separator: ",")
        ]
        return configuration
    }

    private static func hasNetworkConnection() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: "WC2026Tips.SignalGate.NetworkPath")
            let state = ContinuationState()
            monitor.pathUpdateHandler = { path in
                if state.resumeOnce() {
                    monitor.cancel()
                    continuation.resume(returning: path.status == .satisfied)
                }
            }
            monitor.start(queue: queue)
            queue.asyncAfter(deadline: .now() + 1.5) {
                if state.resumeOnce() {
                    monitor.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private static func isOffline(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        switch URLError.Code(rawValue: nsError.code) {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private static func isTimeout(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && URLError.Code(rawValue: nsError.code) == .timedOut
    }

    private static var nativeUserAgent: String {
        let appName = Bundle.main.bundleIdentifier ?? "WC2026Tips"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let networkVersion = Bundle(identifier: "com.apple.CFNetwork")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1490.0.4"
        return "\(appName)/\(appVersion) CFNetwork/\(networkVersion) Darwin/\(darwinVersion)"
    }

    private static var darwinVersion: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return Mirror(reflecting: systemInfo.release).children.compactMap { child -> String? in
            guard let value = child.value as? Int8, value != 0 else { return nil }
            return String(UnicodeScalar(UInt8(value)))
        }.joined()
    }

    private static func syncCookies(from response: HTTPURLResponse) async {
        let responseURL = response.url ?? checkURL
        let headerCookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as? [String: String] ?? [:], for: responseURL)
        let storedCookies = HTTPCookieStorage.shared.cookies(for: responseURL) ?? []
        let cookies = Array(Dictionary(grouping: headerCookies + storedCookies, by: \.name).compactMap { $0.value.last })
        let cookieStore = await WKWebsiteDataStore.default().httpCookieStore
        for cookie in cookies {
            await cookieStore.setCookieAsync(cookie)
        }
    }

    final class RedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            var redirected = request
            redirected.setValue(nativeUserAgent, forHTTPHeaderField: "User-Agent")
            redirected.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
            redirected.setValue(Locale.preferredLanguages.prefix(3).joined(separator: ","), forHTTPHeaderField: "Accept-Language")
            completionHandler(redirected)
        }
    }

    private final class ContinuationState: @unchecked Sendable {
        private let lock = NSLock()
        private var didResume = false

        func resumeOnce() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard !didResume else { return false }
            didResume = true
            return true
        }
    }
}

private extension WKHTTPCookieStore {
    func setCookieAsync(_ cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            setCookie(cookie) { continuation.resume() }
        }
    }
}
