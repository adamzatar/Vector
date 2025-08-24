//
//  SplashView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Onboarding/SplashView.swift
//

import SwiftUI

/// Componentized splash using animated background + reusable LogoMark.
/// Routes quickly to Intro (first run) or Vault.
/// Kept lean to meet cold-launch performance budget.
struct SplashView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.di) private var di

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var appear = false

    var body: some View {
        ZStack {
            SplashBackground()

            VStack(spacing: Spacing.m) {
                LogoMark(size: .large)
                    .scaleEffect(appear ? 1.0 : 0.96)
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.9).delay(0.05), value: appear)

                Text("Vector") // Localize
                    .font(Typography.titleXL)
                    .foregroundStyle(.white)
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.25).delay(0.15), value: appear)

                Text("Zero‑knowledge authenticator") // Localize
                    .font(Typography.bodyS)
                    .foregroundStyle(.white.opacity(0.85))
                    .opacity(appear ? 1.0 : 0.0)
                    .animation(.easeIn(duration: 0.25).delay(0.28), value: appear)
            }
            .padding()
        }
        .onAppear {
            di.logger.info("Splash appeared")
            appear = true
            routeSoon()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Vector — Zero‑knowledge authenticator")) // Localize
    }

    private func routeSoon() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000) // 0.65s
            if hasCompletedOnboarding {
                router.goHome()
            } else {
                router.showIntro()
            }
        }
    }
}

#if DEBUG
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
            .environmentObject(AppRouter())
            .environment(\.di, DIContainer.makePreview())
            .preferredColorScheme(.dark)
    }
}
#endif
