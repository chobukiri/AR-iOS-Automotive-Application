//
//  ARViewContainer.swift
//  ARKit
//
//  Created by Gui Shi Jun on 16/04/2026.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    
    @Binding var selectedModelName: String?
    @Binding var isObjectSelected: Bool
    @Binding var isResizeMode: Bool
    @Binding var isMoveMode: Bool
    @Binding var deleteTrigger: Bool
    @Binding var customColor: Color?
    @Binding var selectedPartName: String
    
    @Binding var currentScalePercentage: Int
    @Binding var isScaling: Bool
    
    @Binding var isObjectPlaced: Bool
    @Binding var isSurfaceFound: Bool
    @Binding var isModelOffScreen: Bool
    @Binding var modelScreenDirection: Double
    @Binding var isLoadingModel: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        arView.environment.sceneUnderstanding.options.insert(.collision)
        
        // ARCoachingOverlayView automatically provides instructions and visual feedback
        // to help users find a suitable surface without removing existing functionality.
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        arView.addSubview(coachingOverlay)
        
        context.coordinator.setupPlacementGuide(in: arView)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleOneFingerPan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
        arView.addGestureRecognizer(panGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.parent = self
        
        if deleteTrigger {
            context.coordinator.deleteSelectedEntity()
            DispatchQueue.main.async {
                self.deleteTrigger = false
                self.isObjectSelected = false
                self.isResizeMode = false
                self.isMoveMode = false
            }
        }
        
        if let safeColor = customColor {
            context.coordinator.applyColor(UIColor(safeColor))
        } else {
            context.coordinator.applyColor(nil)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator {
        var parent: ARViewContainer
        var selectedEntity: ModelEntity?
        var placedAnchor: AnchorEntity?
        
        var initialScale: SIMD3<Float> = [0.01, 0.01, 0.01]
        let minScale: Float = 0.001
        let maxScale: Float = 0.10
        var initialRotation: simd_quatf?
        
        var originalMaterialsCache: [Entity: [RealityKit.Material]] = [:]
        var lastAppliedColor: UIColor? = nil
        
        var ghostAnchor: AnchorEntity?
        var currentGhostIdentifier: String?
        var isPlacementValid = false
        var updateSubscription: (any Cancellable)?
        var isFetching = false
        var loadTask: Task<Void, Never>?
        
        var isDraggingObject = false
        var originalModelCache: [String: ModelEntity] = [:]
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func getRootModelEntity(for entity: Entity) -> Entity? {
            var current: Entity? = entity
            while let p = current?.parent {
                if p is AnchorEntity {
                    return current
                }
                current = p
            }
            return current
        }
        
        func defaultScale(for name: String) -> Float {
            if name.lowercased().contains("xiaomi") {
                return 1.2
            }
            return 1.0
        }
        
        func minScale(for name: String) -> Float {
            if name.lowercased().contains("xiaomi") {
                return 0.12
            }
            return 0.1
        }
        
        func maxScale(for name: String) -> Float {
            if name.lowercased().contains("xiaomi") {
                return 12.0
            }
            return 10.0
        }
        
        func setupPlacementGuide(in arView: ARView) {
            ghostAnchor = AnchorEntity(world: matrix_identity_float4x4)
            arView.scene.addAnchor(ghostAnchor!)
            
            updateSubscription = arView.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                self?.updatePlacementGuide(in: arView)
                self?.updateOffScreenIndicator(in: arView)
            }
        }
        
        func makeTransparent(_ entity: Entity) {
            if var modelComponent = entity.components[ModelComponent.self] {
                var transMaterial = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.3))
                transMaterial.blending = .transparent(opacity: 0.5)
                modelComponent.materials = Array(repeating: transMaterial, count: modelComponent.materials.count)
                entity.components.set(modelComponent)
            }
            for child in entity.children {
                makeTransparent(child)
            }
        }
        
        func updatePlacementGuide(in arView: ARView) {
            guard let ghostAnchor = ghostAnchor else { return }
            
            let isPlacingNew = parent.selectedModelName != nil
            
            if !isPlacingNew {
                ghostAnchor.isEnabled = false
                isPlacementValid = false
                currentGhostIdentifier = nil
                return
            }
            
            let centerPoint = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            let results = arView.raycast(from: centerPoint, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                ghostAnchor.isEnabled = true
                isPlacementValid = true
                ghostAnchor.transform.matrix = firstResult.worldTransform
                
                // Notify SwiftUI that a surface has been found
                if !parent.isSurfaceFound {
                    DispatchQueue.main.async { self.parent.isSurfaceFound = true }
                }
                
                let desiredIdentifier = "new_\(parent.selectedModelName!)"
                
                if currentGhostIdentifier != desiredIdentifier && !isFetching {
                    let modelName = parent.selectedModelName!
                    guard !modelName.isEmpty else { return }
                    
                    isFetching = true
                    ghostAnchor.children.removeAll()
                    
                    // Notify SwiftUI to show loading screen
                    DispatchQueue.main.async { self.parent.isLoadingModel = true }
                    
                    self.loadTask?.cancel()
                    self.loadTask = Task { [weak self] in
                        do {
                            // Background load
                            let newModel = try await ModelEntity(named: modelName)
                            
                            await MainActor.run {
                                guard let self = self, !Task.isCancelled else { return }
                                
                                self.originalModelCache[modelName] = newModel.clone(recursive: true)
                                
                                newModel.name = modelName
                                let scaleVal = self.defaultScale(for: modelName)
                                newModel.scale = [scaleVal, scaleVal, scaleVal]
                                
                                // Shift children to center the model's pivot point horizontally
                                if modelName.lowercased().contains("xiaomi") || modelName.lowercased().contains("su7") {
                                    let bounds = newModel.visualBounds(relativeTo: newModel)
                                    let offset = SIMD3<Float>(-bounds.center.x, 0, -bounds.center.z)
                                    for child in newModel.children {
                                        child.position += offset
                                    }
                                }
                                
                                self.makeTransparent(newModel)
                                self.ghostAnchor?.addChild(newModel)
                                self.currentGhostIdentifier = desiredIdentifier
                                
                                self.isFetching = false
                                self.parent.isLoadingModel = false
                            }
                        } catch {
                            await MainActor.run {
                                guard let self = self else { return }
                                self.isFetching = false
                                self.parent.isLoadingModel = false
                                print("[ARView] ⚠️ Could not load model: \(modelName) - \(error)")
                            }
                        }
                    }
                }
            } else {
                ghostAnchor.isEnabled = false
                isPlacementValid = false
                // No plane in view — reset surface found state
                if parent.isSurfaceFound {
                    DispatchQueue.main.async { self.parent.isSurfaceFound = false }
                }
            }
        }
        
        func updateOffScreenIndicator(in arView: ARView) {
            // Only track when a model has been placed
            guard parent.isObjectPlaced, let anchor = placedAnchor else {
                if parent.isModelOffScreen {
                    DispatchQueue.main.async { self.parent.isModelOffScreen = false }
                }
                return
            }
            
            // Get true absolute world position, not just local translation
            let worldPos = anchor.position(relativeTo: nil)
            let screenCenter = CGPoint(x: arView.bounds.midX, y: arView.bounds.midY)
            // Use a negative or zero inset so the arrow only shows when it's genuinely off-screen
            let visibleRect = arView.bounds.insetBy(dx: -20, dy: -20)
            
            if let projected = arView.project(worldPos) {
                // Model is in front of the camera
                if visibleRect.contains(projected) {
                    // Model is on-screen
                    if parent.isModelOffScreen {
                        DispatchQueue.main.async { self.parent.isModelOffScreen = false }
                    }
                } else {
                    // Model is in front but outside the viewport
                    let dx = projected.x - screenCenter.x
                    let dy = projected.y - screenCenter.y
                    // atan2 gives angle from center; convert so 0° = up
                    let angle = atan2(dy, dx) * 180 / .pi + 90
                    DispatchQueue.main.async {
                        self.parent.modelScreenDirection = Double(angle)
                        self.parent.isModelOffScreen = true
                    }
                }
            } else {
                // project() returned nil — model is behind the camera
                guard let camera = arView.session.currentFrame?.camera else { return }
                
                // Transform the world position into the camera's local space
                let viewMatrix = camera.transform.inverse
                let posCam = simd_mul(viewMatrix, simd_float4(worldPos, 1.0))
                
                // In camera space:
                // X is right/left (positive is right)
                // Y is up/down (positive is up)
                let dx = posCam.x
                // Invert Y because screen Y is top-down, but camera Y is bottom-up
                let dy = -posCam.y
                
                let angle = atan2(dy, dx) * 180 / .pi + 90
                
                DispatchQueue.main.async {
                    self.parent.modelScreenDirection = Double(angle)
                    self.parent.isModelOffScreen = true
                }
            }
        }
        
        func deleteSelectedEntity() {
            if let entity = selectedEntity {
                originalMaterialsCache.removeValue(forKey: entity)
                var rootEntity: Entity = entity
                while let p = rootEntity.parent, !(p is AnchorEntity) { rootEntity = p }
                rootEntity.removeFromParent()
                
                if let anchor = placedAnchor {
                    anchor.removeFromParent()
                }
                
                DispatchQueue.main.async {
                    self.parent.isObjectPlaced = false
                    self.parent.isModelOffScreen = false
                }
            }
            selectedEntity = nil
            placedAnchor = nil
        }
        
        func cacheMaterialsRecursively(for entity: Entity) {
            if let modelComponent = entity.components[ModelComponent.self] {
                originalMaterialsCache[entity] = modelComponent.materials
            }
            for child in entity.children {
                cacheMaterialsRecursively(for: child)
            }
        }
        
        func applyColor(_ color: UIColor?) {
            guard let entity = selectedEntity else { return }
            if color != lastAppliedColor {
                lastAppliedColor = color
                applyColorRecursively(to: entity, color: color)
            }
        }

        private func applyColorRecursively(to entity: Entity, color: UIColor?) {
            if var modelComponent = entity.components[ModelComponent.self] {
                if let c = color {
                    let newMaterial = SimpleMaterial(color: c, isMetallic: false)
                    modelComponent.materials = Array(
                        repeating: newMaterial,
                count: modelComponent.materials.count
            )
        } else {
            if let original = originalMaterialsCache[entity] {
                modelComponent.materials = original
            }
        }
            entity.components.set(modelComponent)
            }
            for child in entity.children {
                applyColorRecursively(to: child, color: color)
            }
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else {return}
            let tapLocation = recognizer.location(in: arView)
            
            // --- 1. ARE WE IN MOVE MODE? ---
            if parent.isMoveMode {
                if let tappedEntity = arView.entity(at: tapLocation), let selected = selectedEntity {
                    var tappedRoot: Entity = tappedEntity
                    while let p = tappedRoot.parent, !(p is AnchorEntity) { tappedRoot = p }
                    
                    var selectedRoot: Entity = selected
                    while let p = selectedRoot.parent, !(p is AnchorEntity) { selectedRoot = p }
                    
                    if tappedRoot == selectedRoot { return }
                }
            }
            
            // --- 2. ARE WE SELECTING AN EXISTING PART? ---
            if let tappedEntity = arView.entity(at: tapLocation) as? ModelEntity, parent.selectedModelName == nil {
                selectedEntity = tappedEntity
                parent.selectedPartName = tappedEntity.name
                parent.isObjectSelected = true
                
                parent.isResizeMode = false
                parent.isMoveMode = false
                parent.customColor = nil
                return
            }
            
            // --- 3. ARE WE PLACING A NEW OBJECT? ---
            guard let modelName = parent.selectedModelName else {
                selectedEntity = nil
                parent.isObjectSelected = false
                parent.isResizeMode = false
                parent.isMoveMode = false
                return
            }
            
            guard isPlacementValid, let ghostAnchor = ghostAnchor else { return }
            
            let modelEntity: ModelEntity
            if let cachedModel = originalModelCache[modelName] {
                modelEntity = cachedModel.clone(recursive: true)
            } else {
                guard let fallback = try? ModelEntity.loadModel(named: modelName) else { return }
                originalModelCache[modelName] = fallback
                modelEntity = fallback.clone(recursive: true)
            }
            
            modelEntity.name = modelName
            let scaleVal = defaultScale(for: modelName)
            modelEntity.scale = [scaleVal, scaleVal, scaleVal]
            
            // Shift children to center the model's pivot point horizontally
            if modelName.lowercased().contains("xiaomi") || modelName.lowercased().contains("su7") {
                let bounds = modelEntity.visualBounds(relativeTo: modelEntity)
                let offset = SIMD3<Float>(-bounds.center.x, 0, -bounds.center.z)
                for child in modelEntity.children {
                    child.position += offset
                }
            }
            
            modelEntity.generateCollisionShapes(recursive: true)
            cacheMaterialsRecursively(for: modelEntity)
            
            let anchorEntity = AnchorEntity(world: ghostAnchor.transform.matrix)
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            // Store reference for off-screen tracking
            placedAnchor = anchorEntity
            
            // Tell SwiftUI the object has successfully been placed!
            parent.isObjectPlaced = true
            parent.isModelOffScreen = false
            
            selectedEntity = modelEntity
            parent.selectedPartName = "Whole \(modelName.capitalized)"
            parent.isObjectSelected = true
            parent.isResizeMode = false
            parent.isMoveMode = false
            parent.customColor = nil
            
            // Setting this to nil tells the placement scanner to turn off
            parent.selectedModelName = nil
        }
        
        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            guard parent.isResizeMode else { return }
            guard let entity = selectedEntity else { return }
            
            let root = getRootModelEntity(for: entity)
            let modelName = root?.name ?? ""
            let defScale = defaultScale(for: modelName)
            let mnScale = minScale(for: modelName)
            let mxScale = maxScale(for: modelName)
            
            switch recognizer.state {
            case .began:
                initialScale = entity.scale
                parent.isScaling = true
                parent.currentScalePercentage = Int(round((entity.scale.x / defScale) * 100))
                
            case .changed:
                let scale = Float(recognizer.scale)
                let newScale = initialScale * scale
                let clampedScale = SIMD3<Float>(
                    x : max(mnScale, min(mxScale, newScale.x)),
                    y : max(mnScale, min(mxScale, newScale.y)),
                    z : max(mnScale, min(mxScale, newScale.z))
                )
                entity.scale = clampedScale
                parent.currentScalePercentage = Int(round((clampedScale.x / defScale) * 100))
                
            case .ended, .cancelled, .failed:
                parent.isScaling = false
                
            default: break
            }
        }
        
        @objc func handleOneFingerPan(_ recognizer: UIPanGestureRecognizer) {
            guard let arView = recognizer.view as? ARView else { return }
            guard let entity = selectedEntity else { return }
            
            let location = recognizer.location(in: arView)
            
            if parent.isMoveMode {
                switch recognizer.state {
                case .began:
                    if let tappedEntity = arView.entity(at: location) {
                        var tappedRoot: Entity = tappedEntity
                        while let p = tappedRoot.parent, !(p is AnchorEntity) { tappedRoot = p }
                        
                        var selectedRoot: Entity = entity
                        while let p = selectedRoot.parent, !(p is AnchorEntity) { selectedRoot = p }
                        
                        if tappedRoot == selectedRoot {
                            isDraggingObject = true
                        }
                    }
                    
                case .changed:
                    guard isDraggingObject else { return }
                    
                    let results = arView.raycast(from: location, allowing: .existingPlaneInfinite, alignment: .horizontal)
                    guard let result = results.first else { return }
                    
                    var rootEntity: Entity = entity
                    while let p = rootEntity.parent {
                        rootEntity = p
                        if rootEntity is AnchorEntity { break }
                    }
                    
                    if let anchor = rootEntity as? AnchorEntity {
                        var newMatrix = anchor.transform.matrix
                        newMatrix.columns.3.x = result.worldTransform.columns.3.x
                        newMatrix.columns.3.z = result.worldTransform.columns.3.z
                        anchor.transform.matrix = newMatrix
                    }
                    
                case .ended, .cancelled:
                    isDraggingObject = false
                    
                default: break
                }
                
            } else if parent.isResizeMode {
                switch recognizer.state {
                case .began:
                    initialRotation = entity.transform.rotation
                case .changed:
                    guard let initialRotation = initialRotation else { return }
                    let translation = recognizer.translation(in: arView)
                    let rotationAngle = Float(translation.x) * 0.01
                    let rotationDelta = simd_quatf(angle: rotationAngle, axis: [0, 1, 0])
                    entity.transform.rotation = simd_mul(rotationDelta, initialRotation)
                case .ended, .cancelled:
                    initialRotation = nil
                default: break
                }
            }
        }
    }
}
