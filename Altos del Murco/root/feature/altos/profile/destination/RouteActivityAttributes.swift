//
//  RouteActivityAttributes.swift
//  Altos del Murco
//
//  Created by José Ruiz on 28/4/26.
//

import Foundation

#if canImport(ActivityKit)
import ActivityKit

@available(iOS 16.2, *)
struct RouteActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var destinationName: String
        var distanceText: String
        var etaText: String
        var arrivalText: String
        var progress: Double
        var statusText: String
        var instructionText: String
        var updatedAt: Date

        static let preview = ContentState(
            destinationName: "Altos del Murco",
            distanceText: "4.2 km",
            etaText: "12 min",
            arrivalText: "14:35",
            progress: 0.42,
            statusText: "En camino",
            instructionText: "Sigue la ruta hacia Altos del Murco.",
            updatedAt: Date()
        )
    }

    var routeName: String
}
#endif
