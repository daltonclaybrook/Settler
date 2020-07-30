import Foundation

struct Person {
    let name: String
    let birthdate: Date
    let address: Address
    let company: Company
    let pets: [Pet]
    let parents: [Person]
}

struct Company {
    enum Industry {
        case software, other
    }

    let name: String
    let address: Address
    let industry: Industry
}

struct Pet {
    enum Species {
        case cat, dog
    }

    let name: String
    let age: Int
    let species: Species
}

struct Address {
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let zipCode: String
}
