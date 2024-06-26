import Saber
import CameraFeatureInterface
import InboxFeatureInterface
import MapFeatureInterface
import LoggedInFeatureInterface
import SwiftUI
import UserSessionServiceInterface
import UserServiceInterface
import UIKit
import WindowServiceInterface

@Injectable(UIViewController.self)
public final class LoggedInTabBarController: UITabBarController {
    @Inject public var inboxViewFactory: Factory<Void, any View>
    @Inject public var cameraViewControllerFactory: Factory<Void, UIViewController>
    @Inject public var mapViewControllerFactory: Factory<Void, UIViewController>

    public init(arguments: Arguments, dependencies: any Dependencies) {
        self._arguments = arguments
        self._dependencies = dependencies
        super.init(nibName: nil, bundle: nil)

        // Configure the tab bar appearance:
        self.configureTabBarAppearance()

        // Create the initial view controllers:
        let inboxViewController = UIHostingController(rootView: AnyView(self.inboxViewFactory.build()))
        inboxViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage.init(systemName: "tray.fill"),
            tag: 0
        )
        let cameraViewController = self.cameraViewControllerFactory.build()
        cameraViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage.init(systemName: "camera.fill"),
            tag: 0
        )
        let mapViewController = self.mapViewControllerFactory.build()
        mapViewController.tabBarItem = UITabBarItem(
            title: nil,
            image: UIImage.init(systemName: "map.fill"),
            tag: 0
        )
        let viewControllers = [
            inboxViewController,
            cameraViewController,
            mapViewController,
        ]

        // Set the initial view controllers:
        self.viewControllers = viewControllers.map { UINavigationController(rootViewController: $0) }
        self.selectedIndex = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.darkText
        appearance.compactInlineLayoutAppearance.normal.iconColor = .lightText
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor : UIColor.lightText]
        appearance.inlineLayoutAppearance.normal.iconColor = .lightText
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor : UIColor.lightText]
        appearance.stackedLayoutAppearance.normal.iconColor = .lightText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor : UIColor.lightText]

        self.tabBar.standardAppearance = appearance
        self.tabBar.scrollEdgeAppearance = appearance
        self.tabBar.tintColor = .white
    }
}
