import Vapor

struct CreateDetachmentRequest: Content {
    var name: String
    var commandPoints: Int
}
