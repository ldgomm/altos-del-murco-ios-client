//
//  LoyaltyServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

protocol LoyaltyServiceable {
    func observeWallet(clientId: String) -> AsyncThrowingStream<LoyaltyWallet, Error>
    func fetchRewards() async throws -> [Reward]
    func fetchTransactions(clientId: String) async throws -> [LoyaltyTransaction]
    func previewRedemption(clientId: String, rewardId: String) async throws -> RedemptionPreview
    func redeemReward(clientId: String, rewardId: String) async throws -> RedemptionResult
}
