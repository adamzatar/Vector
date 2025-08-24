//
//  ImportView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Backup/ImportView.swift
//


import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// Import screen for bringing tokens into Vector.
/// Supports pasting `otpauth://` URIs and picking `.txt/.csv` files in V1.
/// Phase 2 will add encrypted backup import.
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di

    @State private var pickedURL: URL?
    @State private var pasteText: String = ""
    @State private var isImporting: Bool = false
    @State private var errorMessage: String?
    @State private var successCount: Int = 0

    @State private var showPicker = false

    private let allowedTypes: [UTType] = [
        .text,
        .commaSeparatedText,
        UTType(filenameExtension: "csv")!,
        UTType(filenameExtension: "txt")!
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("Import tokens") // Localize
                    .brandTitle(.m)

                // Paste box
                Card {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text("Paste otpauth:// lines (one per row)") // Localize
                            .font(Typography.body)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $pasteText)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                                    .fill(BrandColor.surfaceSecondary)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                                    .strokeBorder(BrandColor.divider.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .padding(Spacing.m)
                }

                // OR divider
                HStack {
                    Rectangle().fill(BrandColor.divider).frame(height: 1)
                    Text("or") // Localize
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                    Rectangle().fill(BrandColor.divider).frame(height: 1)
                }
                .padding(.horizontal, Spacing.m)

                // File picker card
                Card {
                    VStack(alignment: .leading, spacing: Spacing.m) {
                        Text("Pick a .csv or .txt file") // Localize
                            .font(Typography.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: Spacing.m) {
                            SecondaryButton("Choose File", systemImage: "doc.badge.plus") {
                                showPicker = true
                            }

                            if let pickedURL {
                                Text(pickedURL.lastPathComponent)
                                    .font(Typography.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                    .padding(Spacing.m)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xl)
        }
        .background(BrandColor.surface.ignoresSafeArea())
        .navigationTitle("Import") // Localize
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                        .accessibilityLabel("Close") // Localize
                }
                .minTapTarget()
            }
            ToolbarItem(placement: .confirmationAction) {
                PrimaryButton("Import", systemImage: "square.and.arrow.down") {
                    Task { await runImport() }
                }
                .isDisabledIf(!canImport || isImporting)
            }
        }
        .fileImporter(
            isPresented: $showPicker,
            allowedContentTypes: allowedTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):                // <-- Always [URL]
                pickedURL = urls.first
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        }
        .alert("Import", isPresented: Binding(
            get: { errorMessage != nil || successCount > 0 },
            set: { _ in errorMessage = nil; successCount = 0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            } else if successCount > 0 {
                Text("Imported \(successCount) tokens.") // Localize
            }
        }
    }

    // MARK: - Derived

    private var canImport: Bool {
        !pasteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pickedURL != nil
    }

    // MARK: - Import

    private func runImport() async {
        isImporting = true
        defer { isImporting = false }

        var lines: [String] = []

        // 1) Gather otpauth lines from pasted text
        let pasted = pasteText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        lines.append(contentsOf: pasted)

        // 2) If a file is selected, read it
        if let url = pickedURL {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let fileLines = content
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                lines.append(contentsOf: fileLines)
            } catch {
                errorMessage = "Failed to read file: \(error.localizedDescription)" // Localize
                return
            }
        }

        // 3) Parse and create tokens
        var imported: [Token] = []

        for raw in lines {
            if raw.lowercased().hasPrefix("otpauth://") {
                do {
                    let p = try OTPAuthParser.parse(raw) // issuer/account are non-optional in your parser

                    #if DEBUG
                    let issuer  = Ciphertext.debug_fromPlaintext(p.issuer)          // <-- no ??
                    let account = Ciphertext.debug_fromPlaintext(p.account)         // <-- no ??
                    let secret  = Ciphertext.debug_fromPlaintext(p.secretBase32)    // non-optional
                    #else
                    let issuer  = Ciphertext(data: Data(p.issuer.utf8))
                    let account = Ciphertext(data: Data(p.account.utf8))
                    let secret  = Ciphertext(data: Data(p.secretBase32.utf8))
                    #endif

                    let token = Token(
                        issuer: issuer,
                        account: account,
                        secret: secret,
                        algo: p.algorithm,
                        digits: p.digits,
                        period: p.period,
                        color: nil,
                        tags: []
                    )
                    imported.append(token)
                } catch {
                    errorMessage = "Some entries could not be parsed. First error: \(error.localizedDescription)"
                }
            } else {
                // CSV fallback: issuer,account,secret,digits,period,algorithm
                let cols = raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                guard cols.count >= 3 else { continue }
                let issuerPlain  = cols[safe: 0] ?? "Unknown"
                let accountPlain = cols[safe: 1] ?? "Unknown"
                let secretPlain  = cols[safe: 2] ?? ""

                let digits = Int(cols[safe: 3] ?? "") ?? 6
                let period = Int(cols[safe: 4] ?? "") ?? 30
                let algo = OTPAlgorithm(rawValue: (cols[safe: 5] ?? "SHA1").uppercased()) ?? .sha1

                #if DEBUG
                let encIssuer  = Ciphertext.debug_fromPlaintext(issuerPlain)
                let encAccount = Ciphertext.debug_fromPlaintext(accountPlain)
                let encSecret  = Ciphertext.debug_fromPlaintext(secretPlain)
                #else
                let encIssuer  = Ciphertext(data: Data(issuerPlain.utf8))
                let encAccount = Ciphertext(data: Data(accountPlain.utf8))
                let encSecret  = Ciphertext(data: Data(secretPlain.utf8))
                #endif

                imported.append(Token(
                    issuer: encIssuer,
                    account: encAccount,
                    secret: encSecret,
                    algo: algo,
                    digits: digits,
                    period: period,
                    color: nil,
                    tags: []
                ))
            }
        }

        // 4) Persist
        var success = 0
        for t in imported {
            do {
                try await di.vault.add(t)
                success += 1
            } catch {
                errorMessage = "Failed to save some tokens: \(error.localizedDescription)" // Localize
            }
        }
        successCount = success

        // 5) Finish
        if success > 0 {
            pasteText = ""
            pickedURL = nil
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
