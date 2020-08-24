struct SampleResolverContents {
    static var completeResolver: String {
        """
        struct TestResolver: Resolver {
            var someProperty = "abc123"

            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
                typealias Bar = Int
            }

            // Resolver functions
            func resolveFoo(bar: Key.Bar) -> Key.Foo { "abc" }
            func resolveBar() -> Key.Bar { 123 }

            // Config functions
            func configure(foo: Key.Foo, bar: Key.Bar) throws { print(foo) }

            // Ignored functions
            func thisIsIgnored(foo: Key.Foo, testing: String) { print(testing) }
        }
        """
    }

    static var circularResolverContents: String {
        """
        struct TestResolver: Resolver {
            var someProperty = "abc123"

            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
                typealias Bar = Int
                typealias Fizz = Double
                typealias Buzz = Float
            }
            ↓func resolveFoo(bar: Key.Bar) -> Key.Foo { "abc" }
            func resolveBar(fizz: Key.Fizz) -> Key.Bar { 123 }
            func resolveFizz(foo: Key.Foo) -> Key.Fizz { 1.2 }
            func resolveBuzz() -> Key.Buzz { 2.4 }
        }
        """
    }

    /// This resolver has a throwing function that returns a key
    /// that is used lazily elsewhere. This is not allowed.
    static var throwingWithLazyUsageContents: String {
        """
        struct TestResolver: Resolver {
            var someProperty = "abc123"

            typealias Output = Key.Foo
            enum Key {
                typealias Foo = String
                typealias Bar = Int
            }

            func resolveFoo(bar: Lazy<Key.Bar>) -> Key.Foo { "abc" }
            ↓func resolveBar() throws -> Key.Bar { 123 }
        }
        """
    }
}
