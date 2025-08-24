//
//  PaywallFeatureGrid.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
// ===============================
// File: Features/Paywall/Components/PaywallFeatureGrid.swift
// ===============================


import Foundation
import SwiftUI

/// A neat, trustworthy grid of Pro benefits.
public struct PaywallFeatureGrid: View {
    public struct Item: Hashable {
        public let system: String
        public let title: String
        public let subtitle: String
        public init(system: String, title: String, subtitle: String) {
            self.system = system; self.title = title; self.subtitle = subtitle
        }
    }

    public init(items: [Item] = PaywallFeatureGrid.defaultItems) { self.items = items }

    private let items: [Item]
    private let columns = [GridItem(.flexible(), spacing: Spacing.m),
                           GridItem(.flexible(), spacing: Spacing.m)]

    public var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.m) {
            ForEach(items, id: \.self) { i in
                HStack(alignment: .top, spacing: Spacing.m) {
                    Image(systemName: i.system)
                        .imageScale(.large)
                        .frame(width: 28)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(i.title)
                            .font(Typography.body)
                            .foregroundStyle(BrandColor.primaryText)
                        Text(i.subtitle)
                            .font(Typography.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
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
            }
        }
        .accessibilityElement(children: .contain)
    }
}

public extension PaywallFeatureGrid {
    static let defaultItems: [Item] = [
        .init(system: "icloud", title: "iCloud Sync", subtitle: "Your codes on all devices"),
        .init(system: "lock.shield", title: "Encrypted Backups", subtitle: "Bring your codes anywhere"),
        .init(system: "applewatch", title: "Watch & Widgets", subtitle: "2FA at a glance"),
        .init(system: "square.grid.2x2", title: "Icons & Bulk Import", subtitle: "Organize in seconds")
    ]
}

#if DEBUG
struct PaywallFeatureGrid_Previews: PreviewProvider {
    static var previews: some View {
        PaywallFeatureGrid()
            .padding()
            .background(BrandColor.surface)
            .preferredColorScheme(.dark)
    }
}
#endif
