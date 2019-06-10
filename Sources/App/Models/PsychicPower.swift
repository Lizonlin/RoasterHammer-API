import Vapor
import FluentPostgreSQL

final class PsychicPower: PostgreSQLModel {
    var id: Int?
    var name: String
    var description: String
    var armyId: Int
    var army: Parent<PsychicPower, Army> {
        return parent(\.armyId)
    }
    var units: Siblings<PsychicPower, Unit, UnitPsychicPower> {
        return siblings()
    }
    var selectedUnits: Siblings<PsychicPower, SelectedUnit, SelectedUnitPsychicPower> {
        return siblings()
    }
    var keywords: Siblings<PsychicPower, Keyword, PsychicPowerKeyword> {
        return siblings()
    }

    init(name: String, description: String, armyId: Int) {
        self.name = name
        self.description = description
        self.armyId = armyId
    }
}

extension PsychicPower: Content { }
extension PsychicPower: PostgreSQLMigration { }
