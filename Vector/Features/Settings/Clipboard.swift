//
//  Clipboard.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Settings/Clipboard.swift
//

import Foundation
import SwiftUI

/// Settings section for clipboard handling.
/// Lets the user configure how long copied codes stay before auto-clear.
struct ClipboardSettingsView: View {
    @AppStorage("clipboardTimeoutSec") private var clipboardTimeout: Int = 20
    private let options: [Int] = [10, 20, 30, 60]

    var body: some View {
        SettingsSectionCard {
            SettingPickerRow(
                title: "Clear after", // Localize
                systemImage: "scissors",
                selection: $clipboardTimeout,
                options: options,
                labelTransform: { "\($0) seconds" } // Localize
            )
        } header: {
            Text("Clipboard") // Localize
        } footer: {
            Text("Codes you copy will be cleared from the clipboard after this delay.") // Localize
        }
    }
}
