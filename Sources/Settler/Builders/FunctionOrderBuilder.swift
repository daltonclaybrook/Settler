struct FunctionOrderBuilder {
    static func build(with definition: ResolverDefinition) -> Either<FunctionOrder, [DefinitionError]> {
        let allCallsOrErrors = makeFunctionCalls(from: definition.resolverFunctions, in: definition)
        guard var allCalls = allCallsOrErrors.left else {
            return .right(allCallsOrErrors.right ?? [])
        }

        let zeroParameters = allCalls.compactMapRemoving { call -> Located<FunctionCall>? in
            guard call.definition.parameters.isEmpty else { return nil }
            return call
        }

        guard !zeroParameters.isEmpty else {
            let error = DefinitionError(kind: .noResolverFunctionsWithZeroParams, located: definition.adoptionFile)
            return .right([error])
        }

        let initialSection = FunctionSection(calls: zeroParameters.map(\.value))
        let allSectionsResult = allSectionsByGeneratingRemaining(
            initial: initialSection,
            remainingCalls: allCalls,
            definition: definition
        )
        return allSectionsResult.mapLeft(FunctionOrder.init)
    }

    // MARK: - Helpers

    private static func functionCallIsLazy(for function: ResolverFunctionDefinition, in definition: ResolverDefinition) -> Bool {
        let lazyType = function.returnType.lazyWrapped
        return definition.allFunctions.contains { function in
            function.parameters.contains { $0.typeName == lazyType }
        }
    }

    private static func makeFunctionCalls(from functions: [Located<ResolverFunctionDefinition>], in definition: ResolverDefinition) -> Either<[Located<FunctionCall>], [DefinitionError]> {
        let results = functions.map { makeFunctionCall(from: $0, in: definition) }
        let (calls, errors) = results.splitLeftAndRight()
        if errors.isEmpty {
            return .left(calls)
        } else {
            return .right(errors)
        }
    }

    private static func makeFunctionCall(from function: Located<ResolverFunctionDefinition>, in definition: ResolverDefinition) -> Either<Located<FunctionCall>, DefinitionError> {
        let isLazy = functionCallIsLazy(for: function.value, in: definition)
        guard !function.isThrowing || !isLazy else {
            let error = DefinitionError(kind: .resolverFunctionCannotBeThrowingIfResultIsUsedLazily, located: function)
            return .right(error)
        }
        let call = function.map { FunctionCall(definition: $0, isLazy: isLazy) }
        return .left(call)
    }

    private static func allSectionsByGeneratingRemaining(
        initial: FunctionSection,
        remainingCalls: [Located<FunctionCall>],
        definition: ResolverDefinition
    ) -> Either<[FunctionSection], [DefinitionError]> {
        var remainingCalls = remainingCalls
        var allSections = [initial]
        while !remainingCalls.isEmpty {
            let allResolvedTypes = Set(allSections.flatMap(\.calls).map(\.definition.returnType))
            let calls = remainingCalls.compactMapRemoving { call -> FunctionCall? in
                let containsUnresolvedParam = call.definition.parameters.contains { param in
                    !allResolvedTypes.contains(param.typeName.strippingLazyWrapper)
                }
                guard !containsUnresolvedParam else { return nil }
                return call.value
            }

            if calls.isEmpty {
                let errors = remainingCalls.map { call in
                    DefinitionError(kind: .unresolvableDependencies, located: call)
                }
                return .right(errors)
            } else {
                let section = FunctionSection(calls: calls)
                allSections.append(section)
            }
        }
        return .left(allSections)
    }
}
