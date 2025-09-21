//
//  TransactionConfirmationView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct TransactionConfirmationView: View {
    @ObservedObject var commandService: VoiceCommandService
    @ObservedObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            // Warning Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding(.top, 20)
            
            // Title
            Text("Large Transaction Alert")
                .font(FinanceFonts.heading2)
                .foregroundColor(FinanceColors.textPrimary)
                .multilineTextAlignment(.center)
            
            // Transaction Details
            if let transaction = commandService.pendingTransaction {
                VStack(spacing: 16) {
                    // Amount and percentage
                    VStack(spacing: 8) {
                        Text("Amount: \(formatAmount(transaction.amount))")
                            .font(FinanceFonts.heading3)
                            .foregroundColor(FinanceColors.textPrimary)
                        
                        Text("This is \(String(format: "%.1f", transaction.percentageOfBalance))% of your current balance")
                            .font(FinanceFonts.bodyMedium)
                            .foregroundColor(FinanceColors.warningOrange)
                            .multilineTextAlignment(.center)
                    }
                    
                    Divider()
                        .background(FinanceColors.textSecondary)
                    
                    // Transaction type and contact
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transaction Type:")
                                .font(FinanceFonts.caption)
                                .foregroundColor(FinanceColors.textSecondary)
                            Text(transactionTypeText(transaction.type))
                                .font(FinanceFonts.bodyMedium)
                                .foregroundColor(FinanceColors.textPrimary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Contact:")
                                .font(FinanceFonts.caption)
                                .foregroundColor(FinanceColors.textSecondary)
                            Text(transaction.contactName)
                                .font(FinanceFonts.bodyMedium)
                                .foregroundColor(FinanceColors.textPrimary)
                        }
                    }
                    
                    // Current balance
                    HStack {
                        Text("Your Current Balance:")
                            .font(FinanceFonts.bodyMedium)
                            .foregroundColor(FinanceColors.textSecondary)
                        Spacer()
                        Text(formatAmount(userDatabase.getCurrentBalance()))
                            .font(FinanceFonts.bodyMedium.weight(.semibold))
                            .foregroundColor(FinanceColors.successGreen)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FinanceColors.backgroundSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FinanceColors.warningOrange, lineWidth: 2)
                        )
                )
            }
            
            // Description
            Text("This is a large transaction. Please confirm that you want to proceed.")
                .font(FinanceFonts.bodyMedium)
                .foregroundColor(FinanceColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 16) {
                // Confirm Button
                Button(action: {
                    commandService.confirmTransaction(userDatabase: userDatabase)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Yes, Proceed")
                    }
                    .font(FinanceFonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(FinanceColors.successGreen)
                    .cornerRadius(12)
                }
                
                // Cancel Button
                Button(action: {
                    commandService.cancelTransaction()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                        Text("Cancel Transaction")
                    }
                    .font(FinanceFonts.button)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(FinanceColors.errorRed)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(FinanceColors.backgroundPrimary)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(20)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    private func transactionTypeText(_ type: VoiceCommandService.TransactionType) -> String {
        switch type {
        case .send:
            return "Send Money"
        case .split:
            return "Split Bill"
        case .request:
            return "Request Money"
        case .requestFromUser:
            return "Request from User"
        }
    }
}

#Preview {
    TransactionConfirmationView(
        commandService: VoiceCommandService(),
        userDatabase: UserDatabase()
    )
}
