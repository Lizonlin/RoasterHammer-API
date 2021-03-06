import Vapor
import FluentPostgreSQL

final class Rule: PostgreSQLModel {
    var id: Int?
    var name: String
    var description: String

    init(name: String, description: String) {
        self.name = name
        self.description = description
    }
}

extension Rule: Content { }
extension Rule: PostgreSQLMigration { }

extension Rule {
    var games: Siblings<Rule, Game, GameRule> {
        return siblings()
    }
}

extension Rule {
    var roasters: Siblings<Rule, Roaster, RoasterRule> {
        return siblings()
    }
}

extension Rule {
    var armies: Siblings<Rule, Army, ArmyRule> {
        return siblings()
    }
}

extension Rule {
    var units: Siblings<Rule, Unit, UnitRule> {
        return siblings()
    }
}

extension Rule {
    var factions: Siblings<Rule, Faction, FactionRule> {
        return siblings()
    }
}
