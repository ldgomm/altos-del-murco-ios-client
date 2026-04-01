//
//  AdventureService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

struct AdventureService: Identifiable, Hashable {
    let id: String
    let activityType: AdventureActivityType
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let priceText: String
    let durationText: String
    let includes: [String]
    
    init(
        id: String = UUID().uuidString,
        activityType: AdventureActivityType,
        title: String,
        systemImage: String,
        shortDescription: String,
        fullDescription: String,
        priceText: String,
        durationText: String,
        includes: [String]
    ) {
        self.id = id
        self.activityType = activityType
        self.title = title
        self.systemImage = systemImage
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription
        self.priceText = priceText
        self.durationText = durationText
        self.includes = includes
    }
    
    var defaultPackage: AdventurePackageType {
        switch activityType {
        case .offRoad:
            return .singleOffRoad
        case .paintball:
            return .singlePaintball
        case .goKarts:
            return .singleGoKarts
        case .shootingRange:
            return .singleShooting
        }
    }
}

extension AdventureService {
    static let mockServices: [AdventureService] = [
        AdventureService(
            activityType: .offRoad,
            title: "Off-Road",
            systemImage: "car.fill",
            shortDescription: "Explore mountain routes with adrenaline and nature.",
            fullDescription: "Enjoy an off-road experience through outdoor routes near Altos del Murco.",
            priceText: "$20 / hour / person",
            durationText: "1 - 3 hours",
            includes: ["Vehicle", "Guide", "Safety briefing"]
        ),
        AdventureService(
            activityType: .paintball,
            title: "Paintball",
            systemImage: "shield.lefthalf.filled",
            shortDescription: "Action-packed matches for friends and teams.",
            fullDescription: "Challenge your friends in exciting paintball games with outdoor fun.",
            priceText: "$5 / person",
            durationText: "30 min",
            includes: ["Marker", "Mask", "Basic ammo"]
        ),
        AdventureService(
            activityType: .goKarts,
            title: "Go Karts",
            systemImage: "flag.checkered",
            shortDescription: "Fast laps and competitive fun.",
            fullDescription: "Feel the speed and excitement of go kart racing.",
            priceText: "$5 / person",
            durationText: "30 min",
            includes: ["Kart", "Helmet", "Track access"]
        ),
        AdventureService(
            activityType: .shootingRange,
            title: "Shooting Range",
            systemImage: "target",
            shortDescription: "Precision, focus, and outdoor challenge.",
            fullDescription: "Practice aim and concentration in a controlled session.",
            priceText: "$5 / person",
            durationText: "30 min",
            includes: ["Equipment", "Safety briefing", "Supervised session"]
        )
    ]
}
