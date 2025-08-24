//
//  VectorApp.swift
//  Vector
//
//  Created by Adam Zaatar on 8/21/25.
//
// File: App/VectorApp.swift

import SwiftUI

@main
struct VectorApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            AppRootView()   // ✅ use your AppRootView
                .environmentObject(router)
                .environment(\.di, DIContainer.makeDefault())
        }
    }
}
