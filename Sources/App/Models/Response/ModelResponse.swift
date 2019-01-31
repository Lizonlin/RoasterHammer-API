import Vapor

struct ModelResponse: Content {
    let id: Int
    let name: String
    let weaponQuantity: Int
    let characteristics: Characteristics
    let weapons: [WeaponResponse]

    init(model: Model,
         characteristics: Characteristics,
         weapons: [WeaponResponse]) throws {
        self.id = try model.requireID()
        self.name = model.name
        self.weaponQuantity = model.weaponQuantity
        self.characteristics = characteristics
        self.weapons = weapons
    }
}