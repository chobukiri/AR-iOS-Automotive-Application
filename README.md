# 🚗 AR Vehicle Customization App (iOS)

A native iOS augmented reality showroom and vehicle customization application built with **SwiftUI**, **ARKit**, and **RealityKit**. Users can inspect scale-accurate 3D vehicles in their physical environment, swap exterior and interior color variants in real time, compare specifications side by side, and evaluate ownership budgets.

> **Usability Evaluation:** Tested with **25 participants**, achieving a **System Usability Scale (SUS) score of 85.2**.

---

## ✨ Core Features
* **Interactive AR Placement & 3D Inspection:** Place and inspect high-detail `.usdz` vehicles in real-world spaces (`ARViewContainer.swift`, `ARWorkspaceView.swift`, `ViewerModeView.swift`, `ModelObjectView.swift`).
* **Real-Time Colour & Trim Swapping:** Animated colour swatch selector allowing instant switching across exterior finishes and interior trims (`ColourPickerBar.swift`, `DefenderModels.swift`).
* **Side-by-Side Comparison & Specs:** Detailed specification breakdowns and multi-vehicle comparison tools (`SpecsView.swift`, `VehicleDetailView.swift`, `CompareView.swift`).
* **Budget & Automotive Glossary Tools:** Built-in budgeting calculator and interactive terminology guide to assist buyers (`BudgetView.swift`, `GlossaryView.swift`, `ZoomableScrollView.swift`).
* **Unified Design System:** Consistent typography, styling, and reusable SwiftUI components (`DesignSystem.swift`).

## 🚙 Included 3D Vehicle Lineup
All models were prepared in **Blender**, optimized as Apple-native **`.usdz`** assets, and versioned using **Git LFS**:
* **Defender** (`ARKit/Defender/`)
* **NIO ET7** (`ARKit/et7/`)
* **Xiaomi SU7** (`ARKit/su7/`)
* **Voyah Free** (`ARKit/voyah free/` — includes multi-variant exterior & interior trims)

## 🛠️ Tech Stack
* **Language & UI:** Swift, SwiftUI
* **AR & 3D Rendering:** ARKit, RealityKit
* **3D Asset Pipeline:** Blender → USDZ
* **Version Control:** Git & Git LFS (for `.usdz` assets)

## 📂 Project Structure
```text
├── AR App Test.xcodeproj/       # Xcode project configuration
└── ARKit/
    ├── Assets.xcassets/         # App icons and UI image assets
    ├── Defender/                # USDZ vehicle variants
    ├── et7/                     # USDZ vehicle variants
    ├── su7/                     # USDZ vehicle variants
    ├── voyah free/              # USDZ vehicle variants
    ├── ARKitApp.swift           # App entry point
    ├── ContentView.swift        # Main navigation container
    ├── ARViewContainer.swift    # UIViewRepresentable RealityKit/ARKit bridge
    ├── ARWorkspaceView.swift    # Primary AR customization workspace
    ├── ColourPickerBar.swift    # Animated colour swatch UI
    ├── CompareView.swift        # Multi-vehicle comparison view
    ├── BudgetView.swift         # Vehicle budgeting tool
    ├── SpecsView.swift          # Technical specifications view
    ├── VehicleData.swift        # Structured vehicle catalog & metadata
    └── DesignSystem.swift       # Shared UI styling tokens
    ```

## 🚀 Running Locally
Because this project uses **Git LFS** for its 3D `.usdz` models, install Git LFS before cloning:

1. Clone the repository and pull LFS assets:
   ```bash
   git lfs install
   git clone https://github.com/chobukiri/AR-iOS-Automotive-Application.git
   ```
2. Open `AR App Test.xcodeproj` in **Xcode** on macOS.
3. Connect a physical iOS device with ARKit support, select your development team under **Signing & Capabilities**, and press **Run (`Cmd + R`)**.

## 📸 Demo & Previews
*(Add 2–3 iOS screenshots, screen-recording GIFs, or Blender renders here to showcase the live AR placement and colour-swapping UI.)*