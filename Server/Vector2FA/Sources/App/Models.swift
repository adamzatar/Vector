import Vapor
import Fluent

// MARK: - User

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: "appleUserID") var appleUserID: String?
    @Field(key: "username") var username: String?
    @Field(key: "status") var status: String
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?

    init() {
        self.status = "active"
    }

    init(id: UUID? = nil, appleUserID: String? = nil, username: String? = nil, status: String = "active") {
        self.id = id
        self.appleUserID = appleUserID
        self.username = username
        self.status = status
    }
}

// MARK: - Device

final class Device: Model, Content {
    static let schema = "devices"

    @ID(key: .id) var id: UUID?
    @Parent(key: "userID") var user: User
    @Field(key: "pubKeyDER") var pubKeyDER: Data
    @Field(key: "apnsToken") var apnsToken: String
    @Field(key: "modelHash") var modelHash: String
    @Field(key: "osHash") var osHash: String
    @Field(key: "trustLevel") var trustLevel: Int
    @Field(key: "dcScore") var dcScore: Int
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?
    @Timestamp(key: "lastSeenAt", on: .update) var lastSeenAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        userID: UUID,
        pubKeyDER: Data,
        apnsToken: String,
        modelHash: String,
        osHash: String,
        trustLevel: Int,
        dcScore: Int
    ) {
        self.id = id
        self.$user.id = userID
        self.pubKeyDER = pubKeyDER
        self.apnsToken = apnsToken
        self.modelHash = modelHash
        self.osHash = osHash
        self.trustLevel = trustLevel
        self.dcScore = dcScore
    }
}

// MARK: - Challenge

final class Challenge: Model, Content {
    static let schema = "challenges"

    @ID(key: .id) var id: UUID?
    @Parent(key: "userID") var user: User
    @OptionalParent(key: "deviceID") var device: Device?
    @Field(key: "nonce") var nonce: Data
    @Field(key: "expiresAt") var expiresAt: Date
    @Field(key: "used") var used: Bool

    init() {}

    init(userID: UUID, deviceID: UUID?, nonce: Data, ttl: TimeInterval = 60) {
        self.$user.id = userID
        self.$device.id = deviceID
        self.nonce = nonce
        self.expiresAt = Date().addingTimeInterval(ttl)
        self.used = false
    }
}

// MARK: - TOTP Secret

final class TOTPSecret: Model, Content {
    static let schema = "totp_secrets"

    @ID(key: .id) var id: UUID?
    @Parent(key: "userID") var user: User
    @Field(key: "secretCiphertext") var secretCiphertext: Data
    @Field(key: "version") var version: Int
    @Timestamp(key: "createdAt", on: .create) var createdAt: Date?

    init() {}

    init(userID: UUID, secretCiphertext: Data, version: Int = 1) {
        self.$user.id = userID
        self.secretCiphertext = secretCiphertext
        self.version = version
    }
}
