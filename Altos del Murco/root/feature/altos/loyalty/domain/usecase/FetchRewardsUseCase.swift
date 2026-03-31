//
//  FetchRewardsUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct FetchRewardsUseCase {
    let service: LoyaltyServiceable
    
    func execute() async throws -> [Reward] {
        try await service.fetchRewards()
    }
}
