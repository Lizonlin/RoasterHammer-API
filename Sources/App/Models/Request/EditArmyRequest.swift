import Vapor

struct EditArmyRequest: Content {
    let name: String?
    let rules: [AddRuleRequest]?

    init(name: String?, rules: [AddRuleRequest]?) {
        self.name = name
        self.rules = rules
    }
}
