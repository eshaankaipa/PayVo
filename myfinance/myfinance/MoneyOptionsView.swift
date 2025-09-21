//
//  MoneyOptionsView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct MoneyOptionsView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    @State private var animateElements = false
    @State private var showSend = false
    @State private var showRequest = false
    @State private var showSplit = false
    @State private var showPendingRequests = false
    
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
                                Text("Money Options")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("Manage your money")
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
                    
                    // Current balance display
                    VStack(spacing: 16) {
                        Text("Current Balance")
                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                            .foregroundColor(FinanceColors.textSecondary)
                        
                        Text("$\(String(format: "%.2f", userDatabase.getCurrentBalance()))")
                            .font(FinanceFonts.amountLarge)
                            .foregroundColor(FinanceColors.successGreen)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: FinanceRadius.lg)
                            .fill(FinanceColors.cardBackground)
                            .financeCardStyle()
                    )
                    .padding(.horizontal, 24)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .scaleEffect(animateElements ? 1.0 : 0.9)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateElements)
                    
                    Spacer()
                    
                    // Pending Requests Section (only show if there are pending requests)
                    if !userDatabase.getPendingRequestsForCurrentUser().isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Pending Requests")
                                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showPendingRequests = true
                                }) {
                                    HStack(spacing: 4) {
                                        Text("View All")
                                            .font(FinanceFonts.bodySmall.weight(.medium))
                                            .foregroundColor(FinanceColors.primaryBlue)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(FinanceColors.primaryBlue)
                                    }
                                }
                            }
                            
                            // Show first 2 pending requests
                            VStack(spacing: 12) {
                                ForEach(Array(userDatabase.getPendingRequestsForCurrentUser().prefix(2))) { request in
                                    PendingRequestMiniRow(request: request) { accepted in
                                        userDatabase.respondToMoneyRequest(requestId: request.id, accept: accepted)
                                    }
                                }
                                
                                // Show "more" indicator if there are more than 2 requests
                                if userDatabase.getPendingRequestsForCurrentUser().count > 2 {
                                    Button(action: {
                                        showPendingRequests = true
                                    }) {
                                        HStack {
                                            Text("+ \(userDatabase.getPendingRequestsForCurrentUser().count - 2) more requests")
                                                .font(FinanceFonts.bodySmall.weight(.medium))
                                                .foregroundColor(FinanceColors.primaryBlue)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(FinanceColors.primaryBlue)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(FinanceColors.primaryBlue.opacity(0.1))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                .fill(FinanceColors.cardBackground)
                                .financeCardStyle()
                        )
                        .padding(.horizontal, 24)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .scaleEffect(animateElements ? 1.0 : 0.9)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: animateElements)
                        
                        Spacer()
                    }
                    
                    // Money options
                    VStack(spacing: 20) {
                        // Send Money Button
                        Button(action: {
                            showSend = true
                        }) {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.accentBlue.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(FinanceColors.accentBlue)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Send Money")
                                        .font(FinanceFonts.bodyLarge.weight(.semibold))
                                        .foregroundColor(FinanceColors.textPrimary)
                                    
                                    Text("Send money to a contact")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(FinanceColors.textSecondary)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                        
                        // Request Money Button
                        Button(action: {
                            showRequest = true
                        }) {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.warningOrange.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "hand.raised.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(FinanceColors.warningOrange)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Request Money")
                                        .font(FinanceFonts.bodyLarge.weight(.semibold))
                                        .foregroundColor(FinanceColors.textPrimary)
                                    
                                    Text("Request money from a contact")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(FinanceColors.textSecondary)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                        
                        // Split Bill Button
                        Button(action: {
                            showSplit = true
                        }) {
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(FinanceColors.successGreen.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "divide.circle.fill")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(FinanceColors.successGreen)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Split Bill")
                                        .font(FinanceFonts.bodyLarge.weight(.semibold))
                                        .foregroundColor(FinanceColors.textPrimary)
                                    
                                    Text("Split money between contacts")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(FinanceColors.textSecondary)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                    
                    Spacer()
                        .frame(height: 60)
                }
            }
        }
        .onAppear {
            animateElements = true
        }
        .sheet(isPresented: $showSend) {
            SendMoneyView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $showRequest) {
            RequestMoneyView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $showSplit) {
            SplitBillView()
                .environmentObject(userDatabase)
        }
        .sheet(isPresented: $showPendingRequests) {
            PendingRequestsView()
                .environmentObject(userDatabase)
        }
    }
}

// MARK: - Send Money View

struct SendMoneyView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    
    @State private var sendAmount: Double = 0.0
    @State private var selectedContact: Contact?
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var animateElements = false
    
    private let maxAmount: Double = 10000.0
    private let minAmount: Double = 1.0
    
    var contacts: [Contact] {
        userDatabase.getContacts()
    }
    
    var canSend: Bool {
        sendAmount >= minAmount && selectedContact != nil
    }
    
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
                                Text("Send Money")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("Send money to a contact")
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
                    
                    // Contact and amount selection
                    VStack(spacing: 32) {
                        // Contact selection
                        VStack(spacing: 24) {
                            Text("Select Contact")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                            
                            if contacts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                                        .font(.system(size: 48))
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("No contacts available")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("Add contacts to send money")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                .padding(40)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(contacts, id: \.id) { contact in
                                            Button(action: {
                                                selectedContact = contact
                                            }) {
                                                HStack(spacing: 16) {
                                                    Circle()
                                                        .fill(FinanceColors.accentBlue.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                        .overlay(
                                                            Text(String(contact.name.prefix(1)).uppercased())
                                                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                                .foregroundColor(FinanceColors.accentBlue)
                                                        )
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(contact.name)
                                                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                            .foregroundColor(FinanceColors.textPrimary)
                                                        
                                                        Text("Balance: $\(String(format: "%.2f", contact.balance))")
                                                            .font(FinanceFonts.bodySmall)
                                                            .foregroundColor(FinanceColors.textSecondary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if selectedContact?.id == contact.id {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(FinanceColors.successGreen)
                                                    }
                                                }
                                                .padding(16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                        .fill(selectedContact?.id == contact.id ? 
                                                              FinanceColors.accentBlue.opacity(0.1) : 
                                                              FinanceColors.cardBackground)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                                .stroke(selectedContact?.id == contact.id ? 
                                                                        FinanceColors.accentBlue : 
                                                                        Color.clear, lineWidth: 2)
                                                        )
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                        
                        // Amount selection
                        VStack(spacing: 24) {
                            Text("Select Amount")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                            
                            VStack(spacing: 16) {
                                Text("$\(String(format: "%.2f", sendAmount))")
                                    .font(FinanceFonts.amountLarge)
                                    .foregroundColor(FinanceColors.accentBlue)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .scaleEffect(animateElements ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateElements)
                                
                                Slider(value: $sendAmount, in: minAmount...maxAmount, step: 1.0)
                                    .accentColor(FinanceColors.accentBlue)
                                    .padding(.horizontal, 20)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .offset(y: animateElements ? 0 : 20)
                                    .animation(.easeOut(duration: 0.6).delay(1.2), value: animateElements)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                        
                        // Quick amount buttons
                        VStack(spacing: 16) {
                            Text("Quick Amounts")
                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach([25.0, 50.0, 100.0, 250.0], id: \.self) { amount in
                                    Button("$\(String(format: "%.0f", amount))") {
                                        sendAmount = amount
                                    }
                                    .font(FinanceFonts.caption.weight(.semibold))
                                    .foregroundColor(FinanceColors.accentBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: FinanceRadius.sm)
                                            .fill(FinanceColors.accentBlue.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Send button
                    Button(action: {
                        processSend()
                    }) {
                        HStack(spacing: 12) {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            
                            Text(isProcessing ? "Processing..." : "Send $\(String(format: "%.2f", sendAmount))")
                                .font(FinanceFonts.button)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.button)
                                .fill(canSend ? FinanceColors.accentBlue : FinanceColors.textTertiary)
                        )
                    }
                    .disabled(!canSend || isProcessing)
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
        .alert("Send Successful", isPresented: $showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("You have successfully sent $\(String(format: "%.2f", sendAmount)) to \(selectedContact?.name ?? "")")
        }
    }
    
    private func processSend() {
        guard let contact = selectedContact, sendAmount >= minAmount else { return }
        
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let success = userDatabase.sendToContact(contactName: contact.name, amount: sendAmount, description: "Manual Send")
            
            isProcessing = false
            
            if success {
                showSuccess = true
            }
        }
    }
}

// MARK: - Request Money View

struct RequestMoneyView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    
    @State private var requestAmount: Double = 0.0
    @State private var selectedContact: Contact?
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var animateElements = false
    
    private let maxAmount: Double = 10000.0
    private let minAmount: Double = 1.0
    
    var contacts: [Contact] {
        userDatabase.getContacts()
    }
    
    var canRequest: Bool {
        requestAmount >= minAmount && selectedContact != nil
    }
    
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
                                Text("Request Money")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("Request money from a contact")
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
                    
                    // Contact and amount selection (similar to SendMoneyView)
                    VStack(spacing: 32) {
                        // Contact selection
                        VStack(spacing: 24) {
                            Text("Select Contact")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                            
                            if contacts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                                        .font(.system(size: 48))
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("No contacts available")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("Add contacts to request money")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                .padding(40)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(contacts, id: \.id) { contact in
                                            Button(action: {
                                                selectedContact = contact
                                            }) {
                                                HStack(spacing: 16) {
                                                    Circle()
                                                        .fill(FinanceColors.warningOrange.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                        .overlay(
                                                            Text(String(contact.name.prefix(1)).uppercased())
                                                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                                .foregroundColor(FinanceColors.warningOrange)
                                                        )
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(contact.name)
                                                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                            .foregroundColor(FinanceColors.textPrimary)
                                                        
                                                        Text("Balance: $\(String(format: "%.2f", contact.balance))")
                                                            .font(FinanceFonts.bodySmall)
                                                            .foregroundColor(FinanceColors.textSecondary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if selectedContact?.id == contact.id {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(FinanceColors.successGreen)
                                                    }
                                                }
                                                .padding(16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                        .fill(selectedContact?.id == contact.id ? 
                                                              FinanceColors.warningOrange.opacity(0.1) : 
                                                              FinanceColors.cardBackground)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                                .stroke(selectedContact?.id == contact.id ? 
                                                                        FinanceColors.warningOrange : 
                                                                        Color.clear, lineWidth: 2)
                                                        )
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                        
                        // Amount selection
                        VStack(spacing: 24) {
                            Text("Select Amount")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                            
                            VStack(spacing: 16) {
                                Text("$\(String(format: "%.2f", requestAmount))")
                                    .font(FinanceFonts.amountLarge)
                                    .foregroundColor(FinanceColors.warningOrange)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .scaleEffect(animateElements ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateElements)
                                
                                Slider(value: $requestAmount, in: minAmount...maxAmount, step: 1.0)
                                    .accentColor(FinanceColors.warningOrange)
                                    .padding(.horizontal, 20)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .offset(y: animateElements ? 0 : 20)
                                    .animation(.easeOut(duration: 0.6).delay(1.2), value: animateElements)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                        
                        // Quick amount buttons
                        VStack(spacing: 16) {
                            Text("Quick Amounts")
                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach([25.0, 50.0, 100.0, 250.0], id: \.self) { amount in
                                    Button("$\(String(format: "%.0f", amount))") {
                                        requestAmount = amount
                                    }
                                    .font(FinanceFonts.caption.weight(.semibold))
                                    .foregroundColor(FinanceColors.warningOrange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: FinanceRadius.sm)
                                            .fill(FinanceColors.warningOrange.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Request button
                    Button(action: {
                        processRequest()
                    }) {
                        HStack(spacing: 12) {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            
                            Text(isProcessing ? "Processing..." : "Request $\(String(format: "%.2f", requestAmount))")
                                .font(FinanceFonts.button)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.button)
                                .fill(canRequest ? FinanceColors.warningOrange : FinanceColors.textTertiary)
                        )
                    }
                    .disabled(!canRequest || isProcessing)
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
        .alert("Request Successful", isPresented: $showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("You have successfully requested $\(String(format: "%.2f", requestAmount)) from \(selectedContact?.name ?? "")")
        }
    }
    
    private func processRequest() {
        guard let contact = selectedContact, requestAmount >= minAmount else { return }
        
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let success = userDatabase.requestFromContact(contactName: contact.name, amount: requestAmount, description: "Manual Request")
            
            isProcessing = false
            
            if success {
                showSuccess = true
            }
        }
    }
}

// MARK: - Split Bill View

struct SplitBillView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    
    @State private var splitAmount: Double = 0.0
    @State private var selectedContacts: Set<Contact> = []
    @State private var isProcessing = false
    @State private var showSuccess = false
    @State private var animateElements = false
    
    private let maxAmount: Double = 10000.0
    private let minAmount: Double = 1.0
    
    var contacts: [Contact] {
        userDatabase.getContacts()
    }
    
    var canSplit: Bool {
        splitAmount >= minAmount && !selectedContacts.isEmpty
    }
    
    var totalPeople: Int {
        selectedContacts.count + 1 // +1 for you
    }
    
    var amountPerPerson: Double {
        guard totalPeople > 0 else { return 0 }
        return splitAmount / Double(totalPeople)
    }
    
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
                                Text("Split Bill")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("Split money between contacts")
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
                    
                    // Contact and amount selection
                    VStack(spacing: 32) {
                        // Contact selection
                        VStack(spacing: 24) {
                            Text("Select Contacts")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                            
                            if contacts.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                                        .font(.system(size: 48))
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("No contacts available")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                    
                                    Text("Add contacts to split bills")
                                        .font(FinanceFonts.bodySmall)
                                        .foregroundColor(FinanceColors.textSecondary)
                                }
                                .padding(40)
                                .background(
                                    RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                        .fill(FinanceColors.cardBackground)
                                        .financeCardStyle()
                                )
                            } else {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(contacts, id: \.id) { contact in
                                            Button(action: {
                                                if selectedContacts.contains(contact) {
                                                    selectedContacts.remove(contact)
                                                } else {
                                                    selectedContacts.insert(contact)
                                                }
                                            }) {
                                                HStack(spacing: 16) {
                                                    Circle()
                                                        .fill(FinanceColors.successGreen.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                        .overlay(
                                                            Text(String(contact.name.prefix(1)).uppercased())
                                                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                                .foregroundColor(FinanceColors.successGreen)
                                                        )
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(contact.name)
                                                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                                                            .foregroundColor(FinanceColors.textPrimary)
                                                        
                                                        Text("Balance: $\(String(format: "%.2f", contact.balance))")
                                                            .font(FinanceFonts.bodySmall)
                                                            .foregroundColor(FinanceColors.textSecondary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    if selectedContacts.contains(contact) {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(FinanceColors.successGreen)
                                                    }
                                                }
                                                .padding(16)
                                                .background(
                                                    RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                        .fill(selectedContacts.contains(contact) ? 
                                                              FinanceColors.successGreen.opacity(0.1) : 
                                                              FinanceColors.cardBackground)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: FinanceRadius.md)
                                                                .stroke(selectedContacts.contains(contact) ? 
                                                                        FinanceColors.successGreen : 
                                                                        Color.clear, lineWidth: 2)
                                                        )
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                .frame(maxHeight: 200)
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.6), value: animateElements)
                        
                        // Amount selection
                        VStack(spacing: 24) {
                            Text("Total Amount")
                                .font(FinanceFonts.heading3)
                                .foregroundColor(FinanceColors.textPrimary)
                                .opacity(animateElements ? 1.0 : 0.0)
                                .offset(y: animateElements ? 0 : 20)
                                .animation(.easeOut(duration: 0.6).delay(0.8), value: animateElements)
                            
                            VStack(spacing: 16) {
                                Text("$\(String(format: "%.2f", splitAmount))")
                                    .font(FinanceFonts.amountLarge)
                                    .foregroundColor(FinanceColors.successGreen)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .scaleEffect(animateElements ? 1.0 : 0.8)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.0), value: animateElements)
                                
                                Slider(value: $splitAmount, in: minAmount...maxAmount, step: 1.0)
                                    .accentColor(FinanceColors.successGreen)
                                    .padding(.horizontal, 20)
                                    .opacity(animateElements ? 1.0 : 0.0)
                                    .offset(y: animateElements ? 0 : 20)
                                    .animation(.easeOut(duration: 0.6).delay(1.2), value: animateElements)
                                
                                // Split calculation display
                                if canSplit {
                                    VStack(spacing: 8) {
                                        Text("Split Calculation")
                                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                                            .foregroundColor(FinanceColors.textPrimary)
                                        
                                        HStack {
                                            Text("Total People:")
                                                .font(FinanceFonts.bodySmall)
                                                .foregroundColor(FinanceColors.textSecondary)
                                            Spacer()
                                            Text("\(totalPeople)")
                                                .font(FinanceFonts.bodySmall.weight(.semibold))
                                                .foregroundColor(FinanceColors.textPrimary)
                                        }
                                        
                                        HStack {
                                            Text("Each Person Pays:")
                                                .font(FinanceFonts.bodySmall)
                                                .foregroundColor(FinanceColors.textSecondary)
                                            Spacer()
                                            Text("$\(String(format: "%.2f", amountPerPerson))")
                                                .font(FinanceFonts.bodySmall.weight(.semibold))
                                                .foregroundColor(FinanceColors.successGreen)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: FinanceRadius.md)
                                            .fill(FinanceColors.successGreen.opacity(0.1))
                                    )
                                }
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: FinanceRadius.lg)
                                    .fill(FinanceColors.cardBackground)
                                    .financeCardStyle()
                            )
                        }
                        
                        // Quick amount buttons
                        VStack(spacing: 16) {
                            Text("Quick Amounts")
                                .font(FinanceFonts.bodyMedium.weight(.semibold))
                                .foregroundColor(FinanceColors.textPrimary)
                            
                            HStack(spacing: 12) {
                                ForEach([30.0, 60.0, 120.0, 300.0], id: \.self) { amount in
                                    Button("$\(String(format: "%.0f", amount))") {
                                        splitAmount = amount
                                    }
                                    .font(FinanceFonts.caption.weight(.semibold))
                                    .foregroundColor(FinanceColors.successGreen)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: FinanceRadius.sm)
                                            .fill(FinanceColors.successGreen.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(1.4), value: animateElements)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Split button
                    Button(action: {
                        processSplit()
                    }) {
                        HStack(spacing: 12) {
                            if isProcessing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "divide.circle.fill")
                                    .font(.system(size: 20, weight: .medium))
                            }
                            
                            Text(isProcessing ? "Processing..." : "Split $\(String(format: "%.2f", splitAmount))")
                                .font(FinanceFonts.button)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: FinanceRadius.button)
                                .fill(canSplit ? FinanceColors.successGreen : FinanceColors.textTertiary)
                        )
                    }
                    .disabled(!canSplit || isProcessing)
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
        .alert("Split Successful", isPresented: $showSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("You have successfully split $\(String(format: "%.2f", splitAmount)) between \(selectedContacts.count) contacts and you. Each person pays $\(String(format: "%.2f", amountPerPerson)).")
        }
    }
    
    private func processSplit() {
        guard !selectedContacts.isEmpty, splitAmount >= minAmount else { return }
        
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let contactNames = selectedContacts.map { $0.name }
            let success = userDatabase.collectSplitFromMultipleContacts(contactNames: contactNames, totalAmount: splitAmount, description: "Manual Split")
            
            isProcessing = false
            
            if success {
                showSuccess = true
            }
        }
    }
}

// MARK: - Pending Request Mini Row
struct PendingRequestMiniRow: View {
    let request: PendingRequest
    let onResponse: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FinanceColors.primaryBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(String(request.fromUserName.prefix(1)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(FinanceColors.primaryBlue)
            }
            
            // Request info
            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromUserName)
                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text("$\(String(format: "%.2f", request.amount))")
                    .font(FinanceFonts.bodySmall.weight(.medium))
                    .foregroundColor(FinanceColors.successGreen)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    onResponse(false)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FinanceColors.errorRed)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(FinanceColors.errorRed.opacity(0.1))
                        )
                }
                
                Button(action: {
                    onResponse(true)
                }) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(FinanceColors.successGreen)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(FinanceColors.successGreen.opacity(0.1))
                        )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(FinanceColors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(FinanceColors.textSecondary.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    MoneyOptionsView()
        .environmentObject(UserDatabase())
}
