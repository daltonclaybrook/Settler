// Generated using Settler 0.1.0 - https://github.com/daltonclaybrook/Settler
// DO NOT EDIT

extension PersonResolver {
    func resolve() -> Output {
        // Resolver phase 1
        let daltonBirthdate = resolveDaltonBirthdate()
        let daltonAddress = resolveDaltonAddress()
        let rufus = resolveRufus()
        let whiskers = resolveWhiskers()
        // Resolver phase 2
        let daltonCompany = resolveDaltonCompany(address: daltonAddress)
        // Resolver phase 3
        let steve = resolveSteve(birthdate: daltonBirthdate, address: daltonAddress, company: daltonCompany, pet: rufus)
        // Resolver phase 4
        let daltonParents = resolveDaltonParents(steve: steve)
        // Resolver phase 5
        let dalton = resolveDalton(birthdate: daltonBirthdate, address: daltonAddress, company: daltonCompany, rufus: rufus, whiskers: whiskers, parents: daltonParents)

        return dalton
    }
}
