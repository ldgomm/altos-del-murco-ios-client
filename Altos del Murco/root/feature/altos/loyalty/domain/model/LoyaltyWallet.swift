//
//  LoyaltyWallet.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct LoyaltyWallet: Equatable {
    let clientId: String
    let totalAvailablePoints: Int
    let providerBalances: [ProviderPointsBalance]
    let updatedAt: Date
}
