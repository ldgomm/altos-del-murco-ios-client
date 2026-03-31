//
//  Reward.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct Reward: Identifiable, Equatable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let serviceId: String
    let providerId: String
    let pointsRequired: Int
    let settlementAmount: Double
    let imageURL: String?
    let isActive: Bool
}
