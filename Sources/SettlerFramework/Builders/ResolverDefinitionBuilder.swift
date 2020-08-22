import SourceKittenFramework

enum TypeNameConstants {
    static let resolver = "Resolver"
    static let key = "Key"
    static let output = "Output"
}

/// Used to parse all Swift files in the Settler sources path and produce
/// definitions for every Resolver found.
public struct ResolverDefinitionBuilder {
    public struct Output {
        public let definitions: [ResolverDefinition]
        public let errors: [Located<DefinitionError>]
    }

    /// A Resolver must be declared as one of these kinds
    private static let declarationKinds: Set<SwiftDeclarationKind> = [.class, .struct, .enum]

    public static func buildWith(swiftFiles: [String]) throws -> Output {
        var partialDefinitions = try swiftFiles.flatMap { filePath -> [PartialResolverDefinition] in
            guard let file = File(path: filePath) else { return [] }
            let typeChains = try getTypeChainsImplementingResolver(in: file)
            return typeChains.map {
                PartialResolverDefinition(typeChain: $0.value, adoptionFile: $0.mapVoid())
            }
        }

        let definitionErrors = try swiftFiles.reduce(into: [Located<DefinitionError>]()) { result, filePath in
            guard let file = File(path: filePath) else { return }
            let structure = try Structure(file: file)
            let fileMembers = structure.dictionary.substructure ?? []

            try partialDefinitions.mutableForEach { definition in
                let matchingMembers = findFileMembersMatching(typeChain: definition.typeChain, in: fileMembers)
                let errors = try update(
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

        return Output(
            definitions: finalizedOrErrors.compactMap(\.left),
            errors: allErrors
        )
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
    private static func update(definition: inout PartialResolverDefinition, withMatchingMembers members: [[String: SourceKitRepresentable]], in file: File) throws -> [Located<DefinitionError>] {
        try members.flatMap { member in
            try update(definition: &definition, member: member, in: file)
        }
    }

    private static func update(definition: inout PartialResolverDefinition, member: [String: SourceKitRepresentable], in file: File) throws -> [Located<DefinitionError>] {
        if let kind = member.declarationKind, declarationKinds.contains(kind) {
            if definition.declarationFile != nil {
                fatalError("Found multiple declarations for the Resolver \(definition.typeChain.dotJoined). This should never happen.")
            }
            definition.declarationFile = Located(file: file, offset: member.offset)
        }

        let typeMembers = member.substructure ?? []
        return try typeMembers.flatMap { member -> [Located<DefinitionError>] in
            guard let name = member.name,
                let kind = member.declarationKind
                else { return [] }

            if name == TypeNameConstants.key {
                return updateKey(for: &definition, kind: kind, enumStructure: member, file: file)
            } else if name == TypeNameConstants.output {
                return updateOutput(for: &definition, kind: kind, outputStructure: member, file: file)
            } else if kind == .functionMethodInstance {
                return try updateFunctions(for: &definition, functionName: name, functionStructure: member, file: file)
            } else {
                return []
            }
        }
    }

    private static func updateKey(for definition: inout PartialResolverDefinition, kind: SwiftDeclarationKind, enumStructure: [String: SourceKitRepresentable], file: File) -> [Located<DefinitionError>] {
        guard kind == .enum else {
            return [DefinitionError.keyIsNotAnEnum.located(in: file, offset: enumStructure.offset)]
        }

        let aliasStructures = enumStructure.substructure ?? []
        let typeAliasResults = aliasStructures.map { structure in
            TypeAliasDefinitionBuilder
                .buildFrom(aliasStructure: structure, in: file)
                .mapError { error in
                    error.keyMemberError.located(in: file, offset: structure.offset)
                }
        }

        let key = KeyDefinition(typeAliases: typeAliasResults.compactMap(\.successValue))
        definition.keyDefinition = Located(value: key, file: file, offset: enumStructure.offset)
        return typeAliasResults.compactMap(\.failureError)
    }

    private static func updateOutput(for definition: inout PartialResolverDefinition, kind: SwiftDeclarationKind, outputStructure: [String: SourceKitRepresentable], file: File) -> [Located<DefinitionError>] {
        switch TypeAliasDefinitionBuilder.buildFrom(aliasStructure: outputStructure, in: file) {
        case .success(let output) where output.existingType.isAcceptableResolverFunctionReturnType:
            definition.outputDefinition = output
            return []
        case .success(let output):
            return [output.mapConstant(.outputIsNotAKeyMember)]
        case .failure(let error):
            return [error.outputError.located(in: file, offset: outputStructure.offset)]
        }
    }

    private static func updateFunctions(for definition: inout PartialResolverDefinition, functionName: String, functionStructure: [String: SourceKitRepresentable], file: File) throws -> [Located<DefinitionError>] {
        guard let nameOffset = functionStructure.nameOffset,
            let nameLength = functionStructure.nameLength,
            let bodyOffset = functionStructure.bodyOffset else {
                return [
                    DefinitionError.invalidFunction
                        .located(in: file, offset: functionStructure.offset)
                ]
        }

        let returnType = functionStructure.typeName
        let parameterStructures = functionStructure.substructure ?? []
        let parameters = parameterStructures.compactMap { structure -> FunctionParameter? in
            guard let kind = structure.declarationKind,
                kind == .varParameter,
                let name = structure.name,
                let typeName = structure.typeName else { return nil }
            return FunctionParameter(name: name, typeName: typeName)
        }

        let syntaxMap = try SyntaxMap(file: file)
        let startOffset = nameOffset + nameLength
        let isThrowingFunction = syntaxMap.tokens.contains { token in
            let inRange = token.offset.value >= startOffset && (token.offset + token.length).value < bodyOffset
            guard inRange else { return false }
            guard token.type == SyntaxKind.keyword.rawValue else { return false }
            let tokenString = file.stringView.substringWithByteRange(token.range) ?? ""
            return tokenString == "throws"
        }

        // Only create a Resolver function if there are no errors
        let function = PartialFunctionDefinition(name: functionName, parameters: parameters, returnType: returnType, isThrowing: isThrowingFunction)
        let locatedFunction = Located(value: function, file: file, offset: functionStructure.offset)
        definition.functions.append(locatedFunction)
        return []
    }

    /// Discover errors that can only be determined after the definition has been completed
    /// and all source files have been parsed.
    ///
    /// These errors include:
    /// - Key contains alias that does not have a Resolver function
    /// - Key contains alias that is returned by more than one Resolver function
    /// - Resolver function contains parameters not found in the Key
    private static func finalizeDefinition(_ definition: PartialResolverDefinition) -> Either<ResolverDefinition, [Located<DefinitionError>]> {
        guard let key = definition.keyDefinition,
            let output = definition.outputDefinition else {
                // Though these are error states, they will be caught by the
                // Swift compiler since it is a protocol requirement. No need
                // to report additional errors.
                return .right([])
        }
        guard let declarationFilePath = definition.declarationFile?.file.path else {
            return .right([
                definition.adoptionFile.mapConstant(.cantFindDeclarationFile)
            ])
        }

        var resolverFunctions: [Located<ResolverFunctionDefinition>] = []
        var configFunctions: [Located<ConfigFunctionDefinition>] = []
        var functionErrors: [Located<DefinitionError>] = []
        definition.functions.forEach { locatedFunction in
            let function = locatedFunction.value
            let containsNonKeyParam = function.parameters.contains { param in
                !param.typeName.isAcceptableResolverFunctionParameter
            }

            if let returnType = function.returnType, returnType.isAcceptableResolverFunctionReturnType {
                // This is considered a Resolver function
                guard !containsNonKeyParam else {
                    functionErrors.append(locatedFunction.mapConstant(.resolverFunctionContainsNonKeyParam))
                    return
                }

                let resolverFunction = locatedFunction.map {
                    ResolverFunctionDefinition(name: $0.name, parameters: $0.parameters, returnType: returnType, isThrowing: $0.isThrowing)
                }
                resolverFunctions.append(resolverFunction)
            } else if function.returnType == nil && !containsNonKeyParam {
                // This is a config function
                let configFunction = locatedFunction.map {
                    ConfigFunctionDefinition(name: $0.name, parameters: $0.parameters, isThrowing: $0.isThrowing)
                }
                configFunctions.append(configFunction)
            }
            // Other unhandled cases are acceptable, i.e. A Resolver is allowed to have helper
            // functions that return Void and have non-`Key` params, or functions that have
            // non-`Key` return types.
        }

        // Report errors if two or more Resolvers have the same return type
        let duplicateFunctionErrors = resolverFunctions.flatMapEachCombination { first, second -> [Located<DefinitionError>] in
            if first.returnType == second.returnType {
                return [
                    first.mapConstant(.duplicateReturnTypesInResolverFunctions),
                    second.mapConstant(.duplicateReturnTypesInResolverFunctions)
                ]
            } else {
                return []
            }
        }

        // Report errors if the Key contains aliases that are not being resolved
        let allReturnTypes = Set(resolverFunctions.map(\.returnType.strippingKeyAndLazyWrapper))
        let missingFunctionErrors = key.typeAliases.compactMap { alias -> Located<DefinitionError>? in
            if !allReturnTypes.contains(alias.name) {
                return alias.mapConstant(.noResolverFunctionForKey)
            } else {
                return nil
            }
        }

        // If the generated `resolve() -> Output` function has been found, remove it
        resolverFunctions.removeAll { function in
            function.name == "resolve()" && function.returnType == TypeNameConstants.output
        }

        let allErrors = functionErrors + duplicateFunctionErrors + missingFunctionErrors
        if allErrors.isEmpty {
            let resolved = ResolverDefinition(
                typeChain: definition.typeChain,
                adoptionFile: definition.adoptionFile,
                declarationFilePath: declarationFilePath,
                keyDefinition: key.value,
                outputDefinition: output.value,
                resolverFunctions: resolverFunctions,
                configFunctions: configFunctions.map(\.value)
            )
            return .left(resolved)
        } else {
            return .right(allErrors)
        }
    }
}
