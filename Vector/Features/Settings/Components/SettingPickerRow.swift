//
//  SettingPickerRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/Settings/Components/SettingPickerRow.swift
//

import Foundation
import SwiftUI

/// A settings row with a trailing picker menu.
struct SettingPickerRow<Selection: Hashable & CustomStringConvertible>: View {
    let title: String
    var systemImage: String? = nil
    @Binding var selection: Selection
    let options: [Selection]
    var labelTransform: (Selection) -> String = { "\($0)" }

    var body: some View {
        SettingRow(title, systemImage: systemImage) {
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button {
                        selection = opt
                    } label: {
                        HStack {
                            Text(labelTransform(opt))
                            if opt == selection {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(labelTransform(selection))
                        .font(Typography.body)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule().fill(BrandColor.surface.opacity(0.6))
                )
            }
            .buttonStyle(.plain)
            .minTapTarget()
        }
    }
}
