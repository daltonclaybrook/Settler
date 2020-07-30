import SettlerKit

extension PersonResolver {
    func resolveSteve(
        birthdate: Resolved<Key.DaltonBirthdate>,
        address: Resolved<Key.DaltonAddress>,
        company: Resolved<Key.DaltonCompany>,
        pet: Resolved<Key.Rufus>
    ) -> Resolved<Key.Steve> {
        let steve = Person(
            name: "Steve",
            birthdate: birthdate.value,
            address: address.value,
            company: company.value,
            pets: [pet.value],
            parents: []
        )
        return Resolved(steve)
    }

    func resolveDaltonParents(steve: Resolved<Key.Steve>) -> Resolved<Key.DaltonParents> {
        Resolved([steve.value])
    }

    func resolveRufus() -> Resolved<Key.Rufus> {
        Resolved(Pet(name: "Rufus", age: 2, species: .dog))
    }

    func resolveWhiskers() -> Resolved<Key.Whiskers> {
        Resolved(Pet(name: "Whiskers", age: 3, species: .cat))
    }
}
