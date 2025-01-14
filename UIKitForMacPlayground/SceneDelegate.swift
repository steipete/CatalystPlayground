//
//  SceneDelegate.swift
//  UIKitForMacPlayground
//
//  Created by Noah Gilmore on 6/27/19.
//  Copyright © 2019 Noah Gilmore. All rights reserved.
//

import UIKit
#if targetEnvironment(macCatalyst)
import AppKit
#endif
import SwiftUI

// Hacky stuff as per https://stackoverflow.com/questions/27243158/hiding-the-master-view-controller-with-uisplitviewcontroller-in-ios8
extension UISplitViewController {
    func toggleMasterView() {
        let barButtonItem = self.displayModeButtonItem
        UIApplication.shared.sendAction(barButtonItem.action!, to: barButtonItem.target, from: nil, for: nil)
    }
}

class ReportingSplitViewController: UISplitViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.shared.bridge?.sceneBecameActive(identifier: "normal")
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let scene = (scene as? UIWindowScene) else { return }

        let splitViewController = ReportingSplitViewController()
        let listViewController = ListViewController(didSelectDetailType: { type in
            let viewController = self.viewController(forDetailType: type)
            viewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            viewController.navigationItem.leftItemsSupplementBackButton = true
            viewController.navigationItem.largeTitleDisplayMode = .never
            let detailNavController = UINavigationController(rootViewController: viewController)
            splitViewController.showDetailViewController(detailNavController, sender: self)
            if viewController.canBecomeFirstResponder {
                viewController.becomeFirstResponder()
            }
            guard let identifier = self.window?.windowScene?.session.persistentIdentifier else { return }
            NotificationCenter.default.post(name: .didChangeDetailType, object: nil, userInfo: ["detailType": type.rawValue, "identifier": identifier])
        })
        let navController = UINavigationController(rootViewController: listViewController)
        navController.navigationBar.prefersLargeTitles = true
        let viewController = ViewController()
        viewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        viewController.navigationItem.leftItemsSupplementBackButton = true
        viewController.navigationItem.largeTitleDisplayMode = .never
        let detailNavController = UINavigationController(rootViewController: viewController)
        splitViewController.viewControllers = [navController, detailNavController]
        splitViewController.delegate = self
        splitViewController.primaryBackgroundStyle = .sidebar

        window = UIWindow(windowScene: scene)
        window?.rootViewController = splitViewController
        window?.makeKeyAndVisible()

        #if targetEnvironment(macCatalyst)
            if let titlebar = scene.titlebar {
                let toolbar = NSToolbar(identifier: "toolbar")
                toolbar.delegate = self

                titlebar.toolbar = toolbar
                titlebar.titleVisibility = .hidden
            }
        #endif
    }

    func handleDetailType(_ detailType: DetailType) {
        guard let splitViewController = window?.rootViewController as? UISplitViewController else { return }
        guard let navigationController = splitViewController.viewControllers.first as? UINavigationController else { return }
        guard let listViewController = navigationController.topViewController as? ListViewController else { return }
        listViewController.didSelectDetailType(detailType)
    }

    func viewController(forDetailType type: DetailType) -> UIViewController {
        switch type {
        case .windows:
            return WindowsViewController()
        case .hover:
            return HoverViewController()
        case .dragAndDrop:
            return DragAndDropViewController()
        case .touchBar:
            return TouchBarViewController()
        case .contextMenus:
            return ContextMenuViewController()
        case .cursors:
            return CursorsViewController()
        case .swiftUI:
            return UIHostingController(rootView: SwiftUIView())
        default:
            return ViewController()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func windowScene(_ windowScene: UIWindowScene, didUpdate previousCoordinateSpace: UICoordinateSpace, interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation, traitCollection previousTraitCollection: UITraitCollection) {
        print("Old: \(previousCoordinateSpace.bounds), new: \(windowScene.coordinateSpace.bounds)")
    }
}

extension SceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }
}

#if targetEnvironment(macCatalyst)
extension SceneDelegate: NSToolbarDelegate {
    var identifiers: [NSToolbarItem.Identifier] {
        return [NSToolbarItem.Identifier(rawValue: "test"), .flexibleSpace, NSToolbarItem.Identifier(rawValue: "other")]
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.identifiers
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return self.identifiers
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let identifier = self.window?.windowScene?.session.persistentIdentifier else { return nil }
        switch itemIdentifier.rawValue {
        case "test":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton)))
            item.title = "New window"
            return item
        case "other":
            let item = AppDelegate.shared.bridge!.customToolbarItem(identifier: identifier) { string in
                guard let detailType = DetailType(rawValue: string) else { return }
                self.handleDetailType(detailType)
            }
            return item
        default:
            return nil
        }
    }

    @objc private func didTapAddButton(_ sender: NSToolbarItem) {
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil, errorHandler: nil)
    }

    @objc private func didTapOtherButton(_ sender: NSToolbarItem) {
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil, errorHandler: nil)
    }
}
#endif
