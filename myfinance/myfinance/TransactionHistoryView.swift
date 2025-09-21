//
//  TransactionHistoryView.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

struct TransactionHistoryView: View {
    @EnvironmentObject var userDatabase: UserDatabase
    @Environment(\.presentationMode) var presentationMode
    @State private var animateElements = false
    
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
                                Text("Transaction History")
                                    .font(FinanceFonts.heading2)
                                    .foregroundColor(FinanceColors.textPrimary)
                                
                                Text("Recent activity")
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
                    
                    // Transaction list
                    VStack(spacing: 16) {
                        let transactions = userDatabase.getTransactionHistory()
                        
                        if transactions.isEmpty {
                            // Empty state
                            VStack(spacing: 20) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 60))
                                    .foregroundColor(FinanceColors.textTertiary)
                                
                                VStack(spacing: 8) {
                                    Text("No Transactions")
                                        .font(FinanceFonts.heading3)
                                        .foregroundColor(FinanceColors.textPrimary)
                                    
                                    Text("Your transaction history will appear here")
                                        .font(FinanceFonts.bodyMedium)
                                        .foregroundColor(FinanceColors.textSecondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.vertical, 60)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(0.4), value: animateElements)
                        } else {
                            // Transaction list
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(Array(transactions.reversed().enumerated()), id: \.element.id) { index, transaction in
                                        TransactionRow(transaction: transaction)
                                            .opacity(animateElements ? 1.0 : 0.0)
                                            .offset(x: animateElements ? 0 : -20)
                                            .animation(.easeOut(duration: 0.4).delay(0.4 + Double(index) * 0.1), value: animateElements)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onAppear {
            animateElements = true
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Transaction type icon
            ZStack {
                Circle()
                    .fill(transactionTypeColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: transactionTypeIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(transactionTypeColor)
            }
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(FinanceFonts.bodyMedium.weight(.semibold))
                    .foregroundColor(FinanceColors.textPrimary)
                
                Text(formatTransactionDate(transaction.timestamp))
                    .font(FinanceFonts.caption)
                    .foregroundColor(FinanceColors.textSecondary)
                
                Text(transaction.type.rawValue.capitalized)
                    .font(FinanceFonts.caption.weight(.medium))
                    .foregroundColor(transactionTypeColor)
            }
            
            Spacer()
            
            // Amount
            Text(transactionAmountText)
                .font(FinanceFonts.amountMedium)
                .foregroundColor(transactionTypeColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: FinanceRadius.md)
                .fill(FinanceColors.cardBackground)
                .financeCardStyle()
        )
    }
    
    private var transactionTypeColor: Color {
        switch transaction.type {
        case .deposit:
            return FinanceColors.successGreen
        case .withdrawal:
            return FinanceColors.primaryRed
        case .transfer:
            return FinanceColors.accentBlue
        case .split:
            return FinanceColors.warningOrange
        case .request:
            return FinanceColors.successGreen
        case .send:
            return FinanceColors.primaryBlue
        }
    }
    
    private var transactionTypeIcon: String {
        switch transaction.type {
        case .deposit:
            return "plus.circle.fill"
        case .withdrawal:
            return "minus.circle.fill"
        case .transfer:
            return "arrow.left.arrow.right.circle.fill"
        case .split:
            return "divide.circle.fill"
        case .request:
            return "hand.raised.circle.fill"
        case .send:
            return "paperplane.circle.fill"
        }
    }
    
    private var transactionAmountText: String {
        let prefix = (transaction.type == .withdrawal || transaction.type == .send || 
                     (transaction.type == .split && transaction.amount < 0)) ? "-" : "+"
        return "\(prefix)$\(String(format: "%.2f", abs(transaction.amount)))"
    }
    
    private func formatTransactionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TransactionHistoryView()
        .environmentObject(UserDatabase())
}
