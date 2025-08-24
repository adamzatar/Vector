//
//  IntroScreen.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//  File: Features/Onboarding/IntroScreen.swift
//


import Foundation
import SwiftUI

/// First‑run intro explaining Vector’s privacy model with a modern, componentized UI.
/// Flow: SplashView → IntroScreen → Vault
/// - Sets `hasCompletedOnboarding = true` on continue.
/// - Uses monochrome brand gradient and clean motion.
/// - All building blocks live under Features/Onboarding/Components/.
struct IntroScreen: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.di) private var di

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var page: Int = 0
    private let pages = IntroPages.all

    var body: some View {
        ZStack {
            // Background wash: subtle motion using gradient + blur
            BrandGradient.primary()
                .ignoresSafeArea()
                .overlay(
                    VisualNoiseOverlay().allowsHitTesting(false)
                )

            VStack(spacing: Spacing.l) {
                IntroHeader(
                    title: "Welcome to Vector", // Localize
                    subtitle: "A zero‑knowledge authenticator that keeps your secrets on your devices." // Localize
                )
                .padding(.top, Spacing.xl)

                // Pager
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { idx, p in
                        IntroCard(
                            systemImage: p.systemImage,
                            title: p.title,
                            bodyOfIntro: p.body   // ⬅️ fixed label to match IntroCard init
                        )
                        .tag(idx)
                        .padding(.horizontal, Spacing.l)
                        .transition(.asymmetric(insertion: .scale.combined(with: .opacity),
                                                removal: .opacity))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 380)
                .animation(.easeInOut(duration: 0.2), value: page)

                PagerDots(count: pages.count, index: page)
                    .padding(.top, -Spacing.s)

                // CTAs
                VStack(spacing: Spacing.s) {
                    PrimaryButton(page == pages.count - 1 ? "Continue" : "Next") { // Localize
                        onPrimary()
                    }
                    SecondaryButton("Learn more") { // Localize
                        onSecondary()
                    }
                    .tint(.white)
                }
                .padding(.horizontal, Spacing.l)

                Spacer(minLength: Spacing.xl)
            }
            .padding(.bottom, Spacing.l)
        }
        .onAppear { di.logger.info("Intro appeared") }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Actions

    private func onPrimary() {
        if page < pages.count - 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) { page += 1 }
        } else {
            hasCompletedOnboarding = true
            router.goHome()
        }
    }

    private func onSecondary() {
        router.showSettings() // Quick path to Privacy Explainer
    }
}

// MARK: - Fun but subtle background texture (no perf hit)
private struct VisualNoiseOverlay: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        LinearGradient(
            colors: [
                .white.opacity(scheme == .dark ? 0.03 : 0.06),
                .black.opacity(scheme == .dark ? 0.12 : 0.06)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .blendMode(.overlay)
        .blur(radius: 20)
        .opacity(0.6)
    }
}

// MARK: - Previews

#if DEBUG
struct IntroScreen_Previews: PreviewProvider {
    static var previews: some View {
        IntroScreen()
            .environmentObject(AppRouter())
            .di(.makePreview())
            .preferredColorScheme(.dark)

        IntroScreen()
            .environmentObject(AppRouter())
            .di(.makePreview())
            .preferredColorScheme(.light)
    }
}
#endif
