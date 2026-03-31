//
//  LoyaltyWalletEvent.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

enum LoyaltyWalletEvent {
    case onAppear(clientId: String)
    case didTapReward(Reward)
    case confirmRedeem
    case dismissPreview
    case clearMessage
    case retry
}
