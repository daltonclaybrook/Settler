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

struct OrderedResolverDefinition {
    let definition: ResolverDefinition
    let functionOrder: FunctionOrder
}
