//
//  BackupView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Backup/BackupView.swift
//
//

import SwiftUI
import UniformTypeIdentifiers

/// Backup/Export screen (V1: scaffold).
/// Phase 2 will add encrypted AES‑GCM export with passphrase.
struct BackupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.di) private var di

    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.l) {
                Text("Back up your vault") // Localize
                    .brandTitle(.m)

                Card.titled("How it works") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        bullet("Vector will export an encrypted file (AES‑GCM).") // Localize
                        bullet("Restore will require your passphrase.") // Localize
                        bullet("Only ciphertext is stored; we cannot read your data.") // Localize
                    }
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                }

                // Export controls
                VStack(spacing: Spacing.m) {
                    PrimaryButton("Export Encrypted Backup", systemImage: "square.and.arrow.up") {
                        Task { await runExport() }
                    }
                    .isDisabledIf(isExporting)

                    if let exportURL {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: "doc.fill")
                            Text(exportURL.lastPathComponent)
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Spacer()
                            SecondaryButton("Share", systemImage: "square.and.arrow.up") {
                                presentShareSheet(for: exportURL)
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                    }
                }

                // Inline error
                if let errorMessage {
                    Text(errorMessage)
                        .font(Typography.caption)
                        .foregroundStyle(.red)
                }

                // Import CTA
                NavigationLink {
                    ImportView()
                } label: {
                    SettingRow("Import from file", systemImage: "square.and.arrow.down") {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .minTapTarget()
            }
            .padding(.horizontal, Spacing.m)
            .padding(.top, Spacing.l)
            .padding(.bottom, Spacing.xl)
        }
        .background(BrandColor.surface.ignoresSafeArea())
        .navigationTitle("Backup") // Localize
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
        }
    }

    // MARK: - Actions

    private func runExport() async {
        isExporting = true
        defer { isExporting = false }

        // V1 stub: write a tiny JSON placeholder so the flow is testable.
        // Phase 2: real AES‑GCM + header/version + KDF params.
        do {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("Vector-Backup-\(Int(Date().timeIntervalSince1970)).json")
            let payload = ["version": 1, "note": "placeholder export; encrypted backup lands in Phase 2"] as [String : Any]
            let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
            try data.write(to: tmp, options: .atomic)
            exportURL = tmp
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)" // Localize
        }
    }

    private func presentShareSheet(for url: URL) {
        // Bridge to UIKit share sheet.
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.keyWindow?.rootViewController {
            root.present(av, animated: true)
        }
    }

    // MARK: - UI helpers

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Text("•")
            Text(text)
        }
    }
}

// MARK: - Previews

#if DEBUG
struct BackupView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackupView()
        }
        .environment(\.di, DIContainer.makePreview())
        .preferredColorScheme(.dark)
    }
}
#endif
