// Sources/App/Security.swift

import Foundation
import Crypto

/// All crypto utilities used by the server.
enum CryptoBox {
    // MARK: Nonce

    /// Returns `n` random bytes (default 32).
    static func randomNonce(_ n: Int = 32) -> [UInt8] {
        (0..<n).map { _ in UInt8.random(in: .min ... .max) }
    }

    // MARK: Signatures (ECDSA P-256 over SHA256(message))

    /// Verifies a DER-encoded ECDSA P-256 signature against a message.
    static func verifyP256Signature(pubKeyDER: Data, message: Data, signatureDER: Data) -> Bool {
        do {
            let pub = try P256.Signing.PublicKey(derRepresentation: pubKeyDER)
            let sig = try P256.Signing.ECDSASignature(derRepresentation: signatureDER)
            let digest = SHA256.hash(data: message)
            return pub.isValidSignature(sig, for: digest)
        } catch {
            return false
        }
    }

    // MARK: Secret-at-rest (ChaCha20-Poly1305)

    /// Encrypts data using a server symmetric key.
    static func seal(secret: Data, key: SymmetricKey) throws -> Data {
        try ChaChaPoly.seal(secret, using: key).combined
    }

    /// Decrypts data previously sealed by `seal(secret:key:)`.
    static func open(combined: Data, key: SymmetricKey) throws -> Data {
        let box = try ChaChaPoly.SealedBox(combined: combined)
        return try ChaChaPoly.open(box, using: key)
    }

    /// Derives (or loads) a stable 32-byte server key from env `VECTOR_AT_REST_KEY`,
    /// falling back to a dev-only constant. We SHA256 the input to force 32 bytes.
    static func serverKey() -> SymmetricKey {
        let raw = Environment.get("VECTOR_AT_REST_KEY") ?? "dev_only_replace_me_32+bytes__________"
        return SymmetricKey(data: Data(raw.utf8).sha256())
    }

    // MARK: TOTP (RFC 6238) — SHA1, 30s step, 6 digits

    /// Computes a 6-digit TOTP for a given secret and time.
    static func totp(codeFor secret: Data, time: Date = .init(), step: TimeInterval = 30, digits: Int = 6) -> String {
        let counter = UInt64(floor(time.timeIntervalSince1970 / step))
        var big = counter.bigEndian
        let msg = withUnsafeBytes(of: &big) { Data($0) }
        let mac = HMAC<Insecure.SHA1>.authenticationCode(for: msg, using: SymmetricKey(data: secret))
        let hash = Data(mac)

        let offset = Int(hash.last! & 0x0f)
        let truncated =
            (UInt32(hash[offset] & 0x7f) << 24) |
            (UInt32(hash[offset + 1]) << 16) |
            (UInt32(hash[offset + 2]) << 8)  |
             UInt32(hash[offset + 3])

        let mod = UInt32(pow(10, Float(digits)))
        let hotp = truncated % mod
        return String(format: "%0*u", digits, hotp)
    }

    /// Verifies a user-provided TOTP code allowing ±`skew` steps.
    static func totpVerify(secret: Data, code: String, skew: Int = 1, now: Date = .init()) -> Bool {
        let step: TimeInterval = 30
        return (-skew...skew).contains { w in
            let t = now.addingTimeInterval(TimeInterval(w) * step)
            return totp(codeFor: secret, time: t) == code
        }
    }
}

// MARK: - Small helpers

extension Data {
    func sha256() -> Data { Data(SHA256.hash(data: self)) }
}

extension String {
    /// Decodes Base32 (RFC 4648) into `Data`.
    /// Accepts upper/lower case, ignores spaces, `-`, and padding `=`.
    func base32DecodedData() -> Data? {
        let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        var lookup: [Character: UInt8] = [:]
        for (i, c) in alphabet.enumerated() {
            lookup[c] = UInt8(i)
            lookup[Character(c.lowercased())] = UInt8(i)
        }

        // Strip whitespace, hyphens, and padding
        let filtered = self.filter { c in
            c != "=" && c != " " && c != "\n" && c != "\t" && c != "-" && c != "_"
        }

        var buffer: UInt32 = 0
        var bitsLeft: Int = 0
        var out = [UInt8]()
        out.reserveCapacity((filtered.count * 5) / 8)

        for ch in filtered {
            guard let val = lookup[ch] else { return nil }
            buffer = (buffer << 5) | UInt32(val)
            bitsLeft += 5

            if bitsLeft >= 8 {
                bitsLeft -= 8
                let byte = UInt8((buffer >> UInt32(bitsLeft)) & 0xff)
                out.append(byte)
            }
        }

        // Ignore leftover bits (they must be padding)
        return Data(out)
    }
}
