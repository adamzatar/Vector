//
//  AppRootView.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//
// File: App/AppRootView.swift



import Foundation
import SwiftUI

/// Single switchboard for the app’s high-level route.
/// Uses `AppRouter.route` and shows the real feature screens (no placeholders).
/// Each feature owns its own NavigationStack to avoid nested stacks & double toolbars.
/// Adds a subtle, animated brand mark at the very top (except on Splash) for a premium feel.
struct AppRootView: View {
    @EnvironmentObject private var router: AppRouter
    @Environment(\.di) private var di
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    /// Marketing-wise: keep the animated logo on all primary surfaces except splash,
    /// which already functions as a brand moment.
    private var showsGlobalLogo: Bool {
        switch router.route {
        case .splash:   return false
        case .intro,
             .vault,
             .addToken,
             .settings: return true
        }
    }

    var body: some View {
        ZStack {
            // Brand backdrop so transitions feel coherent between screens.
            BrandGradient.primary().ignoresSafeArea()

            Group {
                switch router.route {
                case .splash:
                    SplashView()
                        .onAppear {
                            // Route after a short splash: intro on first run, else vault
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 650_000_000)
                                hasCompletedOnboarding ? router.showVault() : router.showIntro()
                            }
                        }

                case .intro:
                    IntroScreen()

                case .vault:
                    // Vault is the home surface; it can own its own navigation.
                    NavigationStack {
                        VaultView()
                    }

                case .addToken:
                    NavigationStack {
                        AddTokenView(container: di)
                    }

                case .settings:
                    NavigationStack {
                        SettingsView()
                    }
                }
            }
            .transition(.opacity.combined(with: .scale)) // subtle, fast
            .animation(.easeInOut(duration: 0.18), value: router.route)
        }
        // Global, premium brand presence — top-center, restrained size.
        .if(showsGlobalLogo) { view in
            view.appHeaderLogoOverlay(size: 52, topPadding: 6)
        }
        // Global polish knobs (feel free to adjust)
        .tint(.white)
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
    }
}

#if DEBUG
struct AppRootView_Previews: PreviewProvider {
    static var previews: some View {
        let router = AppRouter()
        Group {
            AppRootView()
                .environmentObject(router)
                .environment(\.di, .makePreview())
                .onAppear { router.go(.splash) }

            AppRootView()
                .environmentObject(router)
                .environment(\.di, .makePreview())
                .onAppear { router.go(.intro) }

            AppRootView()
                .environmentObject(router)
                .environment(\.di, .makePreview())
                .onAppear { router.go(.vault) }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
