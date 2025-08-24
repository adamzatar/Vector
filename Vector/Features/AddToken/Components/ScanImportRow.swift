//
//  ScanImportRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/ScanImportRow.swift
//

import SwiftUI
import Foundation

/// Polished “Scan / Import” row for Add Token (binding-friendly).
/// - Primary CTA: Scan QR
/// - Optional: inline paste of `otpauth://` URI with quick validate + Parse
/// - Uses an external `text` binding so callers can control/inspect the value.
///
/// Usage:
/// ```swift
/// @State private var scanURI = ""
/// ScanImportRow(
///   title: "Scan or Paste",
///   subtitle: "Fastest way to add",
///   systemImage: "qrcode.viewfinder",
///   text: $scanURI,
///   showPasteField: true,
///   onScan: { scanning = true },
///   onParse: {
///     let trimmed = scanURI.trimmingCharacters(in: .whitespacesAndNewlines)
///     guard !trimmed.isEmpty else { return }
///     handleURIParse(trimmed)
///   }
/// )
/// ```
public struct ScanImportRow: View {
    // MARK: Inputs
    public var title: String
    public var subtitle: String
    public var systemImage: String
    @Binding public var text: String
    public var showPasteField: Bool
    public var onScan: () -> Void
    public var onParse: () -> Void

    // MARK: Local state & env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealPaste: Bool = false
    @State private var justParsed: Bool = false

    // MARK: Init
    public init(
        title: String,
        subtitle: String,
        systemImage: String = "qrcode.viewfinder",
        text: Binding<String>,
        showPasteField: Bool = true,
        onScan: @escaping () -> Void,
        onParse: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self._text = text
        self.showPasteField = showPasteField
        self.onScan = onScan
        self.onParse = onParse
    }

    // MARK: Derived
    private var isValidURI: Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("otpauth://")
    }

    // MARK: Body
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            // Header
            HStack(spacing: Spacing.s) {
                Image(systemName: systemImage).imageScale(.large)
                Text(title).font(Typography.body)
                Spacer()
                if showPasteField {
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                            revealPaste.toggle()
                        }
                    } label: {
                        Label(revealPaste ? "Hide Paste" : "Paste URI", systemImage: revealPaste ? "chevron.up" : "chevron.down") // Localize
                            .labelStyle(.titleAndIcon)
                            .font(Typography.caption)
                            .padding(.horizontal, Spacing.s)
                            .padding(.vertical, 6)
                            .background(BrandColor.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .minTapTarget()
                }
            }
            .foregroundStyle(BrandColor.primaryText)

            // Scan CTA
            Button { onScan() } label: {
                HStack(spacing: Spacing.m) {
                    Image(systemName: "camera.viewfinder").imageScale(.large)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan QR Code").font(Typography.body) // Localize
                        Text(subtitle).font(Typography.caption).foregroundStyle(.secondary) // Localize
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                        .fill(BrandColor.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                        .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .minTapTarget()

            // Paste field (collapsible)
            if showPasteField && revealPaste {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "link")
                            .imageScale(.medium)
                            .foregroundStyle(.secondary)
                        TextField("Paste otpauth:// URI", text: $text, axis: .vertical) // Localize
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .lineLimit(1...3)
                            .font(Typography.monoM)
                    }
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                            .fill(BrandColor.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.smallCorner, style: .continuous)
                            .stroke(isValidURI ? .green : BrandColor.divider.opacity(0.6), lineWidth: 1)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: isValidURI)
                    )

                    HStack {
                        Button {
                            onParse()
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
                                justParsed = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                                    justParsed = false
                                }
                            }
                        } label: {
                            Label("Parse", systemImage: "arrow.down.doc") // Localize
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValidURI)

                        if justParsed {
                            Text("Parsed")
                                .font(Typography.caption)
                                .foregroundStyle(.secondary)
                                .transition(.opacity)
                        }

                        Spacer()
                        Text(isValidURI ? "Looks valid" : "Starts with otpauth://")
                            .font(Typography.caption)
                            .foregroundStyle(isValidURI ? .green : .secondary)
                    }
                }
            }

            // Footer note
            Text("Scanning & paste happen on-device. We never send your secret anywhere.") // Localize
                .font(Typography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCorner, style: .continuous)
                .fill(BrandColor.surfaceSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCorner, style: .continuous)
                .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Preview
#if DEBUG
struct ScanImportRow_Previews: PreviewProvider {
    @State static var demoURI = ""
    static var previews: some View {
        VStack(spacing: Spacing.l) {
            ScanImportRow(
                title: "Scan or Paste",
                subtitle: "Fastest way to add",
                systemImage: "qrcode.viewfinder",
                text: $demoURI,
                showPasteField: true,
                onScan: {},
                onParse: {}
            )
            ScanImportRow(
                title: "Scan only",
                subtitle: "Paste hidden",
                systemImage: "qrcode.viewfinder",
                text: $demoURI,
                showPasteField: false,
                onScan: {},
                onParse: {}
            )
        }
        .padding()
        .background(BrandColor.surface)
        .preferredColorScheme(.dark)
    }
}
#endif
