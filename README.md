![Build Status](https://github.com/daltonclaybrook/Settler/workflows/Swift/badge.svg)

**Settler** is a Swift metaprogramming tool used to resolve complex dependency graphs in a way that encourages code separation and cleanliness while maintaining the safety guarantees of the compiler. If an object in your resolver cannot be resolved due to a missing or circular dependency, Settler will find it and bottom out compilation of your program.

## The basics

When using Settler, you define **resolvers**. A resolver is a type responsible for creating a _single complex object_ from a collection of dependencies, or `Keys`.

The `Resolver` protocol has two associated types: `Key` and `Output`. Your `Output` is a type-alias to the type of the object you want your resolver to ultimately build. `Key` is a collection of type-aliases — in the form of a caseless enumeration — for the types your resolver is capable of building, including `Output`. Most of the `Key` members are direct or indirect dependencies of your final `Output` type.

Each alias in `Key` needs a corresponding resolver function. You specify dependencies of your `Key` member simply by defining parameters in your resolver function. Each parameter must also be a member of `Key`. The following is a small but complete example of a `Resolver` conformance:

```swift
struct PlayerResolver: Resolver {
    typealias Output = Key.MusicPlayer

    enum Key {
        typealias SongData = Data
        typealias MusicPlayer = AVAudioPlayer
    }

    func resolveSongData() -> Key.SongData {
        Data(…)
    }

    func resolvePlayer(songData: Key.SongData) throws -> Key.MusicPlayer {
        try AVAudioPlayer(data: songData)
    }
}
```

>Note: This is a trivial example which on its own may not warrant a special “resolver,” but as we’ll see below in the “Who is Settler for?” section, a resolver can be helpful in the development and maintenance of large and dense dependency graphs.

See [Resolver.md](https://github.com/daltonclaybrook/Settler/blob/main/Resolver.md) for an in-depth `Resolver` implementation guide.

See the [SettlerDemo directory](https://github.com/daltonclaybrook/Settler/tree/main/Sources/SettlerDemo) for a more detailed resolver example.

## Installation

### Using [CocoaPods](https://cocoapods.org/):

Add the following line to your Podfile:

```ruby
pod 'Settler'
```

This will download the Settler binary and framework to your `Pods` folder during your next `pod install`. In Xcode, add a new Run Script Build Phase for your app _directly above the Compile Sources phase_ with the following contents:

```bash
${PODS_ROOT}/Settler/bin/settler resolve
# Or customize with some options:
# ${PODS_ROOT}/Settler/bin/settler resolve --sources MySources --indent tabs
```

### Using [Swift Package Manager](https://swift.org/package-manager/):

In Xcode, you can add this package to your project by selecting File ➡ Swift Packages ➡ Add Package Dependency… Search for "Settler" and follow the prompts. You will need to select `Settler` and not `SettlerFramework`. (The latter is used internally by the Settler CLI)

If you use a Package.swift file instead, add the following line inside of your package dependencies array:

```swift
.package(url: "https://github.com/daltonclaybrook/Settler", from: "0.1.0"),
```

Now add Settler as a dependency of any relevant targets:

```swift
.target(name: "MyApp", dependencies: ["Settler"]),
```

>Note: This will only install the framework dependency in your project. You will also need to install the Settler binary and add a Run Script Build Phase to your project. You can do this a number of ways such as using Mint, CocoaPods, or by compiling from source.

### Using [Mint](https://github.com/yonaskolb/mint):

Run the following command in Terminal:

```bash
$ mint install daltonclaybrook/Settler
```

In Xcode, add a new Run Script Build Phase for your app _directly above the Compile Sources phase_ with the following contents:

```bash
settler resolve
# Or customize with some options:
# settler resolve --sources MySources --indent tabs
```

>Note: This will only install the Settler binary. You will also need to add `Settler.framework` to your Xcode project. This can be done using CocoaPods, Swift Package Manager, or manually using artifacts downloaded from the [Releases](https://github.com/daltonclaybrook/Settler/releases) page.

### Compiling from source:

You can also install Settler by cloning this repo and running:

```bash
make install
```

>The same note applies about importing `Settler.framework` from the Mint section above.

## Compiler magic

The power (and magic ✨) of Settler lies in its ability to parse your resolvers alongside the Swift compiler and report errors directly in Xcode as if it were part of the toolchain itself.

By defining each dependency as a function, and by using `Key` members as inputs and outputs of those functions, Settler is able to resolve your dependency graph in the correct order, ignoring types that are unused, lazily initializing dependencies where necessary, and reporting errors when things aren’t quite right.

Once configured as a Run Script build phase in Xcode, Settler can report errors in your `Output` and `Key` types, whether your resolver functions contain invalid parameters, whether any dependencies are missing their corresponding function (or are duplicated), whether there’s a circular dependency, and much more. Rest assured that if you see no reported errors, your `Resolver` implementation is correct.

## Who is Settler for?

As Swift developers, the types we instantiate are generally lightweight, requiring a few arguments and minimal configuration, if any. e.g.

```swift
let stackView = UIStackView(arrangedSubviews: [titleLabel, iconView, button])
stackView.axis = .vertical
```

But occasionally, we’re required to create types that are quite complex. These types might require a large number of initialization parameters. They may hold onto dozens of child dependencies, all of which need to be instantiated and injected. These objects (or their dependencies) may have complex configuration requirements. In these cases, we tend to reach for **factories** or **builders**. These are helpful types that encapsulate the logic of creating and configuring all these objects and expose only a few public methods for producing the single desired complex object.

But factories can get messy _fast_. They’re susceptible to coupling. They can violate more than one of the [SOLID](https://en.wikipedia.org/wiki/SOLID) design principles including the single-responsibility and dependency principles. They can violate linter rules for function or file lengths because of long configuration requirements. Team members will tend to avoid working with these types as they’re difficult to comprehend and contextualize, and over time, these types may accrue technical debt.

Settler solves these problems by replacing factories with resolvers. With a `Resolver`, you can flatten your factory into a collection of functions, each of which has a single responsibility: to build an object. A resolver can be divided into many separate extensions that are not required to be co-located. It may actually be helpful to co-locate a Resolver extension with the object(s) it is responsible for creating, for example:

```swift
final class MyAPIService {
    // …
}

extension MyResolver {
    func resolveAPIService(…) -> Key.APIService {
        MyAPIService(…)
    }
}
```

## Settler as a methodology

At this point, you might be asking yourself, “Can’t I do all of this on my own?” The answer is, “Absolutely!” Once you've built and validated your resolver and generated your resolver output function, what you’re left with is plain ol’ Swift code. This is code you could have written yourself without the help of Settler. You could even remove Settler from your project at this point and your resolver would continue to function properly. But if you choose to keep Settler as an integrated part of your build pipeline, what you’ll get is what you had all along while building your resolver: compiler-level enforcement of the _Settler methodology_.

In addition to being a neat tool, Settler is a software methodology. It’s a different way of thinking about building factories for complex object graphs. Settler helps you maintain loose coupling of components, it encourages you to think of your dependencies as pure functions. It lets you specify configuration requirements declaratively. It even simplifies _lazy_ object creation when runtime characteristics determine the need for a particular dependency. Even if you choose not to bring Settler into your application, it’s still the worth the time to understand this approach and how it works, generally.

## License

Settler is available under the MIT license. See [LICENSE](https://github.com/daltonclaybrook/Settler/blob/main/LICENSE) for more information.

## Attributions

This tool is powered by:

* [SourceKitten](https://github.com/jpsim/SourceKitten) - an adorable little framework and command line tool for interacting with SourceKit.
* [Swift Argument Parser](https://github.com/apple/swift-argument-parser) - straightforward, type-safe argument parsing for Swift.
