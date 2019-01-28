import FluentPostgreSQL

struct CreateModelWeapon: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(ModelWeapon.self, on: conn, closure: { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.modelId)
            builder.field(for: \.weaponId)
            builder.field(for: \.minQuantity)
            builder.field(for: \.maxQuantity)
            builder.reference(from: \.modelId, to: \Model.id, onDelete: .cascade)
            builder.reference(from: \.weaponId, to: \Weapon.id, onDelete: .cascade)
        })
    }

    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.delete(ModelWeapon.self, on: conn)
    }
}
