import Fluent

// MARK: - Users

struct CreateUser: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        db.schema("users")
            .id()
            .field("appleUserID", .string)
            .field("username", .string)
            .field("status", .string, .required)
            .field("createdAt", .datetime)
            .create()
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        db.schema("users").delete()
    }
}

// MARK: - Devices

struct CreateDevice: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        db.schema("devices")
            .id()
            .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("pubKeyDER", .data, .required)
            .field("apnsToken", .string, .required)
            .field("modelHash", .string, .required)
            .field("osHash", .string, .required)
            .field("trustLevel", .int, .required)
            .field("dcScore", .int, .required)
            .field("createdAt", .datetime)
            .field("lastSeenAt", .datetime)
            .create()
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        db.schema("devices").delete()
    }
}

// MARK: - Challenges

struct CreateChallenge: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        db.schema("challenges")
            .id()
            .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("deviceID", .uuid, .references("devices", "id", onDelete: .setNull))
            .field("nonce", .data, .required)
            .field("expiresAt", .datetime, .required)
            .field("used", .bool, .required)
            .create()
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        db.schema("challenges").delete()
    }
}

// MARK: - TOTP Secrets

struct CreateTOTPSecret: Migration {
    func prepare(on db: Database) -> EventLoopFuture<Void> {
        db.schema("totp_secrets")
            .id()
            .field("userID", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("secretCiphertext", .data, .required)
            .field("version", .int, .required)
            .field("createdAt", .datetime)
            .create()
    }

    func revert(on db: Database) -> EventLoopFuture<Void> {
        db.schema("totp_secrets").delete()
    }
}
