//
//  Security.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Settings/Security.swift


import Foundation
import SwiftUI

/// Settings section for app lock / security features.
/// Controls Face ID / Touch ID requirement and auto-lock timeout.
struct SecuritySettingsView: View {
    @AppStorage("appLockEnabled") private var appLockEnabled: Bool = true
    @AppStorage("autoLockMinutes") private var autoLockMinutes: Int = 5

    private let options: [Int] = [1, 2, 5, 10, 30]

    var body: some View {
        SettingsSectionCard {
            SettingToggleRow(
                title: "Require Face ID / Passcode", // Localize
                systemImage: "lock.fill",
                isOn: $appLockEnabled
            )

            if appLockEnabled {
                Divider().overlay(BrandColor.divider.opacity(0.6)).padding(.leading, 54)

                SettingPickerRow(
                    title: "Auto‑lock after", // Localize
                    systemImage: "timer",
                    selection: $autoLockMinutes,
                    options: options,
                    labelTransform: { "\($0) min" } // Localize
                )
            }
        } header: {
            Text("Security") // Localize
        } footer: {
            Text("When enabled, Vector will lock after the selected delay or when backgrounded.") // Localize
        }
    }
}
