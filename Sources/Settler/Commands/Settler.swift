import ArgumentParser

struct Settler: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for building complex, type-safe dependency graphs in Swift",
        subcommands: [Resolve.self]
    )
}
