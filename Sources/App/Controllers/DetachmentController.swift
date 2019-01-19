import Vapor
import FluentPostgreSQL

final class DetachmentController {

    // MARK: - Public Functions

    func createDetachment(_ req: Request) throws -> Future<Detachment> {
        return try req.content.decode(Detachment.self)
            .flatMap(to: Detachment.self, { detachment in
                return detachment.save(on: req)
                    .flatMap(to: Detachment.self, { detachment in
                        return try self.generateRoles(forDetachment: detachment, conn: req)
                    })
            })
    }

    func detachments(_ req: Request) throws -> Future<[Detachment]> {
        return Detachment.query(on: req).all()
    }

    func addDetachmentToArmy(_ req: Request) throws -> Future<ArmyResponse> {
        _ = try req.requireAuthenticated(Customer.self)
        let armyId = try req.parameters.next(Int.self)

        return try req.content.decode(AddDetachmentToArmyRequest.self)
            .flatMap(to: Detachment.self, { request in
                return Detachment.find(request.detachmentId, on: req).unwrap(or: RoasterHammerError.detachmentIsMissing)
            })
            .flatMap(to: Army.self, { detachment in
                return Army.find(armyId, on: req).unwrap(or: RoasterHammerError.armyIsMissing).then({ army in
                    return army.detachments.attach(detachment, on: req).then({ _ in
                        return req.future(army)
                    })
                })
            })
            .flatMap(to: ArmyResponse.self, { army in
                let armyController = ArmyController()
                return try armyController.armyResponse(forArmy: army, conn: req)
            })
    }

    // MARK: - Utility Functions

    func roleResponse(forRole role: Role,
                      conn: DatabaseConnectable) throws -> Future<RoleResponse> {
        return try role.units.query(on: conn).all()
            .flatMap(to: [UnitResponse].self, { units in
                let unitController = UnitController()
                return try units.map { try unitController.unitResponse(forUnit: $0, conn: conn) }.flatten(on: conn)
            })
            .map(to: RoleResponse.self, { units in
                return try RoleResponse(role: role, units: units)
            })
    }

    func detachmentResponse(forDetachment detachment: Detachment,
                            conn: DatabaseConnectable) throws -> Future<DetachmentResponse> {
        return try detachment.roles.query(on: conn).all()
            .flatMap(to: [RoleResponse].self, { roles in
                return try roles.map { try self.roleResponse(forRole: $0, conn: conn) }.flatten(on: conn)
            })
            .map(to: DetachmentResponse.self, { roles in
                return try DetachmentResponse(detachment: detachment, roles: roles)
            })
    }

    // MARK: - Private Functions

    private func generateRoles(forDetachment detachment: Detachment,
                               conn: DatabaseConnectable) throws -> Future<Detachment> {
        let detachmentId = try detachment.requireID()
        let rolesFutures = [
            Role(name: "HQ", detachmentId: detachmentId).save(on: conn),
            Role(name: "Troop", detachmentId: detachmentId).save(on: conn),
            Role(name: "Elite", detachmentId: detachmentId).save(on: conn),
            Role(name: "Fast Attack", detachmentId: detachmentId).save(on: conn),
            Role(name: "Heavy Support", detachmentId: detachmentId).save(on: conn)
        ]

        return rolesFutures.flatten(on: conn).then({ _ in
            return conn.future(detachment)
        })
    }

}
