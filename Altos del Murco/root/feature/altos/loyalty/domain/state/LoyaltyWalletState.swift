//
//  LoyaltyWalletState.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct LoyaltyWalletState {
    var clientId: String?
    
    var isLoading: Bool = false
    var isLoadingPreview: Bool = false
    var isRedeeming: Bool = false
    
    var wallet: LoyaltyWallet?
    var rewards: [Reward] = []
    var transactions: [LoyaltyTransaction] = []
    
    var selectedReward: Reward?
    var preview: RedemptionPreview?
    
    var errorMessage: String?
    var successMessage: String?
}
