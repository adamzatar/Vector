//
//  Card.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
// File: UI/Components/Card.swift
//


import Foundation
import SwiftUI

/// Vector's reusable surface container with subtle elevation and consistent padding.
/// Monochrome identity: neutral surfaces, crisp 1pt divider, optional gradient wash.
/// - Accessibility: Sufficient contrast in light/dark, header adopts `.isHeader`.
/// - Customization: Provide a header and/or trailing accessory (e.g., button/badge).
public struct Card<Header: View, Content: View, Accessory: View>: View {
    private let header: Header?
    private let content: Content
    private let accessory: Accessory?

    private let cornerRadius: CGFloat
    private let insets: EdgeInsets
    private let showsBorder: Bool
    private let useWashBackground: Bool

    /// Designated initializer.
    /// - Parameters:
    ///   - cornerRadius: Corner radius; defaults to `Layout.cardCorner`.
    ///   - insets: Inner padding; defaults to `.card`.
    ///   - showsBorder: Draw a 1pt border for crisp separation on light backgrounds.
    ///   - useWashBackground: If `true`, applies a very subtle gradient wash instead of flat surface.
    ///   - header: Optional leading header view (title/label).
    ///   - accessory: Optional trailing accessory (button/badge).
    ///   - content: Main body content.
    public init(
        cornerRadius: CGFloat = Layout.cardCorner,
        insets: EdgeInsets = .card,
        showsBorder: Bool = true,
        useWashBackground: Bool = false,
        @ViewBuilder header: () -> Header,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.insets = insets
        self.showsBorder = showsBorder
        self.useWashBackground = useWashBackground
        let h = header()
        self.header = (h as? EmptyView) == nil ? h : nil
        let a = accessory()
        self.accessory = (a as? EmptyView) == nil ? a : nil
        self.content = content()
    }

    /// Convenience initializer without header/accessory.
    public init(
        cornerRadius: CGFloat = Layout.cardCorner,
        insets: EdgeInsets = .card,
        showsBorder: Bool = true,
        useWashBackground: Bool = false,
        @ViewBuilder content: () -> Content
    ) where Header == EmptyView, Accessory == EmptyView {
        self.cornerRadius = cornerRadius
        self.insets = insets
        self.showsBorder = showsBorder
        self.useWashBackground = useWashBackground
        self.header = nil
        self.accessory = nil
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: Spacing.s) {
            if header != nil || accessory != nil {
                HStack(alignment: .firstTextBaseline) {
                    header
                    Spacer(minLength: Spacing.s)
                    accessory
                }
                .font(Typography.titleS)
                .foregroundStyle(BrandColor.primaryText)
                .accessibilityAddTraits(.isHeader)
            }

            content
                .foregroundStyle(BrandColor.primaryText)
        }
        .padding(insets)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundFill)
        )
        .overlay(
            // Hairline divider for crisp edges (kept subtle in dark mode).
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(BrandColor.divider.opacity(showsBorder ? 0.6 : 0.0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: Layout.shadowRadiusSmall, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }

    private var backgroundFill: some ShapeStyle {
        if useWashBackground {
            // Very subtle wash over the secondary surface
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        BrandColor.surfaceSecondary.opacity(0.98),
                        BrandColor.surfaceSecondary.opacity(0.92)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            AnyShapeStyle(BrandColor.surfaceSecondary)
        }
    }
}

// MARK: - Sugar API

public extension Card where Header == Text, Accessory == EmptyView {
    /// Card with a simple text header.
    static func titled(_ title: String,
                       cornerRadius: CGFloat = Layout.cardCorner,
                       insets: EdgeInsets = .card,
                       showsBorder: Bool = true,
                       useWashBackground: Bool = false,
                       @ViewBuilder content: () -> Content) -> Card<Text, Content, EmptyView> {
        Card(cornerRadius: cornerRadius, insets: insets, showsBorder: showsBorder, useWashBackground: useWashBackground) {
            Text(title) // Localize
        } accessory: {
            EmptyView()
        } content: {
            content()
        }
    }
}

public extension Card where Header == Text, Accessory == AnyView {
    /// Card with a text header and a trailing accessory (e.g., button/badge).
    static func titled(_ title: String,
                       accessory: @escaping () -> some View,
                       cornerRadius: CGFloat = Layout.cardCorner,
                       insets: EdgeInsets = .card,
                       showsBorder: Bool = true,
                       useWashBackground: Bool = false,
                       @ViewBuilder content: () -> Content) -> Card<Text, Content, AnyView> {
        Card(cornerRadius: cornerRadius, insets: insets, showsBorder: showsBorder, useWashBackground: useWashBackground) {
            Text(title) // Localize
        } accessory: {
            AnyView(accessory())
        } content: {
            content()
        }
    }
}

// MARK: - Previews

#if DEBUG
struct Card_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    Card.titled("Quick Actions", useWashBackground: true) {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("Add your first token").font(Typography.body).foregroundStyle(.secondary)
                            PrimaryButton("Add Token", systemImage: "plus") {}
                        }
                    }

                    Card {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: "lock.shield")
                                .imageScale(.large)
                                .foregroundStyle(BrandColor.primaryText)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Face ID Lock").font(Typography.body)
                                Text("Require Face ID to open the vault")
                                    .font(Typography.caption)
                                    .foregroundStyle(.secondary) // Localize
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true)).labelsHidden()
                        }
                    }

                    Card.titled("Clipboard") {
                        HStack {
                            Text("Auto-clear timeout").font(Typography.body)
                            Spacer()
                            Text("20 s").font(Typography.monoM).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(BrandColor.surface)
            }
            .previewDisplayName("Light")

            ScrollView {
                VStack(spacing: Spacing.m) {
                    Card.titled("Quick Actions", useWashBackground: true) {
                        VStack(alignment: .leading, spacing: Spacing.s) {
                            Text("Add your first token").font(Typography.body).foregroundStyle(.secondary)
                            PrimaryButton("Add Token", systemImage: "plus") {}
                        }
                    }
                    Card {
                        HStack(spacing: Spacing.m) {
                            Image(systemName: "lock.shield")
                                .imageScale(.large)
                                .foregroundStyle(BrandColor.primaryText)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Face ID Lock").font(Typography.body)
                                Text("Require Face ID to open the vault")
                                    .font(Typography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true)).labelsHidden()
                        }
                    }
                    Card.titled("Clipboard") {
                        HStack {
                            Text("Auto-clear timeout").font(Typography.body)
                            Spacer()
                            Text("20 s").font(Typography.monoM).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(BrandColor.surface)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark")
        }
    }
}
#endif
