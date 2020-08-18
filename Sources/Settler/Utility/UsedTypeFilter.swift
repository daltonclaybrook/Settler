struct UsedKeysResult {
    let usedKeys: Set<TypeName>
    let unusedKeys: Set<TypeName>
}

struct CircularError: Error {
    let keys: [TypeName]
    let function: Located<ResolverFunctionDefinition>
}

extension CircularError {
    func prepending(key: TypeName) -> CircularError {
        CircularError(keys: [key] + keys, function: function)
    }
}

final class UsedKeysFilter {
    private let definition: ResolverDefinition
    private let functionsForType: [TypeName: Located<ResolverFunctionDefinition>]
    private var typesCurrentlyBeingDetermined: Set<TypeName> = []

    init(definition: ResolverDefinition) {
        self.definition = definition
        self.functionsForType = definition.functionsForType
    }

    /// Returns a struct containing the set of all used keys and the set of all unused
    /// keys within a Resolver definition.
    func determineAllUsedResolverKeys() -> Result<UsedKeysResult, DefinitionError> {
        let allTypes = Set(functionsForType.keys)
        let outputType = definition.outputDefinition.existingType
        return determineAllTypeDependencies(of: outputType)
            .map { allDependencies -> UsedKeysResult in
                let usedKeys = allDependencies.union([outputType])
                let unusedKeys = allTypes.subtracting(usedKeys)
                return UsedKeysResult(usedKeys: usedKeys, unusedKeys: unusedKeys)
            }
            .mapError { error in
                DefinitionError(kind: .circularResolverDependency(keys: error.keys), located: error.function)
            }
    }

    // MARK: - Helpers

    private func determineAllTypeDependencies(of typeName: TypeName) -> Result<Set<TypeName>, CircularError> {
        guard let function = functionsForType[typeName] else {
            fatalError("\(typeName) is not a member of this resolver")
        }

        var typeNames = Set<TypeName>()
        for parameter in function.parameters {
            let typeName = parameter.typeName.strippingLazyWrapper
            guard !typesCurrentlyBeingDetermined.contains(typeName) else {
                return .failure(CircularError(keys: [typeName], function: function))
            }

            typeNames.insert(typeName)
            typesCurrentlyBeingDetermined.insert(typeName)
            switch determineAllTypeDependencies(of: typeName) {
            case .success(let resultTypes):
                typeNames.formUnion(resultTypes)
                typesCurrentlyBeingDetermined.remove(typeName)
            case .failure(let error):
                return .failure(error.prepending(key: typeName))
            }
        }

        return .success(typeNames)
    }
}
