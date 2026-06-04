import SwiftUI
import WebKit

struct WC2026TipsOnlinePassage: View {
    let url: URL
    var fallbackToNative: () -> Void
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var webView: WKWebView?

    var body: some View {
        VStack(spacing: 0) {
            WC2026TipsWebCanvas(url: url, webView: $webView, canGoBack: $canGoBack, canGoForward: $canGoForward, fallbackToNative: fallbackToNative)
                .ignoresSafeArea(edges: .top)
            HStack(spacing: 12) {
                Button { webView?.goBack() } label: { Image(systemName: "chevron.left") }
                    .disabled(!canGoBack)
                Button { webView?.goForward() } label: { Image(systemName: "chevron.right") }
                    .disabled(!canGoForward)
                Spacer()
                Button { webView?.reload() } label: { Image(systemName: "arrow.clockwise") }
                Button(action: fallbackToNative) {
                    Image(systemName: "square.grid.2x2")
                }
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(WC2026TipsTheme.chalk)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(WC2026TipsTheme.ink)
        }
        .onAppear { WC2026TipsOrientationController.current = .allButUpsideDown }
        .onDisappear { WC2026TipsOrientationController.current = .allButUpsideDown }
    }
}

struct WC2026TipsWebCanvas: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    var fallbackToNative: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.websiteDataStore = .default()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        view.load(URLRequest(url: url))
        DispatchQueue.main.async { webView = view }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        canGoBack = uiView.canGoBack
        canGoForward = uiView.canGoForward
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let parent: WC2026TipsWebCanvas

        init(parent: WC2026TipsWebCanvas) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.fallbackToNative()
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if let response = navigationResponse.response as? HTTPURLResponse, (400...599).contains(response.statusCode) {
                decisionHandler(.cancel)
                parent.fallbackToNative()
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let scheme = navigationAction.request.url?.scheme?.lowercased(),
               !["http", "https", "about"].contains(scheme) {
                UIApplication.shared.open(navigationAction.request.url!)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            presentAlert(title: nil, message: message, actions: [UIAlertAction(title: "OK", style: .default) { _ in completionHandler() }])
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            presentAlert(title: nil, message: message, actions: [
                UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) },
                UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) }
            ])
        }

        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { $0.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(alert.textFields?.first?.text) })
            topController()?.present(alert, animated: true)
        }

        private func presentAlert(title: String?, message: String, actions: [UIAlertAction]) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            actions.forEach(alert.addAction)
            topController()?.present(alert, animated: true)
        }

        private func topController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let root = scenes.first?.windows.first(where: \.isKeyWindow)?.rootViewController
            var top = root
            while let presented = top?.presentedViewController { top = presented }
            return top
        }
    }
}
