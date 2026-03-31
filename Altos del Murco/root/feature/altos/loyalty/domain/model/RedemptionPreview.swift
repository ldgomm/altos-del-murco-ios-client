//
//  RedemptionPreview.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct ProviderSettlementShare: Identifiable, Equatable {
    var id: String { "\(providerId)-\(serviceId)" }
    
    let providerId: String
    let providerName: String
    let serviceId: String
    let serviceName: String
    let pointsUsed: Int
    let amount: Double
    let percentage: Double
}

struct RedemptionPreview: Equatable {
    let rewardId: String
    let rewardTitle: String
    let pointsRequired: Int
    let currentAvailablePoints: Int
    let missingPoints: Int
    let canRedeem: Bool
    let settlementAmount: Double
    let providerShares: [ProviderSettlementShare]
}

struct RedemptionResult: Equatable {
    let redemptionId: String
    let newAvailablePoints: Int
    let rewardTitle: String
}
