import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 5 — BUDGET PAGE (Itemised Invoice)
// ══════════════════════════════════════════════════════════════════════════

struct BudgetView: View {
    let vehicle: Vehicle
    let selectedVariantName: String
    let selectedVariantSwatch: Color?
    @Binding var selectedParts: [String: CarPart]
    @Environment(\.dismiss) var dismiss
    
    @Binding var selectedSpecIndex: Int

    var allSpecs: [SpecVariant] {
        if vehicle.specVariants.isEmpty {
            return [SpecVariant(id: "standard", name: "Standard", specs: vehicle.stockSpecs)]
        }
        return vehicle.specVariants
    }
    
    var currentBasePrice: Double {
        let p = allSpecs[selectedSpecIndex].specs.configPrice
        return p > 0 ? p : vehicle.basePrice
    }

    var partsSubtotal: Double {
        selectedParts.values.reduce(0) { $0 + $1.price }
    }

    var grandTotal: Double {
        currentBasePrice + partsSubtotal
    }

    var overBase: Double {
        partsSubtotal
    }

    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 8) {
                    // ── Top Bar ───────────────────────────────────────
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                        Spacer()
                        Text("BUDGET")
                            .font(AppFonts.screenTitle)
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Spacer()
                        Button(action: { }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textTertiary)
                                .padding(12)
                        }
                    }
                    .padding(.horizontal, 4)

                    // ── Total Card ────────────────────────────────────
                    VStack(spacing: 4) {
                        Text("TOTAL BUILD COST")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.cyan)
                            .tracking(1)
                        Text("RM \(Int(grandTotal).formatted())")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white)
                            .tracking(-1)

                        if overBase > 0 {
                            Text("RM \(Int(overBase).formatted()) over base price")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.warningText)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(AppColors.warningBg)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Base Vehicle ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 6) {
                        SectionLabel(text: "Base vehicle", icon: "car.fill")
                        HStack(spacing: 10) {
                            // Colour swatch box
                            if let swatch = selectedVariantSwatch {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(swatch)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(vehicle.name)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                if !selectedVariantName.isEmpty && selectedVariantName != "Standard" {
                                    Text(selectedVariantName)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("RM \(Int(currentBasePrice).formatted())")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                
                                if allSpecs.count > 1 {
                                    Menu {
                                        ForEach(allSpecs.indices, id: \.self) { index in
                                            Button(allSpecs[index].name) {
                                                selectedSpecIndex = index
                                            }
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(allSpecs[selectedSpecIndex].name)
                                                .font(.system(size: 11, weight: .semibold))
                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 9, weight: .bold))
                                        }
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(6)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Selected Parts ────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel(text: "Selected parts", icon: "wrench.fill")
                            .padding(.bottom, 8)

                        let nonDefaultParts = selectedParts.values.filter { !$0.isDefault }.sorted(by: { $0.category < $1.category })

                        if nonDefaultParts.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 24))
                                        .foregroundColor(.cyan)
                                    Text("No aftermarket parts selected")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 20)
                                Spacer()
                            }
                        } else {
                            ForEach(nonDefaultParts) { part in
                                BudgetPartRow(part: part) {
                                    // Remove part and replace with default for that category
                                    if let def = defaultPart(for: vehicle, category: part.category) {
                                        selectedParts[part.category] = def
                                    } else {
                                        selectedParts.removeValue(forKey: part.category)
                                    }
                                }
                            }
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Subtotal Breakdown ────────────────────────────
                    VStack(spacing: 6) {
                        HStack {
                            Text("Parts subtotal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("RM \(Int(partsSubtotal).formatted())")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                        HStack {
                            Text("Base vehicle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("RM \(Int(vehicle.basePrice).formatted())")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Grand Total Button ────────────────────────────
                    VStack(spacing: 2) {
                        Text("TOTAL ESTIMATE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(1)
                        Text("RM \(Int(grandTotal).formatted())")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.accentBlue)
                    .cornerRadius(AppRadius.card)
                    .padding(.horizontal, 12)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// ── Budget Part Row ───────────────────────────────────────────────────────
struct BudgetPartRow: View {
    let part: CarPart
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.swatch)
                    .fill(AppColors.inputBg)
                    .frame(width: 36, height: 36)
                Image(systemName: iconFor(part.category))
                    .font(.system(size: 16))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(part.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                if part.affectsPerformance {
                    HStack(spacing: 2) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                        Text("Performance")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(AppColors.successText)
                } else {
                    Text("Cosmetic")
                        .font(.system(size: 11))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            Text("RM \(Int(part.price).formatted())")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .fill(AppColors.cardBorder.opacity(0.5))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        )
    }

    func iconFor(_ category: String) -> String {
        switch category {
        case "Rims": return "circle.dashed"
        case "Spoilers": return "arrow.up.forward"
        case "Body Kits": return "car.fill"
        case "Wraps": return "paintbrush.fill"
        case "Interior": return "steeringwheel"
        default: return "wrench.fill"
        }
    }
}
