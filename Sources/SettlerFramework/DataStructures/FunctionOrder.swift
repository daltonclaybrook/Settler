/// Represents a call of a particular Resolver function inside of the
/// generated `resolve()` method of a Resolver
public struct FunctionCall {
    public let definition: ResolverFunctionDefinition
    public let isLazy: Bool
}

public struct OrderedResolverDefinition {
    public let definition: ResolverDefinition
    public let orderedCalls: [FunctionCall]

    public init(definition: ResolverDefinition, orderedCalls: [FunctionCall]) {
        self.definition = definition
        self.orderedCalls = orderedCalls
    }
}
