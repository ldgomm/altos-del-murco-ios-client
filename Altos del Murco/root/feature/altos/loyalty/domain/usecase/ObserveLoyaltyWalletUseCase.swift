//
//  ObserveLoyaltyWalletUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct ObserveLoyaltyWalletUseCase {
    let service: LoyaltyServiceable
    
    func execute(clientId: String) -> AsyncThrowingStream<LoyaltyWallet, Error> {
        service.observeWallet(clientId: clientId)
    }
}
