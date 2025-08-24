//
//  SearchBar.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Vault/Components/SearchBar.swift
//

import Foundation
import SwiftUI

/// A polished, reusable inline search bar (iOS 17+), suitable for embedding above lists.
/// - Features:
///   • `@Binding` text with optional debounced `onChange` callback
///   • Clear button and optional Cancel button
///   • Monochrome styling aligned with Vector
///   • Accessible labels and proper focus management
///
/// Usage:
/// ```swift
/// @State private var query = ""
/// SearchBar(text: $query, placeholder: "Search tokens") { debounced in
///     // filter with `debounced` if you want debounce; or react to `query` binding
/// }
/// ```
///
/// Notes:
/// - VaultView currently uses `.searchable`. You can either keep that or replace with `SearchBar`
///   to get an always-visible search UI and custom styling.
public struct SearchBar: View {
    @Binding private var text: String
    private let placeholder: String
    private let showsCancel: Bool
    private let debounce: Duration?
    private let onDebouncedChange: ((String) -> Void)?

    @FocusState private var focused: Bool
    @State private var debounceTask: Task<Void, Never>?

    @Environment(\.colorScheme) private var scheme

    // MARK: - Init

    public init(
        text: Binding<String>,
        placeholder: String = "Search", // Localize
        showsCancel: Bool = false,
        debounce: Duration? = .milliseconds(180),
        onDebouncedChange: ((String) -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.showsCancel = showsCancel
        self.debounce = debounce
        self.onDebouncedChange = onDebouncedChange
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: Spacing.s) {
            HStack(spacing: Spacing.s) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                // Text field
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .keyboardType(.webSearch)
                    .submitLabel(.search)
                    .focused($focused)
                    .onSubmit {
                        onDebouncedChange?(text)
                    }

                // Clear
                if !text.isEmpty {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { text = "" }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary.opacity(0.9))
                            .accessibilityLabel("Clear text") // Localize
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, 10)
            .background(searchFieldBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(BrandColor.divider.opacity(0.6), lineWidth: 1)
            )
            .cornerRadius(12)

            if showsCancel {
                Button("Cancel") { // Localize
                    text = ""
                    focused = false
                    UIAccessibility.post(notification: .announcement, argument: "Search cancelled") // Localize
                }
                .foregroundStyle(.primary)
                .minTapTarget()
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: text, debounce: debounce) { newValue in
            onDebouncedChange?(newValue)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Search")) // Localize
    }

    // MARK: - Styling

    private var searchFieldBackground: some ShapeStyle {
        if scheme == .dark {
            BrandColor.surfaceSecondary.opacity(0.75)
        } else {
            BrandColor.surfaceSecondary.opacity(0.9)
        }
    }
}

// MARK: - Debounce helper

private extension View {
    /// Debounce changes to a `Hashable` value with a `Task`-based delay.
    func onChange<T: Equatable>(
        of value: T,
        debounce: Duration?,
        action: @escaping (T) -> Void
    ) -> some View {
        modifier(DebounceChangeModifier(value: value, debounce: debounce, action: action))
    }
}

private struct DebounceChangeModifier<T: Equatable>: ViewModifier {
    let value: T
    let debounce: Duration?
    let action: (T) -> Void

    @State private var task: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onChange(of: value) { _, new in
                task?.cancel()
                guard let debounce else {
                    action(new); return
                }
                task = Task {
                    do {
                        try await Task.sleep(for: debounce)
                        guard !Task.isCancelled else { return }
                        await MainActor.run { action(new) }
                    } catch { /* cancelled */ }
                }
            }
            .onDisappear { task?.cancel(); task = nil }
    }
}

// MARK: - Previews

#if DEBUG
struct SearchBar_Previews: PreviewProvider {
    struct Demo: View {
        @State private var text = ""
        var body: some View {
            VStack(spacing: Spacing.m) {
                SearchBar(text: $text, placeholder: "Search tokens", showsCancel: true) { s in
                    // simulate a filter call
                    print("Debounced:", s) // Safe in preview; no logger here
                }
                .padding(.horizontal)

                List {
                    ForEach(sample.filter { text.isEmpty ? true : $0.localizedCaseInsensitiveContains(text) }, id: \.self) { s in
                        Text(s)
                    }
                }
                .listStyle(.plain)
            }
            .background(BrandColor.surface)
        }

        private let sample = ["GitHub", "AWS", "Cloudflare", "Google", "Dropbox", "Twitter", "Microsoft"]
    }

    static var previews: some View {
        Demo()
            .preferredColorScheme(.dark)
        Demo()
            .preferredColorScheme(.light)
    }
}
#endif
