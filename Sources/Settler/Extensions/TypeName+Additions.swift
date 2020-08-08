extension TypeName {
    /// A resolver function can only return type-aliases present in the `Key`.
    /// In other words, if a function does not return one of these keys, it is
    /// not a resolver function.
    var isAcceptableResolverFunctionReturnType: Bool {
        hasPrefix("Key.")
    }

    /// A resolver function can only accepts type-aliases present in the `Key`,
    /// or `Lazy` wrappers for those type-aliases. It is an error to write a
    /// resolver function that returns a `Key`, but has one or more arguments
    /// that aren't `Keys` (or Lazy Keys).
    var isAcceptableResolverFunctionParameter: Bool {
        if hasPrefix("Key.") {
            return true
        } else if hasPrefix("Lazy<Key.") && hasSuffix(">") {
            return true
        } else {
            return false
        }
    }

    /// Given "Key.Foo", return "Foo"
    var strippingKeyPrefix: String {
        strippingPrefix("Key.")
    }

    /// Given "Key.Foo", return "Foo". Given "Lazy<Key.Foo>", return "Foo"
    var strippingKeyAndLazyWrapper: String {
        stripping(prefix: "Lazy<", andSuffix: ">").strippingPrefix("Key.")
    }
}

extension TypeNameChain {
    var dotJoined: TypeName {
        joined(separator: ".")
    }
}
