extension TypeName {
    /// A Resolver function can only return type-aliases present in the `Key`.
    /// In other words, if a function does not return one of these keys, it is
    /// not a Resolver function.
    var isAcceptableResolverFunctionReturnType: Bool {
        hasPrefix("Key.")
    }

    /// A Resolver function can only accepts type-aliases present in the `Key`,
    /// or `Lazy` wrappers for those type-aliases. It is an error to write a
    /// Resolver function that returns a `Key`, but has one or more arguments
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

    /// Given "Lazy<Key.Foo>", return "Key.Foo"
    var strippingLazyWrapper: String {
        stripping(prefix: "Lazy<", andSuffix: ">")
    }

    /// Given "Key.Foo", return "Foo". Given "Lazy<Key.Foo>", return "Foo"
    var strippingKeyAndLazyWrapper: String {
        strippingLazyWrapper.strippingKeyPrefix
    }

    /// Given "Key.Foo", return "Lazy<Key.Foo>"
    var lazyWrapped: String {
        "Lazy<\(self)>"
    }

    /// Return true if type is wrapped with "Lazy<...>"
    var isLazy: Bool {
        hasPrefix("Lazy<") && hasSuffix(">")
    }

    /// The name to use as the variable name for this type. Made by stripping
    /// `Key` and `Lazy`, and lowercasing the first character.
    var variableName: String {
        var stripped = strippingKeyAndLazyWrapper
        let first = stripped.removeFirst().lowercased()
        return "\(first)\(stripped)"
    }
}

extension Array where Element == TypeName {
    public var dotJoined: TypeName {
        joined(separator: ".")
    }

    public var arrowJoined: String {
        joined(separator: " → ")
    }
}
