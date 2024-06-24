import SaberPlugin
import SwiftSyntaxMacrosTestSupport
import XCTest

final class StoreMacroTests: XCTestCase {
    private let macros = ["Store": StoreMacro.self]

    func testMacro() throws {
        assertMacroExpansion(
            """
            @Store(UserServiceImplementation.self)
            var userService: any UserService
            """,
            expandedSource:
            """
            var userService: any UserService {
                get {
                    return self.userServiceStore.value
                }
            }

            private lazy var userServiceStore = Store { [unowned self] in
                UserServiceImplementation(dependencies: self)
            }
            """,
            macros: self.macros
        )
    }
}
