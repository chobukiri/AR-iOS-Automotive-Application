import SwiftUI

struct ColourPickerBar: View {
    let variants: [ColourVariant]
    @Binding var selectedVariant: ColourVariant

    var body: some View {
        // Only show if there are colour options
        if variants.count > 1 {
            VStack(spacing: 8) {
                // Colour name label
                Text(selectedVariant.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .animation(.easeInOut, value: selectedVariant.displayName)

                // Colour swatch row
                HStack(spacing: 12) {
                    ForEach(variants) { variant in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedVariant = variant
                            }
                        }) {
                            ZStack {
                                // Outer ring shows when selected
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                                    .opacity(selectedVariant.id == variant.id ? 1 : 0)

                                // Colour swatch
                                Circle()
                                    .fill(variant.swatch)
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
        }
    }
}