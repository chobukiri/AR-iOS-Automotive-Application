import SwiftUI
import RealityKit

struct ARWorkspaceView: View {
    var vehicle: Vehicle
    @Binding var selectedVariant: ColourVariant
    var effectiveModelName: String
    @Environment(\.dismiss) var dismiss

    @State private var selectedObjectName: String? = nil
    @State private var isObjectSelected = false
    @State private var isResizeMode = false
    @State private var isMoveMode = false
    @State private var deleteTrigger = false

    @State private var selectedPartName: String = ""
    @State private var customColor: Color? = nil

    @State private var currentScalePercentage: Int = 100
    @State private var isScaling: Bool = false
    @Binding var isObjectPlaced: Bool
    @Binding var isLoadingModel: Bool
    @State private var isSurfaceFound: Bool = false
    @State private var showDeleteWarning: Bool = false
    @State private var isModelOffScreen: Bool = false
    @State private var modelScreenDirection: Double = 0

    var body: some View {
        ZStack {
            ARViewContainer(
                selectedModelName: $selectedObjectName,
                isObjectSelected: $isObjectSelected,
                isResizeMode: $isResizeMode,
                isMoveMode: $isMoveMode,
                deleteTrigger: $deleteTrigger,
                customColor: $customColor,
                selectedPartName: $selectedPartName,
                currentScalePercentage: $currentScalePercentage,
                isScaling: $isScaling,
                isObjectPlaced: $isObjectPlaced,
                isSurfaceFound: $isSurfaceFound,
                isModelOffScreen: $isModelOffScreen,
                modelScreenDirection: $modelScreenDirection,
                isLoadingModel: $isLoadingModel
            )
            .edgesIgnoringSafeArea(.all)



            // Scale badge
            if isScaling {
                VStack {
                    Text("\(currentScalePercentage)%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.15), radius: 5)
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: isScaling)
            }

            // Surface Detection Banner — only shown before vehicle is placed
            if !isObjectPlaced {
                VStack {
                    Spacer()
                    Group {
                        if isSurfaceFound {
                            Text("Surface Found — Tap to Place")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.1, green: 0.55, blue: 0.95).opacity(0.9))
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.25), radius: 6)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            Text("Finding Surface…")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.25), radius: 6)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .modifier(PulseModifier())
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSurfaceFound)
                    .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isObjectPlaced)
            }

            // Off-screen vehicle indicator arrow
            if isObjectPlaced && isModelOffScreen {
                GeometryReader { geo in
                    let pos = arrowEdgePosition(
                        angle: modelScreenDirection,
                        size: geo.size
                    )
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color(red: 0.1, green: 0.55, blue: 0.95).opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.35), radius: 8)
                        .rotationEffect(Angle(degrees: modelScreenDirection))
                        .position(pos)
                        .animation(.easeInOut(duration: 0.12), value: modelScreenDirection)
                }
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Top Context Bar + Delete Warning
            if isObjectSelected {
                VStack(alignment: .center, spacing: 6) {
                    HStack(spacing: 12) {
                        // Left: Vehicle Name
                        VStack(alignment: .leading, spacing: 2) {
                            Text("SELECTED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.gray)
                                .tracking(1)
                            Text(vehicle.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Right: Adjust Button
                        Button(action: {
                            withAnimation { isResizeMode.toggle(); if isResizeMode { isMoveMode = false } }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Adjust")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(isResizeMode ? Color.blue : Color.white.opacity(0.15))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }

                        // Right: Delete Button
                        Button(action: {
                            withAnimation { deleteTrigger = true }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Delete")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Delete warning — shown under the top bar
                    if showDeleteWarning {
                        Text("Please delete model before making changes or switching to garage")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 7)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.88))
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.25), radius: 6)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onEnded { value in
                                        if value.translation.height < -20 {
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                showDeleteWarning = false
                                            }
                                        }
                                    }
                            )
                    }

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.3), value: showDeleteWarning)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            if !isObjectPlaced {
                selectedObjectName = effectiveModelName
            }
        }
        .onChange(of: isObjectPlaced) {
            if !isObjectPlaced {
                selectedObjectName = effectiveModelName
            }
        }
        .onChange(of: effectiveModelName) {
            if !isObjectPlaced {
                selectedObjectName = effectiveModelName
            }
        }
    }

    func formatPartName(_ name: String) -> String {
        if name.isEmpty { return "Unknown Part" }
        return name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Returns a point on the screen edge (inset) in the direction of `angle`.
    /// Angle convention: 0° = up, 90° = right, 180° = down, -90° = left.
    func arrowEdgePosition(angle: Double, size: CGSize) -> CGPoint {
        let inset: CGFloat = 50
        let centerX = size.width / 2
        let centerY = size.height / 2

        // Convert to standard math angle (0 = right, CCW positive)
        let radians = (angle - 90) * .pi / 180

        let cosA = CGFloat(cos(radians))
        let sinA = CGFloat(sin(radians))

        // Half-sizes of the inset rectangle
        let hw = centerX - inset
        let hh = centerY - inset

        // Find scale factor to reach the edge of the rectangle
        var scale: CGFloat = CGFloat.greatestFiniteMagnitude
        if abs(cosA) > 0.001 {
            scale = min(scale, hw / abs(cosA))
        }
        if abs(sinA) > 0.001 {
            scale = min(scale, hh / abs(sinA))
        }

        let x = centerX + cosA * scale
        let y = centerY + sinA * scale
        return CGPoint(x: x, y: y)
    }
}

// ── Pulse animation for "Finding Surface…" banner ─────────────────────────
private struct PulseModifier: ViewModifier {
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(pulsing ? 0.45 : 1.0)
            .animation(
                .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                value: pulsing
            )
            .onAppear { pulsing = true }
            .onDisappear { pulsing = false }
    }
}
