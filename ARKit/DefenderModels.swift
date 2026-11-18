import SwiftUI
import RealityKit

let defenderColors = [
    ColourVariant(id: "pangea_green", displayName: "Pangea Green",
                  swatch: Color(red: 150/255, green: 165/255, blue: 152/255),
                  modelFile: ""),
    ColourVariant(id: "tasman_blue", displayName: "Tasman Blue",
                  swatch: Color(red: 60/255, green: 77/255, blue: 92/255),
                  modelFile: ""),
    ColourVariant(id: "gondwana_stone", displayName: "Gondwana Stone",
                  swatch: Color(red: 130/255, green: 113/255, blue: 97/255),
                  modelFile: ""),
    ColourVariant(id: "eiger_grey", displayName: "Eiger Grey",
                  swatch: Color(red: 109/255, green: 115/255, blue: 120/255),
                  modelFile: ""),
    ColourVariant(id: "santorini_black", displayName: "Santorini Black",
                  swatch: Color(red: 18/255, green: 18/255, blue: 20/255),
                  modelFile: ""),
    ColourVariant(id: "fuji_white", displayName: "Fuji White",
                  swatch: Color(red: 240/255, green: 242/255, blue: 242/255),
                  modelFile: "")
]

let defenderExplanations = [
    "horsepower": "Horsepower measures the engine's output power. Higher means faster acceleration.",
    "torque": "Torque is the pulling force from the engine. Higher torque means stronger acceleration from a standstill.",
    "zeroToHundred": "How many seconds the car takes to go from 0 to 100 km/h. Lower is faster.",
    "topSpeed": "The maximum speed the car can reach. Higher means better highway performance.",
    "length": "The total length of the vehicle from front bumper to rear bumper.",
    "width": "The total width of the vehicle, important for parking and lane fit.",
    "wheelbase": "Distance between the front and rear axles. Longer wheelbase means smoother ride.",
]

let defender90 = Vehicle(
    id: "defender_90", name: "Defender 90", brand: "Land Rover", category: "SUV",
    thumbnailColor: Color(red: 150/255, green: 165/255, blue: 152/255), scale: 0.8, basePrice: 400000,
    colourVariants: defenderColors, supportsWindowAnim: false, availablePartIDs: ["rim_stock"], mountPoints: [:], rimModelFiles: [:],
    stockSpecs: VehicleSpecs(
        horsepower: 250, torque: 570, zeroToHundred: 8.0, topSpeed: 188,
        length: 4583, width: 2008, wheelbase: 2587, configPrice: 400000, range: nil,
        drivetrain: "AWD", engine: "3.0L Turbocharged Diesel", powertrain: "Internal Combustion (ICE)"
    ),
    modifiedSpecs: VehicleSpecs(
        horsepower: 250, torque: 570, zeroToHundred: 8.0, topSpeed: 188,
        length: 4583, width: 2008, wheelbase: 2587, configPrice: 400000, range: nil,
        drivetrain: "AWD", engine: "3.0L Turbocharged Diesel", powertrain: "Internal Combustion (ICE)"
    ),
    specExplanations: defenderExplanations,
    specVariants: [
        SpecVariant(id: "def90_base", name: "Defender", specs: VehicleSpecs(
            horsepower: 250, torque: 570, zeroToHundred: 8.0, topSpeed: 188,
            length: 4583, width: 2008, wheelbase: 2587, configPrice: 400000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Diesel", powertrain: "Internal Combustion (ICE)"
        )),
        SpecVariant(id: "def90_s", name: "Defender S", specs: VehicleSpecs(
            horsepower: 300, torque: 400, zeroToHundred: 7.1, topSpeed: 191,
            length: 4583, width: 2008, wheelbase: 2587, configPrice: 430000, range: nil,
            drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
        )),
        SpecVariant(id: "def90_se", name: "Defender X-Dynamic SE", specs: VehicleSpecs(
            horsepower: 400, torque: 550, zeroToHundred: 6.0, topSpeed: 191,
            length: 4583, width: 2008, wheelbase: 2587, configPrice: 480000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Inline-6", powertrain: "Mild Hybrid (MHEV)"
        )),
        SpecVariant(id: "def90_hse", name: "Defender X-Dynamic HSE", specs: VehicleSpecs(
            horsepower: 400, torque: 550, zeroToHundred: 6.0, topSpeed: 191,
            length: 4583, width: 2008, wheelbase: 2587, configPrice: 510000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Inline-6", powertrain: "Mild Hybrid (MHEV)"
        ))
    ],
    subModels: []
)

let defender110Base = Vehicle(
    id: "defender_110_base", name: "Defender 110", brand: "Land Rover", category: "SUV",
    thumbnailColor: Color(red: 150/255, green: 165/255, blue: 152/255), scale: 0.8, basePrice: 450000,
    colourVariants: defenderColors, supportsWindowAnim: false, availablePartIDs: ["rim_stock"], mountPoints: [:], rimModelFiles: [:],
    stockSpecs: VehicleSpecs(
        horsepower: 300, torque: 400, zeroToHundred: 7.4, topSpeed: 191,
        length: 5018, width: 2008, wheelbase: 3022, configPrice: 450000, range: nil,
        drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
    ),
    modifiedSpecs: VehicleSpecs(
        horsepower: 300, torque: 400, zeroToHundred: 7.4, topSpeed: 191,
        length: 5018, width: 2008, wheelbase: 3022, configPrice: 450000, range: nil,
        drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
    ),
    specExplanations: defenderExplanations,
    specVariants: [
        SpecVariant(id: "def110_s", name: "Defender S", specs: VehicleSpecs(
            horsepower: 300, torque: 400, zeroToHundred: 7.4, topSpeed: 191,
            length: 5018, width: 2008, wheelbase: 3022, configPrice: 450000, range: nil,
            drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
        )),
        SpecVariant(id: "def110_se", name: "Defender X-Dynamic SE", specs: VehicleSpecs(
            horsepower: 404, torque: 640, zeroToHundred: 5.6, topSpeed: 191,
            length: 5018, width: 2008, wheelbase: 3022, configPrice: 520000, range: nil,
            drivetrain: "AWD", engine: "2.0L Turbo Petrol + Electric", powertrain: "Plug-in Hybrid (PHEV)"
        )),
        SpecVariant(id: "def110_hse", name: "Defender X-Dynamic HSE", specs: VehicleSpecs(
            horsepower: 404, torque: 640, zeroToHundred: 5.6, topSpeed: 191,
            length: 5018, width: 2008, wheelbase: 3022, configPrice: 560000, range: nil,
            drivetrain: "AWD", engine: "2.0L Turbo Petrol + Electric", powertrain: "Plug-in Hybrid (PHEV)"
        )),
        SpecVariant(id: "def110_x", name: "Defender X", specs: VehicleSpecs(
            horsepower: 400, torque: 550, zeroToHundred: 6.1, topSpeed: 191,
            length: 5018, width: 2008, wheelbase: 3022, configPrice: 620000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Inline-6", powertrain: "Mild Hybrid (MHEV)"
        ))
    ],
    subModels: []
)

let defender130 = Vehicle(
    id: "defender_130", name: "Defender 130", brand: "Land Rover", category: "SUV",
    thumbnailColor: Color(red: 150/255, green: 165/255, blue: 152/255), scale: 0.8, basePrice: 500000,
    colourVariants: defenderColors, supportsWindowAnim: false, availablePartIDs: ["rim_stock"], mountPoints: [:], rimModelFiles: [:],
    stockSpecs: VehicleSpecs(
        horsepower: 300, torque: 400, zeroToHundred: 7.5, topSpeed: 191,
        length: 5358, width: 2008, wheelbase: 3022, configPrice: 500000, range: nil,
        drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
    ),
    modifiedSpecs: VehicleSpecs(
        horsepower: 300, torque: 400, zeroToHundred: 7.5, topSpeed: 191,
        length: 5358, width: 2008, wheelbase: 3022, configPrice: 500000, range: nil,
        drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
    ),
    specExplanations: defenderExplanations,
    specVariants: [
        SpecVariant(id: "def130_s", name: "Defender S", specs: VehicleSpecs(
            horsepower: 300, torque: 400, zeroToHundred: 7.5, topSpeed: 191,
            length: 5358, width: 2008, wheelbase: 3022, configPrice: 500000, range: nil,
            drivetrain: "AWD", engine: "2.0L Turbo Petrol", powertrain: "Internal Combustion (ICE)"
        )),
        SpecVariant(id: "def130_se", name: "Defender X-Dynamic SE", specs: VehicleSpecs(
            horsepower: 400, torque: 550, zeroToHundred: 6.6, topSpeed: 191,
            length: 5358, width: 2008, wheelbase: 3022, configPrice: 560000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Inline-6", powertrain: "Mild Hybrid (MHEV)"
        )),
        SpecVariant(id: "def130_hse", name: "Defender X-Dynamic HSE", specs: VehicleSpecs(
            horsepower: 400, torque: 550, zeroToHundred: 6.6, topSpeed: 191,
            length: 5358, width: 2008, wheelbase: 3022, configPrice: 600000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Inline-6", powertrain: "Mild Hybrid (MHEV)"
        )),
        SpecVariant(id: "def130_x", name: "Defender X", specs: VehicleSpecs(
            horsepower: 400, torque: 550, zeroToHundred: 6.6, topSpeed: 191,
            length: 5358, width: 2008, wheelbase: 3022, configPrice: 660000, range: nil,
            drivetrain: "AWD", engine: "3.0L Turbo Inline-6", powertrain: "Mild Hybrid (MHEV)"
        ))
    ],
    subModels: []
)

let defenderOCTA = Vehicle(
    id: "defender_octa", name: "Defender OCTA", brand: "Land Rover", category: "SUV",
    thumbnailColor: Color(red: 18/255, green: 18/255, blue: 20/255), scale: 0.8, basePrice: 1100000,
    colourVariants: defenderColors, supportsWindowAnim: false, availablePartIDs: ["rim_stock"], mountPoints: [:], rimModelFiles: [:],
    stockSpecs: VehicleSpecs(
        horsepower: 635, torque: 750, zeroToHundred: 4.0, topSpeed: 250,
        length: 5018, width: 2105, wheelbase: 3022, configPrice: 1100000, range: nil,
        drivetrain: "AWD", engine: "4.4L Twin-Turbo V8", powertrain: "Mild Hybrid (MHEV)"
    ),
    modifiedSpecs: VehicleSpecs(
        horsepower: 635, torque: 750, zeroToHundred: 4.0, topSpeed: 250,
        length: 5018, width: 2105, wheelbase: 3022, configPrice: 1100000, range: nil,
        drivetrain: "AWD", engine: "4.4L Twin-Turbo V8", powertrain: "Mild Hybrid (MHEV)"
    ),
    specExplanations: defenderExplanations,
    specVariants: [
        SpecVariant(id: "def_octa", name: "Defender OCTA", specs: VehicleSpecs(
            horsepower: 635, torque: 750, zeroToHundred: 4.0, topSpeed: 250,
            length: 5018, width: 2105, wheelbase: 3022, configPrice: 1100000, range: nil,
            drivetrain: "AWD", engine: "4.4L Twin-Turbo V8", powertrain: "Mild Hybrid (MHEV)"
        )),
        SpecVariant(id: "def_octa_black", name: "Defender OCTA BLACK", specs: VehicleSpecs(
            horsepower: 635, torque: 750, zeroToHundred: 4.0, topSpeed: 250,
            length: 5018, width: 2105, wheelbase: 3022, configPrice: 1150000, range: nil,
            drivetrain: "AWD", engine: "4.4L Twin-Turbo V8", powertrain: "Mild Hybrid (MHEV)"
        ))
    ],
    subModels: []
)

// The parent model exposed to the main app catalogue.
let defenderUmbrella = Vehicle(
    id: "defender", name: "Defender", brand: "Land Rover", category: "SUV",
    thumbnailColor: Color(red: 150/255, green: 165/255, blue: 152/255), scale: 0.8, basePrice: 450000,
    colourVariants: defender110Base.colourVariants, supportsWindowAnim: false, availablePartIDs: ["rim_stock"], mountPoints: [:], rimModelFiles: [:],
    stockSpecs: defender110Base.stockSpecs,
    modifiedSpecs: defender110Base.modifiedSpecs,
    specExplanations: defender110Base.specExplanations,
    specVariants: defender110Base.specVariants,
    subModels: [defender90, defender110Base, defender130, defenderOCTA]
)
