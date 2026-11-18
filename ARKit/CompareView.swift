import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 4 — COMPARE PAGE (pick any two versions to compare)
// ══════════════════════════════════════════════════════════════════════════

// A single comparable option — either a named SpecVariant (e.g. Voyah Free's
// "RWD Electric") or the legacy Stock/Modified pair used by other vehicles.
struct CompareOption: Identifiable {
    let id: String
    let name: String
    let specs: VehicleSpecs
}

struct CompareView: View {
    let vehicle: Vehicle
    @Environment(\.dismiss) var dismiss

    // Index into `options` for the two sides being compared.
    @State private var selectedAIndex: Int = 0
    @State private var selectedBIndex: Int = 1

    // Builds the list of choices depending on whether this vehicle uses
    // the new multi-variant system or the original Stock/Modified pair.
    var options: [CompareOption] {
        if !vehicle.specVariants.isEmpty {
            return vehicle.specVariants.map {
                CompareOption(id: $0.id, name: $0.name, specs: $0.specs)
            }
        }
        return [
            CompareOption(id: "stock", name: "Stock", specs: vehicle.stockSpecs),
            CompareOption(id: "modified", name: "Modified", specs: vehicle.modifiedSpecs),
        ]
    }

    var optionA: CompareOption {
        options[min(selectedAIndex, options.count - 1)]
    }

    var optionB: CompareOption {
        options[min(selectedBIndex, options.count - 1)]
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
                        Text("COMPARE")
                            .font(AppFonts.screenTitle)
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Spacer()
                        Spacer().frame(width: 40)
                    }
                    .padding(.horizontal, 4)

                    // ── Version Selector Headers ──────────────────────
                    HStack(spacing: 6) {
                        // Side A picker
                        Menu {
                            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                                Button(option.name) { withAnimation(.easeInOut(duration: 0.2)) { selectedAIndex = index } }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.inputBg)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.cyan)
                                }
                                HStack(spacing: 3) {
                                    Text(optionA.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                                Text("Compare A")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .cardStyle()
                        }

                        // Side B picker
                        Menu {
                            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                                Button(option.name) { withAnimation(.easeInOut(duration: 0.2)) { selectedBIndex = index } }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(AppColors.inputBg)
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "car.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.cyan)
                                }
                                HStack(spacing: 3) {
                                    Text(optionB.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                                Text("Compare B")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .cardStyle()
                        }
                    }
                    .padding(.horizontal, 12)

                    // ── Performance Comparison ────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel(text: "Performance comparison", icon: "bolt.fill")
                            .padding(.bottom, 8)

                        CompareRow(
                            label: "Horsepower",
                            stockValue: "\(optionA.specs.horsepower)",
                            modValue: "\(optionB.specs.horsepower)",
                            diff: diffString(optionB.specs.horsepower - optionA.specs.horsepower, unit: "hp"),
                            isPositive: optionB.specs.horsepower >= optionA.specs.horsepower
                        )
                        CompareRow(
                            label: "Torque",
                            stockValue: "\(optionA.specs.torque)",
                            modValue: "\(optionB.specs.torque)",
                            diff: diffString(optionB.specs.torque - optionA.specs.torque, unit: "Nm"),
                            isPositive: optionB.specs.torque >= optionA.specs.torque
                        )
                        CompareRow(
                            label: "0 – 100 km/h",
                            stockValue: "\(optionA.specs.zeroToHundred)s",
                            modValue: "\(optionB.specs.zeroToHundred)s",
                            diff: diffStringDouble(optionB.specs.zeroToHundred - optionA.specs.zeroToHundred, unit: "s"),
                            // Lower 0-100 time is the improvement, so flip the sign for colour
                            isPositive: optionB.specs.zeroToHundred <= optionA.specs.zeroToHundred
                        )
                        CompareRow(
                            label: "Top speed",
                            stockValue: "\(optionA.specs.topSpeed)",
                            modValue: "\(optionB.specs.topSpeed)",
                            diff: diffString(optionB.specs.topSpeed - optionA.specs.topSpeed, unit: "km/h"),
                            isPositive: optionB.specs.topSpeed >= optionA.specs.topSpeed
                        )
                        CompareRow(
                            label: "Range",
                            stockValue: rangeText(optionA.specs.range),
                            modValue: rangeText(optionB.specs.range),
                            diff: rangeDiff(optionA.specs.range, optionB.specs.range),
                            isPositive: rangeIsPositive(optionA.specs.range, optionB.specs.range),
                            showBorder: false
                        )
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Price Difference ──────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Price difference", icon: "banknote")

                        HStack {
                            VStack(spacing: 4) {
                                Text("\(optionA.name) price")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                Text("RM \(Int(optionA.specs.configPrice).formatted())")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }

                            Image(systemName: "arrow.right")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textDim)

                            VStack(spacing: 4) {
                                Text("\(optionB.name) price")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                Text("RM \(Int(optionB.specs.configPrice).formatted())")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                            }
                        }

                        let priceDelta = Int(optionB.specs.configPrice - optionA.specs.configPrice)
                        HStack {
                            Spacer()
                            Text(priceDeltaLabel(priceDelta))
                                .font(.system(size: 11))
                                .foregroundColor(priceDelta >= 0 ? AppColors.warningText : AppColors.successText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(priceDelta >= 0 ? AppColors.warningBg : AppColors.successBg)
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Keep defaults sane if a vehicle only has 1 option (edge case)
            selectedAIndex = min(selectedAIndex, options.count - 1)
            selectedBIndex = min(selectedBIndex, max(options.count - 1, 0))
        }
    }

    // ── Helpers ────────────────────────────────────────────────────────────
    private func diffString(_ delta: Int, unit: String) -> String {
        let sign = delta > 0 ? "+" : (delta < 0 ? "" : "+")
        return "\(sign)\(delta) \(unit)"
    }

    private func diffStringDouble(_ delta: Double, unit: String) -> String {
        let sign = delta > 0 ? "+" : ""
        return String(format: "%@%.1f %@", sign, delta, unit)
    }

    // "320 km" if present, "-" for variants without a range value
    // (e.g. petrol/range-extender powertrains).
    private func rangeText(_ range: Int?) -> String {
        guard let range = range else { return "-" }
        return "\(range) km"
    }

    private func rangeDiff(_ a: Int?, _ b: Int?) -> String {
        guard let a = a, let b = b else { return "-" }
        return diffString(b - a, unit: "km")
    }

    private func rangeIsPositive(_ a: Int?, _ b: Int?) -> Bool {
        guard let a = a, let b = b else { return true }
        return b >= a
    }

    private func priceDeltaLabel(_ delta: Int) -> String {
        if delta > 0 {
            return "+ RM \(delta.formatted()) more expensive"
        } else if delta < 0 {
            return "RM \(abs(delta).formatted()) cheaper"
        } else {
            return "Same price"
        }
    }
}

// ── Compare Row Component ─────────────────────────────────────────────────
struct CompareRow: View {
    let label: String
    let stockValue: String
    let modValue: String
    let diff: String
    let isPositive: Bool
    var showBorder: Bool = true

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                DifferenceBadge(text: diff, isPositive: isPositive)
            }

            HStack {
                Text(stockValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.cyan)
                Text(modValue)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .overlay(
            showBorder ?
            Rectangle()
                .fill(AppColors.cardBorder.opacity(0.5))
                .frame(height: 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            : nil
        )
    }
}
