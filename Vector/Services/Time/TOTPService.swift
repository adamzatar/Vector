//
//  TOTPService.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
//  File: Services/Time/TOTPService.swift
//
//  RFC 6238-compliant TOTP engine.
//  - Apple-native CryptoKit (HMAC SHA1/256/512)
//  - Internal Base32 decoder (RFC 4648, case-insensitive, '=' optional)
//  - No external dependencies
//

import Foundation
import CryptoKit

/// Service interface so we can mock in tests if needed.
public protocol TOTPServicing: Sendable {
    /// Generate a TOTP code. Returns nil if the secret cannot be decoded.
    func code(
        secretBase32: String,
        algorithm: OTPAlgorithm,
        digits: Int,
        period: Int,
        at date: Date
    ) -> String?

    /// Seconds remaining in the current step.
    func remainingSeconds(period: Int, at date: Date) -> Int

    /// Convenience: returns (code, remaining) as a pair.
    func codeWithRemaining(
        secretBase32: String,
        algorithm: OTPAlgorithm,
        digits: Int,
        period: Int,
        at date: Date
    ) -> (code: String, remaining: Int)?
}

public struct TOTPService: TOTPServicing, Sendable {
    public init() {}

    public func code(
        secretBase32: String,
        algorithm: OTPAlgorithm,
        digits: Int,
        period: Int,
        at date: Date = .init()
    ) -> String? {
        guard let key = TOTPBase32.decode(secretBase32) else { return nil }
        let step = UInt64(floor(date.timeIntervalSince1970 / Double(period)))
        let hmac = hmacTruncate(counter: step, key: key, algorithm: algorithm)
        let modulo = pow10(min(max(digits, 6), 8))
        let otp = hmac % modulo
        return String(format: "%0*\(digits)d", digits, otp)
    }

    public func remainingSeconds(period: Int, at date: Date = .init()) -> Int {
        let t = Int(date.timeIntervalSince1970)
        let mod = t % period
        return max(0, period - mod)
    }

    public func codeWithRemaining(
        secretBase32: String,
        algorithm: OTPAlgorithm,
        digits: Int,
        period: Int,
        at date: Date = .init()
    ) -> (code: String, remaining: Int)? {
        guard let c = code(secretBase32: secretBase32,
                           algorithm: algorithm,
                           digits: digits,
                           period: period,
                           at: date) else { return nil }
        return (c, remainingSeconds(period: period, at: date))
    }
}

// MARK: - Internals

private extension TOTPService {
    func hmacTruncate(counter: UInt64, key: Data, algorithm: OTPAlgorithm) -> Int {
        var c = counter.bigEndian
        let msg = withUnsafeBytes(of: &c) { Data($0) }
        let skey = SymmetricKey(data: key)

        let digest: [UInt8]
        switch algorithm {
        case .sha1:
            digest = Array(HMAC<Insecure.SHA1>.authenticationCode(for: msg, using: skey))
        case .sha256:
            digest = Array(HMAC<SHA256>.authenticationCode(for: msg, using: skey))
        case .sha512:
            digest = Array(HMAC<SHA512>.authenticationCode(for: msg, using: skey))
        }

        let offset = Int(digest.last! & 0x0f)
        let bin = (Int(digest[offset]   & 0x7f) << 24) |
                  (Int(digest[offset+1]) << 16) |
                  (Int(digest[offset+2]) <<  8) |
                   Int(digest[offset+3])
        return bin
    }

    func pow10(_ n: Int) -> Int {
        // n is small (6 or 8), safe to compute iteratively
        var x = 1
        for _ in 0..<n { x *= 10 }
        return x
    }
}

/// Minimal, allocation-friendly Base32 (RFC 4648) decoder.
/// - Case-insensitive
/// - Ignores '=' padding
/// - Skips unknown characters safely (returns nil if any invalid non-padding char is found)
enum TOTPBase32 {
    private static let table: [UInt8] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567".utf8)

    static func decode(_ s: String) -> Data? {
        var buffer: UInt32 = 0
        var bits = 0
        var out = [UInt8]()
        out.reserveCapacity((s.count * 5) / 8)

        for ch in s {
            if ch == "=" { continue }
            let v: UInt8
            if let upper = ch.uppercased().utf8.first,
               let idx = table.firstIndex(of: upper) {
                v = UInt8(idx)
            } else if ch == " " || ch == "-" { // tolerate separators if users paste them
                continue
            } else {
                return nil
            }

            buffer = (buffer << 5) | UInt32(v)
            bits += 5
            if bits >= 8 {
                bits -= 8
                let byte = UInt8((buffer >> UInt32(bits)) & 0xff)
                out.append(byte)
            }
        }
        return Data(out)
    }
}

// MARK: - Formatting helpers (optional)

public enum TOTPFormat {
    /// Group a numeric code as "123 456" (6) or "1234 5678" (8).
    public static func grouped(_ code: String) -> String {
        switch code.count {
        case 6: return code.insertingSeparator(" ", every: 3)
        case 8: return code.insertingSeparator(" ", every: 4)
        default: return code
        }
    }
}

private extension String {
    func insertingSeparator(_ sep: String, every n: Int) -> String {
        guard n > 0 else { return self }
        var out = ""
        out.reserveCapacity(count + count / n)
        for (i, ch) in self.enumerated() {
            if i != 0 && i % n == 0 { out.append(contentsOf: sep) }
            out.append(ch)
        }
        return out
    }
}
