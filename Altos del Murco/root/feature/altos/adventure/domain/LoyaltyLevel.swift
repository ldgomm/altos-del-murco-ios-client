//
//  LoyaltyLevel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

struct ProfileStats {
    let points: Int
    let completedOrders: Int
    let completedBookings: Int
    let restaurantSpent: Double
    let adventureSpent: Double
    let totalSpent: Double
    let level: LoyaltyLevel

    static let empty = ProfileStats(
        points: 0,
        completedOrders: 0,
        completedBookings: 0,
        restaurantSpent: 0,
        adventureSpent: 0,
        totalSpent: 0,
        level: .silver
    )
}
