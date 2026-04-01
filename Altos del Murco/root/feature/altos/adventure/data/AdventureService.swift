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
    
    var defaultDraft: AdventureReservationItemDraft {
        AdventureActivityType.defaultDraft(for: activityType)
    }
}

extension AdventureService {
    static let mockServices: [AdventureService] = [
        AdventureService(
            activityType: .offRoad,
            title: "Off-Road",
            systemImage: "car.fill",
            shortDescription: "Book 1, 2, or 3 hours by vehicle.",
            fullDescription: "One off-road vehicle supports 1 or 2 riders. Pricing is per vehicle per hour.",
            priceText: "$20 / hour / vehicle",
            durationText: "1 - 3 hours",
            includes: ["Vehicle", "Guide", "Safety briefing"]
        ),
        AdventureService(
            activityType: .paintball,
            title: "Paintball",
            systemImage: "shield.lefthalf.filled",
            shortDescription: "Flexible sessions for groups.",
            fullDescription: "Reserve paintball by 30-minute blocks for as many people as you want.",
            priceText: "$5 / 30 min / person",
            durationText: "30 - 120 min",
            includes: ["Marker", "Mask", "Basic ammo"]
        ),
        AdventureService(
            activityType: .goKarts,
            title: "Go Karts",
            systemImage: "flag.checkered",
            shortDescription: "Fast laps with flexible duration.",
            fullDescription: "Reserve go karts by 30-minute blocks for small or large groups.",
            priceText: "$5 / 30 min / person",
            durationText: "30 - 120 min",
            includes: ["Kart", "Helmet", "Track access"]
        ),
        AdventureService(
            activityType: .shootingRange,
            title: "Shooting Range",
            systemImage: "target",
            shortDescription: "Precision sessions by time and headcount.",
            fullDescription: "Reserve the shooting range alone or inside a combo.",
            priceText: "$5 / 30 min / person",
            durationText: "30 - 120 min",
            includes: ["Equipment", "Safety briefing"]
        ),
        AdventureService(
            activityType: .camping,
            title: "Camping",
            systemImage: "tent.fill",
            shortDescription: "Night stay with food and included off-road experience.",
            fullDescription: "Camping is booked per person per night and works as an overnight add-on.",
            priceText: "$30 / person / night",
            durationText: "1+ nights",
            includes: ["Food", "Sleeping area", "Included off-road experience"]
        ),
        AdventureService(
            activityType: .extremeSlide,
            title: "Extreme Slide",
            systemImage: "figure.fall",
            shortDescription: "Slide experience with included off-road transportation.",
            fullDescription: "A fixed session that reserves transport and the slide itself.",
            priceText: "$15 / person",
            durationText: "30 min + transport",
            includes: ["Slide session", "Included off-road transportation"]
        )
    ]
}
