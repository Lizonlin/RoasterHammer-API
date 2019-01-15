import Vapor
import Authentication

/// Register your application's routes here.
public func routes(_ router: Router) throws {

    // Authentication middleware
    let basicAuthMiddleware = Customer.basicAuthMiddleware(using: BCryptDigest())
    let protectedBasicRouter = router.grouped(basicAuthMiddleware)
    let tokenAuthMiddleware = Customer.tokenAuthMiddleware()
    let protectedAuthRouter = router.grouped(tokenAuthMiddleware)

    // User
    let userController = UserController()
    router.post("users/register", use: userController.createUser)
    protectedBasicRouter.post("users/login", use: userController.loginUser)
    protectedAuthRouter.get("users", use: userController.getUser)

    // Game
    let gameController = GameController()
    protectedAuthRouter.post("games", use: gameController.createGame)
    protectedAuthRouter.get("games", use: gameController.getGames)

    // Roaster
    let roasterController = RoasterController()
    protectedAuthRouter.post("games", String.parameter, "roasters", use: roasterController.createRoster)
    protectedAuthRouter.get("games", String.parameter, "roasters", use: roasterController.getRoasters)
}
