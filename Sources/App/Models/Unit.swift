import Vapor
import FluentPostgreSQL

final class Unit: PostgreSQLModel {
    var id: Int?
    var name: String
    var cost: Int
    var characteristics: Children<Unit, Characteristics> {
        return children(\.unitId)
    }
    var roles: Siblings<Unit, Role, UnitRole> {
        return siblings()
    }
    var rules: Siblings<Unit, Rule, UnitRule> {
        return siblings()
    }

    init(name: String, cost: Int) {
        self.name = name
        self.cost = cost
    }

}

extension Unit: Content { }
extension Unit: PostgreSQLMigration { }
