@testable import App
import Vapor
import FluentPostgreSQL
import RoasterHammer_Shared

final class PsychicPowerTestsUtils {
    static func createPsychicPower(app: Application) throws -> (request: CreatePsychicPowerRequest, response: ArmyResponse) {
        let (_, army) = try ArmyTestsUtils.createArmy(app: app)
        let request = CreatePsychicPowerRequest(name: "Psychic Power Name",
                                                description: "Psychic Power Description",
                                                keywordIds: [])

        let armyWithWarlordTrait = try app.getResponse(to: "armies/\(army.requireID())/psychic-powers",
            method: .POST,
            headers: ["Content-Type": "application/json"],
            data: request,
            decodeTo: ArmyResponse.self)

        return (request, armyWithWarlordTrait)
    }
}
