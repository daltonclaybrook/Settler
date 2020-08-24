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
        guard var remainingCalls = allCallsOrErrors.left else {
            return .right(allCallsOrErrors.right ?? [])
        }

        let zeroParameters = remainingCalls.compactMapRemoving { call -> Located<FunctionCall>? in
            guard call.definition.parameters.isEmpty else { return nil }
            return call
        }

        guard !zeroParameters.isEmpty else {
            fatalError("No resolver functions were found with zero parameters, but this should have resulted in `DefinitionError.circularResolverDependency`. If you're seeing this error, please consider creating a GitHub issue.")
        }

        let allOrderedCallsResult = allOrderedCallsByGeneratingRemaining(
            initialCalls: zeroParameters.map(\.value),
            remainingCalls: remainingCalls,
            definition: definition
        )
        return allOrderedCallsResult.mapLeft { orderedCalls in
            OrderedResolverDefinition(definition: definition, orderedCalls: orderedCalls)
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

    private static func allOrderedCallsByGeneratingRemaining(
        initialCalls: [FunctionCall],
        remainingCalls: [Located<FunctionCall>],
        definition: ResolverDefinition
    ) -> Either<[FunctionCall], [Located<DefinitionError>]> {
        var remainingCalls = remainingCalls
        var orderedCalls = initialCalls
        while !remainingCalls.isEmpty {
            let allResolvedTypes = Set(orderedCalls.map(\.definition.returnType))
            let calls = remainingCalls.compactMapRemoving { call -> FunctionCall? in
                let containsUnresolvedParam = call.definition.parameters.contains { param in
                    !allResolvedTypes.contains(param.typeName.strippingLazyWrapper)
                }
                guard !containsUnresolvedParam else { return nil }
                return call.value
            }

            if !calls.isEmpty {
                orderedCalls.append(contentsOf: calls)
            } else {
                fatalError("Unable to determine next function to call. This should have resulted in `DefinitionError.circularResolverDependency`")
            }
        }
        return .left(orderedCalls)
    }
}
