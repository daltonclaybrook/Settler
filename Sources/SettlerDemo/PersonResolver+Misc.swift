import SettlerKit

extension PersonResolver {
    func resolveSteve(
        birthdate: Key.DaltonBirthdate,
        address: Key.DaltonAddress,
        company: Key.DaltonCompany,
        pet: Key.Rufus
    ) -> Key.Steve {
        Person(
            name: "Steve",
            birthdate: birthdate,
            address: address,
            company: company,
            pets: [pet],
            parents: []
        )
    }

    func resolveDaltonParents(steve: Key.Steve) -> Key.DaltonParents {
        [steve]
    }

    func resolveRufus() -> Key.Rufus {
        Pet(name: "Rufus", age: 2, species: .dog)
    }

    func resolveWhiskers() -> Key.Whiskers {
        Pet(name: "Whiskers", age: 3, species: .cat)
    }
}
