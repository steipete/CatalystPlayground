//
//  AppDelegate.swift
//  UIKitForMacPlayground
//
//  Created by Noah Gilmore on 6/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        if let activity = options.userActivities.first {
            if activity.activityType == UserActivities.square.rawValue {
                let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
                configuration.delegateClass = SquareSceneDelegate.self
                return configuration
            }
        }

        let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    override func buildCommands(with builder: UICommandBuilder) {
        let command = UIKeyCommand(
            input: "J",
            modifierFlags: [.command],
            action: #selector(self.jumpSelected(_:))
        )
        command.title = "Jump to Windows"
        builder.insertChild(UICommandGroup(
            __title: "Jump",
            discoverabilityTitle: "Group",
            identifier: UIMenu.Identifier("hey"),
            options: [],
            children: [
                command
            ]
        ), atEndOfGroup: .view)
    }

    @objc private func jumpSelected(_ sender: AppDelegate) {
        guard let delegate = UIApplication.shared.connectedScenes.compactMap({
            ($0 as? UIWindowScene)
        }).filter({ $0.activationState == .foregroundActive })
            .first?.delegate else { return }
        guard let sceneDelegate = delegate as? SceneDelegate else { return }
        sceneDelegate.handleDetailType(.windows)
    }
}

