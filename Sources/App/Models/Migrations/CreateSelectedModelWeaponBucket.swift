import FluentPostgreSQL

struct CreateSelectedModelWeaponBucket: PostgreSQLMigration {
    static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.create(SelectedModelWeaponBucket.self, on: conn, closure: { (builder) in
            builder.field(for: \.id, isIdentifier: true)
            builder.field(for: \.modelId)
            builder.field(for: \.weaponBucketId)
            builder.reference(from: \.modelId, to: \SelectedModel.id, onDelete: .cascade)
            builder.reference(from: \.weaponBucketId, to: \WeaponBucket.id, onDelete: .cascade)
            builder.unique(on: \.modelId, \.weaponBucketId)
        })
    }

    static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return PostgreSQLDatabase.delete(SelectedModelWeaponBucket.self, on: conn)
    }
}
