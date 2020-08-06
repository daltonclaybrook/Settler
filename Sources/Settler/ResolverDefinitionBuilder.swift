import SourceKittenFramework

enum TypeNameConstants {
    static let resolver = "Resolver"
    static let key = "Key"
    static let output = "Output"
}

struct ResolverDefinitionBuilder {
    static func buildWith(swiftFiles: [String]) throws -> [ResolverDefinition] {
        var definitions = try swiftFiles.flatMap { filePath -> [ResolverDefinition] in
            guard let file = File(path: filePath) else { return [] }
            let typeChains = try getTypeChainsImplementingResolver(in: file)
            return typeChains.map {
                ResolverDefinition(typeChain: $0, adoptionFilePath: filePath)
            }
        }

        let errors = try swiftFiles.reduce(into: [DefinitionError]()) { result, filePath in
            guard let file = File(path: filePath) else { return }
            let structure = try Structure(file: file)
            let fileMembers = structure.dictionary.substructure ?? []

            definitions.mutableForEach { definition in
                let matchingMembers = findFileMembersMatching(typeChain: definition.typeChain, in: fileMembers)
                let errors = update(
                    definition: &definition,
                    withMatchingMembers: matchingMembers,
                    in: file
                )
                result.append(contentsOf: errors)
            }
        }

        print(errors)
        return definitions
    }

    // MARK: - Helpers

    private static func getTypeChainsImplementingResolver(in file: File) throws -> [TypeNameChain] {
        let structure = try Structure(file: file)
        let fileMembers = structure.dictionary.substructure ?? []
        return fileMembers.flatMap { fileMember in
            findTypeChains(named: TypeNameConstants.resolver, namespace: [], in: fileMember)
        }
    }

    private static func findTypeChains(named: TypeName, namespace: TypeNameChain, in structure: [String: SourceKitRepresentable]) -> [TypeNameChain] {
        guard let typeName = structure.name else { return [] }

        let namespaceAndType = namespace + [typeName]
        // Recurse into deeper members to find matching chains
        var chains = structure.substructure?.flatMap { deeperMember in
            findTypeChains(named: named, namespace: namespaceAndType, in: deeperMember)
        } ?? []

        let inheritedTypeNames = structure.inheritedTypes?
            .compactMap { possibleType in
                (possibleType as? [String: SourceKitRepresentable])?.name
            } ?? []

        if inheritedTypeNames.contains(named) {
            chains.append(namespaceAndType)
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
    private static func update(definition: inout ResolverDefinition, withMatchingMembers members: [[String: SourceKitRepresentable]], in file: File) -> [DefinitionError] {
        members.flatMap { member in
            update(definition: &definition, member: member, in: file)
        }
    }

    private static func update(definition: inout ResolverDefinition, member: [String: SourceKitRepresentable], in file: File) -> [DefinitionError] {
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

    private static func updateKey(for definition: inout ResolverDefinition, kind: SwiftDeclarationKind, enumStructure: [String: SourceKitRepresentable], file: File) -> [DefinitionError] {
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

        definition.keyDefinition = KeyDefinition(typeAliases: typeAliasResults.compactMap(\.successValue))
        return typeAliasResults.compactMap(\.failureError)
    }

    private static func updateOutput(for definition: inout ResolverDefinition, kind: SwiftDeclarationKind, outputStructure: [String: SourceKitRepresentable], file: File) -> [DefinitionError] {
        switch TypeAliasDefinitionBuilder.buildFrom(aliasStructure: outputStructure, in: file) {
        case .success(let output):
            definition.outputDefinition = output
            return []
        case .failure(let error):
            return [DefinitionError(kind: error.outputErrorKind, file: file, offset: outputStructure.offset)]
        }
    }

    private static func updateFunctions(for definition: inout ResolverDefinition, functionName: String, functionStructure: [String: SourceKitRepresentable], file: File) -> [DefinitionError] {
        let returnType = functionStructure.typeName
        let parameterStructures = functionStructure.substructure ?? []
        let parameterResults = parameterStructures.map { structure -> Result<ResolverFunction.Parameter, DefinitionError> in
            guard let kind = structure.declarationKind,
                kind == .varParameter,
                let name = structure.name,
                let typeName = structure.typeName else {
                    let error = DefinitionError(kind: .unexpectedSyntaxElement, file: file, offset: structure.offset)
                    return .failure(error)
            }

            let parameter = ResolverFunction.Parameter(name: name, typeName: typeName)
            return .success(parameter)
        }

        let parameterErrors = parameterResults.compactMap(\.failureError)
        // Only create a resolver function if there are no errors
        if !parameterErrors.isEmpty {
            let parameters = parameterResults.compactMap(\.successValue)
            let function = ResolverFunction(name: functionName, parameters: parameters, returnType: returnType)
            definition.functions.append(function)
        }
        return parameterErrors
    }
}
