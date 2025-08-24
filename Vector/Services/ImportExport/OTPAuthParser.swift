//
//  OTPAuthParser.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Services/ImportExport/OTPAuthParser.swift
//

import Foundation

/// Parser for `otpauth://` URIs (RFC 6238/Google Authenticator style).
/// Supports `totp` (V1) and validates base32 secrets, digits, period, and algorithm.
/// Examples:
///   otpauth://totp/Issuer:account@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Issuer&digits=6&period=30&algorithm=SHA1
///
/// Usage:
///   let parsed = try OTPAuthParser.parse(uriString)
///   // feed into AddTokenViewModel or Token builder
public enum OTPAuthParser {

    // MARK: - Model

    public struct ParsedOTP: Equatable, Sendable {
        public enum Kind: String, Sendable { case totp /*, hotp (future)*/ }

        public let kind: Kind
        public let issuer: String
        public let account: String
        public let secretBase32: String
        public let algorithm: OTPAlgorithm
        public let digits: Int
        public let period: Int
        // Future: counter for HOTP, image URL, etc.

        public init(kind: Kind,
                    issuer: String,
                    account: String,
                    secretBase32: String,
                    algorithm: OTPAlgorithm,
                    digits: Int,
                    period: Int) {
            self.kind = kind
            self.issuer = issuer
            self.account = account
            self.secretBase32 = secretBase32
            self.algorithm = algorithm
            self.digits = digits
            self.period = period
        }
    }

    // MARK: - Parse

    /// Parse an otpauth URI string.
    /// - Throws: `AppError.validation` with human-friendly reasons.
    public static func parse(_ uri: String) throws -> ParsedOTP {
        guard let url = URL(string: uri) else {
            throw AppError.validation(message: "Not a valid URI.") // Localize
        }
        return try parse(url)
    }

    /// Parse an otpauth URL.
    public static func parse(_ url: URL) throws -> ParsedOTP {
        guard let scheme = url.scheme?.lowercased(), scheme == "otpauth" else {
            throw AppError.validation(message: "URI must start with otpauth://") // Localize
        }

        // Kind: /totp/... or /hotp/...
        let kindString = url.host?.lowercased() ?? ""
        guard kindString == "totp" || kindString == "hotp" else {
            throw AppError.validation(message: "Unsupported OTP type. Only TOTP is supported in this version.") // Localize
        }
        let kind: ParsedOTP.Kind = (kindString == "totp") ? .totp : .totp // force totp for V1

        // Label: path without leading slash. Common formats:
        //   "Issuer:Account"  or just "Account"
        // URL path may be percent-encoded.
        let labelRaw = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let labelDecoded = labelRaw.removingPercentEncoding ?? labelRaw

        let (labelIssuer, labelAccount) = splitLabel(labelDecoded)

        // Query params
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            items.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }?.value
        }

        // secret
        guard let secretRaw = value("secret"), !secretRaw.isEmpty else {
            throw AppError.validation(message: "Missing secret in URI.") // Localize
        }
        let normalizedSecret = normalizeBase32(secretRaw)
        guard isLikelyValidBase32(normalizedSecret) else {
            throw AppError.validation(message: "Secret is not valid Base32.") // Localize
        }

        // issuer (param overrides label issuer if both present; many generators duplicate it)
        let paramIssuer = value("issuer")?.nonEmpty
        let issuer = (paramIssuer ?? labelIssuer ?? "").nonEmpty ?? "Unknown" // Localize later

        // account (from label primary body)
        let account = (labelAccount ?? "").nonEmpty ?? (value("account")?.nonEmpty ?? "")

        // algorithm
        let algoString = value("algorithm")?.uppercased() ?? "SHA1"
        let algorithm: OTPAlgorithm
        switch algoString {
        case "SHA1":  algorithm = .sha1
        case "SHA256": algorithm = .sha256
        case "SHA512": algorithm = .sha512
        default:
            // Keep permissive: default to SHA1 but warn in logs (no direct logging of secrets).
            algorithm = .sha1
        }

        // digits
        let digits: Int = {
            guard let d = value("digits"), let v = Int(d), (v == 6 || v == 8) else { return 6 }
            return v
        }()

        // period
        let period: Int = {
            guard let p = value("period"), let v = Int(p), (15...120).contains(v) else { return 30 }
            return v
        }()

        // If account still empty but issuer contains an email-like, shuffle
        let (finalIssuer, finalAccount) = repairIssuerAccountHeuristics(issuer: issuer, account: account)

        return ParsedOTP(
            kind: kind,
            issuer: finalIssuer,
            account: finalAccount,
            secretBase32: normalizedSecret,
            algorithm: algorithm,
            digits: digits,
            period: period
        )
    }

    // MARK: - Helpers

    /// Split "Issuer:Account" or "Issuer - Account" into (issuer, account).
    /// If no delimiter is present, treat entire label as account.
    private static func splitLabel(_ label: String) -> (String?, String?) {
        if label.isEmpty { return (nil, nil) }
        // Common delimiters used by issuers
        let delimiters = [":", ":", " - "]
        for delim in delimiters {
            if let range = label.range(of: delim) {
                let issuer = String(label[..<range.lowerBound]).trimmed
                let account = String(label[range.upperBound...]).trimmed
                return (issuer.nonEmpty, account.nonEmpty)
            }
        }
        return (nil, label.trimmed.nonEmpty)
    }

    /// Normalize Base32 by removing spaces/hyphens and uppercasing.
    public static func normalizeBase32(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .uppercased()
    }

    /// Heuristic validation for Base32 (A–Z, 2–7, '=' padding only at the end)
    public static func isLikelyValidBase32(_ s: String) -> Bool {
        guard !s.isEmpty else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
        if s.unicodeScalars.contains(where: { !allowed.contains($0) }) { return false }
        if let padIndex = s.firstIndex(of: "=") {
            if s[padIndex...].contains(where: { $0 != "=" }) { return false }
        }
        // Reasonable length (most secrets are >= 16)
        return s.count >= 8
    }

    /// If issuer looks like an email and account is empty, swap; keeps lists tidy.
    private static func repairIssuerAccountHeuristics(issuer: String, account: String) -> (String, String) {
        if account.isEmpty, issuer.contains("@") {
            return ("", issuer) // issuer unknown, account is the email
        }
        return (issuer, account)
    }
}

// MARK: - Small string helpers

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
