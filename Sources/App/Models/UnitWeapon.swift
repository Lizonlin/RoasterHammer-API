import Vapor
import FluentPostgreSQL

final class UnitWeapon: PostgreSQLPivot, ModifiablePivot {

    typealias Left = Unit
    typealias Right = Weapon

    static var leftIDKey: WritableKeyPath<UnitWeapon, Int> = \.unitId
    static var rightIDKey: WritableKeyPath<UnitWeapon, Int> = \.weaponId

    var id: Int?
    var unitId: Int
    var weaponId: Int
    var minQuantity: Int = 1
    var maxQuantity: Int = 1

    init(_ left: Unit, _ right: Weapon) throws {
        unitId = try left.requireID()
        weaponId = try right.requireID()
    }

}

extension UnitWeapon: Content { }
