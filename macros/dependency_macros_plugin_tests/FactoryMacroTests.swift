import DependencyFoundation
import DependencyMacrosPlugin
import SwiftSyntaxMacrosTestSupport
import XCTest

final class FactoryMacroTests: XCTestCase {
    private let macros = ["Factory": FactoryMacro.self]

    func testMacro() throws {
        assertMacroExpansion(
            """
            @Factory(FooFeatureViewControllerImplementation.swift)
            let fooFeature: FooFeature
            """,
            expandedSource:
            """
            let fooFeature: FooFeature
            """,
            macros: self.macros
        )
    }
}
