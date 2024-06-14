import DependencyMacrosTypes
import SwiftSyntax

extension AttributeSyntax {
    public var concreteTypeArgument: TypeDescription? {
        return self.typeDescriptionIfNameEquals(nil)
    }

//    public var argumentsTypeArgument: TypeDescription? {
//        return self.typeDescriptionIfNameEquals("arguments")
//    }

    private func typeDescriptionIfNameEquals(_ expectedName: String?) -> TypeDescription? {
        guard
            let arguments = self.arguments,
            let labeledExpressionList = arguments.as(LabeledExprListSyntax.self),
            let labeledExpression = labeledExpressionList.first(where: { $0.label?.text == expectedName }) else
        {
            return nil
        }

        // Fail if the type was unknown:
        let typeDescription = labeledExpression.expression.typeDescription
        if case .unknown(let description) = typeDescription {
            fatalError(description)
        }

        return typeDescription
    }

    public var factoryKeyPathArgument: String? {
        return self.keyPathBaseNameIfNameEquals("factory")
    }

    private func keyPathBaseNameIfNameEquals(_ expectedName: String?) -> String? {
        guard
            let arguments = self.arguments,
            let labeledExpressionList = arguments.as(LabeledExprListSyntax.self),
            let labeledExpression = labeledExpressionList.first(where: { $0.label?.text == expectedName }),
            let keyPathExpression = KeyPathExprSyntax(labeledExpression.expression),
            let firstComponent = keyPathExpression.components.first,
            let keyPathComponent = KeyPathComponentSyntax(firstComponent),
            let keyPathPropertyComponent = KeyPathPropertyComponentSyntax(keyPathComponent.component) else
        {
            return nil
        }

        return keyPathPropertyComponent.declName.baseName.text
    }

    public var initializationStrategyArgument: InitializationStrategy {
        let rawValue = self.memberAccessBaseNameIfNameEquals("init")
        return InitializationStrategy(rawValue: rawValue ?? "") ?? .lazy
    }

    public var referenceStrategyArgument: ReferenceStrategy {
        let rawValue = self.memberAccessBaseNameIfNameEquals("ref")
        return ReferenceStrategy(rawValue: rawValue ?? "") ?? .strong
    }

    private func memberAccessBaseNameIfNameEquals(_ expectedName: String?) -> String? {
        guard
            let arguments = self.arguments,
            let labeledExpressionList = arguments.as(LabeledExprListSyntax.self),
            let labeledExpression = labeledExpressionList.first(where: { $0.label?.text == expectedName }),
            let memberAccessExpression = MemberAccessExprSyntax(labeledExpression.expression) else
        {
            return nil
        }

        return memberAccessExpression.declName.baseName.text
    }
}
