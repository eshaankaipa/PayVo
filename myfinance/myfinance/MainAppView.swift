//
//  MainAppView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct MainAppView: View {
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var userDatabase = UserDatabase()
    @State private var showHomePage = false
    
    var body: some View {
        ZStack {
            if appStateManager.shouldShowSplash {
                SplashScreenView()
            } else if showHomePage {
                HomePageView(userDatabase: userDatabase)
                    .onDisappear {
                        showHomePage = false
                    }
            } else {
                VoiceAuthView()
            }
        }
        .environmentObject(appStateManager)
        .environmentObject(userDatabase)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoginSuccessful"))) { _ in
            showHomePage = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserLoggedOut"))) { _ in
            showHomePage = false
        }
        .gesture(
            DragGesture()
                .onEnded { dragValue in
                    let translation = dragValue.translation.height
                    let velocity = dragValue.velocity.height
                    
                    if translation > 200 && velocity > 800 {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                        impactFeedback.impactOccurred()
                        appStateManager.resetToSplash()
                        showHomePage = false
                    }
                }
        )
    }
}

#Preview {
    MainAppView()
}
