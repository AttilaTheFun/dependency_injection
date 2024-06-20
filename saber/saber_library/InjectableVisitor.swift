import SwiftDiagnostics
import SwiftSyntax

public final class InjectableVisitor: SyntaxVisitor {

    // MARK: Initialization

    public init() {
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: Properties

    private(set) var isTopLevelDeclaration = true

    public private(set) var diagnostics = [Diagnostic]()

    public private(set) var concreteDeclaration: ConcreteDeclSyntaxProtocol?
    public private(set) var argumentsTypeAliasDeclaration: TypeAliasDeclSyntax?
    public private(set) var dependenciesTypeAliasDeclaration: TypeAliasDeclSyntax?
    public private(set) var initializerDeclaration: InitializerDeclSyntax?

    public private(set) var argumentProperties: [(Property,AttributeSyntax)] = []
    public private(set) var injectProperties: [(Property,AttributeSyntax)] = []
    public private(set) var factoryProperties: [(Property,AttributeSyntax)] = []
    public private(set) var storeProperties: [(Property,AttributeSyntax)] = []

    public var childDependencyProperties: [(Property,AttributeSyntax)] {
        return self.factoryProperties + self.storeProperties
    }

    public var allProperties: [(Property,AttributeSyntax)] {
        return self.argumentProperties + self.injectProperties + self.factoryProperties + self.storeProperties
    }

    // MARK: Concrete Declarations

    public override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        return self.visitConcreteDecl(node)
    }

    public override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        return self.visitConcreteDecl(node)
    }

    public override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        return self.visitConcreteDecl(node)
    }

    private func visitConcreteDecl(_ node: some ConcreteDeclSyntaxProtocol) -> SyntaxVisitorContinueKind {
        if !self.isTopLevelDeclaration {
            return .skipChildren
        }

        self.isTopLevelDeclaration = false
        self.concreteDeclaration = node
        return .visitChildren
    }

    // MARK: Type Alias Declarations

    public override func visit(_ node: TypeAliasDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.name.trimmed.text == "Arguments" {
            self.argumentsTypeAliasDeclaration = node
        }
        if node.name.trimmed.text == "Dependencies" {
            self.dependenciesTypeAliasDeclaration = node
        }

        return .visitChildren
    }

    // MARK: Initializer Declarations

    public override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        let parameters = node.signature.parameterClause.parameters
        guard parameters.count == 2 else {
            return .skipChildren
        }

        guard
            let firstParameter = parameters.first,
            firstParameter.firstName.text == "arguments",
            case .simple(let name, let generics) = firstParameter.type.typeDescription,
            name == "Arguments",
            generics.count == 0 else
        {
            return .skipChildren
        }

        guard
            let secondParameter = parameters.dropFirst().first,
            secondParameter.firstName.text == "dependencies",
            case .any(let typeDescription) = secondParameter.type.typeDescription,
            case .simple(let name, let generics) = typeDescription,
            name == "Dependencies",
            generics.count == 0 else
        {
            return .skipChildren
        }

        self.initializerDeclaration = node
        return .visitChildren
    }

    // MARK: Variable Declarations

    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.modifiers.isStatic {
            return .skipChildren
        }

        guard let injectableMacroType = node.attributes.injectableMacroType else {
            return .skipChildren
        }

        // Ensure that this is a single binding variable declaration:
        if node.bindings.count > 1 {
            // TODO: Diagnostic.
            fatalError()
        }

        // Check that the binding specifier is a var:
        if node.bindingSpecifier.text != "var" {
            // TODO: Diagnostic.
            fatalError()
        }

        for binding in node.bindings {

            // Check that each binding has no initializer.
            if binding.initializer != nil {
                // TODO: Diagnostic.
                fatalError()
            }

            // Parse the property:
            if
                let identifierPattern = IdentifierPatternSyntax(binding.pattern),
                let typeAnnotation = binding.typeAnnotation
            {

                // Parse the type description:
                let typeDescription = typeAnnotation.type.typeDescription
                if case .unknown(let description) = typeDescription {
                    // TODO: Diagnostic.
                    fatalError(description)
                }
                
                let property = Property(
                    accessLevel: node.modifiers.accessLevel,
                    label: identifierPattern.identifier.text,
                    typeDescription: typeDescription
                )
                switch injectableMacroType {
                case .argument(let attributeSyntax):
                    self.argumentProperties.append((property, attributeSyntax))
                case .inject(let attributeSyntax):
                    self.injectProperties.append((property, attributeSyntax))
                case .factory(let attributeSyntax):
                    self.factoryProperties.append((property, attributeSyntax))
                case .store(let attributeSyntax):
                    self.storeProperties.append((property, attributeSyntax))
                }
            } else {
                // TODO: Diagnostic.
                fatalError()
            }
        }

        return .skipChildren
    }
}