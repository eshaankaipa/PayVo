//
//  FontStyles.swift
//  myfinance
//
//  Created by E K on 9/20/25.
//

import SwiftUI

// MARK: - Professional Finance Typography
struct FinanceFonts {
    // Primary headings - Strong, authoritative
    static let heading1 = Font.system(size: 32, weight: .bold, design: .default)
    static let heading2 = Font.system(size: 28, weight: .bold, design: .default)
    static let heading3 = Font.system(size: 24, weight: .semibold, design: .default)
    
    // Body text - Clear, readable
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    
    // Financial data - Monospaced for alignment
    static let amountLarge = Font.system(size: 28, weight: .bold, design: .monospaced)
    static let amountMedium = Font.system(size: 20, weight: .semibold, design: .monospaced)
    static let amountSmall = Font.system(size: 16, weight: .medium, design: .monospaced)
    
    // UI elements
    static let button = Font.system(size: 16, weight: .semibold, design: .default)
    static let caption = Font.system(size: 12, weight: .medium, design: .default)
    static let label = Font.system(size: 14, weight: .semibold, design: .default)
}

// MARK: - Professional Finance Colors
struct FinanceColors {
    // Primary brand colors
    static let primaryBlue = Color(red: 0.05, green: 0.15, blue: 0.35)      // Deep navy
    static let primaryRed = Color(red: 0.8, green: 0.15, blue: 0.15)        // Corporate red
    static let accentBlue = Color(red: 0.0, green: 0.4, blue: 0.8)          // Bright blue
    
    // Financial status colors
    static let successGreen = Color(red: 0.0, green: 0.6, blue: 0.3)        // Success green
    static let warningOrange = Color(red: 1.0, green: 0.6, blue: 0.0)       // Warning orange
    static let errorRed = Color(red: 0.8, green: 0.2, blue: 0.2)           // Error red
    
    // Neutral colors
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)        // Dark text
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.4)      // Medium text
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.6)       // Light text
    
    // Background colors
    static let backgroundPrimary = Color(red: 0.98, green: 0.98, blue: 1.0) // Clean white
    static let backgroundSecondary = Color(red: 0.95, green: 0.96, blue: 0.98) // Light gray
    static let cardBackground = Color.white
    static let overlayBackground = Color.black.opacity(0.4)
}

// MARK: - Professional Shadows and Effects
struct FinanceShadows {
    static let card = Shadow(
        color: Color.black.opacity(0.08),
        radius: 12,
        x: 0,
        y: 4
    )
    
    static let button = Shadow(
        color: Color.black.opacity(0.1),
        radius: 8,
        x: 0,
        y: 2
    )
    
    static let modal = Shadow(
        color: Color.black.opacity(0.15),
        radius: 20,
        x: 0,
        y: 8
    )
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Professional Spacing
struct FinanceSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Professional Corner Radius
struct FinanceRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let button: CGFloat = 28
}

// MARK: - View Modifiers for Professional Styling
extension View {
    func financeCardStyle() -> some View {
        self
            .background(FinanceColors.cardBackground)
            .cornerRadius(FinanceRadius.md)
            .shadow(
                color: FinanceShadows.card.color,
                radius: FinanceShadows.card.radius,
                x: FinanceShadows.card.x,
                y: FinanceShadows.card.y
            )
    }
    
    func financeButtonStyle() -> some View {
        self
            .shadow(
                color: FinanceShadows.button.color,
                radius: FinanceShadows.button.radius,
                x: FinanceShadows.button.x,
                y: FinanceShadows.button.y
            )
    }
    
    func financeTextStyle(_ style: Font, color: Color = FinanceColors.textPrimary) -> some View {
        self
            .font(style)
            .foregroundColor(color)
    }
    
    func financeAmountStyle(_ isPositive: Bool = true) -> some View {
        self
            .font(FinanceFonts.amountMedium)
            .foregroundColor(isPositive ? FinanceColors.successGreen : FinanceColors.errorRed)
    }
}
