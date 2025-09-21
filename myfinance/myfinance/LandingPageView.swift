//
//  LandingPageView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct LandingPageView: View {
    @Binding var showLogin: Bool
    @State private var animateElements = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.8, green: 0.9, blue: 1.0),
                        Color(red: 0.95, green: 0.95, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with logo
                    VStack(spacing: 20) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Logo and brand
                        VStack(spacing: 16) {
                            // Bank logo placeholder
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.8, green: 0.2, blue: 0.2))
                                    .frame(width: 80, height: 80)
                                
                                Text("B")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(animateElements ? 1.0 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
                            
                            VStack(spacing: 8) {
                                Text("MyFinance")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                
                                Text("Banking Made Simple")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Feature highlights
                        VStack(spacing: 24) {
                            FeatureRow(
                                icon: "creditcard.fill",
                                title: "Manage Accounts",
                                description: "View balances and transactions",
                                delay: 0.6
                            )
                            
                            FeatureRow(
                                icon: "shield.fill",
                                title: "Secure Banking",
                                description: "Bank-level security protection",
                                delay: 0.8
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Track Spending",
                                description: "Monitor your financial health",
                                delay: 1.0
                            )
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 30)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: animateElements)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                    
                    // Bottom section with login button
                    VStack(spacing: 20) {
                        Button(action: {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showLogin = true
                            }
                        }) {
                            HStack {
                                Text("Sign In")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color(red: 0.8, green: 0.2, blue: 0.2))
                            )
                        }
                        .scaleEffect(animateElements ? 1.0 : 0.9)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateElements)
                        
                        Button(action: {
                            // Handle create account
                        }) {
                            Text("Create Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 32)
                }
            }
        }
        .onAppear {
            animateElements = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.2, green: 0.3, blue: 0.8).opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .scaleEffect(animate ? 1.0 : 0.9)
        .opacity(animate ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    LandingPageView(showLogin: .constant(false))
}
