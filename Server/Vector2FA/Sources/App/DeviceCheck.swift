// Sources/App/DeviceCheck.swift

import Vapor

/// Placeholder DeviceCheck verifier.
/// Replace with a real call to Apple's DeviceCheck or App Attest as needed.
enum DeviceCheckError: Error, DebuggableError {
    case invalidToken
    var identifier: String { "device_check_invalid_token" }
    var reason: String { "The provided device check token was invalid." }
}

struct DeviceCheck {
    /// Verifies a device check token and returns an integer "score"
    /// you can use to set a device's initial trust level.
    ///
    /// - Returns: 0–100 where >=50 is considered "trusted" in our routes.
    static func verify(token: String, on req: Request) async throws -> Int {
        // Super basic sanity checks for now; log and score conservatively.
        guard !token.isEmpty else { return 0 }

        // Example heuristic: longer tokens score higher (placeholder only).
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 32 {
            return 80
        } else if trimmed.count >= 8 {
            return 50
        } else {
            return 20
        }
    }
}
