import DependencyMacrosPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class InjectableMacroTests: XCTestCase {
    private let macros: [String : any Macro.Type] = [
        "Argument": ArgumentMacro.self,
        "Factory": FactoryMacro.self,
        "Injectable": InjectableMacro.self,
        "Inject": InjectMacro.self,
        "Store": StoreMacro.self,
    ]

    func testAll() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class FooScope {
                @Arguments var fooArguments: FooArguments
                @Argument var foo: Foo
                @Inject var fooService: FooService
                @Factory(FooViewController.self) var fooViewControllerFactory: Factory<FooArguments, UIViewController>
                @Store(BarServiceImplementation.self) var barService: BarService
            }
            """,
            expandedSource:
            """
            public final class FooScope {
                var fooArguments: FooArguments {
                    get {
                        return self._arguments
                    }
                }
                var foo: Foo {
                    get {
                        return self._arguments.foo
                    }
                }
                var fooService: FooService {
                    get {
                        return self._fooServiceStore.building
                    }
                }
                var fooViewControllerFactory: Factory<FooArguments, UIViewController> {
                    get {
                        let childDependencies = self._childDependenciesStore.building
                        return FactoryImplementation { [childDependencies] arguments in
                            FooViewController(arguments: arguments, dependencies: childDependencies)
                        }
                    }
                }
                var barService: BarService {
                    get {
                        return self._barServiceStore.building
                    }
                }

                private let _arguments: FooArguments

                private lazy var _fooServiceStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.fooService
                    }
                )

                private lazy var _barServiceStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return BarServiceImplementation(dependencies: self._childDependenciesStore.building)
                    }
                )

                private lazy var _childDependenciesStore = StoreImplementation(
                    backingStore: WeakBackingStoreImplementation(),
                    function: { [unowned self] in
                        return FooScopeChildDependencies(parent: self)
                    }
                )

                private let _dependencies: any FooScopeDependencies

                public init(
                    arguments: FooArguments,
                    dependencies: any FooScopeDependencies
                ) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                }
            }

            public protocol FooScopeDependencies: AnyObject {
                var fooService: FooService {
                    get
                }
            }

            fileprivate class FooScopeChildDependencies: FooScopeDependencies, BarServiceImplementationDependencies, FooViewControllerDependencies {
                private let _parent: FooScope
                fileprivate var fooArguments: FooArguments {
                    return self._parent.fooArguments
                }
                fileprivate var foo: Foo {
                    return self._parent.foo
                }
                fileprivate var fooService: FooService {
                    return self._parent.fooService
                }
                fileprivate var fooViewControllerFactory: Factory<FooArguments, UIViewController> {
                    return self._parent.fooViewControllerFactory
                }
                fileprivate var barService: BarService {
                    return self._parent.barService
                }
                fileprivate init(parent: FooScope) {
                    self._parent = parent
                }
            }
            """,
            macros: self.macros
        )
    }

    func testInject() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class FooScope {
                @Inject var fooService: FooService
                @Inject(storage: .weak) var barService: BarService
                @Inject(storage: .computed) var bazService: BazService
            }
            """,
            expandedSource:
            """
            public final class FooScope {
                var fooService: FooService {
                    get {
                        return self._fooServiceStore.building
                    }
                }
                var barService: BarService {
                    get {
                        return self._barServiceStore.building
                    }
                }
                var bazService: BazService {
                    get {
                        return self._bazServiceStore.building
                    }
                }

                private lazy var _fooServiceStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.fooService
                    }
                )

                private lazy var _barServiceStore = StoreImplementation(
                    backingStore: WeakBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.barService
                    }
                )

                private lazy var _bazServiceStore = StoreImplementation(
                    backingStore: ComputedBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.bazService
                    }
                )

                private let _dependencies: any FooScopeDependencies

                public init(
                    dependencies: any FooScopeDependencies
                ) {
                    self._dependencies = dependencies
                }
            }

            public protocol FooScopeDependencies: AnyObject {
                var fooService: FooService {
                    get
                }
                var barService: BarService {
                    get
                }
                var bazService: BazService {
                    get
                }
            }
            """,
            macros: self.macros
        )
    }

    func testArguments() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class FooScope {
                @Arguments var fooArguments: FooArguments
                @Argument var foo: Foo
            }
            """,
            expandedSource:
            """
            public final class FooScope {
                var fooArguments: FooArguments {
                    get {
                        return self._arguments
                    }
                }
                var foo: Foo {
                    get {
                        return self._arguments.foo
                    }
                }

                private let _arguments: FooArguments

                private let _dependencies: any FooScopeDependencies

                public init(
                    arguments: FooArguments,
                    dependencies: any FooScopeDependencies
                ) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                }
            }

            public protocol FooScopeDependencies: AnyObject {

            }
            """,
            macros: self.macros
        )
    }

    func testFactory() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class FooScope: FooScopeChildDependencies {
                @Factory(FooViewController.self)
                public var fooViewControllerFactory: Factory<FooFeature, UIViewController>

                @Factory(BarScope.self, factory: \\.barViewControllerFactory)
                public var barViewControllerFactory: Factory<BarFeature, UIViewController>
            }
            """,
            expandedSource:
            """
            public final class FooScope: FooScopeChildDependencies {
                public var fooViewControllerFactory: Factory<FooFeature, UIViewController> {
                    get {
                        let childDependencies = self._childDependenciesStore.building
                        return FactoryImplementation { [childDependencies] arguments in
                            FooViewController(arguments: arguments, dependencies: childDependencies)
                        }
                    }
                }
                public var barViewControllerFactory: Factory<BarFeature, UIViewController> {
                    get {
                        let childDependencies = self._childDependenciesStore.building
                        return FactoryImplementation { [childDependencies] arguments in
                            let concrete = BarScope(arguments: arguments, dependencies: childDependencies)
                            return concrete.barViewControllerFactory.build(arguments: arguments)
                        }
                    }
                }

                private lazy var _childDependenciesStore = StoreImplementation(
                    backingStore: WeakBackingStoreImplementation(),
                    function: { [unowned self] in
                        return FooScopeChildDependencies(parent: self)
                    }
                )

                private let _dependencies: any FooScopeDependencies

                public init(
                    dependencies: any FooScopeDependencies
                ) {
                    self._dependencies = dependencies
                }
            }

            public protocol FooScopeDependencies: AnyObject {

            }

            fileprivate class FooScopeChildDependencies: FooScopeDependencies, BarScopeDependencies, FooViewControllerDependencies {
                private let _parent: FooScope
                fileprivate var fooViewControllerFactory: Factory<FooFeature, UIViewController> {
                    return self._parent.fooViewControllerFactory
                }
                fileprivate var barViewControllerFactory: Factory<BarFeature, UIViewController> {
                    return self._parent.barViewControllerFactory
                }
                fileprivate init(parent: FooScope) {
                    self._parent = parent
                }
            }
            """,
            macros: self.macros
        )
    }

    func testStore() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class FooScope: FooScopeChildDependencies {
                @Store(FooServiceImplementation.self, init: .eager) 
                var fooService: FooService

                @Store(BarServiceImplementation.self, storage: .weak)
                var barService: BarService
            }
            """,
            expandedSource:
            """
            public final class FooScope: FooScopeChildDependencies {
                
                var fooService: FooService {
                    get {
                        return self._fooServiceStore.building
                    }
                }
                var barService: BarService {
                    get {
                        return self._barServiceStore.building
                    }
                }

                private lazy var _fooServiceStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return FooServiceImplementation(dependencies: self._childDependenciesStore.building)
                    }
                )

                private lazy var _barServiceStore = StoreImplementation(
                    backingStore: WeakBackingStoreImplementation(),
                    function: { [unowned self] in
                        return BarServiceImplementation(dependencies: self._childDependenciesStore.building)
                    }
                )

                private lazy var _childDependenciesStore = StoreImplementation(
                    backingStore: WeakBackingStoreImplementation(),
                    function: { [unowned self] in
                        return FooScopeChildDependencies(parent: self)
                    }
                )

                private let _dependencies: any FooScopeDependencies

                public init(
                    dependencies: any FooScopeDependencies
                ) {
                    self._dependencies = dependencies
                    _ = self.fooService
                }
            }

            public protocol FooScopeDependencies: AnyObject {

            }

            fileprivate class FooScopeChildDependencies: FooScopeDependencies, BarServiceImplementationDependencies, FooServiceImplementationDependencies {
                private let _parent: FooScope
                fileprivate var fooService: FooService {
                    return self._parent.fooService
                }
                fileprivate var barService: BarService {
                    return self._parent.barService
                }
                fileprivate init(parent: FooScope) {
                    self._parent = parent
                }
            }
            """,
            macros: self.macros
        )
    }

    func testViewController() throws {
        assertMacroExpansion(
            """
            @Injectable(.viewController)
            public final class FooViewController: UIViewController {
                @Arguments private var fooArguments: FooArguments
                @Inject private var loggedInViewControllerFactory: any Factory<LoggedInFeature, UIViewController>
            }
            """,
            expandedSource:
            """
            public final class FooViewController: UIViewController {
                private var fooArguments: FooArguments {
                    get {
                        return self._arguments
                    }
                }
                private var loggedInViewControllerFactory: any Factory<LoggedInFeature, UIViewController> {
                    get {
                        return self._loggedInViewControllerFactoryStore.building
                    }
                }

                private let _arguments: FooArguments

                private lazy var _loggedInViewControllerFactoryStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.loggedInViewControllerFactory
                    }
                )

                private let _dependencies: any FooViewControllerDependencies

                public init(
                    arguments: FooArguments,
                    dependencies: any FooViewControllerDependencies
                ) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                    super.init(nibName: nil, bundle: nil)
                }

                required init?(coder: NSCoder) {
                    fatalError("not implemented")
                }
            }

            public protocol FooViewControllerDependencies: AnyObject {
                var loggedInViewControllerFactory: any Factory<LoggedInFeature, UIViewController> {
                    get
                }
            }
            """,
            macros: self.macros
        )
    }

    func testView() throws {
        assertMacroExpansion(
            """
            @Injectable(.view)
            public final class FooView: UIView {
                @Arguments private var fooArguments: FooArguments
                @Inject private var loggedInViewControllerFactory: any Factory<LoggedInFeature, UIViewController>
            }
            """,
            expandedSource:
            """
            public final class FooView: UIView {
                private var fooArguments: FooArguments {
                    get {
                        return self._arguments
                    }
                }
                private var loggedInViewControllerFactory: any Factory<LoggedInFeature, UIViewController> {
                    get {
                        return self._loggedInViewControllerFactoryStore.building
                    }
                }

                private let _arguments: FooArguments

                private lazy var _loggedInViewControllerFactoryStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.loggedInViewControllerFactory
                    }
                )

                private let _dependencies: any FooViewDependencies

                public init(
                    arguments: FooArguments,
                    dependencies: any FooViewDependencies
                ) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                    super.init(frame: .zero)
                }

                required init?(coder: NSCoder) {
                    fatalError("init(coder:) has not been implemented")
                }
            }

            public protocol FooViewDependencies: AnyObject {
                var loggedInViewControllerFactory: any Factory<LoggedInFeature, UIViewController> {
                    get
                }
            }
            """,
            macros: self.macros
        )
    }

    func testService() throws {
        assertMacroExpansion(
            """
            @Injectable(.unowned)
            public final class FooServiceImplementation {
                @Inject private var barService: BarService
            }
            """,
            expandedSource:
            """
            public final class FooServiceImplementation {
                private var barService: BarService {
                    get {
                        return self._barServiceStore.building
                    }
                }

                private lazy var _barServiceStore = StoreImplementation(
                    backingStore: StrongBackingStoreImplementation(),
                    function: { [unowned self] in
                        return self._dependencies.barService
                    }
                )

                private unowned let _dependencies: any FooServiceImplementationDependencies

                public init(
                    dependencies: any FooServiceImplementationDependencies
                ) {
                    self._dependencies = dependencies
                }
            }

            public protocol FooServiceImplementationDependencies: AnyObject {
                var barService: BarService {
                    get
                }
            }
            """,
            macros: self.macros
        )
    }

    func testHandWrittenInitializer() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class Foo {
                public init(arguments: Arguments, dependencies: any Dependencies) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                    print("hand written initializer")
                }
            }
            """,
            expandedSource:
            """
            public final class Foo {
                public init(arguments: Arguments, dependencies: any Dependencies) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                    print("hand written initializer")
                }

                public typealias Arguments = Void

                public typealias Dependencies = FooDependencies

                private let _arguments: Arguments

                private let _dependencies: any Dependencies
            }

            public protocol FooDependencies: AnyObject {
            }

            extension Foo: Injectable {
            }
            """,
            macros: self.macros
        )
    }

    func testHandWrittenDependenciesTypeAlias() throws {
        assertMacroExpansion(
            """
            public protocol FooSpecialDependencies {
            }

            @Injectable
            public final class Foo {
                public typealias Dependencies = FooSpecialDependencies
            }
            """,
            expandedSource:
            """
            public protocol FooSpecialDependencies {
            }
            public final class Foo {
                public typealias Dependencies = FooSpecialDependencies

                public typealias Arguments = Void

                private let _arguments: Arguments

                private let _dependencies: any Dependencies

                public init(arguments: Arguments, dependencies: Dependencies) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                }
            }

            extension Foo: Injectable {
            }
            """,
            macros: self.macros
        )
    }

    func testHandWrittenArgumentsTypeAlias() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class Foo {
                public typealias Arguments = FooSpecialArguments
            }
            """,
            expandedSource:
            """
            public final class Foo {
                public typealias Arguments = FooSpecialArguments

                public typealias Dependencies = FooDependencies

                private let _arguments: Arguments

                private let _dependencies: any Dependencies

                public init(arguments: Arguments, dependencies: Dependencies) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                }
            }

            public protocol FooDependencies: AnyObject {
            }

            extension Foo: Injectable {
            }
            """,
            macros: self.macros
        )
    }

    func testEmpty() throws {
        assertMacroExpansion(
            """
            @Injectable
            public final class Foo {
            }
            """,
            expandedSource:
            """
            public final class Foo {

                public typealias Arguments = Void

                public typealias Dependencies = FooDependencies

                private let _arguments: Arguments

                private let _dependencies: any Dependencies

                public init(arguments: Arguments, dependencies: Dependencies) {
                    self._arguments = arguments
                    self._dependencies = dependencies
                }
            }

            public protocol FooDependencies: AnyObject {
            }

            extension Foo: Injectable {
            }
            """,
            macros: self.macros
        )
    }
}
