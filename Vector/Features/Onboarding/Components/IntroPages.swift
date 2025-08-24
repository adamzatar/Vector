//
//  IntroPages.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Features/Onboarding/IntroPages.swift
//

import Foundation

/// Data source for onboarding pages (copy lives here, not inline in the view).
/// Keeps `IntroScreen` slim and makes copy easy to localize later.
struct IntroPages {
    struct Page: Identifiable, Equatable {
        let id = UUID()
        let systemImage: String
        let title: String
        let body: String
    }

    static let all: [Page] = [
        Page(
            systemImage: "lock.shield.fill",
            title: "End‑to‑end encrypted", // Localize
            body: "Your 2FA secrets are encrypted before sync. Only your devices can decrypt them." // Localize
        ),
        Page(
            systemImage: "icloud.fill",
            title: "Private iCloud Sync", // Localize
            body: "Uses your iCloud Private Database. We never run a server that sees your data." // Localize
        ),
        Page(
            systemImage: "hand.raised.fill",
            title: "No tracking. No ads.", // Localize
            body: "Just fast, simple, private. Clipboard auto‑clears; we don’t log sensitive data." // Localize
        )
    ]
}
