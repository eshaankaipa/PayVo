//
//  WithdrawalView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI
import AVFoundation

struct WithdrawalView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var voiceManager = VoiceManager()
    
    @State private var withdrawalAmount: Double = 0.0
    @State private var manualAmount: String = ""
    @State private var showManualInput = false
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var animateElements = false
    
    // Voice synthesis for error messages
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    private let maxAmount: Double = 5000.0
    private let minAmount: Double = 1.0
    
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
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 20) {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(FinanceColors.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(FinanceColors.cardBackground)
                                            .financeCardStyle()
                                    )
                            }
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                Text("Withdraw Money")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("Current Balance: $\(String(format: "%.2f", userDatabase.getCurrentBalance()))")
                                    .font(FinanceFonts.bodySmall)
                                    .foregroundColor(FinanceColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Placeholder for symmetry
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    }
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)
                    
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 32) {
                        // Amount selection
                        VStack(spacing: 24) {
                            Text("Select Amount")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                            
                            // Amount slider
                            VStack(spacing: 16) {
                                Text("$\(String(format: "%.2f", withdrawalAmount))")
                                    .font(FinanceFonts.amountLarge)
                                    .foregroundColor(FinanceColors.primaryBlue)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .scaleEffect(animateElements ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateElements)
                                
                                Slider(value: $withdrawalAmount, in: minAmount...maxAmount, step: 1.0)
                                    .accentColor(FinanceColors.primaryBlue)
                                    .padding(.horizontal, 20)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .offset(y: animateElements ? 0 : 20)
                                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                                
                                HStack {
                                    Text("$\(String(format: "%.0f", minAmount))")
                                        .font(FinanceFonts.caption)
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text("$\(String(format: "%.0f", maxAmount))")
                                        .font(FinanceFonts.caption)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                .padding(.horizontal, 20)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(1.0), value: animateElements)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                        
                        // Input methods
                        VStack(spacing: 16) {
                            // Manual input toggle
                            Button(action: {
                                showManualInput.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: showManualInput ? "keyboard.fill" : "keyboard")
                                        .font(.system(size: 18, weight: .medium))
                                    
                                    Text(showManualInput ? "Hide Manual Input" : "Enter Amount Manually")
                                        .font(FinanceFonts.bodyMedium.weight(.medium))
                                    
                                    Spacer()
                                    
                                    Image(systemName: showManualInput ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(FinanceColors.primaryBlue)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.md)
                                        .fill(FinanceColors.primaryBlue.opacity(0.1))
                                )
                            }
                            
                            // Manual input field
                            if showManualInput {
                                VStack(spacing: 12) {
                                    TextField("Enter amount", text: $manualAmount)
                                        .font(FinanceFonts.bodyMedium)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(16)
                                        .background(
                                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                .fill(FinanceColors.cardBackground)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                        .stroke(FinanceColors.primaryBlue, lineWidth: 1)
                                                )
                                        )
                                        .onChange(of: manualAmount) { newValue in
                                            if let amount = Double(newValue) {
                                                withdrawalAmount = min(max(amount, minAmount), maxAmount)
                                            }
                                        }
                                    
                                    Button("Apply Amount") {
                                        if let amount = Double(manualAmount) {
                                            withdrawalAmount = min(max(amount, minAmount), maxAmount)
                                        }
                                    }
                                    .font(FinanceFonts.button)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(16)
                                    .background(FinanceColors.primaryBlue)
                                    .cornerRadius(FinanceRadius.md)
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .top)),
                                    removal: .opacity.combined(with: .move(edge: .top))
                                ))
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(1.2), value: animateElements)
                        
                        // Voice withdrawal
                        VStack(spacing: 16) {
                            Text("Voice Withdrawal")
                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            Button(action: {
                                startVoiceWithdrawal()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(voiceManager.isListening ? FinanceColors.primaryRed : FinanceColors.primaryBlue)
                                            .frame(width: 50, height: 50)
                                        
                                        Image(systemName: voiceManager.isListening ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(voiceManager.isListening ? "Listening..." : "Speak Amount")
                                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                                            .foregroundColor(FinanceColors.textPrimary)
                                        
                                        Text("Say the amount you want to withdraw")
                                            .font(FinanceFonts.caption)
                                            .foregroundColor(FinanceColors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.md)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                            }
                            .disabled(isProcessing)
                            
                            // Show recognized text
                            if !voiceManager.recognizedText.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recognized:")
                                        .font(FinanceFonts.caption)
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("\"\(voiceManager.recognizedText)\"")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.accentBlue)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: FinanceRadius.sm)
                                                .fill(FinanceColors.accentBlue.opacity(0.1))
                                        )
                                }
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Withdraw button
                        Button(action: {
                            processWithdrawal()
                        }) {
                            HStack(spacing: 12) {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                }
                                
                                Text(isProcessing ? "Processing..." : "Withdraw $\(String(format: "%.2f", withdrawalAmount))")
                                    .font(FinanceFonts.button)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.button)
                                    .fill(canWithdrawAmount ? FinanceColors.primaryBlue : FinanceColors.textTertiary)
                            )
                        }
                        .disabled(!canWithdrawAmount || isProcessing)
                        
                        // Quick amount buttons
                        HStack(spacing: 12) {
                            ForEach([25.0, 50.0, 100.0, 200.0], id: \.self) { amount in
                                Button("$\(String(format: "%.0f", amount))") {
                                    withdrawalAmount = amount
                                }
                                .font(FinanceFonts.caption.weight(.semibold))
                                .foregroundColor(FinanceColors.primaryBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.sm)
                                        .fill(FinanceColors.primaryBlue.opacity(0.1))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 30)
                    .animation(.easeOut(duration: 0.6).delay(1.6), value: animateElements)
                }
            }
        }
        .onAppear {
            animateElements = true
        }
        .alert("Insufficient Funds", isPresented: $showError) {
            Button("OK") {
                showError = false
                errorMessage = ""
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Withdrawal Successful", isPresented: $showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("You have successfully withdrawn $\(String(format: "%.2f", withdrawalAmount))")
        }
    }
    
    // MARK: - Computed Properties
    
    private var canWithdrawAmount: Bool {
        return userDatabase.canWithdraw(amount: withdrawalAmount) && withdrawalAmount >= minAmount
    }
    
    // MARK: - Actions
    
    private func startVoiceWithdrawal() {
        voiceManager.reset()
        voiceManager.startListening()
        
        // Stop listening after 5 seconds and process the voice input
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            voiceManager.stopListening()
            processVoiceWithdrawal()
        }
    }
    
    private func processVoiceWithdrawal() {
        let recognizedText = voiceManager.recognizedText.lowercased()
        
        // Extract amount from voice input
        let amount = extractAmountFromVoice(recognizedText)
        
        if amount > 0 {
            withdrawalAmount = min(max(amount, minAmount), maxAmount)
        } else {
            showVoiceError("Could not understand the amount. Please try again.")
        }
    }
    
    private func extractAmountFromVoice(_ text: String) -> Double {
        // Use the same enhanced extraction logic as VoiceCommandProcessor
        let lowercaseInput = text.lowercased()
        
        // Look for amounts like "fifty", "one hundred", etc. first
        let wordNumbers: [String: Double] = [
            "fifty": 50, "one hundred": 100, "hundred": 100, "two hundred": 200,
            "three hundred": 300, "five hundred": 500, "one thousand": 1000,
            "thousand": 1000, "two thousand": 2000, "five thousand": 5000,
            "ten": 10, "twenty": 20, "thirty": 30, "forty": 40, "sixty": 60,
            "seventy": 70, "eighty": 80, "ninety": 90, "one": 1, "two": 2,
            "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9
        ]
        
        // Check for word numbers first
        for (word, value) in wordNumbers {
            if lowercaseInput.contains(word) {
                print("🎤 WithdrawalView extracted amount from word '\(word)': \(value)")
                return value
            }
        }
        
        // Remove common words and extract numbers
        let cleanedInput = lowercaseInput
            .replacingOccurrences(of: "dollars", with: "")
            .replacingOccurrences(of: "dollar", with: "")
            .replacingOccurrences(of: "withdraw", with: "")
            .replacingOccurrences(of: "take out", with: "")
            .replacingOccurrences(of: "remove", with: "")
            .replacingOccurrences(of: "take", with: "")
            .replacingOccurrences(of: "out", with: "")
            .replacingOccurrences(of: "money", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Extract numbers from input using regex
        let regex = try? NSRegularExpression(pattern: "\\d+(?:\\.\\d+)?", options: [])
        let range = NSRange(location: 0, length: cleanedInput.count)
        if let match = regex?.firstMatch(in: cleanedInput, options: [], range: range) {
            if let numberRange = Range(match.range, in: cleanedInput) {
                let numberString = String(cleanedInput[numberRange])
                if let number = Double(numberString) {
                    print("🎤 WithdrawalView extracted amount from number '\(numberString)': \(number)")
                    return number
                }
            }
        }
        
        // Fallback: extract numbers from words
        let words = cleanedInput.components(separatedBy: .whitespacesAndNewlines)
        let numbers = words.compactMap { Double($0) }
        
        if let firstNumber = numbers.first {
            print("🎤 WithdrawalView extracted amount from fallback: \(firstNumber)")
            return firstNumber
        }
        
        print("🎤 WithdrawalView no amount found in input: '\(text)'")
        return 0.0
    }
    
    private func processWithdrawal() {
        guard canWithdrawAmount else {
            showInsufficientFundsError()
            return
        }
        
        isProcessing = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let success = userDatabase.withdraw(amount: withdrawalAmount, description: "Voice/Manual Withdrawal")
            
            isProcessing = false
            
            if success {
                showSuccess = true
                // Provide voice confirmation
                speakText("Withdrawal successful. You have withdrawn \(String(format: "%.2f", withdrawalAmount)) dollars.")
            } else {
                showInsufficientFundsError()
            }
        }
    }
    
    private func showInsufficientFundsError() {
        let currentBalance = userDatabase.getCurrentBalance()
        errorMessage = "Insufficient funds. You have $\(String(format: "%.2f", currentBalance)) available, but tried to withdraw $\(String(format: "%.2f", withdrawalAmount))."
        showError = true
        
        // Provide voice error message
        speakText("Insufficient funds. You cannot withdraw \(String(format: "%.2f", withdrawalAmount)) dollars. Your current balance is \(String(format: "%.2f", currentBalance)) dollars.")
    }
    
    private func showVoiceError(_ message: String) {
        errorMessage = message
        showError = true
        speakText(message)
    }
    
    private func speakText(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

#Preview {
    WithdrawalView()
        .environmentObject(UserDatabase())
}
