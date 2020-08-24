public struct OrderedDefinitionBuilder {
    /// Takes a Resolver definition and produces a representation of the order
    /// in which Resolver functions should be called in the generated `resolve()`
    /// method
    public static func build(with definition: ResolverDefinition) -> Either<OrderedResolverDefinition, [Located<DefinitionError>]> {
        let keysResult = UsedKeysFilter(definition: definition).determineAllUsedResolverKeys()
        guard case .success(let keys) = keysResult else {
            let errors = keysResult.failureError.map { [$0] } ?? []
            return .right(errors)
        }

        let functionsForType = definition.functionsForType
        let usedResolverFunctions = keys.usedKeys.compactMap { functionsForType[$0] }

        let allCallsOrErrors = makeFunctionCalls(from: usedResolverFunctions, in: definition)
        guard var allCalls = allCallsOrErrors.left else {
            return .right(allCallsOrErrors.right ?? [])
        }

        let zeroParameters = allCalls.compactMapRemoving { call -> Located<FunctionCall>? in
            guard call.definition.parameters.isEmpty else { return nil }
            return call
        }

        guard !zeroParameters.isEmpty else {
            fatalError("No resolver functions were found with zero parameters, but this should have resulted in `DefinitionError.circularResolverDependency`. If you're seeing this error, please consider creating a GitHub issue.")
        }

        let initialSection = FunctionSection(calls: zeroParameters.map(\.value))
        let allSectionsResult = allSectionsByGeneratingRemaining(
            initial: initialSection,
            remainingCalls: allCalls,
            definition: definition
        )
        return allSectionsResult.mapLeft { sections in
            let order = FunctionOrder(sections: sections)
            return OrderedResolverDefinition(
                definition: definition,
                functionOrder: order
            )
        }
    }

    // MARK: - Helpers

    private static func functionCallIsLazy(for function: ResolverFunctionDefinition, in definition: ResolverDefinition) -> Bool {
        let lazyType = function.returnType.lazyWrapped
        return definition.allFunctions.contains { function in
            function.parameters.contains { $0.typeName == lazyType }
        }
    }

    private static func makeFunctionCalls(from functions: [Located<ResolverFunctionDefinition>], in definition: ResolverDefinition) -> Either<[Located<FunctionCall>], [Located<DefinitionError>]> {
        let results = functions.map { makeFunctionCall(from: $0, in: definition) }
        let (calls, errors) = results.splitLeftAndRight()
        if errors.isEmpty {
            return .left(calls)
        } else {
            return .right(errors)
        }
    }

    private static func makeFunctionCall(from function: Located<ResolverFunctionDefinition>, in definition: ResolverDefinition) -> Either<Located<FunctionCall>, Located<DefinitionError>> {
        let isLazy = functionCallIsLazy(for: function.value, in: definition)
        guard !function.isThrowing || !isLazy else {
            return .right(
                function.mapConstant(
                    .resolverFunctionCannotBeThrowingIfResultIsUsedLazily
                )
            )
        }
        let call = function.map { FunctionCall(definition: $0, isLazy: isLazy) }
        return .left(call)
    }

    private static func allSectionsByGeneratingRemaining(
        initial: FunctionSection,
        remainingCalls: [Located<FunctionCall>],
        definition: ResolverDefinition
    ) -> Either<[FunctionSection], [Located<DefinitionError>]> {
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

            if !calls.isEmpty {
                let section = FunctionSection(calls: calls)
                allSections.append(section)
            } else {
                fatalError("Unable to determine next function to call. This should have resulted in `DefinitionError.circularResolverDependency`")
            }
        }
        return .left(allSections)
    }
}
