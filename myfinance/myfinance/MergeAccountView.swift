//
//  MergeAccountView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct MergeAccountView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @StateObject private var voiceManager = VoiceBiometricManager()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var voicePassword = ""
    @State private var confirmVoicePassword = ""
    
    @State private var firstVoiceSample: VoiceSample?
    @State private var secondVoiceSample: VoiceSample?
    @State private var voiceMatchConfidence: Double = 0.0
    
    @State private var currentStep = 1 // 1: Basic info, 2: Voice password, 3: Confirm voice password
    @State private var animateElements = false
    @State private var showSuccess = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Professional finance background
                LinearGradient(
                    gradient: Gradient(colors: [
                        FinanceColors.backgroundPrimary,
                        FinanceColors.backgroundSecondary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if showSuccess {
                    SuccessView {
                        presentationMode.wrappedValue.dismiss()
                    }
                } else {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 20) {
                            HStack {
                                // Enhanced back button
                                Button(action: {
                                    if currentStep > 1 {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentStep -= 1
                                        }
                                        // Reset voice manager when going back
                                        if currentStep == 1 {
                                            voiceManager.reset()
                                        }
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: 18, weight: .semibold))
                                        Text(currentStep > 1 ? "Back" : "Cancel")
                                            .font(FinanceFonts.bodySmall.weight(.medium))
                                    }
                                    .foregroundColor(FinanceColors.primaryBlue)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: FinanceRadius.sm)
                                            .fill(FinanceColors.cardBackground)
                                            .financeCardStyle()
                                    )
                                }
                                
                                Spacer()
                                
                                // Close button (X) for easy dismissal
                                Button(action: {
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(FinanceColors.textSecondary)
                                        .frame(width: 30, height: 30)
                                        .background(
                                            Circle()
                                                .fill(FinanceColors.backgroundSecondary)
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            
                            Spacer()
                                .frame(height: 20)
                            
                            // Logo
                            ZStack {
                                Circle()
                                    .fill(FinanceColors.primaryRed)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "cloud.dollarsign.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .scaleEffect(animateElements ? 1.0 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
                            
                            VStack(spacing: 8) {
                                Text("Merge Account")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.primaryBlue)
                                
                                Text("Create your voice-secured account")
                                    .font(FinanceFonts.bodyMedium)
                                    .foregroundColor(FinanceColors.textSecondary)
                            }
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
                        }
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Progress indicator
                        HStack(spacing: 8) {
                            ForEach(1...3, id: \.self) { step in
                                Circle()
                                    .fill(step <= currentStep ? FinanceColors.primaryBlue : FinanceColors.textTertiary)
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: animateElements)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Content based on current step
                        if currentStep == 1 {
                            BasicInfoStep(email: $email, name: $name, phoneNumber: $phoneNumber) {
                                nextStep()
                            }
                        } else if currentStep == 2 {
                            VoicePasswordStep(
                                voicePassword: $voicePassword,
                                voiceManager: voiceManager,
                                isRecording: voiceManager.isRecording,
                                recognizedText: voiceManager.recognizedText,
                                recordingProgress: voiceManager.recordingProgress,
                                onNext: { voiceSample in
                                    firstVoiceSample = voiceSample
                                    nextStep()
                                },
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep -= 1
                                    }
                                },
                                createVoiceSample: createConsistentVoiceSample
                            )
                        } else if currentStep == 3 {
                            ConfirmVoicePasswordStep(
                                confirmVoicePassword: $confirmVoicePassword,
                                voiceManager: voiceManager,
                                isRecording: voiceManager.isRecording,
                                recognizedText: voiceManager.recognizedText,
                                recordingProgress: voiceManager.recordingProgress,
                                originalPassword: voicePassword,
                                originalVoiceSample: firstVoiceSample,
                                onCreateAccount: { voiceSample in
                                    secondVoiceSample = voiceSample
                                    if let firstSample = firstVoiceSample, let secondSample = voiceSample {
                                        voiceMatchConfidence = voiceManager.getVoiceMatchConfidence(firstSample, secondSample)
                                    }
                                    createAccount()
                                },
                                onBack: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep -= 1
                                    }
                                },
                                createVoiceSample: createConsistentVoiceSample
                            )
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            animateElements = true
        }
        .gesture(
            // Add swipe down gesture to dismiss
            DragGesture()
                .onEnded { value in
                    if value.translation.height > 100 && value.velocity.height > 500 {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        )
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep += 1
            // Reset voice manager when moving to confirmation step
            if currentStep == 3 {
                voiceManager.reset()
            }
        }
    }
    
    private func createAccount() {
        print("🏗️ MergeAccountView - Creating account with:")
        print("  📧 Email: '\(email)'")
        print("  👤 Name: '\(name)'")
        print("  📱 Phone: '\(phoneNumber)'")
        print("  🔐 Voice Password: '\(voicePassword)'")
        
        // Validate that we have the required information
        guard !name.isEmpty, !email.isEmpty, !phoneNumber.isEmpty, !voicePassword.isEmpty else {
            print("❌ Missing required information for account creation")
            return
        }
        
        userDatabase.createUser(
            email: email,
            name: name,
            phoneNumber: phoneNumber,
            voicePassword: voicePassword,
            voiceSample: firstVoiceSample
        )
        
        print("✅ MergeAccountView - Account created successfully!")
        print("  💰 User balance: $\(String(format: "%.2f", userDatabase.getCurrentBalance()))")
        print("  👥 Number of contacts: \(userDatabase.currentUser?.contacts.count ?? 0)")
        print("  🏷️ User TAG: \(userDatabase.currentUser?.uniqueTag ?? "N/A")")
        print("  👤 Final user name: '\(userDatabase.currentUser?.name ?? "nil")'")
        
        withAnimation(.easeInOut(duration: 0.8)) {
            showSuccess = true
        }
        
        // Navigate to home page after account creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            NotificationCenter.default.post(name: NSNotification.Name("LoginSuccessful"), object: nil)
        }
    }
    
    // Create consistent voice samples for the same user/text
    func createConsistentVoiceSample(for text: String) -> VoiceSample {
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
        
        print("🎤 Creating voice sample for '\(text)':")
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
}

struct BasicInfoStep: View {
    @Binding var email: String
    @Binding var name: String
    @Binding var phoneNumber: String
    let onNext: () -> Void
    @State private var animateElements = false
    @State private var emailError = ""
    @State private var phoneError = ""
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(FinanceFonts.label)
                    .foregroundColor(FinanceColors.textPrimary)
                
                TextField("Enter your full name", text: $name)
                    .font(FinanceFonts.bodyMedium)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.words)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Email Address")
                    .font(FinanceFonts.label)
                    .foregroundColor(FinanceColors.textPrimary)
                
                TextField("Enter your email", text: $email)
                    .font(FinanceFonts.bodyMedium)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .stroke(emailError.isEmpty ? Color.clear : FinanceColors.errorRed, lineWidth: 1)
                    )
                    .onChange(of: email) { _ in
                        validateEmail()
                    }
                
                if !emailError.isEmpty {
                    Text(emailError)
                        .font(FinanceFonts.caption)
                        .foregroundColor(FinanceColors.errorRed)
                        .transition(.opacity)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Phone Number")
                    .font(FinanceFonts.label)
                    .foregroundColor(FinanceColors.textPrimary)
                
                TextField("Enter your phone number", text: $phoneNumber)
                    .font(FinanceFonts.bodyMedium)
                    .textFieldStyle(PlainTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.phonePad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                            .stroke(phoneError.isEmpty ? Color.clear : FinanceColors.errorRed, lineWidth: 1)
                    )
                    .onChange(of: phoneNumber) { _ in
                        validatePhoneNumber()
                    }
                
                if !phoneError.isEmpty {
                    Text(phoneError)
                        .font(FinanceFonts.caption)
                        .foregroundColor(FinanceColors.errorRed)
                        .transition(.opacity)
                }
            }
            
            Button(action: onNext) {
                Text("Continue")
                    .font(FinanceFonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.button)
                            .fill(FinanceColors.primaryBlue)
                    )
            }
            .disabled(!isFormValid())
            .opacity(email.isEmpty || name.isEmpty ? 0.6 : 1.0)
        }
        .padding(.horizontal, 32)
        .opacity(animateElements ? 1.0 : 0.0)
        .offset(y: animateElements ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
        .onAppear {
            animateElements = true
        }
    }
    
    private func validateEmail() {
        if email.isEmpty {
            emailError = ""
        } else if !email.contains("@") {
            emailError = "Email must contain @ symbol"
        } else if !email.contains(".com") {
            emailError = "Email must contain .com"
        } else {
            emailError = ""
        }
    }
    
    private func validatePhoneNumber() {
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if phoneNumber.isEmpty {
            phoneError = ""
        } else if digitsOnly.count < 9 {
            phoneError = "Phone number must have at least 9 digits"
        } else {
            phoneError = ""
        }
    }
    
    private func isFormValid() -> Bool {
        return !name.isEmpty && 
               !email.isEmpty && 
               !phoneNumber.isEmpty &&
               emailError.isEmpty &&
               phoneError.isEmpty &&
               email.contains("@") &&
               email.contains(".com") &&
               phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression).count >= 9
    }
}

struct DeleteAccountView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var uniqueTag = ""
    @State private var errorMessage = ""
    @State private var isDeleting = false
    @State private var animateElements = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        presentationMode.wrappedValue.dismiss()
                    }
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Delete Account")
                            .font(FinanceFonts.heading2)
                            .foregroundColor(FinanceColors.textPrimary)
                        
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(FinanceColors.textSecondary)
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(FinanceColors.backgroundSecondary)
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Existing accounts list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Existing Accounts")
                            .font(FinanceFonts.label)
                            .foregroundColor(FinanceColors.textPrimary)
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                   ForEach(userDatabase.getAllAccountsForDeletion(), id: \.email) { account in
                                       VStack(alignment: .leading, spacing: 4) {
                                           HStack {
                                               Text(account.name)
                                                   .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                   .foregroundColor(FinanceColors.textPrimary)
                                               
                                               Spacer()
                                               
                                               Text("TAG: ••••••")
                                                   .font(FinanceFonts.caption)
                                                   .foregroundColor(FinanceColors.textSecondary)
                                                   .padding(.horizontal, 8)
                                                   .padding(.vertical, 4)
                                                   .background(
                                                       RoundedRectangle(cornerRadius: 4)
                                                           .fill(FinanceColors.backgroundSecondary)
                                                   )
                                           }
                                           
                                           Text(account.email)
                                               .font(FinanceFonts.caption)
                                               .foregroundColor(FinanceColors.textSecondary)
                                           
                                           Text("Phone: •••••••••••")
                                               .font(FinanceFonts.caption)
                                               .foregroundColor(FinanceColors.textSecondary)
                                       }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(FinanceColors.cardBackground)
                                            .financeCardStyle()
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 200)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 20)
                    
                       // Verification form
                       VStack(spacing: 16) {
                           Text("Verify Deletion")
                               .font(FinanceFonts.label)
                               .foregroundColor(FinanceColors.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(FinanceFonts.caption)
                                .foregroundColor(FinanceColors.textSecondary)
                            
                            TextField("Enter email", text: $email)
                                .font(FinanceFonts.bodyMedium)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.emailAddress)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                        }
                        
                           VStack(alignment: .leading, spacing: 8) {
                               Text("Phone Number")
                                   .font(FinanceFonts.caption)
                                   .foregroundColor(FinanceColors.textSecondary)
                               
                               TextField("Enter full phone number", text: $phoneNumber)
                                .font(FinanceFonts.bodyMedium)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.phonePad)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                        }
                        
                           VStack(alignment: .leading, spacing: 8) {
                               Text("Unique TAG")
                                   .font(FinanceFonts.caption)
                                   .foregroundColor(FinanceColors.textSecondary)
                               
                               TextField("Enter 6-character TAG", text: $uniqueTag)
                                .font(FinanceFonts.bodyMedium)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(FinanceFonts.caption)
                                .foregroundColor(FinanceColors.errorRed)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: deleteAccount) {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(isDeleting ? "Deleting..." : "Delete Account")
                                    .font(FinanceFonts.button)
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.button)
                                    .fill(FinanceColors.errorRed)
                            )
                        }
                        .disabled(isDeleting || email.isEmpty || phoneNumber.isEmpty || uniqueTag.isEmpty)
                        .opacity((email.isEmpty || phoneNumber.isEmpty || uniqueTag.isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(FinanceColors.backgroundPrimary)
                        .frame(width: max(min(geometry.size.width - 32, 400), 320))
                )
                .frame(width: max(min(geometry.size.width - 32, 400), 320))
                .opacity(animateElements ? 1.0 : 0.0)
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateElements)
            }
        }
        .onAppear {
            animateElements = true
        }
    }
    
    private func deleteAccount() {
        guard !email.isEmpty, !phoneNumber.isEmpty, !uniqueTag.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        
        isDeleting = true
        errorMessage = ""
        
        let success = userDatabase.deleteAccountWithVerification(
            email: email,
            phoneNumber: phoneNumber,
            uniqueTag: uniqueTag
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isDeleting = false
            
            if success {
                presentationMode.wrappedValue.dismiss()
            } else {
                   errorMessage = "Account not found. Check details and try again."
            }
        }
    }
}

struct VoicePasswordStep: View {
    @Binding var voicePassword: String
    let voiceManager: VoiceBiometricManager
    let isRecording: Bool
    let recognizedText: String
    let recordingProgress: Double
    let onNext: (VoiceSample?) -> Void
    let onBack: () -> Void
    let createVoiceSample: (String) -> VoiceSample
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section - fixed height
            VStack(spacing: 16) {
                Text("Create Voice Password")
                    .font(FinanceFonts.heading3)
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text("Choose a phrase you'll remember.")
                    .font(FinanceFonts.bodySmall)
                    .foregroundColor(FinanceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(height: 60)
            
            Spacer()
                .frame(height: 15)
            
            // Voice recording interface - fixed height
            ZStack {
                // Pulse rings
                if isRecording {
                    Circle()
                        .stroke(FinanceColors.primaryRed.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isRecording ? 1.3 : 1.0)
                        .opacity(isRecording ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isRecording)
                }
                
                // Main microphone button
                Button(action: {
                    if isRecording {
                        _ = voiceManager.stopRecording()
                    } else {
                        voiceManager.reset() // Clear any previous state
                        _ = voiceManager.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? FinanceColors.primaryRed : FinanceColors.cardBackground)
                            .frame(width: 80, height: 80)
                            .financeButtonStyle()
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isRecording ? .white : FinanceColors.primaryRed)
                    }
                }
            }
            .frame(height: 120)
            
            Spacer()
                .frame(height: 15)
            
            // Status section - fixed height with reserved space
            VStack(spacing: 6) {
                Text(isRecording ? "Recording..." : "Tap to record")
                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                    .foregroundColor(FinanceColors.textPrimary)
                
                // Reserved space for recognized text and password display
                VStack(spacing: 4) {
                    if !recognizedText.isEmpty {
                        Text("\"\(recognizedText)\"")
                            .font(FinanceFonts.bodySmall)
                            .foregroundColor(FinanceColors.accentBlue)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if !voicePassword.isEmpty {
                        Text("Password: \"\(voicePassword)\"")
                            .font(FinanceFonts.bodySmall)
                            .foregroundColor(FinanceColors.successGreen)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .frame(minHeight: 40) // Reserve minimum space
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .frame(height: 80) // Fixed height for status section
            
            Spacer()
                .frame(height: 5)
            
            HStack(spacing: 16) {
                // Back button
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(FinanceFonts.button)
                    }
                    .foregroundColor(FinanceColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.button)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
                }
                
                // Continue button
                Button(action: {
                    if !recognizedText.isEmpty {
                        voicePassword = recognizedText
                        // Create a simulated voice sample with consistent characteristics
                        let sample = createVoiceSample(recognizedText)
                        onNext(sample)
                    }
                }) {
                    Text("Continue")
                        .font(FinanceFonts.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.button)
                                .fill(FinanceColors.primaryBlue)
                        )
                }
                .disabled(recognizedText.isEmpty)
                .opacity(recognizedText.isEmpty ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, 32)
        .opacity(animateElements ? 1.0 : 0.0)
        .offset(y: animateElements ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
        .onAppear {
            animateElements = true
        }
    }
}

struct ConfirmVoicePasswordStep: View {
    @Binding var confirmVoicePassword: String
    let voiceManager: VoiceBiometricManager
    let isRecording: Bool
    let recognizedText: String
    let recordingProgress: Double
    let originalPassword: String
    let originalVoiceSample: VoiceSample?
    let onCreateAccount: (VoiceSample?) -> Void
    let onBack: () -> Void
    let createVoiceSample: (String) -> VoiceSample
    @State private var animateElements = false
    @State private var passwordsMatch = false
    @State private var voiceMatchConfidence: Double = 0.0
    
    private var voiceMatchResult: (textMatch: Bool, biometricMatch: Bool, overallMatch: Bool, confidence: Double)? {
        // Only calculate match results if we have recognized text
        guard !recognizedText.isEmpty else { return nil }
        
        // Enhanced text matching with better normalization
        let normalizedOriginal = originalPassword.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ") // Replace double spaces with single
            .replacingOccurrences(of: "  ", with: " ") // Handle triple spaces
        
        let normalizedRecognized = recognizedText.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "  ", with: " ") // Replace double spaces with single
            .replacingOccurrences(of: "  ", with: " ") // Handle triple spaces
        
        let textMatch = normalizedOriginal == normalizedRecognized
        
        var biometricMatch = false
        var confidence: Double = 0.0
        
        if let originalSample = originalVoiceSample {
            let newSample = createVoiceSample(recognizedText)
            let rawBiometricMatch = voiceManager.compareVoiceSamples(originalSample, newSample)
            confidence = voiceManager.getVoiceMatchConfidence(originalSample, newSample)
            // Voice matches only if biometric characteristics match AND confidence > 75%
            biometricMatch = rawBiometricMatch && confidence > 0.75
        } else {
            // If no original voice sample, biometric match is considered true (text-only verification)
            biometricMatch = true
            confidence = 1.0
        }
        
        // Overall match requires text match, biometric match, AND confidence above 75%
        let overallMatch = textMatch && biometricMatch && confidence > 0.75
        
        // Enhanced debug logging
        print("🔍 Voice Match Debug:")
        print("  📝 Original: '\(originalPassword)'")
        print("  📝 Recognized: '\(recognizedText)'")
        print("  🧹 Normalized Original: '\(normalizedOriginal)'")
        print("  🧹 Normalized Recognized: '\(normalizedRecognized)'")
        print("  ✅ Text Match: \(textMatch)")
        print("  🎤 Biometric Match: \(biometricMatch)")
        print("  📊 Confidence: \(Int(confidence * 100))% (Required: >75%)")
        print("  🎯 Overall Match: \(overallMatch) (Text: \(textMatch), Voice: \(biometricMatch), Confidence: \(Int(confidence * 100))% > 75%)")
        print("  " + String(repeating: "=", count: 50))
        
        return (textMatch: textMatch, biometricMatch: biometricMatch, overallMatch: overallMatch, confidence: confidence)
    }
    
    // Test function to verify password matching logic
    private func testPasswordMatching() {
        print("🧪 Testing Password Matching Logic:")
        
        let testCases = [
            ("hello world", "hello world", true),
            ("Hello World", "hello world", true),
            ("  hello world  ", "hello world", true),
            ("hello   world", "hello world", true),
            ("hello world", "hello universe", false),
            ("my voice password", "my voice password", true),
            ("My Voice Password", "my voice password", true),
            ("", "hello world", false),
            ("hello world", "", false)
        ]
        
        for (original, recognized, expected) in testCases {
            let normalizedOriginal = original.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "  ", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
            
            let normalizedRecognized = recognized.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "  ", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
            
            let actual = normalizedOriginal == normalizedRecognized
            let result = actual == expected ? "✅ PASS" : "❌ FAIL"
            
            print("  \(result) '\(original)' vs '\(recognized)' -> Expected: \(expected), Got: \(actual)")
        }
        print("🧪 Password Matching Test Complete")
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section - fixed height
            VStack(spacing: 16) {
                Text("Confirm Voice Password")
                    .font(FinanceFonts.heading3)
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text("Say the same phrase again to confirm")
                    .font(FinanceFonts.bodySmall)
                    .foregroundColor(FinanceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(height: 60)
            
            Spacer()
                .frame(height: 15)
            
            // Voice recording interface - fixed height
            ZStack {
                // Pulse rings
                if isRecording {
                    Circle()
                        .stroke(FinanceColors.primaryRed.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isRecording ? 1.3 : 1.0)
                        .opacity(isRecording ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: isRecording)
                }
                
                // Main microphone button
                Button(action: {
                    if isRecording {
                        _ = voiceManager.stopRecording()
                    } else {
                        voiceManager.reset() // Clear any previous state
                        _ = voiceManager.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? FinanceColors.primaryRed : FinanceColors.cardBackground)
                            .frame(width: 80, height: 80)
                            .financeButtonStyle()
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(isRecording ? .white : FinanceColors.primaryRed)
                    }
                }
            }
            .frame(height: 120)
            
            // Status section - fixed height with reserved space
            VStack(spacing: 6) {
                Text(isRecording ? "Recording..." : "Tap to confirm")
                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                    .foregroundColor(FinanceColors.textPrimary)
                
                // Reserved space for recognized text and match results
                VStack(spacing: 4) {
                    if !recognizedText.isEmpty {
                        Text("\"\(recognizedText)\"")
                            .font(FinanceFonts.bodySmall)
                            .foregroundColor(FinanceColors.accentBlue)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    if let matchResult = voiceMatchResult {
                        VStack(spacing: 4) {
                            // Text match result
                            HStack(spacing: 8) {
                                Image(systemName: matchResult.textMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(matchResult.textMatch ? FinanceColors.successGreen : FinanceColors.errorRed)
                                Text(matchResult.textMatch ? "Text matches" : "Text doesn't match")
                                    .font(FinanceFonts.bodySmall)
                                    .foregroundColor(matchResult.textMatch ? FinanceColors.successGreen : FinanceColors.errorRed)
                            }
                            
                            // Voice biometric result (only show if we have voice sample)
                            if let _ = originalVoiceSample {
                                HStack(spacing: 8) {
                                    Image(systemName: matchResult.biometricMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(matchResult.biometricMatch ? FinanceColors.successGreen : FinanceColors.errorRed)
                                    Text(matchResult.biometricMatch ? "Voice matches" : "Voice doesn't match")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(matchResult.biometricMatch ? FinanceColors.successGreen : FinanceColors.errorRed)
                                }
                            }
                        }
                    }
                }
                .frame(minHeight: 40) // Reserve minimum space
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
            .frame(height: 80) // Fixed height for status section
            
            Spacer()
                .frame(height: 1)
            
            HStack(spacing: 16) {
                // Back button
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(FinanceFonts.button)
                    }
                    .foregroundColor(FinanceColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.button)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
                }
                
                // Create Account button
                Button(action: {
                    // Only allow action if passwords match
                    guard let matchResult = voiceMatchResult, matchResult.overallMatch else { return }
                    
                    confirmVoicePassword = recognizedText
                    
                    // Create voice sample for confirmation
                    let confirmSample = createVoiceSample(recognizedText)
                    onCreateAccount(confirmSample)
                }) {
                    Text("Create Account")
                        .font(FinanceFonts.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.button)
                                .fill(FinanceColors.primaryBlue)
                        )
                }
                .disabled(recognizedText.isEmpty || voiceMatchResult?.overallMatch != true)
                .opacity((recognizedText.isEmpty || voiceMatchResult?.overallMatch != true) ? 0.6 : 1.0)
            }
        }
        .padding(.horizontal, 32)
        .opacity(animateElements ? 1.0 : 0.0)
        .offset(y: animateElements ? 0 : 30)
        .animation(.easeOut(duration: 0.6).delay(0.3), value: animateElements)
        .onAppear {
            animateElements = true
            testPasswordMatching() // Test password matching logic
        }
    }
    
    // Get specific failure reason for user feedback
    private func getFailureReason(_ matchResult: (textMatch: Bool, biometricMatch: Bool, overallMatch: Bool, confidence: Double)) -> String {
        if matchResult.overallMatch {
            return "Ready to create account"
        } else if !matchResult.textMatch {
            return "Text doesn't match"
        } else if !matchResult.biometricMatch {
            return "Voice doesn't match"
        } else if matchResult.confidence <= 0.75 {
            return "Confidence too low (\(Int(matchResult.confidence * 100))%)"
        } else {
            return "Passwords don't match"
        }
    }
}

struct SuccessView: View {
    let onDismiss: () -> Void
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Success icon
            ZStack {
                Circle()
                    .fill(FinanceColors.successGreen)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(animateElements ? 1.0 : 0.8)
            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateElements)
            
            VStack(spacing: 16) {
                Text("Account Created!")
                    .font(FinanceFonts.heading1)
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text("Your voice-secured account is ready. You can now use voice commands to access your account.")
                    .font(FinanceFonts.bodyMedium)
                    .foregroundColor(FinanceColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.3), value: animateElements)
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("Get Started")
                    .font(FinanceFonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.button)
                            .fill(FinanceColors.primaryBlue)
                    )
            }
            .padding(.horizontal, 32)
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 20)
            .animation(.easeOut(duration: 0.8).delay(0.6), value: animateElements)
        }
        .onAppear {
            animateElements = true
        }
    }
}

#Preview {
    MergeAccountView()
}
