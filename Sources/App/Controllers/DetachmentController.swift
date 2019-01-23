import Vapor
import FluentPostgreSQL

final class DetachmentController {

    // MARK: - Public Functions

    func createDetachment(_ req: Request) throws -> Future<Detachment> {
        return try req.content.decode(CreateDetachmentRequest.self)
            .flatMap(to: Detachment.self, { request in
                return Army.find(request.armyId, on: req).unwrap(or: RoasterHammerError.armyIsMissing)
                    .flatMap(to: Detachment.self, { army in
                        let armyId = try army.requireID()
                        return Detachment(name: request.name, commandPoints: request.commandPoints, armyId: armyId)
                            .save(on: req)
                    })
                    .flatMap(to: Detachment.self, { detachment in
                        return try self.generateRoles(forDetachment: detachment, conn: req)
                    })
            })
    }

    func detachments(_ req: Request) throws -> Future<[Detachment]> {
        return Detachment.query(on: req).all()
    }

    func addDetachmentToRoaster(_ req: Request) throws -> Future<RoasterResponse> {
        _ = try req.requireAuthenticated(Customer.self)
        let roasterId = try req.parameters.next(Int.self)

        return try req.content.decode(AddDetachmentToRoasterRequest.self)
            .flatMap(to: Detachment.self, { request in
                // Might need to duplicate the detachment for the roaster to avoid collusion
                return Detachment.find(request.detachmentId, on: req).unwrap(or: RoasterHammerError.detachmentIsMissing)
            })
            .flatMap(to: Roaster.self, { detachment in
                return Roaster.find(roasterId, on: req).unwrap(or: RoasterHammerError.roasterIsMissing)
                    .then({ roaster in
                        return roaster.detachments.attach(detachment, on: req)
                            .then ({ _ in
                                return req.future(roaster)
                            })
                    })
            })
            .flatMap(to: RoasterResponse.self, { roaster in
                let roasterController = RoasterController()
                return try roasterController.roasterResponse(forRoaster: roaster, conn: req)
            })
    }

    // MARK: - Utility Functions

    func roleResponse(forRole role: Role,
                      conn: DatabaseConnectable) throws -> Future<RoleResponse> {
        return try role.units.query(on: conn).all()
            .flatMap(to: [SelectedUnitResponse].self, { units in
                let unitController = UnitController()
                return try units.map { try unitController.unitResponse(forSelectedUnit: $0, conn: conn) }.flatten(on: conn)
            })
            .map(to: RoleResponse.self, { units in
                return try RoleResponse(role: role, units: units)
            })
    }

    func detachmentResponse(forDetachment detachment: Detachment,
                            conn: DatabaseConnectable) throws -> Future<DetachmentResponse> {
        let rolesFuture = try detachment.roles.query(on: conn).all()
        let armyFuture = detachment.army.get(on: conn)

        return flatMap(rolesFuture, armyFuture, { (roles, army) in
            let roleResponsesFuture = try roles.map { try self.roleResponse(forRole: $0, conn: conn) }.flatten(on: conn)
            let armyResponse = try ArmyController().armyResponse(forArmy: army, conn: conn)

            return map(roleResponsesFuture, armyResponse, { (roleResponses, armyResponse) in
                return try DetachmentResponse(detachment: detachment, roles: roleResponses, army: armyResponse)
            })
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
