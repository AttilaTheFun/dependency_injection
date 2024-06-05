import DependencyFoundation
import LoggedInFeatureInterface
import LoggedInFeatureInterface
import LoggedInFeatureImplementation
import LoggedOutFeatureInterface
import ScopeInitializationPluginInterface
import UIKit
import UserServiceInterface
import UserSessionServiceInterface
import UserSessionServiceImplementation
import WindowServiceInterface

// TODO: Generate with @FeaatureScopeBuilder macro.
public final class LoggedInFeatureBuilder: DependencyContainer<LoggedInScopeImplementationDependencies>, Builder {
    public func build(arguments: LoggedInFeatureArguments) -> UIViewController {
        let scope = LoggedInScopeImplementation(dependencies: self.dependencies, arguments: arguments)
        return scope.loggedInFeatureViewControllerBuilder.build(arguments: arguments)
    }
}

// TODO: Generate with @Buildable macro.
public final class LoggedInScopeImplementationBuilder: DependencyContainer<LoggedInScopeImplementationDependencies>, Builder {
    public func build(arguments: LoggedInFeatureArguments) -> AnyObject {
        return LoggedInScopeImplementation(dependencies: self.dependencies, arguments: arguments)
    }
}

// TODO: Generate with @Injectable macro.
public typealias LoggedInScopeImplementationDependencies
    = DependencyProvider
    & LoggedOutFeatureBuilderProvider
    & UserSessionStorageServiceProvider
    & UserStorageServiceProvider
    & WindowServiceProvider

// @Buildable(building: AnyObject.self)
// @Injectable
final class LoggedInScopeImplementation: Scope<LoggedInScopeImplementationDependencies> {

    // @Arguments
    let loggedInFeatureArguments: LoggedInFeatureArguments

    // @Propagate
    // let userStorageService: UserStorageService

    // @Propagate
    // let userSessionStorageService: UserSessionStorageService

    // @Propagate
    // let windowService: WindowService

    // @Propagate
    // let loggedOutFeatureBuilder: LoggedOutFeatureBuilder

    // @Instantiate(UserSessionServiceImplementation.self)
    // let userSessionService: UserSessionService

    // TODO: Generate with @Injectable macro.
    init(dependencies: LoggedInScopeImplementationDependencies, arguments: LoggedInFeatureArguments) {
        self.loggedInFeatureArguments = arguments
        super.init(dependencies: dependencies)
    }
}

// TODO: Generate from the @Propagate macro.
extension LoggedInScopeImplementation: UserStorageServiceProvider {
    var userStorageService: any UserStorageService {
        return self.dependencies.userStorageService
    }
}

// TODO: Generate from the @Propagate macro.
extension LoggedInScopeImplementation: UserSessionStorageServiceProvider {
    var userSessionStorageService: any UserSessionStorageService {
        return self.dependencies.userSessionStorageService
    }
}

// TODO: Generate from the @Propagate macro.
extension LoggedInScopeImplementation: WindowServiceProvider {
    var windowService: any WindowService {
        return self.dependencies.windowService
    }
}

// TODO: Generate from the @Propagate macro.
extension LoggedInScopeImplementation: LoggedOutFeatureBuilderProvider {
    var loggedOutFeatureBuilder: any Builder<LoggedOutFeatureArguments, UIViewController> {
        return self.dependencies.loggedOutFeatureBuilder
    }
}

// TODO: Generate from the @Instantiate macro.
extension LoggedInScopeImplementation: UserSessionServiceProvider {
    var userSessionService: any UserSessionService {
        return self.strong { [unowned self] in
            return UserSessionServiceImplementation(dependencies: self)
        }
    }
}

// TODO: Generate from the @Instantiate macro.
extension LoggedInScopeImplementation {
    var loggedInFeatureViewControllerBuilder: any Builder<LoggedInFeatureArguments, UIViewController> {
        return self.strong { [unowned self] in
            return LoggedInFeatureViewControllerBuilder(dependencies: self)
        }
    }
}

// TODO: Generate from @Arguments macro.
extension LoggedInScopeImplementation: LoggedInFeatureArgumentsProvider {}
