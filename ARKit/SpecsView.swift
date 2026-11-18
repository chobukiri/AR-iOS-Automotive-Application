import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 3 — SPECIFICATIONS PAGE
// ══════════════════════════════════════════════════════════════════════════

struct SpecsView: View {
    let vehicle: Vehicle
    @State private var showStock = true
    @State private var selectedVariantIndex: Int = 0   // used when vehicle.specVariants is non-empty
    @State private var expandedSpec: String? = nil
    @Environment(\.dismiss) var dismiss

    // True when this vehicle has multiple named variants (e.g. Voyah Free).
    // Falls back to the simple Stock/Modified toggle otherwise.
    var hasMultipleVariants: Bool {
        !vehicle.specVariants.isEmpty
    }

    var currentSpecs: VehicleSpecs {
        if hasMultipleVariants {
            let safeIndex = min(selectedVariantIndex, vehicle.specVariants.count - 1)
            return vehicle.specVariants[safeIndex].specs
        }
        return showStock ? vehicle.stockSpecs : vehicle.modifiedSpecs
    }

    // "320 km" if the vehicle has a range value, "-" for gasoline-only
    // vehicles or variants that rely on a petrol range-extender.
    var rangeValueText: String {
        if let range = currentSpecs.range {
            return "\(range) km"
        }
        return "-"
    }

    var turbochargerText: String {
        let e = currentSpecs.engine.lowercased()
        let pt = currentSpecs.powertrain.lowercased()
        if e.contains("turbo") {
            return "Yes"
        } else if e.contains("super") {
            return "Supercharged"
        } else if pt.contains("combustion") || pt.contains("hybrid") {
            return "NA" // Naturally Aspirated
        } else {
            return "None" // EV
        }
    }

    // Returns a short explanation tailored to the current drivetrain type.
    // Falls back to a general explanation covering all types if the value
    // is "-" (not set) or doesn't match a known abbreviation.
    func drivetrainExplanation(for type: String) -> String {
        switch type {
        case "FWD":
            return "Front-Wheel Drive — the engine/motor sends power only to the front two wheels. Common in everyday cars for efficiency and interior space."
        case "RWD":
            return "Rear-Wheel Drive — power goes only to the rear two wheels. Often preferred for better weight balance and sportier handling."
        case "AWD":
            return "All-Wheel Drive — power is sent to all four wheels at all times, usually via two motors (EV) or a transfer case (ICE). Improves traction and stability."
        case "4WD":
            return "Four-Wheel Drive — power can be sent to all four wheels, often selectable by the driver for off-road or low-traction conditions."
        default:
            return "Indicates which wheels receive power from the motor(s): FWD (front), RWD (rear), AWD (all four, always on), or 4WD (all four, often selectable)."
        }
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
                        Text("SPECIFICATIONS")
                            .font(AppFonts.screenTitle)
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Spacer()
                        NavigationLink(destination: GlossaryView()) {
                            HStack(spacing: 4) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 12))
                                Text("Glossary")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(AppColors.cardBg)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 4)

                    // ── Variant Selector ──────────────────────────────
                    // Shows a horizontal scroll of named variants (e.g.
                    // "RWD Electric", "AWD High-Power") when the vehicle
                    // has more than the simple Stock/Modified split.
                    // Otherwise falls back to the original 2-way toggle.
                    if hasMultipleVariants {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(vehicle.specVariants.enumerated()), id: \.element.id) { index, variant in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) { selectedVariantIndex = index }
                                    }) {
                                        Text(variant.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(selectedVariantIndex == index ? .white : .white.opacity(0.8))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedVariantIndex == index ? AppColors.accentBlue : AppColors.cardBg)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppRadius.button)
                                                    .stroke(AppColors.cardBorder, lineWidth: selectedVariantIndex == index ? 0 : 0.5)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                    } else {
                        HStack(spacing: 0) {
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showStock = true } }) {
                                Text("Stock")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(showStock ? .white : .white.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(showStock ? AppColors.accentBlue : AppColors.cardBg)
                            }
                            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showStock = false } }) {
                                Text("Modified")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(!showStock ? .white : .white.opacity(0.8))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(!showStock ? AppColors.accentBlue : AppColors.cardBg)
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.button)
                                .stroke(AppColors.cardBorder, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                        .padding(.horizontal, 12)
                    }

                    // ── Powertrain Section ────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel(text: "Powertrain", icon: "bolt.car.fill")
                            .padding(.bottom, 8)

                        SpecRow(label: "Type", value: currentSpecs.powertrain,
                                hint: "Indicates whether the vehicle is purely electric (BEV), hybrid (PHEV/MHEV), or internal combustion (ICE).",
                                isExpanded: expandedSpec == "powertrain",
                                onTap: { toggleSpec("powertrain") })
                        SpecRow(label: "Motor / Engine", value: currentSpecs.engine,
                                hint: "The physical configuration of the engine or electric motors.",
                                isExpanded: expandedSpec == "engine",
                                onTap: { toggleSpec("engine") })
                        SpecRow(label: "Turbocharger", value: turbochargerText,
                                hint: "Indicates whether the engine uses forced induction (Turbo/Supercharger), is Naturally Aspirated (NA), or if the vehicle is purely electric (None).",
                                isExpanded: expandedSpec == "turbo",
                                onTap: { toggleSpec("turbo") })

                        SpecRow(label: "Horsepower", value: "\(currentSpecs.horsepower) hp",
                                hint: vehicle.specExplanations["horsepower"] ?? "",
                                isExpanded: expandedSpec == "hp",
                                onTap: { toggleSpec("hp") })
                        SpecRow(label: "Torque", value: "\(currentSpecs.torque) Nm",
                                hint: vehicle.specExplanations["torque"] ?? "",
                                isExpanded: expandedSpec == "torque",
                                onTap: { toggleSpec("torque") })
                        SpecRow(label: "0 – 100 km/h", value: "\(currentSpecs.zeroToHundred) s",
                                hint: vehicle.specExplanations["zeroToHundred"] ?? "",
                                isExpanded: expandedSpec == "0100",
                                onTap: { toggleSpec("0100") })
                        SpecRow(label: "Top speed", value: "\(currentSpecs.topSpeed) km/h",
                                hint: vehicle.specExplanations["topSpeed"] ?? "",
                                isExpanded: expandedSpec == "top",
                                onTap: { toggleSpec("top") })
                        SpecRow(label: "Range", value: rangeValueText,
                                hint: "Estimated distance the vehicle can travel on a full charge (EV) or full tank (petrol/hybrid). Manufacturer figures — real-world range varies with driving conditions.",
                                isExpanded: expandedSpec == "range",
                                onTap: { toggleSpec("range") })
                        SpecRow(label: "Drivetrain", value: currentSpecs.drivetrain,
                                hint: drivetrainExplanation(for: currentSpecs.drivetrain),
                                isExpanded: expandedSpec == "drivetrain",
                                onTap: { toggleSpec("drivetrain") },
                                showBorder: false)
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Dimensions Section ────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        SectionLabel(text: "Dimensions", icon: "ruler")
                            .padding(.bottom, 8)

                        SpecRow(label: "Length", value: String(format: "%.0f cm", Double(currentSpecs.length) / 10),
                                hint: vehicle.specExplanations["length"] ?? "",
                                isExpanded: expandedSpec == "length",
                                onTap: { toggleSpec("length") })
                        SpecRow(label: "Width", value: String(format: "%.0f cm", Double(currentSpecs.width) / 10),
                                hint: vehicle.specExplanations["width"] ?? "",
                                isExpanded: expandedSpec == "width",
                                onTap: { toggleSpec("width") })
                        SpecRow(label: "Wheelbase", value: String(format: "%.0f cm", Double(currentSpecs.wheelbase) / 10),
                                hint: vehicle.specExplanations["wheelbase"] ?? "",
                                isExpanded: expandedSpec == "wb",
                                onTap: { toggleSpec("wb") },
                                showBorder: false)
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Price Card ────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CONFIGURATION PRICE")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                                .tracking(1)
                            Text("RM \(Int(currentSpecs.configPrice).formatted())")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    func toggleSpec(_ key: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedSpec = expandedSpec == key ? nil : key
        }
    }
}

// ── Spec Row Component ────────────────────────────────────────────────────
struct SpecRow: View {
    let label: String
    let value: String
    var hint: String = ""
    var isExpanded: Bool = false
    var onTap: (() -> Void)? = nil
    var showBorder: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    if !hint.isEmpty {
                        HStack(spacing: 2) {
                            Text(isExpanded ? "Tap to collapse" : hint.prefix(30) + "...")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            Image(systemName: "info.circle")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                Spacer()
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap?() }

            // Expanded explanation
            if isExpanded && !hint.isEmpty {
                    Text(hint)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                    .padding(.top, 6)
                    .transition(.opacity)
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
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}
