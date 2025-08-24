//
//  KeyboardAccessoryBar.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/AddToken/Components/KeyboardAccessoryBar.swift
//

import SwiftUI
import Foundation

/// A polished keyboard toolbar with quick actions:
/// - Scan QR, Paste from clipboard, and Done (dismiss).
/// - Drop-in via `.keyboardAccessoryBar(onScan:onPaste:onDone:)` on any container view.
/// - Uses semantic typography and respects Reduced Motion.
public struct KeyboardAccessoryBar: ViewModifier {
    public init(onScan: @escaping () -> Void,
                onPaste: @escaping () -> Void,
                onDone: @escaping () -> Void) {
        self.onScan = onScan
        self.onPaste = onPaste
        self.onDone = onDone
    }

    private let onScan: () -> Void
    private let onPaste: () -> Void
    private let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    HStack(spacing: Spacing.s) {
                        Button {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { onScan() }
                        } label: {
                            Label("Scan", systemImage: "qrcode.viewfinder") // Localize
                                .labelStyle(.titleAndIcon)
                        }

                        Button {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { onPaste() }
                        } label: {
                            Label("Paste", systemImage: "doc.on.clipboard") // Localize
                                .labelStyle(.titleAndIcon)
                        }

                        Spacer(minLength: Spacing.l)

                        Button {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) { onDone() }
                        } label: {
                            Label("Done", systemImage: "keyboard.chevron.compact.down") // Localize
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(Typography.body)
                }
            }
    }
}

public extension View {
    /// Adds a keyboard accessory bar with Scan/Paste/Done actions.
    func keyboardAccessoryBar(onScan: @escaping () -> Void,
                              onPaste: @escaping () -> Void,
                              onDone: @escaping () -> Void) -> some View {
        modifier(KeyboardAccessoryBar(onScan: onScan, onPaste: onPaste, onDone: onDone))
    }
}

#if DEBUG
struct KeyboardAccessoryBar_Previews: PreviewProvider {
    struct Demo: View {
        @State private var text = ""
        @FocusState private var focus: Bool
        var body: some View {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Text("Demo Field").font(Typography.titleS)
                TextField("Type something…", text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus)
                    .padding()
                    .background(BrandColor.surfaceSecondary, in: RoundedRectangle(cornerRadius: Layout.smallCorner))
            }
            .padding()
            .background(BrandColor.surface)
            .keyboardAccessoryBar(
                onScan: { /* present scanner */ },
                onPaste: { if let s = UIPasteboard.general.string { text = s } },
                onDone: { focus = false }
            )
        }
    }
    static var previews: some View {
        Demo()
            .preferredColorScheme(.dark)
    }
}
#endif
