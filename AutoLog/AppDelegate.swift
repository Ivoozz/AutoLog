import UIKit
import CarPlay

@objc(AppDelegate)
public class AppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return true
    }

    public func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let role = connectingSceneSession.role.rawValue

        if role == "CPTemplateApplicationSceneSessionRoleApplication" || role.contains("CPTemplateApplicationScene") {
            let sceneConfig = UISceneConfiguration(name: "CarPlay", sessionRole: connectingSceneSession.role)
            sceneConfig.delegateClass = CarPlaySceneDelegate.self
            return sceneConfig
        }

        let sceneConfig = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        return sceneConfig
    }
}
