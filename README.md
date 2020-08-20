**Settler** is a metaprogramming tool for Swift used to resolve complex dependency graphs in a way that encourages code separation and cleanliness while maintaining the safety guarantees of the Swift compiler. If an object in your Resolver cannot be resolved due to a missing or circular dependency, Settler will find it and fail compilation of your program.

## The basics

When using Settler, you are responsible for defining **Resolvers**. A Resolver is a type that is responsible for creating a _single complex object_ from a collection of dependencies, or `Keys`. The Resolver protocol has only two associated type requirements: `Key` and `Output`. Your `Output` is a type-alias to the type of the object you want your Resolver to ultimately build. Your `Key` is a collection of type-aliases to dependency types that may be required to build your `Output`. See [Resolver.md](https://github.com/daltonclaybrook/Settler/blob/main/Resolver.md) for an in-depth Resolver implementation guide.

## Compiler magic

The power (and magic ✨) of Settler lies in it's ability to parse your Resolvers in-line with the Swift compiler and report errors directly in Xcode as if it were part of the compiler itself. Once configured as a Run Script build phase in Xcode, Settler can report errors in your `Output` and `Key` types, whether your resolver functions contain invalid parameters, whether any dependencies are missing a corresponding function (or are duplicated), whether you have a circular dependency, and many more. Rest assured that if you see no reported errors in Xcode, your Resolver is correct.

## Who is Settler for?

A Swift developers, most of the objects we instantiate are fairly lightweight, requiring only a few arguments and minimal configuration, if any. e.g.

```swift
let stackView = UIStackView(arrangedSubviews: [titleLabel, iconView, button])
stackView.axis = .vertical
```

But occasionally, we are required to create objects that are quite complex. These types might have a high number of initializer parameters. They may own tens or even hundreds of child objects, all of which need to be instantiated and injected. These objects (or their dependencies) may have complex configuration requirements. In these cases, we tend to reach for **Factories** or **Builders**. These are helpful types that encapsulate the logic of creating and configuring all these objects, and expose only a few public methods for producing the single desired complex object.

But Factories can get messy _fast_. They are susceptible to tight-coupling. They can easily violate more than one of the [SOLID](https://en.wikipedia.org/wiki/SOLID) design principles including the Single-responsibility principle and the Dependency inversion principle. They can easily violate your linter rules for function length or file length because of complex configuration requirements. Team members will tend to avoid working in these types as they are difficult to comprehend and contextualize, and over time, these types may be disproportionally susceptible to [code rot](https://en.wikipedia.org/wiki/Software_rot).

Settler solves these problems by replacing your Factory with a **Resolver**. With a Resolver, you can break your Factory up into a flat collection of functions, each of which has a single responsibility: to build an object. A Resolver can be divided into many separate extensions which are not required to be co-located. It may actually be helpful to co-locate a Resolver extension with the object(s) it is responsible for creating, for example:

```swift
class MyAPIService {
    // ...
}

extension MyResolver {
    func resolveAPIService(...) -> Key.APIService {
        MyAPIService(...)
    }
}
```

## Settler as a methodology

At this point, you might be asking yourself, "Can't I do all of this on my own?" The answer is, "Absolutely!" Once you've completely built and validated your Resolver and generated your Resolver output function, what you're left with is plain ol' Swift code. This is code you could have written yourself without the help of Settler. You could even remove Settler from your project completely at this point and your Resolver would continue to function properly. But if you choose to keep Settler as an integrated part of your build pipeline, what you'll get is what you had all along while building your Resolver: compiler-level enforcement of the _Settler methodology_.

In addition to being a neat tool, Settler is a software methodology. It's a different way of thinking about building Factories for complex object graphs. Settler helps you maintain loose-coupling of components, it encourages you to think of your dependencies as pure functions. It lets you specify your configuration requirements declaratively. It even simplifies _lazy_ object creation when runtime circumstances influence the need for a particular dependency. Even if you choose not to implement Settler in your application, it might still be worth your time to understand the problem it solves and how it works.

## Licence

Settler is available under the MIT license. See [LICENSE](https://github.com/daltonclaybrook/Settler/blob/main/LICENSE) for more information.

## Attributions

This tool is powered by:

* [SourceKitten](https://github.com/jpsim/SourceKitten) - An adorable little framework and command line tool for interacting with SourceKit.
* [Swift Argument Parser](https://github.com/apple/swift-argument-parser) - Straightforward, type-safe argument parsing for Swift.
