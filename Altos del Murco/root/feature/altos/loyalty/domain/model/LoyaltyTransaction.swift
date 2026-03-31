//
//  LoyaltyTransaction.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

enum LoyaltyTransactionKind: String, Codable {
    case earn
    case redeem
    case adjustment
}

struct LoyaltyTransaction: Identifiable, Equatable {
    let id: String
    let kind: LoyaltyTransactionKind
    let serviceId: String
    let serviceName: String
    let providerId: String
    let providerName: String
    let points: Int
    let note: String?
    let createdAt: Date
}
