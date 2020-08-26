// Generated using Settler 0.1.1 - https://github.com/daltonclaybrook/Settler
// DO NOT EDIT
import Settler

extension PersonResolver {
    func resolve() -> Output {
        // Resolver functions
        let daltonBirthdate = resolveDaltonBirthdate()
        let daltonAddress = Lazy {
            self.resolveDaltonAddress()
        }
        let rufus = resolveRufus()
        let whiskers = resolveWhiskers()
        let daltonCompany = Lazy {
            self.resolveDaltonCompany(address: daltonAddress)
        }
        let steve = resolveSteve(birthdate: daltonBirthdate, address: daltonAddress.resolve(), company: daltonCompany.resolve(), pet: rufus)
        let daltonParents = resolveDaltonParents(steve: steve)
        let dalton = resolveDalton(birthdate: daltonBirthdate, address: daltonAddress.resolve(), company: daltonCompany.resolve(), rufus: rufus, whiskers: whiskers, parents: daltonParents)
        // Configuration
        configure(whiskers: whiskers, company: daltonCompany)
        return dalton
    }
}
