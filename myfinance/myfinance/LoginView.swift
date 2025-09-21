//
//  LoginView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct LoginView: View {
    @Binding var showLogin: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var animateElements = false
    @State private var isLoggingIn = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.95, blue: 1.0),
                        Color(red: 0.9, green: 0.9, blue: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 20) {
                            HStack {
                                Button(action: {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        showLogin = false
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            Spacer()
                                .frame(height: 40)
                            
                            // Logo
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.8, green: 0.2, blue: 0.2))
                                    .frame(width: 100, height: 100)
                                
                                Text("B")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(animateElements ? 1.0 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
                            
                            VStack(spacing: 8) {
                                Text("Welcome Back")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                
                                Text("Sign in to your account")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        }
                        
                        Spacer()
                            .frame(height: 60)
                        
                        // Login Form
                        VStack(spacing: 24) {
                            // Username Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username or Email")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)
                                    
                                    TextField("Enter your username", text: $username)
                                        .font(.system(size: 16))
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)
                                    
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .font(.system(size: 16))
                                            .textFieldStyle(PlainTextFieldStyle())
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .font(.system(size: 16))
                                            .textFieldStyle(PlainTextFieldStyle())
                                    }
                                    
                                    Button(action: {
                                        showPassword.toggle()
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                            
                            // Remember Me & Forgot Password
                            HStack {
                                Button(action: {}) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.square")
                                            .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                        
                                        Text("Remember me")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {}) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                }
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.6).delay(1.0), value: animateElements)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Login Button
                        VStack(spacing: 20) {
                            Button(action: {
                                isLoggingIn = true
                                // Simulate login process
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    isLoggingIn = false
                                    // Handle successful login
                                }
                            }) {
                                HStack {
                                    if isLoggingIn {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(Color(red: 0.8, green: 0.2, blue: 0.2))
                                )
                            }
                            .disabled(isLoggingIn)
                            .scaleEffect(animateElements ? 1.0 : 0.9)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.2), value: animateElements)
                            
                            // Sign Up Link
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.secondary)
                                
                                Button(action: {}) {
                                    Text("Sign Up")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.8))
                                }
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                            .frame(height: 60)
                    }
                }
            }
        }
        .onAppear {
            animateElements = true
        }
    }
}

#Preview {
    LoginView(showLogin: .constant(true))
}
