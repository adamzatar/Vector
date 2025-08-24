//
//  PrimaryButton.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
// File: UI/Components/PrimaryButton.swift
//

import Foundation
import SwiftUI

/// Brand primary button with filled style and large hit area.
/// Supports optional system image, loading state, disabled state, and destructive role.
/// Uses monochrome-friendly styling (accent in Light, high-contrast in Dark).
public struct PrimaryButton: View {
    private let title: String
    private let systemImage: String?
    private let role: ButtonRole?
    private let action: () -> Void

    @State private var isPressed: Bool = false
    public var isLoading: Bool
    public var isDisabled: Bool

    public init(_ title: String,
                systemImage: String? = nil,
                role: ButtonRole? = nil,
                isLoading: Bool = false,
                isDisabled: Bool = false,
                action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.role = role
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(role: role) {
            guard !isLoading else { return }
            action()
        } label: {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .textCase(.none)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(backgroundFill)
            )
            .opacity(isDisabled ? 0.55 : 1.0)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation { isPressed = true } }
                .onEnded   { _ in withAnimation { isPressed = false } }
        )
        .disabled(isDisabled || isLoading)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(role == .destructive ? Text("Destructive action") : Text(""))
    }

    // MARK: - Styling

    @Environment(\.colorScheme) private var scheme

    private var backgroundFill: Color {
        if role == .destructive { return .red }
        // Use accent color for brand. In dark mode, bump contrast slightly.
        return scheme == .dark ? Color.accentColor.opacity(0.95) : Color.accentColor
    }
}

// MARK: - Convenience

public extension View {
    /// Sugar for conditionally disabling interactions.
    func isDisabledIf(_ condition: Bool) -> some View {
        self.disabled(condition)
    }
}
