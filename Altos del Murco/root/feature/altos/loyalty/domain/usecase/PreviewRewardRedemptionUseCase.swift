//
//  PreviewRewardRedemptionUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct PreviewRewardRedemptionUseCase {
    let service: LoyaltyServiceable
    
    func execute(clientId: String, rewardId: String) async throws -> RedemptionPreview {
        try await service.previewRedemption(clientId: clientId, rewardId: rewardId)
    }
}
