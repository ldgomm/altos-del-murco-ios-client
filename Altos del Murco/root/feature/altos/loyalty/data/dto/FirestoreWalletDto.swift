//
//  FirestoreWalletDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreWalletDTO: Codable {
    @DocumentID var documentId: String?
    
    let clientId: String
    let totalAvailablePoints: Int
    let providerBalances: [FirestoreProviderBalanceDTO]
    let updatedAt: Date?
}

struct FirestoreProviderBalanceDTO: Codable {
    let providerId: String
    let providerName: String
    let serviceIds: [String]
    let availablePoints: Int
}

extension FirestoreWalletDTO {
    func toDomain() -> LoyaltyWallet {
        LoyaltyWallet(
            clientId: clientId,
            totalAvailablePoints: totalAvailablePoints,
            providerBalances: providerBalances.map { $0.toDomain() },
            updatedAt: updatedAt ?? .now
        )
    }
}

extension FirestoreProviderBalanceDTO {
    func toDomain() -> ProviderPointsBalance {
        ProviderPointsBalance(
            providerId: providerId,
            providerName: providerName,
            serviceIds: serviceIds,
            availablePoints: availablePoints
        )
    }
}
