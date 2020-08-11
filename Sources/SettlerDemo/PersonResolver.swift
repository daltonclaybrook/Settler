import Foundation
import SettlerKit

// 👨‍👨‍👧‍👦👨‍👨‍👧‍👦👨‍👨‍👧‍👦👨‍👨‍👧‍👦
enum ResolverError: Error {
    case dateError
}

struct PersonResolver: Resolver {
    typealias Output = Key.Dalton

    enum Key {
        typealias Dalton = Person
        typealias DaltonBirthdate = Date
        typealias DaltonAddress = Address
        typealias DaltonCompany = Company
        typealias DaltonParents = [Person]
        typealias Steve = Person
        typealias Rufus = Pet
        typealias Whiskers = Pet
    }
}

extension PersonResolver {
    func resolveDalton(
        birthdate: Key.DaltonBirthdate,
        address: Key.DaltonAddress,
        company: Key.DaltonCompany,
        rufus: Key.Rufus,
        whiskers: Key.Whiskers,
        parents: Key.DaltonParents
    ) -> Key.Dalton {
        Person(
            name: "Dalton",
            birthdate: birthdate,
            address: address,
            company: company,
            pets: [rufus, whiskers],
            parents: parents
        )
    }

    func resolveDaltonBirthdate() -> Key.DaltonBirthdate {
        let components = DateComponents(year: 1989, month: 9, day: 25)
        return Calendar.current.date(from: components)!
    }

    func resolveDaltonAddress() -> Key.DaltonAddress {
        Address(
            line1: "123 Awesome St",
            line2: nil,
            city: "New York",
            state: "NY",
            zipCode: "10001"
        )
    }

    func resolveDaltonCompany(address: Lazy<Key.DaltonAddress>) -> Key.DaltonCompany {
        Company(
            name: "Peloton",
            address: address.resolve(),
            industry: .software
        )
    }
}
