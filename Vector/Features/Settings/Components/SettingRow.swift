//
//  SettingRow.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/Settings/Components/SettingRow.swift
//

import Foundation
import SwiftUI

/// A basic settings row with a title, optional subtitle, leading icon, and trailing custom content.
struct SettingRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    @ViewBuilder var trailing: Trailing

    init(
        _ title: String,
        subtitle: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: Spacing.m) {
            if let systemImage {
                Image(systemName: systemImage)
                    .frame(width: 22)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Typography.body)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: Spacing.m)
            trailing
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, 12)
        .background(
            Rectangle().fill(Color.clear)
        )
        .accessibilityElement(children: .combine)
    }
}
