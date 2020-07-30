import Foundation
import SettlerKit

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
        birthdate: Resolved<Key.DaltonBirthdate>,
        address: Resolved<Key.DaltonAddress>,
        company: Resolved<Key.DaltonCompany>,
        rufus: Resolved<Key.Rufus>,
        whiskers: Resolved<Key.Whiskers>,
        parents: Resolved<Key.DaltonParents>
    ) -> Resolved<Key.Dalton> {
        Resolved(Person(
            name: "Dalton",
            birthdate: birthdate.value,
            address: address.value,
            company: company.value,
            pets: [rufus.value, whiskers.value],
            parents: parents.value
        ))
    }

    func resolveDaltonBirthdate() throws -> Resolved<Key.DaltonBirthdate> {
        let components = DateComponents(year: 1989, month: 9, day: 25)
        if let birthdate = Calendar.current.date(from: components) {
            return Resolved(birthdate)
        } else {
            throw ResolverError.dateError
        }
    }

    func resolveDaltonAddress() -> Resolved<Key.DaltonAddress> {
        Resolved(Address(
            line1: "123 Awesome St",
            line2: nil,
            city: "New York",
            state: "NY",
            zipCode: "10001"
        ))
    }

    func resolveDaltonCompany(address: Resolved<Key.DaltonAddress>) -> Resolved<Key.DaltonCompany> {
        Resolved(Company(
            name: "Peloton",
            address: address.value,
            industry: .software
        ))
    }
}
