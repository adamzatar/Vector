//
//  PaywallView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/23/25.
//  File: Features/Paywall/PaywallView.swift
//

import Foundation
import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    enum Plan: Hashable { case monthly, lifetime }
    @State private var selected: Plan = .monthly
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    // Injected by a container or caller that loads products
    let monthly: Product?
    let lifetime: Product?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                PaywallHeader()

                PaywallFeatureGrid()
                    .padding(.top, Spacing.s)

                PaywallPriceSelector(
                    selected: $selected,
                    options: [
                        .init(plan: .monthly,  title: "Monthly",  price: monthly?.displayPrice ?? "$0.99"),
                        .init(plan: .lifetime, title: "Lifetime", price: lifetime?.displayPrice ?? "$14.99")
                    ]
                )

                PrimaryButton(isPurchasing ? "Purchasing…" : "Unlock Pro") {
                    Task { await purchase() }
                }
                .isDisabledIf(isPurchasing || (selected == .monthly && monthly == nil) || (selected == .lifetime && lifetime == nil))

                Button("Restore Purchases") { Task { await restore() } }
                    .buttonStyle(.bordered)

                Button("Maybe later") { dismiss() }
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)

                Text("No ads. No tracking. Cancel anytime.")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(.horizontal, Spacing.l)
            .padding(.bottom, Spacing.xl)
        }
        .background(BrandGradient.primary().ignoresSafeArea())
        .task { log("paywall_shown") }
        .alert("Purchase Failed", isPresented: .constant(errorMessage != nil)) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    // MARK: - StoreKit actions (self-contained)

    private func purchase() async {
        guard let product = (selected == .monthly ? monthly : lifetime) else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    log("pro_purchased", ["product": product.id])
                    dismiss()
                } else {
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled, .pending:
                // No error UI for cancel/pending
                break
            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        do {
            try await AppStore.sync()
            var restored = false
            for await status in Transaction.currentEntitlements {
                if case .verified(let t) = status, t.productID.hasPrefix("pro.") {
                    restored = true
                }
            }
            if restored { dismiss() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Minimal local metrics (no DI)

    private func log(_ event: String, _ props: [String: String] = [:]) {
        #if DEBUG
        print("📊 \(event) \(props)")
        #endif
        // If you later add Metrics service in DI, replace with: di.metrics.log(.paywall_shown) etc.
    }
}

#if DEBUG
struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(monthly: nil, lifetime: nil)
            .preferredColorScheme(.dark)
    }
}
#endif
