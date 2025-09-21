//
//  SplashScreenView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var animateLogo = false
    
    // Color extracted from logo.png
    private let logoBackgroundColor = Color(red: 58/255, green: 115/255, blue: 208/255)
    
    var body: some View {
        ZStack {
            // Background color matching the logo
            logoBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 120)
                
                // PayVo text with updated styling
                VStack(spacing: 16) {
                    Text("PayVo")
                        .font(.system(size: 52, weight: .black, design: .rounded))
                        .italic()
                        .foregroundColor(.white)
                        .opacity(animateLogo ? 1.0 : 0.0)
                        .offset(y: animateLogo ? 0 : -20)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateLogo)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                    
                    // Subtitle underneath PayVo
                    Text("Say it. Pay it.")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.95))
                        .opacity(animateLogo ? 1.0 : 0.0)
                        .offset(y: animateLogo ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: animateLogo)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
            }
        }
        .onAppear {
            animateLogo = true
        }
    }
}

#Preview {
    SplashScreenView()
}
