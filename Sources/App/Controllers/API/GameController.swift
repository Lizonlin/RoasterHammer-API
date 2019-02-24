import Vapor
import FluentPostgreSQL
import RoasterHammer_Shared

final class GameController {

    // MARK: - Public Functions

    func createGame(_ req: Request) throws -> Future<GameResponse> {
        let customer = try req.requireAuthenticated(Customer.self)
        return Game(name: "Warhammer 40,000", version: 8).save(on: req)
            .flatMap(to: Game.self, { game in
                return customer.games.attach(game, on: req).then({ _ in
                    return req.future(game)
                })
            })
            .flatMap(to: GameResponse.self, { game in
                return try self.gameResponse(forGame: game, conn: req)
            })
    }

    func games(_ req: Request) throws -> Future<[GameResponse]> {
        let customer = try req.requireAuthenticated(Customer.self)
        return try customer.games
            .query(on: req)
            .all()
            .flatMap(to: [GameResponse].self, { games in
                let gameResponseFutures = try games.map { try self.gameResponse(forGame: $0, conn: req) }
                return gameResponseFutures.flatten(on: req)
            })
    }

    func gameById(_ req: Request) throws -> Future<GameResponse> {
        let customer = try req.requireAuthenticated(Customer.self)
        let gameId = try req.parameters.next(Int.self)
        return try customer.games
            .query(on: req)
            .filter(\.id == gameId)
            .first()
            .unwrap(or: RoasterHammerError.gameIsMissing.error())
            .flatMap(to: GameResponse.self, { game in
                return try self.gameResponse(forGame: game, conn: req)
            })
    }

    // MARK: - Private Functions

    private func gameResponse(forGame game: Game,
                              conn: DatabaseConnectable) throws -> Future<GameResponse> {
        let roastersFuture = try game.roasters.query(on: conn).all()
        let rulesFuture = try game.rules.query(on: conn).all()

        return flatMap(to: GameResponse.self, roastersFuture, rulesFuture, { (roasters, rules) in
            let roasterController = RoasterController()
            let roasterResponses = try roasters
                .map { try roasterController.roasterResponse(forRoaster: $0, conn: conn) }
                .flatten(on: conn)

            return roasterResponses.map(to: GameResponse.self, { roasters in
                let gameDTO = GameDTO(id: try game.requireID(),
                                      name: game.name,
                                      version: game.version)
                let rulesResponse = RuleController().rulesResponse(forRules: rules)
                return GameResponse(game: gameDTO, roasters: roasters, rules: rulesResponse)
            })
        })
    }

}
