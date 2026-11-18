import SwiftUI
import RealityKit

// ══════════════════════════════════════════════════════════════════════════
// VEHICLE DATA MODEL — AR Garage App
// ══════════════════════════════════════════════════════════════════════════

struct ColourVariant: Identifiable, Hashable {
    let id: String
    let displayName: String
    let swatch: Color
    let modelFile: String

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: ColourVariant, rhs: ColourVariant) -> Bool { lhs.id == rhs.id }
}

struct MountPoint {
    let position: SIMD3<Float>
    let rotation: simd_quatf
    let scale: SIMD3<Float>

    static let zero = MountPoint(
        position: SIMD3<Float>(0, 0, 0),
        rotation: simd_quatf(angle: 0, axis: [0,1,0]),
        scale: SIMD3<Float>(1, 1, 1)
    )
}

struct CarPart: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let price: Double
    let modelFile: String
    let description: String
    let affectsPerformance: Bool
    let isDefault: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: CarPart, rhs: CarPart) -> Bool { lhs.id == rhs.id }
}

struct VehicleSpecs {
    let horsepower: Int
    let torque: Int
    let zeroToHundred: Double
    let topSpeed: Int
    let length: Int
    let width: Int
    let wheelbase: Int
    let configPrice: Double
    var range: Int? = nil
    var drivetrain: String = "-"
    var engine: String = "-"
    var powertrain: String = "-"
}

// ── NAMED SPEC VARIANT ─────────────────────────────────────────────────────
// For vehicles with more than 2 powertrain options (e.g. RWD, AWD, AWD
// High-Power). SpecsView shows these as a horizontal selector instead of
// the Stock/Modified toggle when a vehicle has any entries here.
struct SpecVariant: Identifiable {
    let id: String
    let name: String
    let specs: VehicleSpecs
}

struct GlossaryTerm: Identifiable {
    let id: String
    let term: String
    let definition: String
    let category: String
}

struct Vehicle: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let thumbnailColor: Color
    let scale: Float
    let basePrice: Double
    let colourVariants: [ColourVariant]
    let supportsWindowAnim: Bool
    let availablePartIDs: [String]
    let mountPoints: [String: MountPoint]
    let rimModelFiles: [String: String]
    let stockSpecs: VehicleSpecs
    let modifiedSpecs: VehicleSpecs
    let specExplanations: [String: String]

    // Optional list of named spec variants (e.g. "RWD Electric", "AWD
    // High-Power"). Leave as [] for vehicles using only Stock/Modified.
    let specVariants: [SpecVariant]
    
    // Optional list of sub-models for this vehicle (e.g. Defender 90, 110, 130).
    var subModels: [Vehicle] = []

    var defaultModelFile: String {
        colourVariants.first?.modelFile ?? id
    }

    var powertrainBadges: [String] {
        var badges: Set<String> = []
        
        let allVariants: [SpecVariant]
        if !subModels.isEmpty {
            allVariants = subModels.flatMap { $0.specVariants }
        } else if !specVariants.isEmpty {
            allVariants = specVariants
        } else {
            allVariants = [SpecVariant(id: "dummy", name: "dummy", specs: stockSpecs)]
        }
        
        for variant in allVariants {
            let p = variant.specs.powertrain.lowercased()
            let e = variant.specs.engine.lowercased()
            
            if p.contains("electric (bev)") || p == "electric" || p.contains("bev") {
                badges.insert("Electric")
            }
            if p.contains("hybrid") || p.contains("phev") || p.contains("mhev") {
                badges.insert("Hybrid")
            }
            if p.contains("ice") || p.contains("internal combustion") {
                if e.contains("diesel") {
                    badges.insert("Diesel")
                } else {
                    badges.insert("Petrol") // Assume petrol if ICE and not diesel
                }
            }
        }
        
        // Sort to ensure consistent order
        return Array(badges).sorted {
            let order = ["Electric": 0, "Hybrid": 1, "Petrol": 2, "Diesel": 3]
            return (order[$0] ?? 4) < (order[$1] ?? 4)
        }
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Vehicle, rhs: Vehicle) -> Bool { lhs.id == rhs.id }
}

// ══════════════════════════════════════════════════════════════════════════
// MASTER PARTS CATALOGUE
// ══════════════════════════════════════════════════════════════════════════
let masterPartsCatalogue: [CarPart] = [
    // ── RIMS ──────────────────────────────────────────────────────────────
    CarPart(id: "rim_stock", name: "Stock", category: "Rims",
            price: 0, modelFile: "",
            description: "Factory-fitted rims that came with the vehicle.",
            affectsPerformance: false, isDefault: true),
    CarPart(id: "rim_sport_a", name: "Sport Rim A", category: "Rims",
            price: 1200, modelFile: "rim_sport_a",
            description: "Lightweight alloy rims for better handling and a sporty look.",
            affectsPerformance: true, isDefault: false),
    CarPart(id: "rim_classic_b", name: "Classic Rim B", category: "Rims",
            price: 800, modelFile: "rim_classic_b",
            description: "Classic 5-spoke design for a clean factory-style appearance.",
            affectsPerformance: false, isDefault: false),
    CarPart(id: "rim_track_c", name: "Track Rim C", category: "Rims",
            price: 1800, modelFile: "rim_track_c",
            description: "Ultra-lightweight forged rims designed for track performance.",
            affectsPerformance: true, isDefault: false),

    // ── SPOILERS ──────────────────────────────────────────────────────────
    CarPart(id: "spoiler_none", name: "None", category: "Spoilers",
            price: 0, modelFile: "",
            description: "No spoiler installed.",
            affectsPerformance: false, isDefault: true),
    CarPart(id: "spoiler_gt", name: "Ducktail", category: "Spoilers",
            price: 950, modelFile: "spoiler_gt",
            description: "Improves rear downforce at speed.",
            affectsPerformance: true, isDefault: false),
    CarPart(id: "spoiler_wing_rs", name: "Spoiler RS", category: "Spoilers",
            price: 1400, modelFile: "spoiler_wing_rs",
            description: "Large rear wing for maximum downforce on track.",
            affectsPerformance: true, isDefault: false),

    // ── BODY KITS ─────────────────────────────────────────────────────────
    CarPart(id: "bodykit_none", name: "None", category: "Body Kits",
            price: 0, modelFile: "",
            description: "No body kit installed.",
            affectsPerformance: false, isDefault: true),
    CarPart(id: "bodykit_aero", name: "Fenders", category: "Body Kits",
            price: 3500, modelFile: "bodykit_aero",
            description: "Full aero kit with front splitter and side skirts.",
            affectsPerformance: true, isDefault: false),

    // ── WRAPS ─────────────────────────────────────────────────────────────
    CarPart(id: "wrap_none", name: "None", category: "Wraps",
            price: 0, modelFile: "",
            description: "Original paint finish.",
            affectsPerformance: false, isDefault: true),

    // ── INTERIOR ──────────────────────────────────────────────────────────
    // Interior trim/colour themes. No USDZ files wired up yet — modelFile
    // is left empty as a placeholder. Fill these in once interior models
    // are ready (no other file needs to change when you do).
    CarPart(id: "interior_deep_sea_blue", name: "Deep Sea Blue", category: "Interior",
            price: 0, modelFile: "deep sea blue",
            description: "High-tech interior theme — charcoal leather with steel blue accents and light ash upper trim.",
            affectsPerformance: false, isDefault: true),
    CarPart(id: "interior_amber_brown", name: "Amber Brown", category: "Interior",
            price: 0, modelFile: "amber brown",
            description: "Classic, warm luxury interior — saddle/amber brown leather with dark grey trim.",
            affectsPerformance: false, isDefault: false),
    CarPart(id: "interior_aurora_purple", name: "Aurora Purple", category: "Interior",
            price: 0, modelFile: "aurora purple",
            description: "A bold, striking interior option with a distinctive purple-accented cabin.",
            affectsPerformance: false, isDefault: false),
]

// ══════════════════════════════════════════════════════════════════════════
// VEHICLE CATALOGUE
// ══════════════════════════════════════════════════════════════════════════
let vehicleCatalogue: [Vehicle] = [

    // ── Xiaomi SU7 ────────────────────────────────────────────────────────
    Vehicle(
        id: "xiaomi_su7",
        name: "Xiaomi SU7",
        brand: "Xiaomi",
        category: "EV",
        thumbnailColor: .gray,
        scale: 0.8,
        basePrice: 299900,
        colourVariants: [
            ColourVariant(id: "black", displayName: "Midnight Black",
                          swatch: Color(red: 0.1, green: 0.1, blue: 0.1),
                          modelFile: "su7 black (rim default)"),
            ColourVariant(id: "blue", displayName: "Ocean Blue",
                          swatch: .blue,
                          modelFile: "su7 blue (rim default)"),
            ColourVariant(id: "purple", displayName: "Cosmic Purple",
                          swatch: .purple,
                          modelFile: "su7 purple (rim default)"),
            ColourVariant(id: "red", displayName: "Racing Red",
                          swatch: .red,
                          modelFile: "su7 red (rim default)"),
        ],
        supportsWindowAnim: false,
        availablePartIDs: [
            "rim_stock", "rim_sport_a", "rim_classic_b", "rim_track_c",
            "spoiler_none", "spoiler_gt", "spoiler_wing_rs",
            "bodykit_none", "bodykit_aero",
            "wrap_none",
        ],
        mountPoints: [
            "Spoilers": MountPoint(
                position: SIMD3<Float>(0, 0.85, -1.2),
                rotation: simd_quatf(angle: 0, axis: [0,1,0]),
                scale: SIMD3<Float>(1, 1, 1)
            ),
            "Body Kits": MountPoint(
                position: SIMD3<Float>(0, 0.15, 0),
                rotation: simd_quatf(angle: 0, axis: [0,1,0]),
                scale: SIMD3<Float>(1, 1, 1)
            ),
        ],
        rimModelFiles: [
            "black_rim_sport_a":    "su7 black (rim a)",
            "black_rim_classic_b":  "su7 black (rim b)",
            "black_rim_track_c":    "su7 black (rim c)",
            "blue_rim_sport_a":     "su7 blue (rim a)",
            "blue_rim_classic_b":   "su7 blue (rim b)",
            "blue_rim_track_c":     "su7 blue (rim c)",
            "purple_rim_sport_a":   "su7 purple (rim a)",
            "purple_rim_classic_b": "su7 purple (rim b)",
            "purple_rim_track_c":   "su7 purple (rim c)",
            "red_rim_sport_a":      "su7 red (rim a)",
            "red_rim_classic_b":    "su7 red (rim b)",
            "red_rim_track_c":      "su7 red (rim c)",
        ],
        stockSpecs: VehicleSpecs(
            horsepower: 315, torque: 505,
            zeroToHundred: 5.28, topSpeed: 240,
            length: 4997, width: 1963, wheelbase: 3000,
            configPrice: 215900,
            range: 720,
            drivetrain: "RWD",
            engine: "Single Motor",
            powertrain: "Electric (BEV)"
        ),
        modifiedSpecs: VehicleSpecs(
            horsepower: 315, torque: 505,
            zeroToHundred: 5.28, topSpeed: 240,
            length: 4997, width: 1963, wheelbase: 3000,
            configPrice: 215900,
            range: 720,
            drivetrain: "RWD",
            engine: "Single Motor",
            powertrain: "Electric (BEV)"
        ),
        specExplanations: [
            "horsepower": "Horsepower measures the engine's output power. Higher means faster acceleration.",
            "torque": "Torque is the pulling force from the engine. Higher torque means stronger acceleration from a standstill.",
            "zeroToHundred": "How many seconds the car takes to go from 0 to 100 km/h. Lower is faster.",
            "topSpeed": "The maximum speed the car can reach. Higher means better highway performance.",
            "length": "The total length of the vehicle from front bumper to rear bumper.",
            "width": "The total width of the vehicle, important for parking and lane fit.",
            "wheelbase": "Distance between the front and rear axles. Longer wheelbase means smoother ride.",
        ],
        specVariants: [
            SpecVariant(
                id: "su7_standard",
                name: "Standard",
                specs: VehicleSpecs(
                    horsepower: 315, torque: 505,
                    zeroToHundred: 5.28, topSpeed: 240,
                    length: 4997, width: 1963, wheelbase: 3000,
                    configPrice: 215900,
                    range: 720,
                    drivetrain: "RWD",
                    engine: "Single Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "su7_pro",
                name: "Pro",
                specs: VehicleSpecs(
                    horsepower: 315, torque: 505,
                    zeroToHundred: 5.7, topSpeed: 240,
                    length: 4997, width: 1963, wheelbase: 3000,
                    configPrice: 245900,
                    range: 902,
                    drivetrain: "RWD",
                    engine: "Single Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "su7_max",
                name: "Max",
                specs: VehicleSpecs(
                    horsepower: 681, torque: 866,
                    zeroToHundred: 3.08, topSpeed: 265,
                    length: 4997, width: 1963, wheelbase: 3000,
                    configPrice: 299900,
                    range: 835,
                    drivetrain: "AWD",
                    engine: "Dual Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "su7_ultra",
                name: "Ultra",
                specs: VehicleSpecs(
                    horsepower: 1548, torque: 1770,
                    zeroToHundred: 1.98, topSpeed: 350,
                    length: 4997, width: 1963, wheelbase: 3000,
                    configPrice: 530000,
                    range: 630,
                    drivetrain: "AWD",
                    engine: "Tri Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
        ]
    ),

    // ── Nio ET7 ────────────────────────────────────────────────────────────
    Vehicle(
        id: "nio_et7",
        name: "Nio ET7",
        brand: "Nio",
        category: "Sedan",
        thumbnailColor: Color(red: 0.45, green: 0.62, blue: 0.78),
        scale: 0.8,
        basePrice: 320000,
        colourVariants: [
            ColourVariant(id: "cyan", displayName: "Cyan",
                          swatch: Color(red: 0.62, green: 0.78, blue: 0.92),
                          modelFile: "et7 cyan"),
            ColourVariant(id: "white", displayName: "Glacier White",
                          swatch: .white,
                          modelFile: "et7 white"),
            ColourVariant(id: "red", displayName: "Racing Red",
                          swatch: .red,
                          modelFile: "et7 red"),
            ColourVariant(id: "teal", displayName: "Teal",
                          swatch: Color(red: 0.0, green: 0.55, blue: 0.55),
                          modelFile: "et7 teal"),
        ],
        supportsWindowAnim: false,
        availablePartIDs: [
            "rim_stock",
            "spoiler_none",
            "bodykit_none",
            "wrap_none",
        ],
        mountPoints: [:],
        rimModelFiles: [:],
        stockSpecs: VehicleSpecs(
            horsepower: 653, torque: 850,
            zeroToHundred: 3.8, topSpeed: 200,
            length: 5101, width: 1987, wheelbase: 3060,
            configPrice: 320000,
            range: 550,
            drivetrain: "AWD",
            engine: "Dual Motor",
            powertrain: "Electric (BEV)"
        ),
        modifiedSpecs: VehicleSpecs(
            horsepower: 653, torque: 850,
            zeroToHundred: 3.8, topSpeed: 200,
            length: 5101, width: 1987, wheelbase: 3060,
            configPrice: 320000,
            range: 550,
            drivetrain: "AWD",
            engine: "Dual Motor",
            powertrain: "Electric (BEV)"
        ),
        specExplanations: [
            "horsepower": "Horsepower measures the engine's output power. Higher means faster acceleration.",
            "torque": "Torque is the pulling force from the engine. Higher torque means stronger acceleration from a standstill.",
            "zeroToHundred": "How many seconds the car takes to go from 0 to 100 km/h. Lower is faster.",
            "topSpeed": "The maximum speed the car can reach. Higher means better highway performance.",
            "length": "The total length of the vehicle from front bumper to rear bumper.",
            "width": "The total width of the vehicle, important for parking and lane fit.",
            "wheelbase": "Distance between the front and rear axles. Longer wheelbase means smoother ride.",
        ],
        specVariants: [
            SpecVariant(
                id: "75kwh_standard",
                name: "75 kWh Standard Range",
                specs: VehicleSpecs(
                    horsepower: 653, torque: 850,
                    zeroToHundred: 3.8, topSpeed: 200,
                    length: 5101, width: 1987, wheelbase: 3060,
                    configPrice: 320000,
                    range: 550,
                    drivetrain: "AWD",
                    engine: "Dual Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "100kwh_long",
                name: "100 kWh Long Range",
                specs: VehicleSpecs(
                    horsepower: 653, torque: 850,
                    zeroToHundred: 3.8, topSpeed: 200,
                    length: 5101, width: 1987, wheelbase: 3060,
                    configPrice: 380000,
                    range: 675,
                    drivetrain: "AWD",
                    engine: "Dual Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "150kwh_ultra_long",
                name: "150 kWh Ultra Long Range",
                specs: VehicleSpecs(
                    horsepower: 653, torque: 850,
                    zeroToHundred: 3.8, topSpeed: 200,
                    length: 5101, width: 1987, wheelbase: 3060,
                    configPrice: 450000,
                    range: 1050,
                    drivetrain: "AWD",
                    engine: "Dual Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
        ]
    ),

    // ── Voyah Free ────────────────────────────────────────────────────────
    // Customise panel: Rims + Interior only (Spoilers/Body Kits/Wraps removed
    // for this vehicle). 6 exterior colours, 3 interior trim themes.
    // No USDZ files wired up yet — every modelFile is a placeholder ("").
    Vehicle(
        id: "voyah_free",
        name: "Voyah Free",
        brand: "Voyah",
        category: "SUV",
        thumbnailColor: Color(red: 0.620, green: 0.792, blue: 0.882),
        scale: 0.8,
        basePrice: 350000,
        colourVariants: [
            // 1. Cloud Light Blue (云清蓝) — #9ECAE1
            ColourVariant(id: "cloud_light_blue", displayName: "Cloud Light Blue",
                          swatch: Color(red: 0.620, green: 0.792, blue: 0.882),
                          modelFile: "voyah light blue"),
            // 2. Duruo White (杜若白) — #F4F6F6
            ColourVariant(id: "duruo_white", displayName: "Duruo White",
                          swatch: Color(red: 0.957, green: 0.965, blue: 0.965),
                          modelFile: "voyah white"),
            // 3. Xuanying Black (玄英黑) — #0E0E10
            ColourVariant(id: "xuanying_black", displayName: "Xuanying Black",
                          swatch: Color(red: 0.055, green: 0.055, blue: 0.063),
                          modelFile: "voyah black"),
            // 4. Chenxing Gray (宸星灰) — #7A7F85
            ColourVariant(id: "chenxing_gray", displayName: "Chenxing Gray",
                          swatch: Color(red: 0.478, green: 0.498, blue: 0.522),
                          modelFile: "voyah grey"),
            // 5. Shaohua Green (韶华青) — #3F514D
            ColourVariant(id: "shaohua_green", displayName: "Shaohua Green",
                          swatch: Color(red: 0.247, green: 0.318, blue: 0.302),
                          modelFile: "voyah green"),
            // 6. Yunsha Gold (云纱金) — #C8B6A6
            ColourVariant(id: "yunsha_gold", displayName: "Yunsha Gold",
                          swatch: Color(red: 0.784, green: 0.714, blue: 0.651),
                          modelFile: "voyah gold"),
        ],
        supportsWindowAnim: false,
        availablePartIDs: [
            "rim_stock",
            "interior_deep_sea_blue",
            "interior_amber_brown",
            "interior_aurora_purple",
        ],
        mountPoints: [:],
        rimModelFiles: [:],
        stockSpecs: VehicleSpecs(
            horsepower: 490, torque: 720,
            zeroToHundred: 4.4, topSpeed: 200,
            length: 4905, width: 1950, wheelbase: 2960,
            configPrice: 350000,
            range: 500,
            drivetrain: "AWD",
            engine: "Dual Motor",
            powertrain: "Electric (BEV)"
        ),
        modifiedSpecs: VehicleSpecs(
            horsepower: 684, torque: 1040,
            zeroToHundred: 4.7, topSpeed: 200,
            length: 4905, width: 1950, wheelbase: 2960,
            configPrice: 410000,
            range: 460,
            drivetrain: "AWD",
            engine: "Dual Motor",
            powertrain: "Electric (BEV)"
        ),
        specExplanations: [
            "horsepower": "Horsepower measures the engine's output power. Higher means faster acceleration.",
            "torque": "Torque is the pulling force from the engine. Higher torque means stronger acceleration from a standstill.",
            "zeroToHundred": "How many seconds the car takes to go from 0 to 100 km/h. Lower is faster.",
            "topSpeed": "The maximum speed the car can reach. Higher means better highway performance.",
            "length": "The total length of the vehicle from front bumper to rear bumper.",
            "width": "The total width of the vehicle, important for parking and lane fit.",
            "wheelbase": "Distance between the front and rear axles. Longer wheelbase means smoother ride.",
        ],
        specVariants: [
            SpecVariant(
                id: "rwd_electric",
                name: "RWD Electric",
                specs: VehicleSpecs(
                    horsepower: 347, torque: 520,
                    zeroToHundred: 7.3, topSpeed: 180,
                    length: 4905, width: 1950, wheelbase: 2960,
                    configPrice: 290000,
                    range: 500,
                    drivetrain: "RWD",
                    engine: "Single Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "awd_electric",
                name: "AWD Electric",
                specs: VehicleSpecs(
                    horsepower: 490, torque: 720,
                    zeroToHundred: 4.4, topSpeed: 200,
                    length: 4905, width: 1950, wheelbase: 2960,
                    configPrice: 350000,
                    range: 500,
                    drivetrain: "AWD",
                    engine: "Dual Motor",
                    powertrain: "Electric (BEV)"
                )
            ),
            SpecVariant(
                id: "awd_high_power",
                name: "AWD High-Power",
                specs: VehicleSpecs(
                    horsepower: 684, torque: 1040,
                    zeroToHundred: 4.7, topSpeed: 200,
                    length: 4905, width: 1950, wheelbase: 2960,
                    configPrice: 410000,
                    range: 460,
                    drivetrain: "AWD",
                    engine: "Dual Motor",
                    powertrain: "Electric (BEV)"
                )
            ),                                       
            SpecVariant(
                id: "extended_range",
                name: "Extended-Range",
                specs: VehicleSpecs(
                    horsepower: 490, torque: 1040,
                    zeroToHundred: 4.8, topSpeed: 200,
                    length: 4905, width: 1950, wheelbase: 2960,
                    configPrice: 330000,
                    range: nil,
                    drivetrain: "AWD",
                    engine: "1.5L Turbo 4-Cyl + Dual Motor",
                    powertrain: "Plug-in Hybrid (PHEV)"
                )
            ),
        ]
    ),

    // ── LAND ROVER DEFENDER ───────────────────────────────────────────────
    defenderUmbrella

]

// ══════════════════════════════════════════════════════════════════════════
// GLOSSARY DATA
// ══════════════════════════════════════════════════════════════════════════
let glossaryTerms: [GlossaryTerm] = [
    // ── Engine & Power ──────────────────────────────────────────
    GlossaryTerm(id: "hp", term: "Horsepower (HP)", definition: "A measure of how much power an engine produces. Higher horsepower means the car can accelerate faster and maintain higher speeds more easily.", category: "Engine & Power"),
    GlossaryTerm(id: "torque", term: "Torque (Nm)", definition: "The rotational force produced by the engine. Higher torque means stronger pulling power, especially useful when accelerating from a stop or going uphill.", category: "Engine & Power"),
    GlossaryTerm(id: "cc", term: "CC (Cubic Capacity)", definition: "The volume of the engine's cylinders in cubic centimeters. It is another way to measure engine displacement, where 1000cc is equal to 1.0L. A higher CC generally means more power and fuel consumption.", category: "Engine & Power"),
    GlossaryTerm(id: "ice", term: "ICE", definition: "Internal Combustion Engine. A traditional vehicle powered completely by burning fossil fuels (petrol or diesel).", category: "Engine & Power"),
    GlossaryTerm(id: "na", term: "NA (Naturally Aspirated)", definition: "An internal combustion engine that draws in air at atmospheric pressure without the use of forced induction, such as a turbocharger or supercharger.", category: "Engine & Power"),
    GlossaryTerm(id: "turbocharger", term: "Turbocharger", definition: "A device powered by exhaust gases that forces more air into the engine, increasing power without needing a larger engine.", category: "Engine & Power"),
    GlossaryTerm(id: "supercharger", term: "Supercharger", definition: "A mechanically driven device that forces more air into the engine, providing an immediate power boost without the 'lag' sometimes felt in turbochargers.", category: "Engine & Power"),
    GlossaryTerm(id: "displacement", term: "Engine Displacement", definition: "The total volume of all the cylinders in an engine, usually measured in liters (e.g., 2.0L) or cubic centimeters (cc).", category: "Engine & Power"),
    GlossaryTerm(id: "cylinder", term: "Cylinder", definition: "The central working part of an engine where fuel is burned to create power. The number of cylinders (e.g., 4, 6, 8) generally correlates with the engine's power output and smoothness.", category: "Engine & Power"),
    GlossaryTerm(id: "inline_engine", term: "Inline Engine", definition: "An engine configuration where all the cylinders are arranged in a single straight row. Common layouts include Inline-4 or Inline-6. Known for smooth power delivery and mechanical simplicity.", category: "Engine & Power"),
    GlossaryTerm(id: "v_engine", term: "V-Engine (V6, V8, etc.)", definition: "An engine configuration where the cylinders are divided into two banks angled away from each other to form a 'V' shape. This allows a larger number of cylinders to be packed into a shorter, more compact space.", category: "Engine & Power"),

    // ── Transmissions & Gearboxes ──────────────────────────────
    GlossaryTerm(id: "cvt", term: "CVT", definition: "Continuously Variable Transmission. A type of automatic gearbox that smoothly changes through an infinite number of gear ratios for better fuel efficiency, without traditional 'gears'.", category: "Transmissions & Gearboxes"),
    GlossaryTerm(id: "at", term: "Automatic Transmission (AT)", definition: "A gearbox that automatically changes gear ratios as the vehicle moves, freeing the driver from having to shift gears manually.", category: "Transmissions & Gearboxes"),
    GlossaryTerm(id: "mt", term: "Manual Transmission (MT)", definition: "A traditional gearbox where the driver must manually select gears using a gear stick and a clutch pedal.", category: "Transmissions & Gearboxes"),
    GlossaryTerm(id: "dct", term: "Dual-Clutch Transmission (DCT)", definition: "An automated manual transmission that uses two separate clutches for odd and even gear sets, allowing for incredibly fast and smooth gear changes.", category: "Transmissions & Gearboxes"),

    // ── Electric & Hybrid Vehicles (Car Types) ─────────────────
    GlossaryTerm(id: "bev", term: "BEV (Battery Electric Vehicle)", definition: "A purely electric vehicle powered solely by an electric motor and a large battery pack, with no internal combustion engine. Produces zero tailpipe emissions.", category: "Electric & Hybrid Vehicles"),
    GlossaryTerm(id: "phev", term: "PHEV (Plug-in Hybrid)", definition: "Features both a traditional internal combustion engine and an electric motor with a battery that can be plugged in to charge. Can drive short distances purely on electric power before the petrol engine kicks in.", category: "Electric & Hybrid Vehicles"),
    GlossaryTerm(id: "mhev", term: "MHEV (Mild Hybrid)", definition: "Uses a small electric motor and battery to assist the internal combustion engine with acceleration and efficiency. It cannot drive on electric power alone and does not need to be plugged in.", category: "Electric & Hybrid Vehicles"),
    GlossaryTerm(id: "hev", term: "HEV (Hybrid Electric Vehicle)", definition: "A standard hybrid that uses both a combustion engine and an electric motor. The battery is charged through regenerative braking and the engine, but cannot be plugged into an outlet.", category: "Electric & Hybrid Vehicles"),

    // ── Drivetrain ──────────────────────────────────────────────
    GlossaryTerm(id: "drivetrain", term: "Drivetrain Overview", definition: "Indicates which wheels receive power from the engine or motor(s).", category: "Drivetrain"),
    GlossaryTerm(id: "fwd", term: "FWD (Front-Wheel Drive)", definition: "Power is sent only to the front two wheels. Most common in standard commuter cars.", category: "Drivetrain"),
    GlossaryTerm(id: "rwd", term: "RWD (Rear-Wheel Drive)", definition: "Power is sent only to the rear two wheels. Often preferred for sportier handling and better weight distribution.", category: "Drivetrain"),
    GlossaryTerm(id: "awd", term: "AWD (All-Wheel Drive)", definition: "Power is sent to all four wheels at all times. Common in SUVs and high-performance cars for maximum traction.", category: "Drivetrain"),
    GlossaryTerm(id: "4wd", term: "4WD (Four-Wheel Drive)", definition: "Can send power to all four wheels, often selectable by the driver for off-road or low-traction conditions.", category: "Drivetrain"),

    // ── Handling & Safety ───────────────────────────────────────
    GlossaryTerm(id: "abs", term: "ABS (Anti-lock Braking System)", definition: "Prevents the wheels from locking up during hard braking, allowing the driver to maintain steering control to avoid obstacles.", category: "Handling & Safety"),
    GlossaryTerm(id: "tcs", term: "Traction Control System (TCS)", definition: "Prevents wheel spin during acceleration by reducing engine power or applying brakes to specific wheels, ensuring maximum grip.", category: "Handling & Safety"),
    GlossaryTerm(id: "esc", term: "Electronic Stability Control (ESC)", definition: "Helps prevent loss of control in corners or slippery conditions by automatically applying brakes to individual wheels to keep the car on its intended path.", category: "Handling & Safety"),
    GlossaryTerm(id: "adas", term: "ADAS", definition: "Advanced Driver Assistance Systems. Includes safety features like lane departure warning, adaptive cruise control, and automatic emergency braking.", category: "Handling & Safety"),
    GlossaryTerm(id: "wheelbase", term: "Wheelbase", definition: "The distance between the front and rear axles. A longer wheelbase generally provides a smoother, more stable ride and more interior legroom.", category: "Handling & Safety"),
    GlossaryTerm(id: "unsprung_weight", term: "Unsprung Weight", definition: "The weight of components not supported by the suspension, such as wheels and brakes. Lighter unsprung weight means much better handling.", category: "Handling & Safety"),

    // ── Wheels & Tires ──────────────────────────────────────────
    GlossaryTerm(id: "offset", term: "Offset", definition: "The distance between the centre line of the wheel and its mounting surface. Affects how the wheel sits in the wheel arch and can heavily impact handling.", category: "Wheels & Tires"),
    GlossaryTerm(id: "bolt_pattern", term: "Bolt Pattern", definition: "The arrangement of bolt holes on a wheel. Must exactly match the vehicle's hub for the wheel to fit securely.", category: "Wheels & Tires"),

    // ── Exterior & Aerodynamics ─────────────────────────────────
    GlossaryTerm(id: "downforce", term: "Downforce", definition: "Aerodynamic force that pushes the car down toward the road. Spoilers and splitters increase downforce for better grip at high speeds.", category: "Exterior & Aerodynamics"),
    GlossaryTerm(id: "body_kit", term: "Body Kit", definition: "A set of aftermarket exterior modifications including bumpers, side skirts, and splitters. Can be cosmetic or improve aerodynamics.", category: "Exterior & Aerodynamics"),
    GlossaryTerm(id: "diffuser", term: "Diffuser", definition: "A shaped section of the rear underbody that improves the car's aerodynamic properties by smoothing airflow underneath the vehicle.", category: "Exterior & Aerodynamics")
]

// ══════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════

func partsFor(_ vehicle: Vehicle) -> [CarPart] {
    masterPartsCatalogue.filter { vehicle.availablePartIDs.contains($0.id) }
}

func partsFor(_ vehicle: Vehicle, category: String) -> [CarPart] {
    partsFor(vehicle).filter { $0.category == category }
}

func categoriesFor(_ vehicle: Vehicle) -> [String] {
    let parts = partsFor(vehicle)
    return Array(Set(parts.map { $0.category })).sorted()
}

func defaultLabel(for category: String) -> String {
    category == "Rims" ? "Stock" : "None"
}

func defaultPart(for vehicle: Vehicle, category: String) -> CarPart? {
    partsFor(vehicle, category: category).first { $0.isDefault }
}
