//
//  AddTokenViewModel.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/AddToken/AddTokenViewModel.swift
//


import Foundation
import SwiftUI
import UIKit

/// ViewModel for the "Add Token" flow (manual form + QR hookup).
/// - Owns form state, validates inputs, and creates a `Token` pushed into `VaultStore`.
/// - Parsing of `otpauth://` is delegated to `OTPAuthParser` (Services/ImportExport).
@MainActor
final class AddTokenViewModel: ObservableObject {
    // MARK: - Form State (manual entry)

    @Published var issuer: String = ""
    @Published var account: String = ""
    @Published var secretBase32: String = ""
    @Published var selectedAlgo: OTPAlgorithm = .sha1
    @Published var digits: Int = 6
    @Published var period: Int = 30
    @Published var color: TokenColor? = nil
    @Published var tags: [String] = []

    // UI
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showQRScanner: Bool = false

    // MARK: - Dependencies

    private let container: DIContainer
    private var vault: any VaultStore { container.vault }
    private var logger: any Logging { container.logger }

    // MARK: - Init

    init(container: DIContainer) {
        self.container = container
    }

    // MARK: - Derived

    var canSave: Bool {
        // Basic guard: issuer/account non-empty and base32 plausibly valid length.
        !issuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !account.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        isLikelyBase32(secretBase32) &&
        (digits == 6 || digits == 8) &&
        period >= 10 && period <= 60
    }

    // MARK: - Actions

    /// Save a token from the manual form.
    func saveManual() {
        errorMessage = nil
        guard canSave else {
            errorMessage = "Please complete the form with a valid Base32 secret." // Localize
            return
        }

        isSaving = true
        let issuerText = issuer.trimmingCharacters(in: .whitespacesAndNewlines)
        let accountText = account.trimmingCharacters(in: .whitespacesAndNewlines)
        let tagsClean = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        Task {
            defer { isSaving = false }
            do {
                // V1: wrap plaintext in debug helpers so UI shows readable labels in DEBUG.
                #if DEBUG
                let encIssuer = Ciphertext.debug_fromPlaintext(issuerText)
                let encAccount = Ciphertext.debug_fromPlaintext(accountText)
                let encSecret = Ciphertext.debug_fromPlaintext(secretBase32.uppercased())
                #else
                // Phase 2: derive vault key, AES‑GCM encrypt issuer/account/secret.
                let encIssuer = Ciphertext(data: Data(issuerText.utf8))
                let encAccount = Ciphertext(data: Data(accountText.utf8))
                let encSecret = Ciphertext(data: Data(secretBase32.uppercased().utf8))
                #endif

                let token = Token(
                    issuer: encIssuer,
                    account: encAccount,
                    secret: encSecret,
                    algo: selectedAlgo,
                    digits: digits,
                    period: period,
                    color: color,
                    tags: tagsClean
                )

                try await vault.add(token)

                // Gentle success haptic
                let gen = UINotificationFeedbackGenerator()
                gen.notificationOccurred(.success)

            } catch {
                logger.error("Add token failed: \(error.localizedDescription)")
                errorMessage = AppError.wrap(error).localizedDescription
            }
        }
    }

    /// Handle a scanned `otpauth://` URI string.
    func handleScanned(_ code: String) {
        do {
            // Parser API is `parse(_:)`. In our current parser, these
            // fields are non-optional; guard only for emptiness.
            let parsed = try OTPAuthParser.parse(code)

            let newIssuer = parsed.issuer
            if !newIssuer.isEmpty { issuer = newIssuer }

            let newAccount = parsed.account
            if !newAccount.isEmpty { account = newAccount }

            // Non-optional payload from parser
            secretBase32 = parsed.secretBase32
            digits = parsed.digits
            period = parsed.period
            selectedAlgo = parsed.algorithm

        } catch {
            errorMessage = AppError.wrap(error).localizedDescription
            logger.warn("QR parse failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    /// A quick heuristic for Base32: characters set + length multiple of 8 (padding optional).
    private func isLikelyBase32(_ s: String) -> Bool {
        let trimmed = s.replacingOccurrences(of: " ", with: "").uppercased()
        guard !trimmed.isEmpty else { return false }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) { return false }
        // length heuristic (not strict): >= 16 and divisible by 8 or ends with '=' padding
        return trimmed.count >= 16 && ((trimmed.count % 8) == 0 || trimmed.last == "=")
    }
}
