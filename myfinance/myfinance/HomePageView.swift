//
//  HomePageView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct HomePageView: View {
    @ObservedObject var userDatabase: UserDatabase
    @StateObject private var voiceManager = VoiceManager()
    @StateObject private var commandService = VoiceCommandService()
    
    @State private var animateElements = false
    @State private var showLogoutAlert = false
    @State private var showWithdrawal = false
    @State private var showMoneyOptions = false
    @State private var showTransactionHistory = false
    @State private var showContacts = false
    @State private var showBalanceCheck = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color matching the PayVo logo
                Color(red: 58/255, green: 115/255, blue: 208/255)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Welcome,")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(userDatabase.currentUser?.name ?? "User")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .onAppear {
                                        print("🏠 HomePageView - Current user name: '\(userDatabase.currentUser?.name ?? "nil")'")
                                        print("🏠 HomePageView - Current user email: '\(userDatabase.currentUser?.email ?? "nil")'")
                                        print("🏠 HomePageView - Current user phone: '\(userDatabase.currentUser?.phoneNumber ?? "nil")'")
                                    }
                                
                                Text(userDatabase.currentUser?.email ?? "")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Unique TAG and date info
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("TAG")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(userDatabase.currentUser?.uniqueTag ?? "N/A")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Text("Since \(formatDate(userDatabase.currentUser?.dateCreated))")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            
                            // Logout button
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                Image(systemName: "power")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(FinanceColors.errorRed)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        Circle()
                                            .fill(.white.opacity(0.3))
                                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                            .overlay(
                                                Circle()
                                                    .stroke(.white.opacity(0.4), lineWidth: 2)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        // Account info card
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(FinanceColors.primaryBlue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Account Details")
                                        .font(FinanceFonts.label)
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Text(userDatabase.currentUser?.email ?? "")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(.white)
                                    
                                    Text(userDatabase.currentUser?.phoneNumber ?? "")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("Voice Authentication Enabled")
                                        .font(FinanceFonts.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                            }
                            
                            // Account balance and creation date
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Account Balance")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("$\(String(format: "%.2f", userDatabase.getCurrentBalance()))")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("Member Since")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(formatDate(userDatabase.currentUser?.dateCreated))
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                .fill(.black.opacity(0.8))
                                .financeCardStyle()
                        )
                        .padding(.horizontal, 24)
                    }
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : -20)
                    .animation(.easeOut(duration: 0.6).delay(0.2), value: animateElements)
                    
                    Spacer()
                    
                    // Primary action buttons
                    VStack(spacing: 16) {
                        // Voice Input Button - Centered
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
                                        .fill((voiceManager.isListening ? FinanceColors.errorRed : Color.white).opacity(0.8))
                                        .frame(width: 80, height: 80)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    
                                    if commandService.isProcessing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: FinanceColors.primaryBlue))
                                            .scaleEffect(1.2)
                                    } else {
                                        Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                                            .font(.system(size: 32, weight: .medium))
                                            .foregroundColor(voiceManager.isListening ? FinanceColors.errorRed : FinanceColors.primaryBlue)
                                    }
                                }
                            }
                            .disabled(commandService.isProcessing)
                            
                            VStack(spacing: 4) {
                                Text(voiceManager.isListening ? "Listening..." : "Voice Command")
                                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                                    .foregroundColor(.white)
                                
                                Text(commandService.isProcessing ? "Processing..." : (voiceManager.isListening ? "Tap to stop" : "Tap to speak"))
                                    .font(FinanceFonts.bodySmall)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                // Test button for debugging - hidden from user view
                                Button("") {
                                    // Hidden functionality
                                }
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                            }
                        }
                        
                        // Money Options Button
                        Button(action: {
                            showMoneyOptions = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.successGreen.opacity(0.4))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "dollarsign.circle.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(FinanceColors.successGreen)
                                    
                                    // Notification badge for pending requests
                                    if !userDatabase.getPendingRequestsForCurrentUser().isEmpty {
                                        Circle()
                                            .fill(FinanceColors.errorRed)
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Text("\(userDatabase.getPendingRequestsForCurrentUser().count)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 18, y: -18)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Money Options")
                                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Send & Request")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.md)
                                    .fill(.white.opacity(0.25))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Transaction History Button
                        Button(action: {
                            showTransactionHistory = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.warningOrange.opacity(0.4))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(FinanceColors.warningOrange)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Transaction History")
                                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("View recent activity")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.md)
                                    .fill(.white.opacity(0.25))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        // Contacts Button
                        Button(action: {
                            showContacts = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.accentBlue.opacity(0.4))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(FinanceColors.accentBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Contacts")
                                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                                        .foregroundColor(.white)
                                    
                                    Text("Manage contacts")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.md)
                                    .fill(.white.opacity(0.25))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                    }
                    .padding(.horizontal, 24)
                        .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                    
                    // Voice Feedback Section - hidden from user view
                    VStack(spacing: 16) {
                        // All feedback elements hidden but layout preserved
                    }
                    .padding(.horizontal, 24)
                    .opacity(0.0) // Completely hidden
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
        }
        .onAppear {
            animateElements = true
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .sheet(isPresented: $showWithdrawal) {
            WithdrawalView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $showMoneyOptions) {
            MoneyOptionsView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $showTransactionHistory) {
            TransactionHistoryView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $showContacts) {
            ContactsView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $commandService.showConfirmationDialog) {
            TransactionConfirmationView(commandService: commandService, userDatabase: userDatabase)
        }
        .sheet(isPresented: $showBalanceCheck) {
            BalanceCheckView(userDatabase: userDatabase)
        }
        .onChange(of: voiceManager.isListening) { isListening in
            print("🎤 Listening state changed: \(isListening)")
            print("📝 Recognized text: '\(voiceManager.recognizedText)'")
            print("⚙️ Processing: \(commandService.isProcessing)")
            
            // When user stops listening, process the command after a short delay
            if !isListening && !voiceManager.recognizedText.isEmpty && !commandService.isProcessing {
                print("⏰ Scheduling command processing in 0.8 seconds...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    let textToProcess = voiceManager.recognizedText
                    print("🎯 About to execute command: '\(textToProcess)'")
                    if !textToProcess.isEmpty {
                        commandService.processVoiceCommand(textToProcess, userDatabase: userDatabase)
                        print("✅ Command processing initiated")
                    } else {
                        print("❌ No text to process")
                    }
                }
            }
        }
        
        // Also listen for changes in recognized text to debug
        .onChange(of: voiceManager.recognizedText) { newText in
            print("📝 Recognized text changed to: '\(newText)'")
        }
        // Listen for balance check commands
        .onChange(of: commandService.lastResult) { result in
            if result.contains("Your current balance is") {
                showBalanceCheck = true
            }
        }
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func logout() {
        // Post logout notification instead of deleting user
        NotificationCenter.default.post(name: NSNotification.Name("UserLoggedOut"), object: nil)
    }
}

struct HomeActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                        .foregroundColor(FinanceColors.textPrimary)
                    
                    Text(subtitle)
                        .font(FinanceFonts.bodySmall)
                        .foregroundColor(FinanceColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(FinanceColors.textSecondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: FinanceRadius.md)
                    .fill(FinanceColors.cardBackground)
                    .financeCardStyle()
            )
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct BalanceCheckView: View {
    @ObservedObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    @State private var animateElements = false
    
    var recentTransactions: [Transaction] {
        return Array(userDatabase.getTransactionHistory().prefix(5))
    }
    
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
                        Text("Account Balance")
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
                    
                    // Balance display
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("Current Balance")
                                .font(FinanceFonts.label)
                                .foregroundColor(FinanceColors.textSecondary)
                            
                            Text("$\(String(format: "%.2f", userDatabase.getCurrentBalance()))")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(FinanceColors.primaryBlue)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                .fill(FinanceColors.cardBackground)
                                .financeCardStyle()
                        )
                        
                        // Recent transactions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Transactions")
                                .font(FinanceFonts.label)
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            if recentTransactions.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 40))
                                        .foregroundColor(FinanceColors.textTertiary)
                                    
                                    Text("No recent transactions")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 8) {
                                        ForEach(recentTransactions) { transaction in
                                            BalanceTransactionRow(transaction: transaction)
                                        }
                                    }
                                }
                                .frame(maxHeight: 300)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                .fill(FinanceColors.cardBackground)
                                .financeCardStyle()
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                        .frame(height: 20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(FinanceColors.backgroundPrimary)
                        .frame(width: min(geometry.size.width - 32, 400))
                )
                .frame(width: min(geometry.size.width - 32, 400))
                .opacity(animateElements ? 1.0 : 0.0)
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateElements)
            }
        }
        .onAppear {
            animateElements = true
        }
    }
}

struct BalanceTransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Transaction icon
            ZStack {
                Circle()
                    .fill(transactionColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: transactionIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(transactionColor)
            }
            
            // Transaction details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(FinanceFonts.bodyMedium.weight(.medium))
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text(formatTransactionDate(transaction.timestamp))
                    .font(FinanceFonts.caption)
                    .foregroundColor(FinanceColors.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(transactionAmount)
                .font(FinanceFonts.bodyMedium.weight(.semibold))
                .foregroundColor(transactionColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FinanceColors.backgroundSecondary)
        )
    }
    
    private var transactionColor: Color {
        switch transaction.type {
        case .deposit, .request:
            return FinanceColors.successGreen
        case .withdrawal, .send, .split, .transfer:
            return FinanceColors.errorRed
        }
    }
    
    private var transactionIcon: String {
        switch transaction.type {
        case .deposit:
            return "plus.circle.fill"
        case .withdrawal:
            return "minus.circle.fill"
        case .send:
            return "arrow.up.circle.fill"
        case .request:
            return "arrow.down.circle.fill"
        case .split:
            return "divide.circle.fill"
        case .transfer:
            return "arrow.right.arrow.left.circle.fill"
        }
    }
    
    private var transactionAmount: String {
        let sign = (transaction.type == .deposit || transaction.type == .request) ? "+" : "-"
        return "\(sign)$\(String(format: "%.2f", transaction.amount))"
    }
    
    private func formatTransactionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PendingRequestsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var userDatabase: UserDatabase
    @State private var animateElements = false
    
    var pendingRequests: [PendingRequest] {
        userDatabase.getPendingRequestsForCurrentUser()
    }
    
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
                        Text("Pending Requests")
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
                    
                    // Content
                    if pendingRequests.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 60))
                                .foregroundColor(FinanceColors.textTertiary)
                            
                            Text("No Pending Requests")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            Text("You don't have any pending money requests at the moment.")
                                .font(FinanceFonts.bodyMedium)
                                .foregroundColor(FinanceColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(pendingRequests) { request in
                                    PendingRequestRow(request: request) { accepted in
                                        userDatabase.respondToMoneyRequest(requestId: request.id, accept: accepted)
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        .frame(maxHeight: 400)
                    }
                    
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
}

struct PendingRequestRow: View {
    let request: PendingRequest
    let onResponse: (Bool) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Request header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(request.fromUserName)
                        .font(FinanceFonts.bodyMedium.weight(.semibold))
                        .foregroundColor(FinanceColors.textPrimary)
                    
                    Text("Requested")
                        .font(FinanceFonts.caption)
                        .foregroundColor(FinanceColors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.2f", request.amount))")
                        .font(FinanceFonts.heading3)
                        .foregroundColor(FinanceColors.primaryBlue)
                    
                    Text(formatDate(request.dateCreated))
                        .font(FinanceFonts.caption)
                        .foregroundColor(FinanceColors.textSecondary)
                }
            }
            
            // Description
            if !request.description.isEmpty {
                Text(request.description)
                    .font(FinanceFonts.bodySmall)
                    .foregroundColor(FinanceColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    onResponse(false)
                }) {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .font(FinanceFonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(FinanceColors.errorRed)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    onResponse(true)
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                        Text("Accept")
                    }
                    .font(FinanceFonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(FinanceColors.successGreen)
                    .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FinanceColors.cardBackground)
                .financeCardStyle()
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    HomePageView(userDatabase: UserDatabase())
}
