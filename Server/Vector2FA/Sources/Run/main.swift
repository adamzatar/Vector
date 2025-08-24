// Sources/Run/main.swift
import App
import Vapor

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

// App setup (DB, migrations list, routes, APNS, etc.)
try configure(app)

// Register CLI commands (migrate/revert)
registerCommands(app)

try app.run()
