//
//  CallablePreviewDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct CallablePreviewDTO: Decodable {
    let rewardId: String
    let rewardTitle: String
    let pointsRequired: Int
    let currentAvailablePoints: Int
    let missingPoints: Int
    let canRedeem: Bool
    let settlementAmount: Double
    let providerShares: [CallableProviderShareDTO]
}

struct CallableProviderShareDTO: Decodable {
    let providerId: String
    let providerName: String
    let serviceId: String
    let serviceName: String
    let pointsUsed: Int
    let amount: Double
    let percentage: Double
}

extension CallablePreviewDTO {
    func toDomain() -> RedemptionPreview {
        RedemptionPreview(
            rewardId: rewardId,
            rewardTitle: rewardTitle,
            pointsRequired: pointsRequired,
            currentAvailablePoints: currentAvailablePoints,
            missingPoints: missingPoints,
            canRedeem: canRedeem,
            settlementAmount: settlementAmount,
            providerShares: providerShares.map { $0.toDomain() }
        )
    }
}

extension CallableProviderShareDTO {
    func toDomain() -> ProviderSettlementShare {
        ProviderSettlementShare(
            providerId: providerId,
            providerName: providerName,
            serviceId: serviceId,
            serviceName: serviceName,
            pointsUsed: pointsUsed,
            amount: amount,
            percentage: percentage
        )
    }
}
