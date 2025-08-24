//
//  SettingsSectionsCard.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/Settings/Components/SettingsSectionCard.swift
//

import Foundation
import SwiftUI

/// A modern section container for Settings. Renders a subtle card with header and optional footer.
struct SettingsSectionCard<Content: View, Header: View, Footer: View>: View {
    @ViewBuilder var content: Content
    @ViewBuilder var header: Header
    @ViewBuilder var footer: Footer

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.content = content()
        self.header = header()
        self.footer = footer()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.s)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BrandColor.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(BrandColor.divider.opacity(0.7), lineWidth: 1)
                    )
            )
            .padding(.top, Spacing.s)

            footer
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.s)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
    }
}
