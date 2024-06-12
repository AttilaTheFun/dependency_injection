import SwiftDiagnostics
import SwiftSyntax

public final class InjectableVisitor: SyntaxVisitor {

    // MARK: Initialization

    public init() {
        super.init(viewMode: .sourceAccurate)
    }

    // MARK: Properties

    public private(set) var diagnostics = [Diagnostic]()
    public private(set) var argumentsProperty: Property?
    public private(set) var injectedProperties: [Property] = []
    private(set) var isTopLevelDeclaration = true

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
        return .visitChildren
    }

    // MARK: Variable Declarations

    public override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.modifiers.staticModifier == nil else {
            return .skipChildren
        }

        guard let injectableMacroType = node.attributes.injectableMacroType else {
            return .skipChildren
        }

        if node.bindings.count > 1 {
            // TODO: Figure out if this can happen?
            // Maybe multiple variable binding like:
            // let (foo, bar) = functionThatReturnsTyple()
            fatalError("Does this happen?")
        }

        for binding in node.bindings {

            // Check that each variable has no initializer.
            if binding.initializer != nil {
                // TODO: Diagnostic.
                fatalError()
            }

            // Parse the property:
            if
                let identifierPatternSyntax = binding.pattern.as(IdentifierPatternSyntax.self),
                let typeAnnotationSyntax = binding.typeAnnotation
            {
                if let identifierTypeSyntax = typeAnnotationSyntax.type.as(IdentifierTypeSyntax.self) {
                    let label = identifierPatternSyntax.identifier.text
                    let typeName = identifierTypeSyntax.name.text
                    let property = Property(label: label, typeName: typeName)
                    switch injectableMacroType {
                    case .arguments:
                        self.argumentsProperty = property
                    case .inject:
                        self.injectedProperties.append(property)
                    }
                } else {
                    // TODO: Do we want to handle any other type annotations?
                    fatalError()
                }
            } else {
                // TODO: Diagnostic.
                fatalError()
            }
        }

        return .skipChildren
    }
}