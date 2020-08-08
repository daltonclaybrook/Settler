import SourceKittenFramework

enum TypeNameConstants {
    static let resolver = "Resolver"
    static let key = "Key"
    static let output = "Output"
}

struct ResolverDefinitionBuilder {
    /// A Resolver must be declared as one of these kinds
    private static let declarationKinds: Set<SwiftDeclarationKind> = [.class, .struct, .enum]

    static func buildWith(swiftFiles: [String]) throws -> [ResolverDefinition] {
        var partialDefinitions = try swiftFiles.flatMap { filePath -> [PartialResolverDefinition] in
            guard let file = File(path: filePath) else { return [] }
            let typeChains = try getTypeChainsImplementingResolver(in: file)
            return typeChains.map {
                PartialResolverDefinition(typeChain: $0.value, adoptionFile: $0.mapVoid())
            }
        }

        let definitionErrors = try swiftFiles.reduce(into: [DefinitionError]()) { result, filePath in
            guard let file = File(path: filePath) else { return }
            let structure = try Structure(file: file)
            let fileMembers = structure.dictionary.substructure ?? []

            partialDefinitions.mutableForEach { definition in
                let matchingMembers = findFileMembersMatching(typeChain: definition.typeChain, in: fileMembers)
                let errors = update(
                    definition: &definition,
                    withMatchingMembers: matchingMembers,
                    in: file
                )
                result.append(contentsOf: errors)
            }
        }

        let finalizedOrErrors = definitionErrors.isEmpty ? partialDefinitions.map(finalizeDefinition(_:)) : []
        let finalizeErrors = finalizedOrErrors.flatMap { $0.right ?? [] }
        let allErrors = definitionErrors + finalizeErrors

        if allErrors.isEmpty {
            return finalizedOrErrors.compactMap(\.left)
        } else {
            throw AggregateError(underlying: allErrors)
        }
    }

    // MARK: - Helpers

    private static func getTypeChainsImplementingResolver(in file: File) throws -> [Located<TypeNameChain>] {
        let structure = try Structure(file: file)
        let fileMembers = structure.dictionary.substructure ?? []
        return fileMembers.flatMap { fileMember in
            findTypeChains(named: TypeNameConstants.resolver, namespace: [], in: file, structure: fileMember)
        }
    }

    private static func findTypeChains(named: TypeName, namespace: TypeNameChain, in file: File, structure: [String: SourceKitRepresentable]) -> [Located<TypeNameChain>] {
        guard let typeName = structure.name else { return [] }

        let namespaceAndType = namespace + [typeName]
        // Recurse into deeper members to find matching chains
        var chains = structure.substructure?.flatMap { deeperMember in
            findTypeChains(named: named, namespace: namespaceAndType, in: file, structure: deeperMember)
        } ?? []

        let inheritedTypeNames = structure.inheritedTypes?
            .compactMap { possibleType in
                (possibleType as? [String: SourceKitRepresentable])?.name
            } ?? []

        if inheritedTypeNames.contains(named) {
            let location = Located(value: namespaceAndType, file: file, offset: structure.offset)
            chains.append(location)
        }

        return chains
    }

    /// Find all file members matching the given type chain
    private static func findFileMembersMatching(typeChain: TypeNameChain, in fileMembers: [[String: SourceKitRepresentable]]) -> [[String: SourceKitRepresentable]] {
        var typeChain = typeChain
        guard !typeChain.isEmpty else { return [] }
        let firstType = typeChain.removeFirst()

        let structuresForType = fileMembers.filter { structure in
            structure.name == firstType
        }
        if typeChain.isEmpty {
            return structuresForType
        } else {
            return findFileMembersMatching(typeChain: typeChain, in: structuresForType)
        }
    }

    // MARK: - Hydrating the definitions

    /// Update the provided Resolver definition with the members of the provided file
    /// if possible, returning any errors that occur along the way
    ///
    /// Members provided to this function should already be confirmed to match the
    /// type chain of the definition. Passing unconfirmed members is a programmer error.
    private static func update(definition: inout PartialResolverDefinition, withMatchingMembers members: [[String: SourceKitRepresentable]], in file: File) -> [DefinitionError] {
        members.flatMap { member in
            update(definition: &definition, member: member, in: file)
        }
    }

    private static func update(definition: inout PartialResolverDefinition, member: [String: SourceKitRepresentable], in file: File) -> [DefinitionError] {
        if let kind = member.declarationKind, declarationKinds.contains(kind) {
            if definition.declarationFile != nil {
                fatalError("Found multiple declarations for the Resolver \(definition.typeChain.dotJoined). This should never happen.")
            }
            definition.declarationFile = Located(file: file, offset: member.offset)
        }

        let typeMembers = member.substructure ?? []
        return typeMembers.flatMap { member -> [DefinitionError] in
            guard let name = member.name,
                let kind = member.declarationKind
                else { return [] }

            if name == TypeNameConstants.key {
                return updateKey(for: &definition, kind: kind, enumStructure: member, file: file)
            } else if name == TypeNameConstants.output {
                return updateOutput(for: &definition, kind: kind, outputStructure: member, file: file)
            } else if kind == .functionMethodInstance {
                return updateFunctions(for: &definition, functionName: name, functionStructure: member, file: file)
            } else {
                return []
            }
        }
    }

    private static func updateKey(for definition: inout PartialResolverDefinition, kind: SwiftDeclarationKind, enumStructure: [String: SourceKitRepresentable], file: File) -> [DefinitionError] {
        guard kind == .enum else {
            return [DefinitionError(kind: .keyIsNotAnEnum, file: file, offset: enumStructure.offset)]
        }

        let aliasStructures = enumStructure.substructure ?? []
        let typeAliasResults = aliasStructures.map { structure in
            TypeAliasDefinitionBuilder
                .buildFrom(aliasStructure: structure, in: file)
                .mapError { error in
                    DefinitionError(kind: error.keyMemberErrorKind, file: file, offset: structure.offset)
                }
        }

        let key = KeyDefinition(typeAliases: typeAliasResults.compactMap(\.successValue))
        definition.keyDefinition = Located(value: key, file: file, offset: enumStructure.offset)
        return typeAliasResults.compactMap(\.failureError)
    }

    private static func updateOutput(for definition: inout PartialResolverDefinition, kind: SwiftDeclarationKind, outputStructure: [String: SourceKitRepresentable], file: File) -> [DefinitionError] {
        switch TypeAliasDefinitionBuilder.buildFrom(aliasStructure: outputStructure, in: file) {
        case .success(let output):
            definition.outputDefinition = output
            return []
        case .failure(let error):
            return [DefinitionError(kind: error.outputErrorKind, file: file, offset: outputStructure.offset)]
        }
    }

    private static func updateFunctions(for definition: inout PartialResolverDefinition, functionName: String, functionStructure: [String: SourceKitRepresentable], file: File) -> [DefinitionError] {
        let returnType = functionStructure.typeName
        let parameterStructures = functionStructure.substructure ?? []
        let parameterResults = parameterStructures.compactMap { structure -> Result<FunctionParameter, DefinitionError>? in
            guard let kind = structure.declarationKind,
                kind == .varParameter,
                let name = structure.name,
                let typeName = structure.typeName else {
                    return nil
            }

            let parameter = FunctionParameter(name: name, typeName: typeName)
            return .success(parameter)
        }

        let parameterErrors = parameterResults.compactMap(\.failureError)
        // Only create a resolver function if there are no errors
        if parameterErrors.isEmpty {
            let parameters = parameterResults.compactMap(\.successValue)
            let function = PartialFunctionDefinition(name: functionName, parameters: parameters, returnType: returnType)
            let locatedFunction = Located(value: function, file: file, offset: functionStructure.offset)
            definition.functions.append(locatedFunction)
        }
        return parameterErrors
    }

    /// Discover errors that can only be determined after the definition has been completed
    /// and all source files have been parsed.
    ///
    /// These errors include:
    /// - Key contains alias that does not have a resolver function
    /// - Key contains alias that is returned by more than one resolver function
    /// - Resolver function contains parameters not found in the Key
    private static func finalizeDefinition(_ definition: PartialResolverDefinition) -> Either<ResolverDefinition, [DefinitionError]> {
        guard let key = definition.keyDefinition,
            let output = definition.outputDefinition else {
                // Though these are error states, they will be caught by the
                // Swift compiler since it is a protocol requirement. No need
                // to report additional errors.
                return .right([])
        }
        guard let declarationFilePath = definition.declarationFile?.file.path else {
            let error = DefinitionError(kind: .cantFindDeclarationFile, located: definition.adoptionFile)
            return .right([error])
        }
        guard let adoptionPath = definition.adoptionFile.file.path else {
            fatalError("The adoption file path should never be nil since the file is always initialized with a path.")
        }

        var resolverFunctions: [Located<ResolverFunctionDefinition>] = []
        var configFunctions: [Located<ConfigFunctionDefinition>] = []
        var functionErrors: [DefinitionError] = []
        definition.functions.forEach { locatedFunction in
            let function = locatedFunction.value
            let containsNonKeyParam = function.parameters.contains { param in
                !param.typeName.isAcceptableResolverFunctionParameter
            }

            if let returnType = function.returnType, returnType.isAcceptableResolverFunctionReturnType {
                // This is considered a resolver function
                guard !containsNonKeyParam else {
                    let error = DefinitionError(kind: .resolverFunctionContainsNonKeyParam, located: locatedFunction)
                    functionErrors.append(error)
                    return
                }

                let resolverFunction = locatedFunction.map {
                    ResolverFunctionDefinition(name: $0.name, parameters: $0.parameters, returnType: returnType)
                }
                resolverFunctions.append(resolverFunction)
            } else if function.returnType == nil && !containsNonKeyParam {
                // This is a config function
                let configFunction = locatedFunction.map {
                    ConfigFunctionDefinition(name: $0.name, parameters: $0.parameters)
                }
                configFunctions.append(configFunction)
            }
            // Other unhandled cases are acceptable, i.e. A Resolver is allowed to have helper
            // functions that return Void and have non-`Key` params, or functions that have
            // non-`Key` return types.
        }

        // Report errors if two or more resolvers have the same return type
        let duplicateFunctionErrors = resolverFunctions.flatMapEachCombination { first, second -> [DefinitionError] in
            if first.returnType == second.returnType {
                let error1 = DefinitionError(kind: .duplicateReturnTypesInResolverFunctions, located: first)
                let error2 = DefinitionError(kind: .duplicateReturnTypesInResolverFunctions, located: second)
                return [error1, error2]
            } else {
                return []
            }
        }

        // Report errors if the Key contains aliases that are not being resolved
        let allReturnTypes = Set(resolverFunctions.map(\.returnType.strippingKeyAndLazyWrapper))
        let missingFunctionErrors = key.typeAliases.compactMap { alias -> DefinitionError? in
            if !allReturnTypes.contains(alias.name) {
                return DefinitionError(kind: .noResolverFunctionForKey, located: alias)
            } else {
                return nil
            }
        }

        let allErrors = functionErrors + duplicateFunctionErrors + missingFunctionErrors
        if allErrors.isEmpty {
            let resolved = ResolverDefinition(
                typeChain: definition.typeChain,
                adoptionFilePath: adoptionPath,
                declarationFilePath: declarationFilePath,
                keyDefinition: key.value,
                outputDefinition: output.value,
                resolverFunctions: resolverFunctions.map(\.value),
                configFunctions: configFunctions.map(\.value)
            )
            return .left(resolved)
        } else {
            return .right(allErrors)
        }
    }
}
