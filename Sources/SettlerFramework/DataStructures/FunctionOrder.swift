/// Represents a call of a particular Resolver function inside of the
/// generated `resolve()` method of a Resolver
public struct FunctionCall {
    public let definition: ResolverFunctionDefinition
    public let isLazy: Bool
}

public struct FunctionSection {
    public let calls: [FunctionCall]
}

public struct FunctionOrder {
    public let sections: [FunctionSection]
}

public struct OrderedResolverDefinition {
    public let definition: ResolverDefinition
    public let functionOrder: FunctionOrder

    public init(definition: ResolverDefinition, functionOrder: FunctionOrder) {
        self.definition = definition
        self.functionOrder = functionOrder
    }
}
