import UserSessionServiceInterface
import UserServiceInterface

public struct LoggedInTabBarControllerArguments {
    public let userSession: UserSession
    public let user: User

    public init(userSession: UserSession, user: User) {
        self.userSession = userSession
        self.user = user
    }
}