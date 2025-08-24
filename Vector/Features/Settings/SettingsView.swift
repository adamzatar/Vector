//
//  SettingsView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Settings/SettingsView.swift
//

import Foundation
import SwiftUI

/// Root Settings screen using modern section cards and rows.
/// Groups Security, Clipboard, Appearance, and About.
struct SettingsView: View {
    @Environment(\.di) private var di
    @EnvironmentObject private var router: AppRouter

    @State private var showPrivacyExplainer = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s) {
                    // SECURITY
                    SecuritySettingsView()

                    // CLIPBOARD
                    ClipboardSettingsView()

                    // APPEARANCE
                    SettingsSectionCard {
                        AppearanceSettingsView()
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, 12)
                    } header: {
                        Text("Appearance") // Localize
                    } footer: {
                        Text("Vector adapts to system dark/light mode. More themes coming soon.") // Localize
                    }

                    // ABOUT
                    SettingsSectionCard {
                        VStack(spacing: 0) {
                            SettingRow("Version", systemImage: "info.circle") {
                                Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                                    .font(Typography.body)
                                    .foregroundStyle(.secondary)
                            }
                            Divider()
                                .overlay(BrandColor.divider.opacity(0.6))
                                .padding(.leading, 54)

                            Button {
                                showPrivacyExplainer = true
                            } label: {
                                SettingRow("Privacy Explainer", systemImage: "hand.raised.fill") {
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .minTapTarget()
                        }
                    } header: {
                        Text("About") // Localize
                    } footer: {
                        EmptyView()
                    }
                }
                .padding(.vertical, Spacing.s)
                .padding(.bottom, Spacing.l)
            }
            .background(BrandColor.surface.ignoresSafeArea())
            .navigationTitle("Settings") // Localize
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.goHome()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .accessibilityLabel("Close") // Localize
                    }
                    .minTapTarget()
                }
            }
            .sheet(isPresented: $showPrivacyExplainer) {
                PrivacyExplainerView()
            }
        }
    }
}

// MARK: - Appearance Subview

/// Simple appearance section (placeholder for future themes/icons).
struct AppearanceSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var useSystem = true

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            SettingToggleRow(
                title: "Match System Appearance", // Localize
                systemImage: "circle.lefthalf.filled.righthalf.striped.horizontal",
                isOn: $useSystem
            )
            .disabled(true) // Using system for now

            HStack {
                Text("Current").font(Typography.body) // Localize
                Spacer()
                Text(scheme == .dark ? "Dark" : "Light") // Localize
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 6)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Privacy Explainer

private struct PrivacyExplainerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("End‑to‑End Encryption (E2EE)") // Localize
                        .brandTitle(.m)

                    Text("""
Vector encrypts your 2FA secrets before they ever touch iCloud. We cannot read your data. Your vault is locked by a key derived from your passphrase; the key is protected by the Secure Enclave where available.
""") // Localize
                    .font(Typography.body)
                    .foregroundStyle(.secondary)

                    Divider()

                    Text("Clipboard") // Localize
                        .brandTitle(.s)

                    Text("""
Copied codes clear automatically after a short delay. We never log clipboard contents.
""") // Localize
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.l)
            }
            .background(BrandColor.surface.ignoresSafeArea())
            .navigationTitle("Privacy") // Localize
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() } // Localize
                        .minTapTarget()
                }
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.di, DIContainer.makePreview())
            .environmentObject(AppRouter())
            .preferredColorScheme(.dark)
    }
}
#endif
