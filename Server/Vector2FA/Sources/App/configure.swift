import Vapor
import Fluent
import FluentSQLiteDriver
#if canImport(APNS)
import APNS
#endif

public func configure(_ app: Application) throws {
    // DB
    app.databases.use(.sqlite(.file("vector.sqlite")), as: .sqlite)

    // Migrations
    app.migrations.add(CreateUser())
    app.migrations.add(CreateDevice())
    app.migrations.add(CreateChallenge())
    app.migrations.add(CreateTOTPSecret())

    // APNS (token/JWT based) – optional at build time
    #if canImport(APNS)
    if
        let teamId = Environment.get("APNS_TEAM_ID"),
        let keyId  = Environment.get("APNS_KEY_ID"),
        let bundle = Environment.get("APNS_BUNDLE_ID")
    {
        let p8Path = app.directory.resourcesDirectory + "Config/apns-auth-key.p8"
        let env = (Environment.get("APNS_ENV") == "prod") ? APNSEnvironment.production : .sandbox

        // Configure a default APNS container
        app.apns.containers.use(
            .init(
                configuration: .init(
                    authenticationMethod: .jwt(
                        key: .private(filePath: p8Path),
                        keyIdentifier: .init(stringLiteral: keyId),
                        teamIdentifier: teamId
                    ),
                    topic: bundle,
                    environment: env
                )
            ),
            default: .init()
        )
    }
    #endif

    try routes(app)
}
