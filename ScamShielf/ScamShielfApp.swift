//
//  ScamShielfApp.swift
//  ScamShielf
//
//  Created by Emilio Saenz on 10/23/26.
//

import SwiftUI

@main
struct ScamShieldApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView().transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    OnboardingView().transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        }
    }
}
