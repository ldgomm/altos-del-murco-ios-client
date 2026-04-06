//
//  ProfileStats.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct ProfileStats {
    let points: Int
    let orders: Int
    let bookings: Int

    static let empty = ProfileStats(
        points: 0,
        orders: 0,
        bookings: 0
    )
}
