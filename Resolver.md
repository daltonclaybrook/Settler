# Resolver Implementation

In order to create a Resolver, you must create a type that implements the `Resolver` protocol.
A Resolver has only two requirements, `Key` and `Output`.

The `Key` type is used as a namespace to specify which kinds of objects the Resolver
is expected to produce. To ensure this type has no functionality of its own, it is recommended
that you use an `enum` with no cases. Instead of cases, this namespace should contain a
number of type-aliases, each one representing a unique object produced by the Resolver.
Consider the following example:

```swift
enum Key {
    typealias MusicPlayer = AVAudioPlayer
    typealias SongData = Data
}
```

On the left-hand side of the type-alias is a unique key/identifier. This key is specific to your
application and can be whatever you choose. On the right side is the data type of the object
that will be resolved. You can use any type, including your own types and those imported
from third-party frameworks. In some cases, it may make sense for the key to match the data
type. In these cases, you can prefix the type with its module name to fix type ambiguity:

```swift
enum Key {
    typealias SessionManager = Alamofire.SessionManager
}
```

Each and every object produced by your Resolver must have a corresponding key under the
`Key` namespace. Don't worry, if you forget something or make a mistake, the compiler will
help you fix it. The beauty of Settler is that it is **completely compiler-safe.**

The other requirement of a Resolver is the `Output` type. This is the final type produced by
your Resolver. It should take the form of a type-alias of one of the keys in your `Key` namespace.
More than likely, this is a complex object requiring many (if not all) of the other dependencies listed
in the `Key` namespace. Given the above example for `Key`, the `Output` type-alias might be:

```swift
typealias Output = Key.MusicPlayer
```

At this point, you might be asking yourself, "How do I actually resolve dependencies?" After all,
we've already satisfied the full requirements of the protocol with `Key` and `Output`. Although
we have indeed satisfied all of the *Swift* requirements for this protocol, we have yet to satisfy
the *Settler* requirements for a Resolver. If you've configured the Settler build phase (see the docs
on configuration), you need only build your project to see that there's still work to be done. If things
are configured correctly, you should see a compiler error for each key indicating that a resolver
function could not be found. To fix these errors, you must implement resolver functions.

A resolver function does one thing: create one of the dependencies declared in the `Key` namespace.
There will be exactly as many resolver functions as there are type-aliases in the namespace. A resolver
function declares its dependencies by accepting arguments. Though, the function's argument list can
only contain other keys found in the `Key` namespace. If your resolver function has other external
dependencies, consider including them in your Resolver's initializer. The following is an example
resolver function:

```swift
func resolvePlayer(songData: Key.SongData) throws -> Key.MusicPlayer {
    try AVAudioPlayer(data: songData)
}
```

Things to note about resolver functions:

* They must be a member of your Resolver type, but they can be spread out over multiple extensions,
as long as those extensions are included in the Settler `sources` directory.
* The return type and every argument type must be under the `Key` namespace.
* You can name the functions however you like! There are no naming requirements (e.g. they
don't need to be prefixed with "resolve").
* They can have an access control level of `internal` or `public`, but not `private`.
* They can `throw`, but if any single resolver function `throws`, the final output resolver function
will `throw` as well.
* Your Resolver type may contain generated and/or stored properties, custom initializers, and a
deinitializer (`deinit`), but it must not contain any functions that are not resolver functions. These
will cause a build failure.

So, you've implemented all of your resolver functions and you have no more compiler errors. All
that's left to do is obtain the `Output` object from your final resolver function. Assuming your project
is properly configured (see the docs on configuration), when you build your app, a new file will be
generated in the same directory as your Resolver declaration called
`[YourResolver]+Output.swift`. Add this file to your app target in Xcode. This generated
file contains an extension on your Resolver with a single function:

```swift
func resolve() -> Output {
    // ...
}
```

(Depending on whether any of your resolver functions are `throwing` functions, this function may
also be marked as `throws`)

All that's left to do is instantiate your Resolver, call the `resolve()` function, and make use of your
final resolved object. Rest assured, if any dependency is missing (or duplicated), Settler will find it.
