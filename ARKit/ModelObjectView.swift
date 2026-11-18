import SwiftUI
import RealityKit


// ══════════════════════════════════════════════════════════════════════════
// GARAGE VIEWER — Non-AR 3D viewer (RealityKit .nonAR camera mode)
// ══════════════════════════════════════════════════════════════════════════

struct ModelObjectView: UIViewRepresentable {

    let modelName: String
    let scale: Float
    let vehicle: Vehicle
    let selectedParts: [String: CarPart]
    @Binding var lightIntensity: Float
    @Binding var verticalOffset: Float
    @Binding var isLoadingModel: Bool
    let isFreeRotationEnabled: Bool
    let isZoomEnabled: Bool
    @Binding var currentZoom: Float
    @Binding var resetTrigger: UUID

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero,
                            cameraMode: .nonAR,
                            automaticallyConfigureSession: false)

        arView.environment.background = .color(UIColor(white: 0.07, alpha: 1))
        applyLighting(to: arView, lightIntensity: lightIntensity)
        loadCarBody(in: arView, context: context)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.delegate = context.coordinator
        arView.addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinch.delegate = context.coordinator
        arView.addGestureRecognizer(pinch)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // ── Colour / model swap ───────────────────────────────────────────
        if context.coordinator.currentModelName != modelName {
            uiView.scene.anchors.removeAll()
            context.coordinator.currentRotation = [0, Coordinator.initialYaw, 0]
            context.coordinator.attachedParts.removeAll()
            loadCarBody(in: uiView, context: context)
        }

        // ── Vertical offset ───────────────────────────────────────────────
        if let anchor = context.coordinator.modelAnchor {
            anchor.position.y = Coordinator.baseY + verticalOffset
        }

        // ── Weather / Lighting ────────────────────────────────────────────
        if context.coordinator.lastLightIntensity != lightIntensity {
            context.coordinator.lastLightIntensity = lightIntensity
            applyLighting(to: uiView, lightIntensity: lightIntensity)
        }

        // ── Part swap ─────────────────────────────────────────────────────
        if context.coordinator.lastSelectedParts != selectedParts {
            context.coordinator.lastSelectedParts = selectedParts
            updateParts(context: context)
        }
        
        // ── Free Rotation ─────────────────────────────────────────────────
        context.coordinator.isFreeRotationEnabled = isFreeRotationEnabled
        
        // ── Reset ─────────────────────────────────────────────────────────
        if context.coordinator.lastResetTrigger != resetTrigger {
            context.coordinator.lastResetTrigger = resetTrigger
            context.coordinator.currentRotation = [0, Coordinator.initialYaw, 0]
            if let carBody = context.coordinator.carBody {
                carBody.transform.rotation = Coordinator.buildRotation(angles: [0, Coordinator.initialYaw, 0])
            }
        }
        
        // ── Zoom ──────────────────────────────────────────────────────────
        context.coordinator.isZoomEnabled = isZoomEnabled
        if let carBody = context.coordinator.carBody {
            let s = scale * 2.2 * currentZoom
            carBody.scale = SIMD3<Float>(s, s, s)
        }
        
        context.coordinator.currentZoom = currentZoom
        context.coordinator.onZoomUpdate = { newZoom in
            DispatchQueue.main.async {
                self.currentZoom = newZoom
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    // ── Load car body ─────────────────────────────────────────────────────
    private func loadCarBody(in arView: ARView, context: Context) {
        let targetModelName = modelName
        guard !targetModelName.isEmpty else {
            print("[Garage] ⚠️ Model name is empty, skipping load")
            return
        }
        
        // Capture value-type copies for use in closures (structs can't use [weak self])
        let capturedScale = scale
        let capturedVerticalOffset = verticalOffset
        let capturedLightIntensity = lightIntensity
        let capturedZoom = currentZoom
        // Capture the binding directly so the Task can update SwiftUI
        let loadingBinding = $isLoadingModel
        let coordinator = context.coordinator
        
        coordinator.currentModelName = targetModelName
        
        DispatchQueue.main.async {
            coordinator.isLoading = true
            loadingBinding.wrappedValue = true
        }
        
        coordinator.loadTask?.cancel()
        coordinator.loadTask = Task {
            do {
                // Background load
                let car = try await ModelEntity(named: targetModelName)
                
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    
                    let bounds = car.visualBounds(relativeTo: car)
                    let pivot = SIMD3<Float>(-bounds.center.x, 0, -bounds.center.z)
                    for child in car.children { child.position += pivot }

                    let s = capturedScale * 2.2 * capturedZoom
                    car.scale = SIMD3<Float>(s, s, s)
                    car.name = "car_body"

                    let rotation = Coordinator.buildRotation(angles: [0, Coordinator.initialYaw, 0])
                    car.transform.rotation = rotation

                    if let oldAnchor = coordinator.modelAnchor {
                        arView.scene.removeAnchor(oldAnchor)
                    }

                    let anchor = AnchorEntity(world: SIMD3<Float>(
                        Coordinator.baseX,
                        Coordinator.baseY + capturedVerticalOffset,
                        Coordinator.baseZ
                    ))
                    anchor.addChild(car)
                    arView.scene.addAnchor(anchor)

                    coordinator.modelAnchor          = anchor
                    coordinator.carBody              = car
                    coordinator.lastLightIntensity   = capturedLightIntensity
                    coordinator.lastSelectedParts    = [:]
                    coordinator.currentRotation      = [0, Coordinator.initialYaw, 0]
                    
                    coordinator.isLoading = false
                    loadingBinding.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    coordinator.isLoading = false
                    loadingBinding.wrappedValue = false
                    print("[Garage] ⚠️ Could not load model: \(targetModelName) - \(error)")
                }
            }
        }
    }

    // ── Part swap — non-rim parts only ───────────────────────────────────
    // Rim swapping is handled at the model level (whole car USDZ swap via
    // effectiveModelName in ViewerModeView) so rims are skipped here.
    private func updateParts(context: Context) {
        guard let carBody = context.coordinator.carBody else { return }

        for (_, e) in context.coordinator.attachedParts { e.removeFromParent() }
        context.coordinator.attachedParts.removeAll()

        for (category, part) in selectedParts {
            guard category != "Rims" else { continue }   // rims handled by model swap
            guard !part.isDefault, !part.modelFile.isEmpty else { continue }
            guard let mp = vehicle.mountPoints[category] else {
                print("[Garage] ⚠️ No mount point for: \(category)")
                continue
            }
            
            let partModelFile = part.modelFile
            let partName = "part_\(category)"
            
            Task {
                guard let partEntity = try? await ModelEntity(named: partModelFile) else {
                    print("[Garage] ⚠️ No part USDZ: \(partModelFile)")
                    return
                }
                
                await MainActor.run {
                    partEntity.position           = mp.position
                    partEntity.transform.rotation = mp.rotation
                    partEntity.scale              = mp.scale
                    partEntity.name               = partName
                    
                    // Add it only if the carBody still exists
                    carBody.addChild(partEntity)
                    context.coordinator.attachedParts[category] = partEntity
                }
            }
        }
    }

    // ── Lighting ──────────────────────────────────────────────────────────
    private func applyLighting(to arView: ARView, lightIntensity: Float) {
        arView.environment.lighting.intensityExponent = lightIntensity
        
        // Map lightIntensity (0.2...2.0) to background white value (0.02...0.15)
        let minBg: Float = 0.02
        let maxBg: Float = 0.15
        let fraction = (lightIntensity - 0.2) / 1.8
        let bgWhite = minBg + fraction * (maxBg - minBg)
        
        arView.environment.background = .color(UIColor(white: CGFloat(bgWhite), alpha: 1))
    }

    // ══════════════════════════════════════════════════════════════════════
    // COORDINATOR
    // ══════════════════════════════════════════════════════════════════════
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var arView: ARView?

        var loadTask: Task<Void, Never>?
        var isLoading: Bool = false
        var modelAnchor: AnchorEntity?
        var carBody: ModelEntity?
        var currentModelName: String = ""
        var lastLightIntensity: Float = 1.0
        var lastSelectedParts: [String: CarPart] = [:]
        var attachedParts: [String: ModelEntity] = [:]

        var currentRotation: SIMD3<Float> = [0, Coordinator.initialYaw, 0]
        var isFreeRotationEnabled: Bool = false
        var isZoomEnabled: Bool = false
        var lastResetTrigger: UUID = UUID()
        var currentZoom: Float = 1.0
        var onZoomUpdate: ((Float) -> Void)?

        static let baseX: Float =  0.0
        static let baseY: Float = -0.25
        static let baseZ: Float =  0.0
        static let initialYaw: Float = .pi / 5 + .pi / 2 + .pi - .pi / 12

        static let standUpAngle: Float = -.pi / 2

        static func buildRotation(angles: SIMD3<Float>) -> simd_quatf {
            let standUp = simd_quatf(angle: standUpAngle, axis: [1, 0, 0])
            let spinX = simd_quatf(angle: angles.x, axis: [1, 0, 0])
            let spinY = simd_quatf(angle: angles.y, axis: [0, 1, 0])
            let spinZ = simd_quatf(angle: angles.z, axis: [0, 0, 1])
            // Apply standard order: Z then X then Y, all stacked on the initial standUp rotation
            return simd_mul(spinY, simd_mul(spinX, simd_mul(spinZ, standUp)))
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard isFreeRotationEnabled, let carBody = carBody else { return }
            let delta = recognizer.translation(in: recognizer.view)
            
            // Free rotation (Yaw and Pitch)
            currentRotation.y += Float(delta.x) * 0.005
            currentRotation.x -= Float(delta.y) * 0.005
            
            carBody.transform.rotation = Coordinator.buildRotation(angles: currentRotation)
            recognizer.setTranslation(.zero, in: recognizer.view)
        }
        
        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard isZoomEnabled else { return }
            let scaleFactor = Float(recognizer.scale)
            let newZoom = min(max(currentZoom * scaleFactor, 0.5), 3.0)
            
            if recognizer.state == .changed {
                currentZoom = newZoom
                onZoomUpdate?(newZoom)
                recognizer.scale = 1.0
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
