import SwiftUI

// ══════════════════════════════════════════════════════════════════════════
// SCREEN 6 — AR / GARAGE VIEWER with Customisation Panel
// ══════════════════════════════════════════════════════════════════════════

enum ViewMode {
    case ar
    case garage
}

struct ViewerModeView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentMode: ViewMode = .garage
    @State private var selectedVariant: ColourVariant
    @State private var selectedCategory: String = "Rims"
    @State private var selectedParts: [String: CarPart] = [:]  // key = category
    @State private var showInvoice = false
    @State private var selectedSpecIndex: Int = 0
    @State private var carVerticalOffset: Float = 0.0
    @State private var isObjectPlaced: Bool = false
    @State private var showDeleteWarning: Bool = false
    @State private var isPanelMinimized: Bool = false
    @State private var isLoadingModel: Bool = false
    @State private var lightIntensity: Float = 1.0
    @State private var loadingRotation: Double = 0
    @State private var carPulse: Bool = false
    @State private var showBrightnessSlider: Bool = false
    @State private var showHeightSlider: Bool = false
    @State private var heightDragStart: Float? = nil
    @State private var warningWorkItem: DispatchWorkItem? = nil
    
    @State private var isViewLocked: Bool = false
    var isFreeRotationEnabled: Bool { !isViewLocked }
    var isZoomEnabled: Bool { true }
    @State private var carZoom: Float = 1.0
    @State private var zoomDragStart: Float? = nil
    @State private var resetTrigger: UUID = UUID()
    @State private var showGuideline: Bool = false
    @State private var isToolsExpanded: Bool = false
    
    @State private var actionToastMessage: String? = nil
    @State private var actionToastWorkItem: DispatchWorkItem? = nil

    let vehicle: Vehicle
    let initialMode: ViewMode

    init(vehicle: Vehicle, initialVariant: ColourVariant? = nil, initialMode: ViewMode = .garage) {
        self.vehicle = vehicle
        self.initialMode = initialMode
        _currentMode = State(initialValue: initialMode)
        _selectedVariant = State(
            initialValue: initialVariant ??
            vehicle.colourVariants.first ??
            ColourVariant(id: "default", displayName: vehicle.name,
                          swatch: vehicle.thumbnailColor,
                          modelFile: vehicle.defaultModelFile)
        )
        // Initialise with default parts for each category
        var defaults: [String: CarPart] = [:]
        for category in categoriesFor(vehicle) {
            if let def = defaultPart(for: vehicle, category: category) {
                defaults[category] = def
            }
        }
        _selectedParts = State(initialValue: defaults)
    }

    var totalBuild: Double {
        let base: Double = {
            if !vehicle.specVariants.isEmpty {
                let p = vehicle.specVariants[selectedSpecIndex].specs.configPrice
                return p > 0 ? p : vehicle.basePrice
            }
            return vehicle.basePrice
        }()
        return base + selectedParts.values.reduce(0) { $0 + $1.price }
    }

    var selectedSpecName: String {
        guard !vehicle.specVariants.isEmpty else { return "" }
        return vehicle.specVariants[selectedSpecIndex].name
    }

    func showActionToast(_ message: String) {
        actionToastWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.3)) {
            actionToastMessage = message
        }
        let item = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.5)) {
                actionToastMessage = nil
            }
        }
        actionToastWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: item)
    }

    var effectiveModelName: String {
        if vehicle.id == "voyah_free" {
            var name = selectedVariant.modelFile
            if let interior = selectedParts["Interior"] {
                if interior.id == "interior_amber_brown" {
                    name += " (orange interior)"
                } else if interior.id == "interior_aurora_purple" {
                    name += " (purple interior)"
                }
            }
            return name
        } else if vehicle.id == "xiaomi_su7" {
            var components: [String] = []
            
            // 1. Rims
            if let rim = selectedParts["Rims"] {
                if rim.id == "rim_sport_a" { components.append("rim a") }
                else if rim.id == "rim_classic_b" { components.append("rim b") }
                else if rim.id == "rim_track_c" { components.append("rim c") }
                else { components.append("rim default") }
            } else {
                components.append("rim default")
            }
            
            // 2. Body Kits (Fenders)
            if let kit = selectedParts["Body Kits"], kit.id == "bodykit_aero" {
                components.append("fenders")
            }
            
            // 3. Spoilers
            if let spoiler = selectedParts["Spoilers"] {
                if spoiler.id == "spoiler_gt" { components.append("ducktail") }
                else if spoiler.id == "spoiler_wing_rs" { components.append("spoiler") }
            }
            
            let joined = components.joined(separator: "+")
            return "su7 \(selectedVariant.id) (\(joined))"
        }
        return selectedVariant.modelFile
    }

    var body: some View {
        ZStack(alignment: .top) {
            AppColors.background.edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // ── Top Navigation Bar ───────────────────────────────
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                    }
                    Spacer()
                    // AR / Garage Toggle
                    HStack(spacing: 0) {
                        Button(action: { currentMode = .ar }) {
                            Text("AR")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(currentMode == .ar ? .white : AppColors.textTertiary)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 14)
                                .background(currentMode == .ar ? AppColors.accentBlue : Color.clear)
                                .cornerRadius(8)
                        }
                        Button(action: {
                            if currentMode == .ar && isObjectPlaced {
                                warningWorkItem?.cancel()
                                withAnimation { showDeleteWarning = true }
                                let item = DispatchWorkItem {
                                    withAnimation(.easeInOut(duration: 0.5)) { showDeleteWarning = false }
                                }
                                warningWorkItem = item
                                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: item)
                                return
                            }
                            currentMode = .garage 
                        }) {
                            Text("Garage")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(currentMode == .garage ? .white : AppColors.textTertiary)
                                .padding(.vertical, 5)
                                .padding(.horizontal, 14)
                                .background(currentMode == .garage ? AppColors.accentBlue : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                    .padding(2)
                    .background(AppColors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.chip)
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .cornerRadius(AppRadius.chip)
                    Spacer()
                    // Info button and Brightness slider for Garage mode
                    if currentMode == .garage {
                        HStack(spacing: 8) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showGuideline = true
                                }
                                showActionToast("Guidelines opened")
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                                    .frame(width: 32, height: 32)
                                    .background(AppColors.cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.chip)
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                                    .cornerRadius(AppRadius.chip)
                            }
                            
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                        showBrightnessSlider.toggle()
                                    }
                                }) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(showBrightnessSlider ? AppColors.accentBlue : .white)
                                        .frame(width: 32, height: 32)
                                        .background(AppColors.cardBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppRadius.chip)
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                        .cornerRadius(AppRadius.chip)
                                }
                                
                                if showBrightnessSlider {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cloud.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(AppColors.textTertiary)
                                        Slider(value: $lightIntensity, in: 0.2...2.0)
                                            .frame(width: 110)
                                            .accentColor(AppColors.accentBlue)
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                            )
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                                    .offset(y: 40)
                                    .transition(.scale(scale: 0.8, anchor: .topTrailing).combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .zIndex(100)

                // ── Main 3D View Area ────────────────────────────────
                ZStack {
                    if currentMode == .ar {
                        ARWorkspaceView(
                            vehicle: vehicle,
                            selectedVariant: $selectedVariant,
                            effectiveModelName: effectiveModelName,
                            isObjectPlaced: $isObjectPlaced,
                            isLoadingModel: $isLoadingModel
                        )
                    } else {
                        ZStack {
                            ModelObjectView(
                                modelName: effectiveModelName,
                                scale: vehicle.scale,
                                vehicle: vehicle,
                                selectedParts: selectedParts,
                                lightIntensity: $lightIntensity,
                                verticalOffset: $carVerticalOffset,
                                isLoadingModel: $isLoadingModel,
                                isFreeRotationEnabled: isFreeRotationEnabled,
                                isZoomEnabled: isZoomEnabled,
                                currentZoom: $carZoom,
                                resetTrigger: $resetTrigger
                            )
                            .edgesIgnoringSafeArea(.all)

                            // Horizontal controls at the top right
                            VStack {
                                HStack(alignment: .top) {
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 8) {
                                        // Main button row
                                        HStack(alignment: .center, spacing: 6) {
                                            if !isToolsExpanded {
                                                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isToolsExpanded = true } }) {
                                                    Image(systemName: "ellipsis")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 40, height: 40)
                                                }
                                            } else {
                                                Button(action: { withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isToolsExpanded = false; showHeightSlider = false } }) {
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 40, height: 40)
                                                }
                                                
                                                // Reset Button
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.3)) {
                                                        carZoom = 1.0
                                                        carVerticalOffset = 0.0
                                                        isViewLocked = false
                                                        resetTrigger = UUID()
                                                        showHeightSlider = false
                                                    }
                                                    showActionToast("View reset")
                                                }) {
                                                    Image(systemName: "arrow.counterclockwise")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 40, height: 40)
                                                }

                                                // Lock View Toggle
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                        isViewLocked.toggle()
                                                    }
                                                    showActionToast(isViewLocked ? "View locked" : "View unlocked")
                                                }) {
                                                    Image(systemName: isViewLocked ? "lock.fill" : "lock.open.fill")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(isViewLocked ? AppColors.accentBlue : .white)
                                                        .frame(width: 40, height: 40)
                                                }

                                                // Height Toggle Button
                                                Button(action: {
                                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                        showHeightSlider.toggle()
                                                    }
                                                    showActionToast(showHeightSlider ? "Height controls opened" : "Height controls closed")
                                                }) {
                                                    Image(systemName: "arrow.up.and.down")
                                                        .font(.system(size: 16))
                                                        .foregroundColor(showHeightSlider ? AppColors.accentBlue : .white)
                                                        .frame(width: 40, height: 40)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(24)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 24)
                                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                        )
                                        
                                        if showHeightSlider {
                                            VStack(spacing: 12) {
                                                // Up arrow
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.1)) {
                                                        carVerticalOffset = min(carVerticalOffset + 0.05, 0.5)
                                                    }
                                                }) {
                                                    Image(systemName: "chevron.up")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 40, height: 40)
                                                }

                                                // Vertical slider track + thumb
                                                GeometryReader { geo in
                                                    ZStack(alignment: .top) {
                                                        Capsule()
                                                            .fill(Color.white.opacity(0.15))
                                                            .frame(width: 4)
                                                            .frame(maxWidth: .infinity)

                                                        let range: Float = 1.0
                                                        let normalised = CGFloat((carVerticalOffset + 0.5) / range)
                                                        let thumbHeight: CGFloat = 50
                                                        let thumbY = (1.0 - normalised) * (geo.size.height - thumbHeight)

                                                        Capsule()
                                                            .fill(.ultraThinMaterial)
                                                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                                                            .frame(width: 24, height: thumbHeight)
                                                            .frame(maxWidth: .infinity)
                                                            .contentShape(Rectangle())
                                                            .offset(y: max(0, min(thumbY, geo.size.height - thumbHeight)))
                                                            .gesture(
                                                                DragGesture(minimumDistance: 0)
                                                                    .onChanged { value in
                                                                        if heightDragStart == nil {
                                                                            heightDragStart = carVerticalOffset
                                                                        }
                                                                        let usableHeight = geo.size.height - thumbHeight
                                                                        let deltaPct = Float(value.translation.height / usableHeight)
                                                                        let newOffset = heightDragStart! - deltaPct * 1.0
                                                                        carVerticalOffset = max(-0.5, min(0.5, newOffset))
                                                                    }
                                                                    .onEnded { _ in
                                                                        heightDragStart = nil
                                                                    }
                                                            )
                                                    }
                                                }
                                                .frame(width: 40, height: 160)

                                                // Down arrow
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.1)) {
                                                        carVerticalOffset = max(carVerticalOffset - 0.05, -0.5)
                                                    }
                                                }) {
                                                    Image(systemName: "chevron.down")
                                                        .font(.system(size: 16, weight: .semibold))
                                                        .foregroundColor(.white)
                                                        .frame(width: 40, height: 40)
                                                }
                                            }
                                            .padding(.vertical, 14)
                                            .frame(width: 52)
                                            .background(
                                                RoundedRectangle(cornerRadius: 26)
                                                    .fill(.ultraThinMaterial)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 26)
                                                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                                    )
                                            )
                                            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)
                                            .transition(.scale(scale: 0.8, anchor: .top).combined(with: .opacity))
                                        }
                                    }
                                }
                                .padding(.trailing, 16)
                                .padding(.top, 40) // Raised slightly higher than the old 70 padding
                                
                                Spacer()
                            }
                        }
                        .edgesIgnoringSafeArea(.all)
                    }
                    
                    // Guideline Overlay
                    if showGuideline {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showGuideline = false
                                    }
                                }
                            
                            VStack(spacing: 20) {
                                Text("Virtual Garage Controls")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "cube.transparent")
                                            .frame(width: 24)
                                        Text("AR View: Place the vehicle in your real-world environment using Augmented Reality.")
                                    }
                                    HStack {
                                        Image(systemName: "car.fill")
                                            .frame(width: 24)
                                        Text("Garage: View and customize the vehicle in a stunning 3D virtual environment.")
                                    }
                                    HStack {
                                        Image(systemName: "rotate.3d")
                                            .frame(width: 24)
                                        Text("Rotate & Zoom: By default, you can freely drag to rotate and pinch to zoom the model.")
                                    }
                                    HStack {
                                        Image(systemName: "lock.open.fill")
                                            .frame(width: 24)
                                        Text("Lock/Unlock view: Locks rotation so you don't accidentally move the car (zoom still works).")
                                    }
                                    HStack {
                                        Image(systemName: "arrow.up.and.down")
                                            .frame(width: 24)
                                        Text("Adjust Height: Move the vehicle up/down.")
                                    }
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                            .frame(width: 24)
                                        Text("Reset all rotations and zoom.")
                                    }
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .frame(width: 24)
                                        Text("Brightness: Adjust the lighting intensity to see the car in different conditions.")
                                    }
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showGuideline = false
                                    }
                                }) {
                                    Text("Got it")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.accentBlue)
                                        .padding(.horizontal, 32)
                                        .padding(.vertical, 12)
                                        .background(AppColors.inputBg)
                                        .cornerRadius(20)
                                }
                                .padding(.top, 10)
                            }
                            .padding(24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(AppColors.cardBg)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24)
                                            .stroke(AppColors.cardBorder, lineWidth: 1)
                                    )
                            )
                            .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                            .padding(.horizontal, 40)
                        }
                        .zIndex(100)
                    }
                    
                    // Loading overlay
                    if isLoadingModel {
                        VStack(spacing: 16) {
                            ZStack {
                                // Outer spinning ring
                                Circle()
                                    .trim(from: 0.0, to: 0.7)
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [AppColors.accentBlue.opacity(0), AppColors.accentBlue]),
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 52, height: 52)
                                    .rotationEffect(.degrees(loadingRotation))
                                    .onAppear {
                                        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                            loadingRotation = 360
                                        }
                                    }
                                    .onDisappear { loadingRotation = 0 }

                                // Car icon in center
                                Image(systemName: "car.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .scaleEffect(carPulse ? 1.1 : 0.9)
                                    .onAppear {
                                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                                            carPulse = true
                                        }
                                    }
                                    .onDisappear { carPulse = false }
                            }

                            Text("Loading model...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.85))
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 20)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        .animation(.spring(response: 0.35), value: isLoadingModel)
                    }
                    
                    // Action Toast Notification
                    if let message = actionToastMessage {
                        VStack {
                            Text(message)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.8))
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                                .padding(.top, 60)
                            Spacer()
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(200)
                    }
                }
                .frame(maxHeight: .infinity)

                // ── Bottom Customisation Panel ───────────────────────
                VStack(spacing: 0) {
                    // ── Handle row with minimize arrow (fixed, never moves) ──────────────
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isPanelMinimized.toggle()
                        }
                    }) {
                        Image(systemName: isPanelMinimized ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                    }
                    .background(AppColors.background)

                    if !isPanelMinimized {
                        VStack(spacing: 6) {
                    // Colour row
                    HStack(spacing: 0) {
                        SectionLabel(text: "Colour")
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                ForEach(vehicle.colourVariants) { variant in
                                    Button(action: {
                                        if currentMode == .ar && isObjectPlaced {
                                            warningWorkItem?.cancel()
                                            withAnimation { showDeleteWarning = true }
                                            let item = DispatchWorkItem {
                                                withAnimation(.easeInOut(duration: 0.5)) { showDeleteWarning = false }
                                            }
                                            warningWorkItem = item
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: item)
                                            return
                                        }

                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedVariant = variant
                                            carZoom = 1.0
                                            carVerticalOffset = 0.0
                                            isViewLocked = false
                                            resetTrigger = UUID()
                                        }
                                    }) {
                                        RoundedRectangle(cornerRadius: AppRadius.small)
                                            .fill(variant.swatch)
                                            .frame(width: 26, height: 26)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppRadius.small)
                                                    .stroke(
                                                        selectedVariant.id == variant.id ? AppColors.accentBlue : Color.white.opacity(0.1),
                                                        lineWidth: selectedVariant.id == variant.id ? 2 : 1
                                                    )
                                            )
                                    }
                                }
                            }
                            Text(selectedVariant.displayName)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.leading, 4)
                        }
                        .padding(.horizontal, 12)
                    }

                    // ── Category chips ────────────────────────────────
                    HStack(spacing: 0) {
                        SectionLabel(text: "Customise")
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(categoriesFor(vehicle), id: \.self) { cat in
                                CategoryChip(
                                    title: cat,
                                    isSelected: selectedCategory == cat,
                                    action: { selectedCategory = cat }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                    }

                    // ── Parts for selected category ──────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(partsFor(vehicle, category: selectedCategory)) { part in
                                PartCard(
                                    part: part,
                                    isSelected: selectedParts[selectedCategory]?.id == part.id,
                                    action: {
                                        if currentMode == .ar && isObjectPlaced {
                                            warningWorkItem?.cancel()
                                            withAnimation { showDeleteWarning = true }
                                            let item = DispatchWorkItem {
                                                withAnimation(.easeInOut(duration: 0.5)) { showDeleteWarning = false }
                                            }
                                            warningWorkItem = item
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: item)
                                            return
                                        }

                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedParts[selectedCategory] = part
                                            carZoom = 1.0
                                            carVerticalOffset = 0.0
                                            isViewLocked = false
                                            resetTrigger = UUID()
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    }

                        }
                        .background(AppColors.background)
                    } // end if !isPanelMinimized

                    // ── Budget Bar always visible ─────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TOTAL BUILD")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.cyan)
                                .tracking(1)
                            HStack(spacing: 6) {
                                Text("RM \(Int(totalBuild).formatted())")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                if !selectedSpecName.isEmpty {
                                    Text(selectedSpecName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.cyan.opacity(0.12))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        Spacer()
                        Button(action: { showInvoice = true }) {
                            HStack(spacing: 3) {
                                Image(systemName: "receipt")
                                    .font(.system(size: 12))
                                Text("Invoice")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(AppColors.textBlue)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(AppColors.invoiceBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(AppColors.invoiceBorder, lineWidth: 0.5)
                            )
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .overlay(
                        Rectangle()
                            .fill(AppColors.cardBorder)
                            .frame(height: 0.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    )
                }
                .background(AppColors.background)
                .overlay(alignment: .top) {
                    // Warning pills float above the panel, no background box
                    VStack(spacing: 6) {
                        if showDeleteWarning {
                            Text("Please delete model before making changes or switching to garage")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.red.opacity(0.8))
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.2), radius: 4)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .onTapGesture {
                                    warningWorkItem?.cancel()
                                    withAnimation(.easeInOut(duration: 0.5)) { showDeleteWarning = false }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onEnded { value in
                                            if value.translation.height < -20 {
                                                warningWorkItem?.cancel()
                                                withAnimation(.easeInOut(duration: 0.5)) { showDeleteWarning = false }
                                            }
                                        }
                                )
                        }
                    }
                    .padding(.bottom, 4)
                    .frame(maxWidth: .infinity)
                    .offset(y: -(showDeleteWarning ? 44 : 0))
                    .animation(.easeInOut(duration: 0.3), value: showDeleteWarning)
                }
            }
        }
        .allowsHitTesting(!isLoadingModel)
        .disabled(isLoadingModel)
        .sheet(isPresented: $showInvoice) {
            BudgetView(
                vehicle: vehicle,
                selectedVariantName: selectedVariant.displayName,
                selectedVariantSwatch: selectedVariant.swatch,
                selectedParts: $selectedParts,
                selectedSpecIndex: $selectedSpecIndex
            )
            .preferredColorScheme(.dark)
        }
        .onChange(of: isObjectPlaced) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                if isObjectPlaced {
                    isPanelMinimized = true
                } else {
                    isPanelMinimized = false
                }
            }
        }
        .onAppear {
            currentMode = initialMode
        }
    }
}

// ── Part Card (for horizontal scroll in customise panel) ──────────────────
struct PartCard: View {
    let part: CarPart
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.swatch)
                        .fill(AppColors.inputBg)
                        .frame(width: 40, height: 40)

                    if part.isDefault {
                        Image(systemName: part.category == "Rims" ? "circle.dashed" : "xmark")
                            .font(.system(size: part.isDefault && part.category != "Rims" ? 14 : 16))
                            .foregroundColor(isSelected ? AppColors.textBlue : AppColors.textDim)
                    } else {
                        Image(systemName: iconFor(part.category))
                            .font(.system(size: 16))
                            .foregroundColor(isSelected ? AppColors.textBlue : AppColors.textDim)
                    }
                }

                Text(part.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                if part.isDefault {
                    Text("Default")
                        .font(.system(size: 9))
                        .foregroundColor(AppColors.successText)
                } else {
                    Text("RM \(Int(part.price).formatted())")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isSelected ? AppColors.accentBlue : .white)
                }
            }
            .frame(width: 90)
            .padding(.vertical, 8)
            .background(AppColors.cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.chip)
                    .stroke(isSelected ? AppColors.accentBlue : AppColors.cardBorder,
                            lineWidth: isSelected ? 2 : 0.5)
            )
            .cornerRadius(AppRadius.chip)
        }
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
