import Vapor
import Fluent
import Crypto
#if canImport(APNS)
import APNS
#endif

// MARK: - Push payload
struct SilentChallengePush: Codable {
    struct APS: Codable {
        let contentAvailable: Int
        enum CodingKeys: String, CodingKey { case contentAvailable = "content-available" }
    }
    let aps: APS
    let challengeID: String
    init(challengeID: String) {
        self.aps = .init(contentAvailable: 1)
        self.challengeID = challengeID
    }
}

// MARK: - DTOs
struct RegisterDeviceRequest: Content {
    let userID: UUID
    let apnsToken: String
    let pubKeyDER: Data
    let modelHash: String
    let osHash: String
    let deviceCheckToken: String
}

struct BeginAuthRequest: Content { let userID: UUID }

struct ApproveRequest: Content {
    let challengeID: UUID
    let deviceID: UUID
    let signatureDER: Data
}

struct TOTPSetupRequest: Content {
    let userID: UUID
    let secretBase32: String
}
struct TOTPVerifyRequest: Content {
    let userID: UUID
    let code: String
}

public func routes(_ app: Application) throws {

    app.get("health") { _ in "ok" }

    // Device register
    app.post("device", "register") { req async throws -> Device in
        let r = try req.content.decode(RegisterDeviceRequest.self)
        guard let user = try await User.find(r.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }

        let score = try await DeviceCheck.verify(token: r.deviceCheckToken, on: req)
        let dev = Device(
            userID: try user.requireID(),
            pubKeyDER: r.pubKeyDER,
            apnsToken: r.apnsToken,
            modelHash: r.modelHash,
            osHash: r.osHash,
            trustLevel: score >= 50 ? 1 : 0,
            dcScore: score
        )
        try await dev.save(on: req.db)
        return dev
    }

    // Begin auth: create challenge & push
    app.post("auth", "begin") { req async throws -> Challenge in
        let r = try req.content.decode(BeginAuthRequest.self)
        guard let user = try await User.find(r.userID, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        let uid = try user.requireID()

        guard let device = try await Device.query(on: req.db)
            .filter(\.$user.$id == uid)
            .filter(\.$trustLevel >= 1)
            .sort(\.$lastSeenAt, .descending)
            .first()
        else {
            throw Abort(.failedDependency, reason: "No trusted devices")
        }

        let nonce = Data(try CryptoBox.randomNonce())
        let ch = Challenge(userID: uid, deviceID: try device.requireID(), nonce: nonce, ttl: 60)
        try await ch.save(on: req.db)

        // Silent/background push first (compile-time optional)
        #if canImport(APNS)
        do {
            try await req.apns.send(
                SilentChallengePush(challengeID: ch.id!.uuidString),
                pushType: .background,
                to: device.apnsToken
            )        } catch {
            req.logger.warning("APNs send failed: \(error.localizedDescription)")
        }
        #else
        req.logger.info("APNS not available at build time; would push challenge \(ch.id!.uuidString)")
        #endif

        return ch
    }

    // Challenge details
    app.get("auth", "challenge", ":id") { req async throws -> [String: String] in
        guard
            let idStr = req.parameters.get("id"),
            let id = UUID(uuidString: idStr),
            let ch = try await Challenge.find(id, on: req.db)
        else { throw Abort(.notFound) }

        guard !ch.used, ch.expiresAt > Date() else { throw Abort(.gone) }

        return [
            "challengeID": id.uuidString,
            "userID": ch.$user.id.uuidString,
            "nonceB64": ch.nonce.base64EncodedString()
        ]
    }

    // Approve
    app.post("auth", "approve") { req async throws -> HTTPStatus in
        let r = try req.content.decode(ApproveRequest.self)
        guard let ch = try await Challenge.find(r.challengeID, on: req.db) else { throw Abort(.notFound) }
        guard !ch.used, ch.expiresAt > Date() else { throw Abort(.gone) }
        guard let device = try await Device.find(r.deviceID, on: req.db) else { throw Abort(.notFound) }

        var ctx = Data()
        ctx.append(ch.$user.id.uuidString.data(using: .utf8)!)
        ctx.append(try device.requireID().uuidString.data(using: .utf8)!)
        ctx.append(ch.nonce)

        let ok = CryptoBox.verifyP256Signature(pubKeyDER: device.pubKeyDER, message: ctx, signatureDER: r.signatureDER)
        guard ok else { throw Abort(.unauthorized) }

        ch.used = true
        try await ch.update(on: req.db)
        return .ok
    }

    // TOTP setup
    app.post("totp", "setup") { req async throws -> HTTPStatus in
        let r = try req.content.decode(TOTPSetupRequest.self)
        guard let user = try await User.find(r.userID, on: req.db) else { throw Abort(.notFound) }
        guard let secret = r.secretBase32.base32DecodedData() else { throw Abort(.badRequest, reason: "Invalid Base32") }
        let key = CryptoBox.serverKey()
        let sealed = try CryptoBox.seal(secret: secret, key: key)
        let item = TOTPSecret(userID: try user.requireID(), secretCiphertext: sealed)
        try await item.save(on: req.db)
        return .created
    }

    // TOTP verify
    app.post("totp", "verify") { req async throws -> HTTPStatus in
        let r = try req.content.decode(TOTPVerifyRequest.self)
        guard let item = try await TOTPSecret.query(on: req.db).filter(\.$user.$id == r.userID).first() else {
            throw Abort(.notFound)
        }
        let key = CryptoBox.serverKey()
        let secret = try CryptoBox.open(combined: item.secretCiphertext, key: key)
        let ok = CryptoBox.totpVerify(secret: secret, code: r.code)
        guard ok else { throw Abort(.unauthorized) }
        return .ok
    }
}
