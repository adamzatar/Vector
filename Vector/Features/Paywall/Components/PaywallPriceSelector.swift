//
//  PaywallPriceSelector.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//
// ===============================
// File: Features/Paywall/Components/PaywallPriceSelector.swift
// ===============================

import Foundation
import SwiftUI

/// Segmented "Monthly vs Lifetime" selector with polished cards.
public struct PaywallPriceSelector<Plan: Hashable>: View {
    public struct Option: Hashable {
        public let plan: Plan
        public let title: String
        public let price: String
        public init(plan: Plan, title: String, price: String) {
            self.plan = plan; self.title = title; self.price = price
        }
    }

    public init(selected: Binding<Plan>, options: [Option]) {
        self._selected = selected; self.options = options
    }

    @Binding private var selected: Plan
    private let options: [Option]

    public var body: some View {
        HStack(spacing: Spacing.m) {
            ForEach(options, id: \.self) { opt in
                SelectCard(isSelected: opt.plan == selected,
                           title: opt.title,
                           subtitle: opt.price) {
                    selected = opt.plan
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SelectCard: View {
    let isSelected: Bool
    let title: String
    let subtitle: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(title).font(Typography.body)
                Text(subtitle).font(Typography.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCorner, style: .continuous)
                    .fill(isSelected ? BrandColor.surface : BrandColor.surfaceSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCorner, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : BrandColor.divider.opacity(0.6), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#if DEBUG
struct PaywallPriceSelector_Previews: PreviewProvider {
    enum Plan { case monthly, lifetime }
    static var previews: some View {
        StatefulPreview()
            .padding()
            .background(BrandColor.surface)
            .preferredColorScheme(.dark)
    }

    private struct StatefulPreview: View {
        @State var selected: Plan = .monthly
        var body: some View {
            PaywallPriceSelector(
                selected: $selected,
                options: [
                    .init(plan: .monthly, title: "Monthly",  price: "$0.99"),
                    .init(plan: .lifetime, title: "Lifetime", price: "$14.99")
                ]
            )
        }
    }
}
#endif
