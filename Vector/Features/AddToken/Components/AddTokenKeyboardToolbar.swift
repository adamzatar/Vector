//
//  AddTokenKeyboardToolbar.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/AddTokenKeyboardToolbar.swift
//

import SwiftUI
import Foundation

/// Reusable keyboard accessory toolbar for the Add Token form.
/// - Shows Previous / Next / Done actions with large tap targets.
/// - You control navigation by passing `prev`, `next`, and `done` closures.
/// - Respects Dynamic Type and Reduce Motion, and uses brand styling.
///
/// Usage (example):
/// ```swift
/// @FocusState private var focus: Field?
/// VStack { … }
///   .addTokenKeyboardToolbar(
///       showPrev: focus != .issuer,
///       showNext: focus != .tags,
///       prev:  { moveToPreviousField() },
///       next:  { moveToNextField() },
///       done:  { focus = nil }
///   )
/// ```
public struct AddTokenKeyboardToolbar: ViewModifier {
    let showPrev: Bool
    let showNext: Bool
    let prev: () -> Void
    let next: () -> Void
    let done: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack(spacing: Spacing.s) {
                        if showPrev {
                            Button {
                                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { prev() }
                            } label: {
                                toolbarPill(icon: "chevron.left", title: "Previous")
                            }
                            .accessibilityLabel(Text("Previous field")) // Localize
                        }

                        if showNext {
                            Button {
                                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { next() }
                            } label: {
                                toolbarPill(icon: "chevron.right", title: "Next")
                            }
                            .accessibilityLabel(Text("Next field")) // Localize
                        }

                        Spacer(minLength: Spacing.m)

                        Button {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { done() }
                        } label: {
                            Text("Done") // Localize
                                .font(Typography.body)
                                .padding(.horizontal, Spacing.m)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(BrandColor.accent.opacity(0.16))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Color.accentColor, lineWidth: 1)
                                )
                        }
                        .accessibilityLabel(Text("Dismiss keyboard")) // Localize
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: appeared)
                    .onAppear { appeared = true }
                }
            }
    }

    @ViewBuilder
    private func toolbarPill(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).imageScale(.medium)
            Text(title).font(Typography.body)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(BrandColor.surfaceSecondary)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(BrandColor.divider.opacity(0.6), lineWidth: 1)
        )
        .foregroundStyle(BrandColor.primaryText)
    }
}

public extension View {
    /// Attach the Add-Token keyboard toolbar to any view.
    func addTokenKeyboardToolbar(
        showPrev: Bool = true,
        showNext: Bool = true,
        prev: @escaping () -> Void,
        next: @escaping () -> Void,
        done: @escaping () -> Void
    ) -> some View {
        modifier(AddTokenKeyboardToolbar(showPrev: showPrev, showNext: showNext, prev: prev, next: next, done: done))
    }
}

// MARK: - Preview

#if DEBUG
private struct _PreviewHarness: View {
    @State private var issuer = ""
    @State private var account = ""
    @State private var secret  = ""
    @FocusState private var focus: Field?

    enum Field { case issuer, account, secret }

    var body: some View {
        Form {
            TextField("Issuer", text: $issuer).focused($focus, equals: .issuer)
            TextField("Account", text: $account).focused($focus, equals: .account)
            SecureField("Secret", text: $secret).focused($focus, equals: .secret)
        }
        .addTokenKeyboardToolbar(
            showPrev: focus != .issuer,
            showNext: focus != .secret,
            prev:  { move(-1) },
            next:  { move(1) },
            done:  { focus = nil }
        )
        .onAppear { focus = .issuer }
        .background(BrandColor.surface)
    }

    private func move(_ delta: Int) {
        let order: [Field] = [.issuer, .account, .secret]
        guard let idx = order.firstIndex(of: focus ?? .issuer) else { return }
        let newIdx = (idx + delta).clamped(to: 0...(order.count - 1))
        focus = order[newIdx]
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}

struct AddTokenKeyboardToolbar_Previews: PreviewProvider {
    static var previews: some View {
        _PreviewHarness()
            .preferredColorScheme(.dark)
    }
}
#endif
