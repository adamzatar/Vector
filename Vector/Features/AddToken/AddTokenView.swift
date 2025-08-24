//
//  AddTokenView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/AddToken/AddTokenView.swift
//


import SwiftUI
import Foundation

/// Manual + QR “Add Token” screen (brand components only; no raw TextField/SecureField).
/// Business logic lives in `AddTokenViewModel`.
struct AddTokenView: View {
    @Environment(\.di) private var di
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm: AddTokenViewModel

    @State private var scanURI: String = ""
    @State private var showingError = false
    @State private var scanning = false
    @State private var parseError: String?

    // MARK: Init
    init(container: DIContainer? = nil) {
        _vm = StateObject(wrappedValue: AddTokenViewModel(container: container ?? DIContainer.makeDefault()))
    }

    // MARK: Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    headerBlock
                    accountCard
                    secretCard
                    parametersCard
                    presentationCard
                    previewCard
                    scanImportCard
                }
                .padding(.horizontal, Spacing.m)
                .padding(.vertical, Spacing.m)
                .background(BrandColor.surface.ignoresSafeArea())
            }
            .navigationTitle("Add Token") // Localize
            .toolbar { toolbar }
            .scrollDismissesKeyboard(.interactively)
            .alert("Cannot Save", isPresented: $showingError) {
                Button("OK", role: .cancel) { showingError = false }
            } message: { Text(vm.errorMessage ?? "") }
            .alert("Invalid QR", isPresented: .constant(parseError != nil)) {
                Button("OK", role: .cancel) { parseError = nil }
            } message: { Text(parseError ?? "") }
            .sheet(isPresented: $scanning) { scannerSheet }
        }
        .appHeaderLogoOverlay(size: 48, topPadding: 2)
        .onChange(of: vm.errorMessage) { _, new in showingError = (new?.isEmpty == false) }
    }

    // MARK: Sections

    @ViewBuilder private var headerBlock: some View {
        AddTokenHeroHeader(
            title: "Add Token",
            subtitle: "Scan a QR or enter details manually" // Localize
        )
    }

    @ViewBuilder private var accountCard: some View {
        Card.titled("Account") {
            IssuerAccountFields(
                issuer: $vm.issuer,
                account: $vm.account
            )
            .padding(.top, 2)

            Text("Your secret stays encrypted on your device. We can’t read it.") // Localize
                .font(Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    @ViewBuilder private var secretCard: some View {
        Card.titled("Secret") {
            // Component expects `text:` binding
            Base32SecretField(text: $vm.secretBase32)
            // Optional validation UI (if your component set exposes it):
            // SecretValidationIndicator(isValid: vm.isSecretValid)
            // ValidationHintRow(text: vm.secretValidationMessage)
        }
    }

    @ViewBuilder private var parametersCard: some View {
        Card.titled("Security Parameters") {
            VStack(spacing: Spacing.s) {
                Picker("Algorithm", selection: $vm.selectedAlgo) { // Localize
                    ForEach(OTPAlgorithm.allCases, id: \.self) { algo in
                        Text(algo.rawValue).tag(algo)
                    }
                }

                HStack(spacing: Spacing.m) {
                    Stepper {
                        HStack {
                            Text("Digits") // Localize
                            Spacer()
                            Text("\(vm.digits)").font(Typography.monoM).foregroundStyle(.secondary)
                        }
                    } onIncrement: { vm.digits = min(8, vm.digits + 2) }
                      onDecrement: { vm.digits = max(6, vm.digits - 2) }

                    Stepper {
                        HStack {
                            Text("Period") // Localize
                            Spacer()
                            Text("\(vm.period) s").font(Typography.monoM).foregroundStyle(.secondary)
                        }
                    } onIncrement: { vm.period = min(120, vm.period + 5) }
                      onDecrement: { vm.period = max(15, vm.period - 5) }
                }

                Text("Most services use 6 digits and a 30-second period with SHA-1.") // Localize
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
    }

    @ViewBuilder private var presentationCard: some View {
        Card.titled("Presentation") {
            VStack(alignment: .leading, spacing: Spacing.m) {
                Picker("Color Label", selection: Binding<TokenColor>(
                    get: { vm.color ?? .gray },
                    set: { vm.color = $0 }
                )) { // Localize
                    ForEach(TokenColor.allCases, id: \.self) { color in
                        HStack(spacing: Spacing.s) {
                            Circle().fill(color.color).frame(width: 12, height: 12)
                            Text(colorDisplayName(color))
                        }
                        .tag(color)
                    }
                }

                // Chip-based tag editor (no raw TextField here)
                TagInputChips(
                    tags: $vm.tags,
                    placeholder: "Comma or space to add" // Localize
                )

                if !vm.tags.isEmpty {
                    AddTokenTagCloud(tags: vm.tags)
                        .padding(.top, 2)
                }
            }
        }
    }

    @ViewBuilder private var previewCard: some View {
        TokenPreviewCard(
            issuer: vm.issuer,
            account: vm.account,
            color: vm.color,
            digits: vm.digits,
            period: vm.period
        )
    }

    @ViewBuilder private var scanImportCard: some View {
        Card.titled("Scan / Import") {
            VStack(spacing: Spacing.s) {
                PrimaryButton("Scan QR", systemImage: "qrcode.viewfinder") { // Localize
                    scanning = true
                }

                // Brand URI paste component — expects a `text:` binding
                AddTokenURIParseField(
                    text: $scanURI,
                    onParse: { uri in handleURIParse(uri) }
                )

                Text("Supports otpauth:// URIs. Guided imports coming soon.") // Localize
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Scanner sheet
    @ViewBuilder private var scannerSheet: some View {
        QRScannerView { uri in
            do {
                let p = try OTPAuthParser.parse(uri)
                vm.issuer = p.issuer
                vm.account = p.account
                vm.secretBase32 = p.secretBase32
                vm.selectedAlgo = p.algorithm
                vm.digits = p.digits
                vm.period = p.period
            } catch let err as AppError {
                if case let .validation(msg) = err { parseError = msg }
                else { parseError = err.localizedDescription }
            } catch {
                parseError = error.localizedDescription
            }
        }
        .preferredColorScheme(.dark)
        .appHeaderLogoOverlay(size: 44, topPadding: 8)
    }

    // MARK: Toolbar
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { router.goHome() } // Localize
                .minTapTarget()
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                vm.saveManual()
            } label: {
                if vm.isSaving { ProgressView() } else { Text("Save") } // Localize
            }
            .disabled(!vm.canSave || vm.isSaving)
            .minTapTarget()
        }
    }

    // MARK: Helpers
    private func colorDisplayName(_ c: TokenColor) -> String {
        switch c {
        case .blue: return "Blue"
        case .orange: return "Orange"
        case .green: return "Green"
        case .purple: return "Purple"
        case .gray: return "Gray"
        }
    }

    private func handleURIParse(_ uri: String) {
        do {
            let p = try OTPAuthParser.parse(uri)
            vm.issuer = p.issuer
            vm.account = p.account
            vm.secretBase32 = p.secretBase32
            vm.selectedAlgo = p.algorithm
            vm.digits = p.digits
            vm.period = p.period
        } catch let err as AppError {
            if case let .validation(msg) = err { parseError = msg } else { parseError = err.localizedDescription }
        } catch {
            parseError = error.localizedDescription
        }
    }
}

#if DEBUG
struct AddTokenView_Previews: PreviewProvider {
    static var previews: some View {
        let c = DIContainer.makePreview()
        NavigationStack { AddTokenView(container: c) }
            .environmentObject(AppRouter())
            .preferredColorScheme(.dark)
    }
}
#endif
