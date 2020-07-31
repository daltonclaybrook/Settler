/// A marker protocol to tell Settler which types to treat as Resolvers.
///
/// A Resolver has only two requirements, `Key` and `Output`.
///
/// The `Key` type is used as a namespace to specify which kinds of objects the Resolver
/// is expected to produce. To ensure this type has no functionality of its own, it is recommended
/// that you use an `enum` with no cases. Instead of cases, this namespace should contain a
/// number of type-aliases, each one representing a unique object produced by the Resolver.
/// Consider the following example:
/// ```
/// enum Key {
///     typealias MusicPlayer = AVAudioPlayer
///     typealias DespacitoSongData = Data
/// }
/// ```
/// On the left-hand side of the type-alias is a unique key/identifier. This key is specific to your
/// application and can be whatever you choose. On the right side is the data type of the object
/// that will be resolved. You can use any type, including your own types and those imported
/// from third-party frameworks. In some cases, it may make sense for the key to match the data
/// type. In these cases, you can prefix the type with its module name to clear up compiler ambiguity:
/// ```
/// typealias SessionManager = Alamofire.SessionManager
/// ```
/// Each and every object produced by your Resolver must have a corresponding key under the
/// `Key` namespace. Don't worry, if you forget something or make a mistake, the compiler will
/// help you fix it. The beauty of Settler is that it is **completely compiler-safe!**
///
/// The other requirement of a Resolver is the `Output` type. This is the final type produced by
/// your Resolver. It should take the form of a type-alias to one of the keys in your `Key` namespace.
/// This type may depend on some or all of the other dependencies listed in the namespace. Given
/// the above example for `Key`, the `Output` type-alias might be:
/// ```
/// typealias Output = Key.MusicPlayer
/// ```
///
public protocol Resolver {
    associatedtype Key
    associatedtype Output
}
