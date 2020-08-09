struct FunctionCall {
    let definition: ResolverFunctionDefinition
    let isLazy: Bool
}

struct FunctionSection {
    let calls: [FunctionCall]
}

struct FunctionOrder {
    let sections: [FunctionSection]
}

struct FunctionOrderBuilder {
    static func build(with definition: ResolverDefinition) -> Result<FunctionOrder, AggregateError<DefinitionError>> {
        var resolverFunctions = definition.resolverFunctions
        let zeroParameters = resolverFunctions.compactMapRemoving { function -> FunctionCall? in
            guard function.parameters.isEmpty else { return nil }
            return FunctionCall(definition: function.value, isLazy: functionCallIsLazy(for: function.value, in: definition))
        }

        guard !zeroParameters.isEmpty else {
            let error = DefinitionError(kind: .noResolverFunctionsWithZeroParams, located: definition.adoptionFile)
            return .failure(AggregateError(underlying: [error]))
        }

        let initialSection = FunctionSection(calls: zeroParameters)
        let allSectionsResult = allSectionsByGeneratingRemaining(
            initial: initialSection,
            remainingFunctions: resolverFunctions,
            definition: definition
        )
        return allSectionsResult.map(FunctionOrder.init)
    }

    // MARK: - Helpers

    private static func functionCallIsLazy(for function: ResolverFunctionDefinition, in definition: ResolverDefinition) -> Bool {
        let lazyType = function.returnType.lazyWrapped
        return definition.allFunctions.contains { function in
            function.parameters.contains { $0.typeName == lazyType }
        }
    }

    private static func allSectionsByGeneratingRemaining(
        initial: FunctionSection,
        remainingFunctions: [Located<ResolverFunctionDefinition>],
        definition: ResolverDefinition
    ) -> Result<[FunctionSection], AggregateError<DefinitionError>> {
        var remainingFunctions = remainingFunctions
        var allSections = [initial]
        while !remainingFunctions.isEmpty {
            let allResolvedTypes = Set(allSections.flatMap(\.calls).map(\.definition.returnType))
            let calls = remainingFunctions.compactMapRemoving { function -> FunctionCall? in
                let containsUnresolvedParam = function.parameters.contains { param in
                    !allResolvedTypes.contains(param.typeName.strippingLazyWrapper)
                }
                guard !containsUnresolvedParam else { return nil }
                return FunctionCall(definition: function.value, isLazy: functionCallIsLazy(for: function.value, in: definition))
            }

            if calls.isEmpty {
                let errors = remainingFunctions.map { function in
                    DefinitionError(kind: .unresolvableDependencies, located: function)
                }
                let aggregate = AggregateError(underlying: errors)
                return .failure(aggregate)
            } else {
                let section = FunctionSection(calls: calls)
                allSections.append(section)
            }
        }
        return .success(allSections)
    }
}
