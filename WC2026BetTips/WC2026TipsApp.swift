import SwiftUI
import UIKit

@main
struct WC2026TipsApp: App {
    @UIApplicationDelegateAdaptor(WC2026TipsAppDelegate.self) private var appDelegate
    @StateObject private var store = WC2026TipsLocalStore()

    var body: some Scene {
        WindowGroup {
            WC2026TipsArrivalStage(appDelegate: appDelegate)
                .environmentObject(store)
        }
    }
}

@MainActor
final class WC2026TipsAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        WC2026TipsOrientationController.current
    }
}

@MainActor
enum WC2026TipsOrientationController {
    static var current: UIInterfaceOrientationMask = .allButUpsideDown {
        didSet { refresh() }
    }

    private static func refresh() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows {
                update(from: window.rootViewController)
            }
            if #available(iOS 16.0, *) {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: current))
            }
        }
    }

    private static func update(from controller: UIViewController?) {
        if #available(iOS 16.0, *) {
            controller?.setNeedsUpdateOfSupportedInterfaceOrientations()
        }
        if let navigation = controller as? UINavigationController { update(from: navigation.visibleViewController) }
        if let tab = controller as? UITabBarController { update(from: tab.selectedViewController) }
        if let presented = controller?.presentedViewController { update(from: presented) }
    }
}
