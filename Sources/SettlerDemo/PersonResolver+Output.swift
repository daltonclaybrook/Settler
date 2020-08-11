// Generated using Settler 0.1.0 - https://github.com/daltonclaybrook/Settler
// DO NOT EDIT
import SettlerKit

extension PersonResolver {
    func resolve() -> Output {
        // Resolver phase 1
        let daltonBirthdate = resolveDaltonBirthdate()
        let daltonAddress = Lazy {
            self.resolveDaltonAddress()
        }
        let rufus = resolveRufus()
        let whiskers = resolveWhiskers()
        // Resolver phase 2
        let daltonCompany = Lazy {
            self.resolveDaltonCompany(address: daltonAddress)
        }
        // Resolver phase 3
        let steve = resolveSteve(birthdate: daltonBirthdate, address: daltonAddress.resolve(), company: daltonCompany.resolve(), pet: rufus)
        // Resolver phase 4
        let daltonParents = resolveDaltonParents(steve: steve)
        // Resolver phase 5
        let dalton = resolveDalton(birthdate: daltonBirthdate, address: daltonAddress.resolve(), company: daltonCompany.resolve(), rufus: rufus, whiskers: whiskers, parents: daltonParents)
        // Configuration
        configure(whiskers: whiskers, company: daltonCompany)
        return dalton
    }
}
