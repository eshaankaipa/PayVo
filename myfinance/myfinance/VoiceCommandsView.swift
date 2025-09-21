//
//  VoiceCommandsView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct VoiceCommandsView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var voiceManager = VoiceManager()
    @StateObject private var commandService = VoiceCommandService()
    
    @State private var showMoneyOptions = false
    @State private var showContacts = false
    @State private var showTransactionHistory = false
    
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
                                            .fill(FinanceColors.backgroundSecondary)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                            }
                            
                            Spacer()
                            
                            Text("Voice Commands")
                                .font(FinanceFonts.heading1)
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            Spacer()
                            
                            // Placeholder for symmetry
                            Color.clear
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 10)
                    }
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Voice Command Section
                            VStack(spacing: 24) {
                                // Microphone Button
                                VStack(spacing: 16) {
                                    Button(action: {
                                        if voiceManager.isListening {
                                            voiceManager.stopListening()
                                        } else {
                                            voiceManager.startListening()
                                        }
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(voiceManager.isListening ? FinanceColors.errorRed : FinanceColors.primaryBlue)
                                                .frame(width: 120, height: 120)
                                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                            
                                            if commandService.isProcessing {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(1.2)
                                            } else {
                                                Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                                                    .font(.system(size: 40, weight: .medium))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                    .disabled(commandService.isProcessing)
                                    
                                    Text(voiceManager.isListening ? "Listening..." : "Tap to Start")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                
                                // Recognized Text Display
                                if !voiceManager.recognizedText.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("You said:")
                                            .font(FinanceFonts.caption)
                                            .foregroundColor(FinanceColors.textSecondary)
                                        
                                        Text(voiceManager.recognizedText)
                                            .font(FinanceFonts.bodyMedium)
                                            .foregroundColor(FinanceColors.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(FinanceColors.backgroundSecondary)
                                                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                            )
                                    }
                                }
                                
                                // Command Result Display
                                if !commandService.lastResult.isEmpty {
                                    VStack(spacing: 12) {
                                        Text("Result:")
                                            .font(FinanceFonts.caption)
                                            .foregroundColor(FinanceColors.textSecondary)
                                        
                                        Text(commandService.lastResult)
                                            .font(FinanceFonts.bodyMedium)
                                            .foregroundColor(FinanceColors.textPrimary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(FinanceColors.successGreen.opacity(0.1))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(FinanceColors.successGreen.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                                
                                // Error Message Display
                                if !voiceManager.errorMessage.isEmpty {
                                    Text(voiceManager.errorMessage)
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.errorRed)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                                
                                if !commandService.errorMessage.isEmpty {
                                    Text(commandService.errorMessage)
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.errorRed)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 20)
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Process Command Button
                            if !voiceManager.recognizedText.isEmpty && !commandService.isProcessing {
                                Button(action: {
                                    commandService.processVoiceCommand(voiceManager.recognizedText, userDatabase: userDatabase)
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Text("Process Command")
                                            .font(FinanceFonts.button)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(FinanceColors.primaryBlue)
                                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            // Command Examples
                            VStack(spacing: 16) {
                                Text("Voice Command Examples")
                                    .font(FinanceFonts.heading3)
                                    .foregroundColor(FinanceColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    CommandExample(command: "Check balance", description: "View your current account balance")
                                    CommandExample(command: "Deposit 100 dollars", description: "Add money to your account")
                                    CommandExample(command: "Withdraw 50 dollars", description: "Remove money from your account")
                                    CommandExample(command: "Show transactions", description: "View your transaction history")
                                    CommandExample(command: "Transfer 200 dollars", description: "Send money to another account")
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Quick Actions
                            VStack(spacing: 16) {
                                Text("Quick Actions")
                                    .font(FinanceFonts.heading3)
                                    .foregroundColor(FinanceColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(spacing: 12) {
                                    QuickActionButton(
                                        title: "Money Options",
                                        icon: "dollarsign.circle.fill",
                                        color: FinanceColors.successGreen
                                    ) {
                                        showMoneyOptions = true
                                    }
                                    
                                    QuickActionButton(
                                        title: "Transaction History",
                                        icon: "clock.arrow.circlepath",
                                        color: FinanceColors.warningOrange
                                    ) {
                                        showTransactionHistory = true
                                    }
                                    
                                    QuickActionButton(
                                        title: "Contacts",
                                        icon: "person.2.fill",
                                        color: FinanceColors.accentBlue
                                    ) {
                                        showContacts = true
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
        }
        .onChange(of: voiceManager.recognizedText) { newText in
            // Auto-process command when text is recognized and user stops speaking
            if !newText.isEmpty && !voiceManager.isListening && !commandService.isProcessing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    commandService.processVoiceCommand(newText, userDatabase: userDatabase)
                }
            }
        }
        .sheet(isPresented: $showMoneyOptions) {
            MoneyOptionsView()
        }
        .sheet(isPresented: $showContacts) {
            ContactsView()
        }
        .sheet(isPresented: $showTransactionHistory) {
            TransactionHistoryView()
        }
    }
}

struct CommandExample: View {
    let command: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(command)
                    .font(FinanceFonts.bodyMedium)
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text(description)
                    .font(FinanceFonts.caption)
                    .foregroundColor(FinanceColors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(FinanceColors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FinanceColors.backgroundSecondary)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(FinanceFonts.bodyMedium)
                    .foregroundColor(FinanceColors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(FinanceColors.textTertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FinanceColors.backgroundSecondary)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
}

#Preview {
    VoiceCommandsView()
        .environmentObject(UserDatabase())
}