/// Used to produce the string contents of a generated `Resolver+Output.swift`
/// file. This process is decoupled from the process of actually determining
/// the function order, which is handled by `FunctionOrderBuilder`.
final class OutputFileContentsBuilder {
    let orderedDefinition: OrderedResolverDefinition

    private static let projectURL = "https://github.com/daltonclaybrook/Settler"
    private static let headerString = "// Generated using Settler \(SettlerVersion.current.value) - \(projectURL)"
    private static let doNotEditString = "// DO NOT EDIT"
    private static let importSettler = "import SettlerKit"

    init(orderedDefinition: OrderedResolverDefinition) {
        self.orderedDefinition = orderedDefinition
    }

    func buildFileContents(with indentation: Indentation) -> String {
        let definition = orderedDefinition.definition
        let extensionIndent = indentation.depth(1)
        let functionIndent = extensionIndent + 1

        let sectionsString = makeStringForAllSections(indent: functionIndent)
        let configsString = makeStringForConfigFunctions(indent: functionIndent)
        let returnString = makeReturnString(indent: functionIndent)
        let throwsString = areAnyFunctionsThrowing() ? " throws " : " "

        return """
        \(OutputFileContentsBuilder.headerString)
        \(OutputFileContentsBuilder.doNotEditString)
        \(OutputFileContentsBuilder.importSettler)

        extension \(definition.typeChain.dotJoined) {
        \(extensionIndent)func resolve()\(throwsString)-> Output {
        \(sectionsString)
        \(configsString)
        \(returnString)
        \(extensionIndent)}
        }

        """
    }

    // MARK: - Helper functions

    private func makeStringForAllSections(indent: IndentDepth) -> String {
        let sectionStrings = orderedDefinition.functionOrder
            .sections
            .enumerated()
            .map { index, section -> String in
                let allCallsString = section.calls
                    .map { makeString(for: $0, indent: indent) }
                    .joined(separator: "\n")
                return "\(indent)// Resolver phase \(index + 1)\n\(allCallsString)"
            }
        return sectionStrings.joined(separator: "\n")
    }

    private func makeStringForConfigFunctions(indent: IndentDepth) -> String {
        let definition = orderedDefinition.definition
        guard !definition.configFunctions.isEmpty else { return "" }

        let configCallsString = definition.configFunctions.map { function in
            "\(indent)\(makeCallString(for: function, indent: indent))"
        }.joined(separator: "\n")
        return "\(indent)// Configuration\n\(configCallsString)"
    }

    private func makeReturnString(indent: IndentDepth) -> String {
        let variableType = orderedDefinition.definition.outputDefinition.existingType
        if isArgumentLazy(for: variableType) {
            return "\(indent)return \(variableType.variableName).resolve()"
        } else {
            return "\(indent)return \(variableType.variableName)"
        }
    }

    private func areAnyFunctionsThrowing() -> Bool {
        orderedDefinition.definition.allFunctions.contains(where: \.isThrowing)
    }

    private func makeString(for call: FunctionCall, indent: IndentDepth) -> String {
        let callString = makeCallString(for: call.definition, indent: indent)
        let returnVariable = call.definition.returnType.variableName
        if call.isLazy {
            return """
            \(indent)let \(returnVariable) = Lazy {
            \(indent + 1)self.\(callString)
            \(indent)}
            """
        } else {
            let tryString = call.definition.isThrowing ? "try " : ""
            return "\(indent)let \(returnVariable) = \(tryString)\(callString)"
        }
    }

    private func makeCallString(for definition: FunctionDefinitionType, indent: IndentDepth) -> String {
        let nameWithoutArgs = definition.name.components(separatedBy: "(").first ?? ""
        let allArguments = definition.parameters.map { param in
            // Is the argument we're passing to this function an instance of `Lazy`?
            let argumentIsLazy = isArgumentLazy(for: param.typeName)
            // Is the param type of this function `Lazy`?
            let paramIsLazy = param.typeName.isLazy

            if !paramIsLazy && argumentIsLazy {
                return "\(param.name): \(param.typeName.variableName).resolve()"
            } else {
                return "\(param.name): \(param.typeName.variableName)"
            }
        }.joined(separator: ", ")
        return "\(nameWithoutArgs)(\(allArguments))"
    }

    private var isLazyMemoized: [TypeName: Bool] = [:]
    private func isArgumentLazy(for typeName: TypeName) -> Bool {
        if let isLazy = isLazyMemoized[typeName] {
            return isLazy
        }

        let callForType = orderedDefinition.functionOrder
            .sections
            .lazy
            .flatMap(\.calls).first { call in
                call.definition.returnType == typeName
            }
        let isLazy = callForType?.isLazy ?? false
        isLazyMemoized[typeName] = isLazy
        return isLazy
    }
}
