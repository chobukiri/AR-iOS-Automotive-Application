import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 2 — VEHICLE DETAIL PAGE
// ══════════════════════════════════════════════════════════════════════════

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @State private var currentVehicle: Vehicle
    @State private var selectedVariant: ColourVariant
    @State private var showViewer = false
    @State private var viewerInitialMode: ViewMode = .garage
    @State private var showMissingModelToast: Bool = false
    @State private var toastWorkItem: DispatchWorkItem? = nil
    @State private var fullscreenIndex: Int? = nil
    @State private var currentCarouselIndex: Int = 0
    @State private var budgetSpecIndex: Int = 0
    @Environment(\.dismiss) var dismiss

    var carouselImages: [UIImage] {
        let baseImageName = "\(currentVehicle.id)_\(selectedVariant.id)"
        let sideImage    = UIImage(named: "\(baseImageName)_side")
        let diagImage    = UIImage(named: "\(baseImageName)_diagonal")
        let fallbackImage = UIImage(named: baseImageName) ?? UIImage(named: currentVehicle.id)

        var imgs: [UIImage] = []
        if let s = sideImage    { imgs.append(s) }
        if let d = diagImage    { imgs.append(d) }
        if imgs.isEmpty, let f = fallbackImage { imgs.append(f) }
        return imgs
    }

    init(vehicle: Vehicle) {
        self.vehicle = vehicle
        let initialVehicle = vehicle.subModels.first ?? vehicle
        _currentVehicle = State(initialValue: initialVehicle)
        _selectedVariant = State(
            initialValue: initialVehicle.colourVariants.first ??
            ColourVariant(id: "default", displayName: initialVehicle.name,
                          swatch: initialVehicle.thumbnailColor,
                          modelFile: initialVehicle.defaultModelFile)
        )
    }

    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 0) {
                    // ── Top Navigation Bar ───────────────────────────
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                        }
                        Spacer()
                        Text(currentVehicle.name.uppercased())
                            .font(AppFonts.screenTitle)
                            .foregroundColor(.white)
                            .tracking(0.5)
                        Spacer()
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.clear)
                            .padding(12)
                    }
                    .padding(.horizontal, 4)

                    // ── Hero Car Image Carousel ───────────────────────


                    GeometryReader { geo in
                        let frameWidth = geo.size.width
                        let frameHeight = frameWidth * (9.0 / 16.0) // 16:9 landscape ratio

                        if carouselImages.isEmpty {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                                    )
                                VStack(spacing: 10) {
                                    Image(systemName: "car.side.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(selectedVariant.swatch.opacity(0.4))
                                    Text("No image available")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                            .frame(width: frameWidth, height: frameHeight)
                        } else {
                            TabView(selection: $currentCarouselIndex) {
                                ForEach(Array(carouselImages.enumerated()), id: \.offset) { offset, img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: frameWidth, height: frameHeight)
                                        .clipped()
                                        .tag(offset)
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                fullscreenIndex = offset
                                            }
                                        }
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: carouselImages.count > 1 ? .always : .never))
                            .frame(width: frameWidth, height: frameHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                            )
                            .overlay(alignment: .bottomTrailing) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        fullscreenIndex = currentCarouselIndex
                                    }
                                }) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.8))
                                        .padding(8)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(10)
                            }
                        }
                    }
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .padding(.horizontal, 12)
                    .animation(.easeInOut(duration: 0.3), value: selectedVariant.id)

                    // ── Main Info Card ────────────────────────────────
                    VStack(spacing: 0) {
                        // Title + Price
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(currentVehicle.name)
                                    .font(AppFonts.cardTitle)
                                    .foregroundColor(.white)
                                    .tracking(-0.5)
                            }
                        }

                        Divider()
                            .background(AppColors.cardBorder)
                            .padding(.vertical, 10)

                        // ── Sub-Model Picker ────────────────────────────
                        if !vehicle.subModels.isEmpty {
                            SectionLabel(text: "CHOOSE YOUR MODEL")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 8)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(vehicle.subModels) { subModel in
                                        Button(action: {
                                            currentVehicle = subModel
                                        }) {
                                            Text(subModel.name)
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(currentVehicle.id == subModel.id ? .black : AppColors.textSecondary)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 8)
                                                .background(currentVehicle.id == subModel.id ? Color.white : AppColors.inputBg)
                                                .cornerRadius(AppRadius.button)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppRadius.button)
                                                        .stroke(currentVehicle.id == subModel.id ? Color.white : AppColors.cardBorder, lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 14)
                        }

                        // ── Colour Picker ────────────────────────────
                        if currentVehicle.colourVariants.count > 1 {
                            SectionLabel(text: "Colour")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 8)

                            HStack(spacing: 8) {
                                ForEach(currentVehicle.colourVariants) { variant in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedVariant = variant
                                        }
                                    }) {
                                        VStack(spacing: 3) {
                                            RoundedRectangle(cornerRadius: AppRadius.swatch)
                                                .fill(variant.swatch)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppRadius.swatch)
                                                        .stroke(
                                                            selectedVariant.id == variant.id ? AppColors.accentBlue : Color.white.opacity(0.1),
                                                            lineWidth: selectedVariant.id == variant.id ? 2 : 1
                                                        )
                                                )
                                            Text(variant.displayName.components(separatedBy: " ").last ?? "")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                Spacer()
                                Text(selectedVariant.displayName)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding(.bottom, 14)
                        }

                        // ── Action Buttons ───────────────────────────
                        HStack(spacing: 8) {
                            PrimaryButton(title: "AR View", icon: "arkit") {
                                if currentVehicle.id.hasPrefix("defender") {
                                    showToast()
                                } else {
                                    viewerInitialMode = .ar
                                    showViewer = true
                                }
                            }
                            SecondaryButton(title: "Garage", icon: "cube") {
                                if currentVehicle.id.hasPrefix("defender") {
                                    showToast()
                                } else {
                                    viewerInitialMode = .garage
                                    showViewer = true
                                }
                            }
                        }
                    }
                    .padding(14)
                    .cardStyle()
                    .padding(.horizontal, 12)

                    // ── Navigation Buttons Row ───────────────────────
                    HStack(spacing: 8) {
                        NavigationLink(destination: SpecsView(vehicle: currentVehicle)) {
                            HStack(spacing: 3) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Variant Specs")
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.button).stroke(Color.white, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                        }

                        NavigationLink(destination: CompareView(vehicle: currentVehicle)) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Compare")
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.button).stroke(Color.white, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                        }

                        NavigationLink(destination: BudgetView(
                            vehicle: currentVehicle,
                            selectedVariantName: selectedVariant.displayName,
                            selectedVariantSwatch: selectedVariant.swatch,
                            selectedParts: .constant([:]),
                            selectedSpecIndex: $budgetSpecIndex
                        )) {
                            HStack(spacing: 3) {
                                Image(systemName: "receipt")
                                    .font(.system(size: 15, weight: .semibold))
                                Text("Pricing")
                                    .font(.system(size: 11, weight: .bold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .foregroundColor(.white)
                            .frame(minWidth: 0, maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.button).stroke(Color.white, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                    // ── Vehicle Highlights ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        SectionLabel(text: "Highlights")
                            .padding(.horizontal, 12)
                        
                        let powertrains = ( [currentVehicle.stockSpecs] + currentVehicle.specVariants.map { $0.specs } )
                            .compactMap { $0.powertrain.components(separatedBy: " ").last?.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "") }
                        let uniquePowertrains = Array(Set(powertrains)).sorted().joined(separator: " / ")
                        
                        HStack(spacing: 6) {
                            StatCard(value: currentVehicle.stockSpecs.drivetrain, unit: "", label: "DRIVETRAIN")
                            StatCard(value: uniquePowertrains.isEmpty ? "N/A" : uniquePowertrains, unit: "", label: "POWERTRAIN")
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.top, 20)

                    Spacer().frame(height: 40)
                }
            }
            if showMissingModelToast {
                VStack {
                    Text("Model doesn't exist")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 60)
                    Spacer()
                }
                .zIndex(100)
            }

            // ── Fullscreen Image Lightbox ─────────────────────────
            if fullscreenIndex != nil {
                ZStack {
                    Color.black.opacity(0.92)
                        .edgesIgnoringSafeArea(.all)

                    TabView(selection: Binding(
                        get: { fullscreenIndex ?? 0 },
                        set: { fullscreenIndex = $0 }
                    )) {
                        ForEach(Array(carouselImages.enumerated()), id: \.offset) { offset, img in
                            ZoomableScrollView {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                            }
                            .edgesIgnoringSafeArea(.all)
                            .tag(offset)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: carouselImages.count > 1 ? .always : .never))
                    .edgesIgnoringSafeArea(.all)

                    // Close button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    fullscreenIndex = nil
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 60)
                        }
                        Spacer()
                    }
                }
                .zIndex(999)
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showViewer) {
            ViewerModeView(vehicle: vehicle, initialVariant: selectedVariant, initialMode: viewerInitialMode)
        }
    }

    private func showToast() {
        toastWorkItem?.cancel()
        withAnimation(.spring()) { showMissingModelToast = true }
        
        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut) { showMissingModelToast = false }
        }
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }
}
