//
//  OTPAuthParserTests.swift
//  VectorTests
//
//  Created by Adam Zaatar on 8/22/25.
//  File: Tests/Unit/OTPAuthParserTests.swift
//

import Foundation
import XCTest
@testable import Vector

/// Unit tests for `OTPAuthParser`.
/// Covers: valid URIs, missing/invalid fields, label parsing, algorithm/digits/period handling,
/// base32 normalization/validation, and issuer/account heuristics.
final class OTPAuthParserTests: XCTestCase {

    // MARK: - Happy paths

    func testParse_TOTP_FullParams() throws {
        // Given
        let uri = "otpauth://totp/Acme:dev@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Acme&digits=6&period=30&algorithm=SHA1"

        // When
        let parsed = try OTPAuthParser.parse(uri)

        // Then
        XCTAssertEqual(parsed.kind, .totp)
        XCTAssertEqual(parsed.issuer, "Acme")
        XCTAssertEqual(parsed.account, "dev@example.com")
        XCTAssertEqual(parsed.secretBase32, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(parsed.algorithm, .sha1)
        XCTAssertEqual(parsed.digits, 6)
        XCTAssertEqual(parsed.period, 30)
    }

    func testParse_TOTP_LabelOnlyIssuerAndAccount() throws {
        let uri = "otpauth://totp/GitHub:ops@example.com?secret=JBSWY3DPEHPK3PXP"
        let p = try OTPAuthParser.parse(uri)
        XCTAssertEqual(p.issuer, "GitHub")
        XCTAssertEqual(p.account, "ops@example.com")
        XCTAssertEqual(p.digits, 6)   // default
        XCTAssertEqual(p.period, 30)  // default
        XCTAssertEqual(p.algorithm, .sha1) // default
    }

    func testParse_TOTP_URLEncodedLabel() throws {
        let uri = "otpauth://totp/Cloudflare%3Auser%40example.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256&digits=8&period=45"
        let p = try OTPAuthParser.parse(uri)
        XCTAssertEqual(p.issuer, "Cloudflare")
        XCTAssertEqual(p.account, "user@example.com")
        XCTAssertEqual(p.algorithm, .sha256)
        XCTAssertEqual(p.digits, 8)
        XCTAssertEqual(p.period, 45)
    }

    func testParse_TOTP_ParamIssuerOverridesLabelIssuer() throws {
        let uri = "otpauth://totp/OldIssuer:alice?secret=JBSWY3DPEHPK3PXP&issuer=NewIssuer"
        let p = try OTPAuthParser.parse(uri)
        XCTAssertEqual(p.issuer, "NewIssuer")
        XCTAssertEqual(p.account, "alice")
    }

    // MARK: - Error cases

    func testParse_RejectsNonOtpauthScheme() {
        let uri = "https://example.com/foo?secret=JBSWY3DPEHPK3PXP"
        assertValidationError(uri, expectedMessageContains: "otpauth://")
    }

    func testParse_RejectsMissingSecret() {
        let uri = "otpauth://totp/Issuer:acct?digits=6"
        assertValidationError(uri, expectedMessageContains: "Missing secret")
    }

    func testParse_RejectsInvalidBase32Characters() {
        let uri = "otpauth://totp/Issuer:acct?secret=NOT*BASE32!"
        assertValidationError(uri, expectedMessageContains: "Base32")
    }

    // MARK: - Defaults & bounds

    func testParse_DefaultsAlgorithmDigitsPeriod() throws {
        let uri = "otpauth://totp/Issuer:acct?secret=JBSWY3DPEHPK3PXP"
        let p = try OTPAuthParser.parse(uri)
        XCTAssertEqual(p.algorithm, .sha1)
        XCTAssertEqual(p.digits, 6)
        XCTAssertEqual(p.period, 30)
    }

    func testParse_DigitsBounds() throws {
        let six = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&digits=6")
        XCTAssertEqual(six.digits, 6)

        let eight = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&digits=8")
        XCTAssertEqual(eight.digits, 8)

        // invalid -> default to 6
        let invalid = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&digits=7")
        XCTAssertEqual(invalid.digits, 6)
    }

    func testParse_PeriodBounds() throws {
        // valid in-range
        let p1 = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&period=45")
        XCTAssertEqual(p1.period, 45)

        // out of range -> default 30
        let tooLow = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&period=5")
        XCTAssertEqual(tooLow.period, 30)

        let tooHigh = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&period=600")
        XCTAssertEqual(tooHigh.period, 30)
    }

    func testParse_UnknownAlgorithmFallsBackToSHA1() throws {
        let p = try OTPAuthParser.parse("otpauth://totp/A:a?secret=JBSWY3DPEHPK3PXP&algorithm=SHA3")
        XCTAssertEqual(p.algorithm, .sha1)
    }

    // MARK: - Label heuristics

    func testParse_LabelWithoutIssuerTreatsAsAccount() throws {
        let p = try OTPAuthParser.parse("otpauth://totp/alice@example.com?secret=JBSWY3DPEHPK3PXP")
        // Issuer not provided -> "Unknown" (per parser) and account is the label
        XCTAssertEqual(p.issuer, "Unknown")
        XCTAssertEqual(p.account, "alice@example.com")
    }

    func testParse_IssuerLooksLikeEmail_SwappedToAccount() throws {
        // Label issuer looks like an email; account empty -> swap
        let p = try OTPAuthParser.parse("otpauth://totp/bob@example.com?secret=JBSWY3DPEHPK3PXP")
        XCTAssertEqual(p.issuer, "")
        XCTAssertEqual(p.account, "bob@example.com")
    }

    // MARK: - Base32 helpers

    func testNormalizeBase32_StripsSpacesHyphensAndUppercases() {
        let raw = " jb swy3dp-ehpk3pxp "
        let norm = OTPAuthParser.normalizeBase32(raw)
        XCTAssertEqual(norm, "JBSWY3DPEHPK3PXP")
    }

    func testIsLikelyValidBase32_PaddingRules() {
        XCTAssertTrue(OTPAuthParser.isLikelyValidBase32("JBSWY3DPEHPK3PXP"))
        XCTAssertTrue(OTPAuthParser.isLikelyValidBase32("JBSWY3DPEHPK3PXP==")) // padding only at end
        XCTAssertFalse(OTPAuthParser.isLikelyValidBase32("JBSW=Y3DP")) // padding mid-string
        XCTAssertFalse(OTPAuthParser.isLikelyValidBase32("INVALID*CHARS"))
    }

    // MARK: - Performance sanity (parsing many URIs)

    func testParse_PerformanceMany() {
        let uris = (0..<500).map { i in
            "otpauth://totp/Acme:user\(i)%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Acme&digits=6&period=30"
        }
        measure {
            for u in uris {
                _ = try? OTPAuthParser.parse(u)
            }
        }
    }

    // MARK: - Helpers

    private func assertValidationError(_ uri: String, expectedMessageContains needle: String, file: StaticString = #filePath, line: UInt = #line) {
        do {
            _ = try OTPAuthParser.parse(uri)
            XCTFail("Expected validation error", file: file, line: line)
        } catch let err as AppError {
            guard case .validation(let message) = err else {
                XCTFail("Expected AppError.validation, got \(err)", file: file, line: line)
                return
            }
            XCTAssertTrue(message.localizedCaseInsensitiveContains(needle), "Message '\(message)' should contain '\(needle)'", file: file, line: line)
        } catch {
            XCTFail("Expected AppError.validation, got \(error)", file: file, line: line)
        }
    }
}
