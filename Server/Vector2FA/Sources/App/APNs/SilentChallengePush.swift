//
//  File.swift
//  Vector2FA
//
//  Created by Adam Zaatar on 8/24/25.
//

import Foundation

/// Background push that carries only a challenge ID.
public struct SilentChallengePush: Codable {
    public struct APS: Codable {
        public let contentAvailable: Int
        enum CodingKeys: String, CodingKey { case contentAvailable = "content-available" }
    }
    public let aps: APS
    public let challengeID: String

    public init(challengeID: String) {
        self.aps = .init(contentAvailable: 1)
        self.challengeID = challengeID
    }
}
