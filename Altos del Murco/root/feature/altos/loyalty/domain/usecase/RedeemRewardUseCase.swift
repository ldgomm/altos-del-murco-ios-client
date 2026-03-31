//
//  RedeemRewardUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct RedeemRewardUseCase {
    let service: LoyaltyServiceable
    
    func execute(clientId: String, rewardId: String) async throws -> RedemptionResult {
        try await service.redeemReward(clientId: clientId, rewardId: rewardId)
    }
}
