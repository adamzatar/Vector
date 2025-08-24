//
//  SettingToggleRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/Settings/Components/SettingToggleRow.swift
//

import Foundation
import SwiftUI

/// A settings row with a trailing toggle.
struct SettingToggleRow: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    @Binding var isOn: Bool
    var onToggle: ((Bool) -> Void)? = nil

    var body: some View {
        SettingRow(title, subtitle: subtitle, systemImage: systemImage) {
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newVal in
                    isOn = newVal
                    onToggle?(newVal)
                }
            ))
            .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture { isOn.toggle(); onToggle?(isOn) }
    }
}
