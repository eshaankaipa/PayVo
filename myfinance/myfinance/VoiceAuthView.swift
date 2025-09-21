//
//  VoiceAuthView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI
import AVFoundation

struct VoiceAuthView: View {
    @StateObject private var voiceManager = VoiceBiometricManager()
    @EnvironmentObject var userDatabase: UserDatabase
    @State private var showOptions = false
    @State private var animateElements = false
    @State private var showMergeAccount = false
    @State private var showHomePage = false
    @State private var isAuthenticating = false
    @State private var showDeleteAccount = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color matching the PayVo logo
                Color(red: 58/255, green: 115/255, blue: 208/255)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    Spacer()
                        .frame(height: 1)
                    
                    // Voice interface
                    VStack(spacing: 1) {
                        // Instruction text above microphone
                        Text(userDatabase.allAccounts.isEmpty ? "Speak your command" : "Speak your login credentials")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .italic()
                            .foregroundColor(.white)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.4), value: animateElements)
                        
                        // Microphone button
                        ZStack {
                            // Pulse rings - always present to prevent layout shifts
                            Circle()
                                .stroke(FinanceColors.primaryRed.opacity(0.3), lineWidth: 3)
                                .frame(width: 320, height: 320)
                                .scaleEffect(voiceManager.isRecording ? 1.5 : 1.0)
                                .opacity(voiceManager.isRecording ? 0.0 : 0.0)
                                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: voiceManager.isRecording)
                            
                            Circle()
                                .stroke(FinanceColors.primaryRed.opacity(0.2), lineWidth: 3)
                                .frame(width: 360, height: 360)
                                .scaleEffect(voiceManager.isRecording ? 1.3 : 1.0)
                                .opacity(voiceManager.isRecording ? 0.0 : 0.0)
                                .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false).delay(0.5), value: voiceManager.isRecording)
                            
                            // Main microphone button
                            Button(action: {
                                if userDatabase.allAccounts.isEmpty {
                                    // No accounts exist - just start/stop listening for demo
                                    if voiceManager.isRecording {
                                        voiceManager.stopRecording()
                                    } else {
                                        voiceManager.startRecording()
                                        // Also implement voice activity detection for demo mode
                                        startDemoVoiceActivityDetection()
                                    }
                                } else {
                                    // Accounts exist - toggle voice authentication
                                    if voiceManager.isRecording {
                                        // Stop recording and process authentication
                                        processVoiceAuthentication()
                                    } else {
                                        // Start voice authentication
                                        handleVoiceAuthentication()
                                    }
                                }
                            }) {
                                ZStack {
                                    // Completely static background circle
                                    Circle()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(width: 180, height: 180)
                                        .shadow(color: .black.opacity(0.6), radius: 15, x: 0, y: 8)
                                        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.4), lineWidth: 2)
                                        )
                                    
                                    // Completely static icon - never changes
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 70, weight: .medium))
                                        .foregroundColor(FinanceColors.primaryRed)
                                        .frame(width: 70, height: 70)
                                }
                            }
                            .frame(width: 180, height: 180)
                            .scaleEffect(animateElements ? 1.0 : 0.9)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateElements)
                        }
                        .frame(width: 360, height: 360)
                        
                        // Status text below microphone - fixed height to prevent layout shifts
                        VStack(spacing: 8) {
                            Text(voiceManager.isRecording ? "Listening..." : (userDatabase.allAccounts.isEmpty ? "Tap to speak" : ""))
                                .font(.system(size: 20, weight: .medium, design: .default))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(height: 22) // Fixed height for status text
                            
                                // Show recognized text - hidden from user view
                                Text("")
                                    .font(FinanceFonts.bodySmall)
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .frame(height: 40) // Fixed height for recognized text
                                
                                // Show authentication status - always present but invisible when not authenticating
                                HStack(spacing: 8) {
                                    if isAuthenticating {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Authenticating...")
                                            .font(.system(size: 20, weight: .medium, design: .default))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                .frame(height: 20) // Fixed height for auth status
                            
                        }
                        .frame(height: 50) // Much smaller spacer
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                    }
                    
                    // Quick options based on user state - moved up to replace error message area
                    VStack(spacing: 16) {
                        if userDatabase.allAccounts.isEmpty {
                            // No accounts - show create account option (delete button removed for new users)
                            Text("New to this App?")
                                .font(FinanceFonts.label)
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(spacing: 20) {
                                VoiceCommandButton(
                                    title: "Create Account",
                                    icon: "person.badge.plus",
                                    action: {
                                        showMergeAccount = true
                                    }
                                )
                                
                                // Delete button temporarily removed for new users
                            }
                        } else {
                            // Accounts exist - show account options
                            Spacer()
                                .frame(height: 20)
                            
                            Text("Account Options")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 20) {
                                VoiceCommandButton(
                                    title: "Create New Account",
                                    icon: "person.badge.plus",
                                    action: {
                                        showMergeAccount = true
                                    }
                                )
                                
                                VoiceCommandButton(
                                    title: "Delete Account",
                                    icon: "trash.fill",
                                    action: {
                                        showDeleteAccount = true
                                    }
                                )
                            }
                        }
                    }
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(1.0), value: animateElements)
                    
                    Spacer()
                        .frame(height: 60)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            animateElements = true
        }
        .gesture(
            // Add swipe down gesture to dismiss/go back
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 && value.velocity.height > 500 {
                        // Swipe down detected - could trigger app reset or navigation
                        // For now, just provide haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                }
        )
        .sheet(isPresented: $showMergeAccount) {
            MergeAccountView()
                .interactiveDismissDisabled(false) // Allow swipe to dismiss
        }
        .sheet(isPresented: $showDeleteAccount) {
            DeleteAccountView()
                .interactiveDismissDisabled(false) // Allow swipe to dismiss
        }
    }
    
    
    private func handleVoiceCommand(_ command: String) {
        // Handle voice command logic here
        print("Voice command: \(command)")
    }
    
    private func handleVoiceAuthentication() {
        // Allow authentication even if no current user (check all accounts)
        
        isAuthenticating = true
        
        // Start recording with VoiceBiometricManager
        let _ = voiceManager.startRecording()
        
        // Clear any previous error messages
        voiceManager.errorMessage = ""
        
        // Implement voice activity detection - automatically stop after silence
        startVoiceActivityDetection()
    }
    
    private func startVoiceActivityDetection() {
        // Check for voice activity every 500ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // If still recording, check if we should stop
            if self.voiceManager.isRecording {
                // Get current recognized text
                let currentText = self.voiceManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If we have text and it hasn't changed in the last check, assume user stopped talking
                if !currentText.isEmpty {
                    // Wait a bit more to see if more text comes in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Check again - if text hasn't changed, stop recording
                        let finalText = self.voiceManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if finalText == currentText && self.voiceManager.isRecording {
                            print("🎤 Voice activity detection: User stopped talking, processing authentication...")
                            self.processVoiceAuthentication()
                        } else {
                            // Text is still changing, continue listening
                            self.startVoiceActivityDetection()
                        }
                    }
                } else {
                    // No text yet, continue listening
                    self.startVoiceActivityDetection()
                }
            }
        }
    }
    
    private func startDemoVoiceActivityDetection() {
        // Check for voice activity every 500ms for demo mode
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // If still recording, check if we should stop
            if self.voiceManager.isRecording {
                // Get current recognized text
                let currentText = self.voiceManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If we have text and it hasn't changed in the last check, assume user stopped talking
                if !currentText.isEmpty {
                    // Wait a bit more to see if more text comes in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // Check again - if text hasn't changed, stop recording
                        let finalText = self.voiceManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if finalText == currentText && self.voiceManager.isRecording {
                            print("🎤 Demo voice activity detection: User stopped talking, stopping recording...")
                            self.voiceManager.stopRecording()
                        } else {
                            // Text is still changing, continue listening
                            self.startDemoVoiceActivityDetection()
                        }
                    }
                } else {
                    // No text yet, continue listening
                    self.startDemoVoiceActivityDetection()
                }
            }
        }
    }
    
    private func processVoiceAuthentication() {
        // Stop recording and get the voice sample
        let voiceSample = voiceManager.stopRecording()
        
        // Get what the user ACTUALLY said
        let actualSpokenText = voiceManager.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if user actually said something
        guard !actualSpokenText.isEmpty else {
            isAuthenticating = false
            // Voice feedback for no input
            speakText("No voice input detected. Please try again.")
            return
        }
        
        // Attempt authentication with what the user ACTUALLY said
        let isAuthenticated = userDatabase.authenticateLogin(
            voicePassword: actualSpokenText,  // What user actually said
            voiceSample: voiceSample ?? VoiceSample(audioData: Data(), transcript: actualSpokenText, timestamp: Date(), duration: 0.0, pitch: 0.0, amplitude: 0.0)  // Voice characteristics of what they said
        )
        
        isAuthenticating = false
        
        if isAuthenticated {
            print("✅ Login successful!")
            print("  📝 User said: '\(actualSpokenText)'")
            print("  🎤 Voice biometric: MATCH")
            print("  👤 User name preserved: '\(userDatabase.currentUser?.name ?? "Unknown")'")
            
            // Initialize contacts with random balances if not already done
            if userDatabase.getContacts().isEmpty {
                userDatabase.initializeContactsWithRandomBalances()
            }
            
            // Voice feedback for successful login
            speakText("Welcome back! Authentication successful.")
            
            // Navigate to home page
            showHomePage = true
            
            NotificationCenter.default.post(name: NSNotification.Name("LoginSuccessful"), object: nil)
        } else {
            print("❌ Login failed!")
            print("  📝 User said: '\(actualSpokenText)'")
            print("  🎤 Voice biometric: NO MATCH")
            // Voice feedback for failed login
            speakText("Authentication failed. Please try again.")
        }
    }
    
    
    // Create consistent voice samples for the same user/text (same as in MergeAccountView)
    private func createConsistentVoiceSample(for text: String) -> VoiceSample {
        // Create consistent voice characteristics based on text hash
        let textHash = text.hash
        let normalizedHash = abs(textHash)
        
        // Generate consistent pitch based on text hash (same text = same pitch)
        let basePitch: Float = 150.0 // Base pitch in Hz
        let pitchVariation: Float = Float(normalizedHash % 100) // 0-99 Hz variation
        let pitch = basePitch + pitchVariation
        
        // Generate consistent amplitude based on text length and hash
        let baseAmplitude: Float = 0.6
        let amplitudeVariation: Float = Float(normalizedHash % 30) / 100.0 // 0-0.3 variation
        let amplitude = min(1.0, baseAmplitude + amplitudeVariation)
        
        // Duration based on text length (more words = longer duration)
        let wordCount = text.components(separatedBy: .whitespaces).count
        let duration = max(2.0, Double(wordCount) * 0.8) // ~0.8 seconds per word, minimum 2 seconds
        
        print("🎤 Creating consistent voice sample for '\(text)':")
        print("  📊 Pitch: \(pitch) Hz")
        print("  📊 Amplitude: \(amplitude)")
        print("  📊 Duration: \(duration) seconds")
        
        return VoiceSample(
            audioData: Data(),
            transcript: text,
            timestamp: Date(),
            duration: duration,
            pitch: pitch,
            amplitude: amplitude
        )
    }
    
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

struct VoiceCommandButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: FinanceRadius.lg)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 140, height: 140)
                        .shadow(color: .black.opacity(0.6), radius: 12, x: 0, y: 6)
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                .stroke(.white.opacity(0.3), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    VoiceAuthView()
}
