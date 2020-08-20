/// A marker protocol to tell Settler which types to treat as Resolvers.
///
/// The protocol has only two Swift requirements, but several more Settler requirements. Once you have
/// implement both of the requirements described below, you'll need to make sure your project is configured
/// to use the Settler run-script build phase in Xcode (See the docs on configuration). Once this phase has
/// been configured, you should start seeing build errors in your Resolver for keys that are missing a
/// corresponding _Resolver function_. A Resolver function looks like this:
/// ```
/// func resolvePlayer(songData: Key.SongData) -> Key.MusicPlayer {
///     AVAudioPlayer(data: songData)
/// }
/// ```
/// Resolver functions have several requirements that are all documented in
/// [Resolver.md](https://github.com/daltonclaybrook/Settler/blob/main/Resolver.md)
///
/// Once each of your keys has a corresponding Resolver function, your Xcode project will build successfully.
/// Look for a file called `[YourResolver]+Output.swift` in the same directory where your Resolver
/// is declared and add it to your Xcode project. The file contains an extension on your Resolver with a single
/// function:
/// ```
/// func resolve() -> Output {
///     // ...
/// }
/// ```
/// This is the function used by clients of your Resolver to obtain your Resolver's final output. For example:
/// ```
/// let output = MyResolver().resolve()
/// ```
public protocol Resolver {
    /// This type acts as a namespace rather than a concrete type, so the recommendation is to use an enum
    /// with no cases. Inside, add a type-alias for every object your Resolver is expected to resolve. Example:
    /// ```
    /// enum Key {
    ///     typealias MusicPlayer = AVAudioPlayer
    ///     typealias SongData = Data
    /// }
    /// ```
    /// The left-hand side of the alias is a key you choose to uniquely identifying the resolved object. On the
    /// right is the data type of the object to resolve. In some cases, it may make sense for the key to match
    /// the data type. In these cases, you will need to include the module name of the type to satisfy the
    /// compiler. For example:
    /// ```
    /// typealias SessionManager = Alamofire.SessionManager
    /// ```
    associatedtype Key
    /// This is the final type produced by your Resolver. It should take the form of a type-alias of one of the
    /// keys in your `Key` namespace. More than likely, this is a complex object requiring many (if not all)
    /// of the other dependencies listed in the `Key` namespace. Given the above example for `Key`,
    /// the `Output` type-alias might be:
    /// ```
    /// typealias Output = Key.MusicPlayer
    /// ```
    associatedtype Output
}
