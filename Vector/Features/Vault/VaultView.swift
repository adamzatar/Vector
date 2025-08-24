//
//  VaultView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
// File: Features/Vault/VaultView.swift
//

import SwiftUI
import Foundation

struct VaultView: View {
    @Environment(\.di) private var di
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm: VaultViewModel

    init(container: DIContainer? = nil) {
        _vm = StateObject(wrappedValue: VaultViewModel(container: container ?? DIContainer.makeDefault()))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                BrandColor.surface.ignoresSafeArea()

                VStack(spacing: 0) {
                    SearchBar(
                        text: $vm.query,
                        placeholder: "Search tokens",
                        showsCancel: vm.query.isEmpty == false
                    )
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.s)
                    .padding(.bottom, Spacing.s)

                    content
                }
            }
            .navigationTitle("Vector")
            .toolbar { toolbar }
        }
        .onAppear { vm.onAppear() }
        .copyToastHost()
    }

    @ViewBuilder
    private var content: some View {
        Group {
            if vm.isLoading && vm.tokens.isEmpty {
                loadingState
            } else if vm.tokens.isEmpty && vm.query.isEmpty {
                emptyState
            } else {
                listState
            }
        }
        .refreshable { vm.pullFromCloud() }
        .overlay(alignment: .top) {
            if let err = vm.errorMessage {
                errorBanner(err)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: Spacing.m) {
            ProgressView()
            Text("Loading your vault…")
                .font(Typography.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BrandColor.surface)
    }

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                Image(systemName: "lock.circle")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(.secondary)
                    .padding(.top, Spacing.xl)

                Text("No tokens yet")
                    .brandTitle(.m)

                Text("Add your first account to start generating 2-factor codes.")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.l)

                PrimaryButton("Add Token", systemImage: "plus") {
                    router.showAddToken()
                }
                .padding(.horizontal, Spacing.l)

                Card.titled("Quick tips") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        bullet("Scan an otpauth:// QR code from your account’s security page.")
                        bullet("Or enter a Base32 secret manually.")
                        bullet("Everything stays encrypted on your devices.")
                    }
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, Spacing.m)
            }
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .background(BrandColor.surface)
    }

    private var listState: some View {
        List {
            if !allTags.isEmpty {
                tagsSection
            }

            ForEach(vm.filteredTokens, id: \.id) { token in
                TokenRow(
                    issuer: vm.displayIssuer(token),
                    account: vm.displayAccount(token),
                    color: token.color,
                    secondsRemaining: vm.secondsRemaining(for: token),
                    progress: vm.windowProgress(for: token),
                    onCopy: { vm.copyCode(for: token) }
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(BrandColor.surface)
            }
        }
        .listStyle(.plain)
        .background(BrandColor.surface)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.showSettings()
            } label: {
                Image(systemName: "gearshape")
                    .accessibilityLabel("Settings")
            }
            .minTapTarget()
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                router.showAddToken()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .accessibilityLabel("Add Token")
            }
            .minTapTarget()
        }
    }

    private var allTags: [String] {
        let set = Set(vm.tokens.flatMap { $0.tags })
        return set.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    @ViewBuilder
    private var tagsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    FilterChip(title: "All", isSelected: vm.selectedTag == nil) {
                        vm.selectedTag = nil
                    }
                    ForEach(allTags, id: \.self) { tag in
                        FilterChip(title: tag, isSelected: vm.selectedTag == tag) {
                            vm.selectedTag = tag
                        }
                    }
                }
                .padding(.vertical, Spacing.s)
                .padding(.leading, 2)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Text("•")
            Text(text)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: Spacing.m) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(.primary)
            Spacer()
            Button {
                withAnimation { vm.errorMessage = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .minTapTarget()
            .accessibilityLabel("Dismiss error")
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(BrandColor.surfaceSecondary.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(BrandColor.divider.opacity(0.6), lineWidth: 1)
                )
        )
        .padding(.horizontal, Spacing.m)
        .padding(.top, Spacing.m)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.bodyS)
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.primary.opacity(0.12) : Color.secondary.opacity(0.10))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .minTapTarget()
        .accessibilityLabel(Text(isSelected ? "\(title), selected" : title))
    }
}

#if DEBUG
struct VaultView_Previews: PreviewProvider {
    static var previews: some View {
        let container = DIContainer.makePreview()
        Task { await (container.vault as? InMemoryVaultStore)?.seedForPreview() }

        return NavigationStack {
            VaultView(container: container)
        }
        .environmentObject(AppRouter())
        .preferredColorScheme(.dark)
    }
}
#endif
