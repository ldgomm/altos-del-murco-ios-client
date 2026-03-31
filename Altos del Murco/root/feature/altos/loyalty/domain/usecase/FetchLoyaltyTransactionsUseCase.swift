//
//  FetchLoyaltyTransactionsUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct FetchLoyaltyTransactionsUseCase {
    let service: LoyaltyServiceable
    
    func execute(clientId: String) async throws -> [LoyaltyTransaction] {
        try await service.fetchTransactions(clientId: clientId)
    }
}
