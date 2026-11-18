import SwiftUI
import UIKit

// ══════════════════════════════════════════════════════════════════════════
// DESIGN SYSTEM — AR Garage App
// Hybrid Design: Glass Card Layout (Option A) + Solid Components (Option B)
// ══════════════════════════════════════════════════════════════════════════

struct AppColors {
    // Backgrounds
    static let background       = Color(red: 0.047, green: 0.047, blue: 0.078)  // #0c0c14
    static let cardBg           = Color(red: 0.078, green: 0.078, blue: 0.125)  // #141420
    static let cardBorder       = Color(red: 0.118, green: 0.118, blue: 0.18)   // #1e1e2e
    static let deepBg           = Color(red: 0.031, green: 0.031, blue: 0.063)  // #080810
    static let inputBg          = Color(red: 0.055, green: 0.055, blue: 0.1)    // #0e0e1a

    // Accent
    static let accentBlue       = Color(red: 0.102, green: 0.373, blue: 0.647)  // #1a5fa5
    static let textBlue         = Color(red: 0.102, green: 0.561, blue: 1.0)    // #1a8fff
    static let buttonSecondary  = Color(red: 0.11, green: 0.11, blue: 0.165)    // #1c1c2a
    static let buttonSecBorder  = Color(red: 0.165, green: 0.165, blue: 0.227)  // #2a2a3a

    // Text
    static let textPrimary      = Color.white
    static let textSecondary    = Color(red: 0.4, green: 0.4, blue: 0.45)       // #667
    static let textTertiary     = Color(red: 0.33, green: 0.33, blue: 0.38)     // #556
    static let textHint         = Color(red: 0.267, green: 0.267, blue: 0.31)   // #445
    static let textDim          = Color(red: 0.2, green: 0.2, blue: 0.25)       // #334

    // Semantic
    static let successText      = Color(red: 0.165, green: 0.604, blue: 0.353)  // #2a9a5a
    static let successBg        = Color(red: 0.039, green: 0.165, blue: 0.094)  // #0a2a18
    static let warningText      = Color(red: 0.847, green: 0.353, blue: 0.188)  // #d85a30
    static let warningBg        = Color(red: 0.165, green: 0.082, blue: 0.063)  // #2a1510

    // Invoice
    static let invoiceBg        = Color(red: 0.063, green: 0.094, blue: 0.145)  // #101825
    static let invoiceBorder    = Color(red: 0.102, green: 0.188, blue: 0.314)  // #1a3050
}

struct AppRadius {
    static let card: CGFloat    = 14
    static let button: CGFloat  = 12
    static let chip: CGFloat    = 10
    static let swatch: CGFloat  = 8
    static let small: CGFloat   = 6
}

struct AppFonts {
    static let screenTitle  = Font.system(size: 16, weight: .bold)
    static let cardTitle    = Font.system(size: 24, weight: .bold)
    static let cardPrice    = Font.system(size: 18, weight: .semibold)
    static let sectionLabel = Font.system(size: 12, weight: .bold)
    static let bodyText     = Font.system(size: 14, weight: .medium)
    static let specValue    = Font.system(size: 16, weight: .semibold)
    static let statNumber   = Font.system(size: 20, weight: .bold)
    static let statLabel    = Font.system(size: 11, weight: .semibold)
    static let buttonLabel  = Font.system(size: 15, weight: .bold)
    static let chipLabel    = Font.system(size: 13, weight: .semibold)
    static let badgeLabel   = Font.system(size: 12, weight: .bold)
}

// ── Reusable Card Modifier ────────────────────────────────────────────────
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card)
                    .stroke(AppColors.cardBorder, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// ── Section Label ─────────────────────────────────────────────────────────
struct SectionLabel: View {
    let text: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
            }
            Text(text.uppercased())
                .font(.system(size: 12, weight: .bold)) // Let's also bump the size to match other headers like we did before
                .foregroundColor(.cyan)
                .tracking(1)
        }
    }
}

// ── Primary Button ────────────────────────────────────────────────────────
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                }
                Text(title)
                    .font(AppFonts.buttonLabel)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(AppColors.accentBlue)
            .cornerRadius(AppRadius.button)
        }
    }
}

// ── Secondary Button ──────────────────────────────────────────────────────
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                }
                Text(title)
                    .font(AppFonts.buttonLabel)
            }
            .foregroundColor(Color(white: 0.67))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(AppColors.buttonSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button)
                    .stroke(AppColors.buttonSecBorder, lineWidth: 0.5)
            )
            .cornerRadius(AppRadius.button)
        }
    }
}

// ── Stat Card ─────────────────────────────────────────────────────────────
struct StatCard: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text(value)
                    .font(AppFonts.statNumber)
                    .foregroundColor(.white)
                Text(unit)
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textTertiary)
            }
            Text(label.uppercased())
                .font(AppFonts.statLabel)
                .foregroundColor(.white)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .cardStyle()
    }
}

// ── Category Chip ─────────────────────────────────────────────────────────
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.8))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? AppColors.accentBlue : AppColors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.chip)
                        .stroke(isSelected ? Color.clear : AppColors.cardBorder, lineWidth: 0.5)
                )
                .cornerRadius(AppRadius.chip)
        }
    }
}

// ── Badge ─────────────────────────────────────────────────────────────────
struct DifferenceBadge: View {
    let text: String
    let isPositive: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 9))
            .foregroundColor(isPositive ? AppColors.successText : AppColors.warningText)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(isPositive ? AppColors.successBg : AppColors.warningBg)
            .cornerRadius(8)
    }
}

//  DesignSystem.swift
//  AR App Test
//
//  Created by Gui Shi Jun on 14/06/2026.
//

