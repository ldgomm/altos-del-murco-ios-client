//
//  ProviderPointsBalance.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct ProviderPointsBalance: Identifiable, Equatable {
    var id: String { providerId }
    
    let providerId: String
    let providerName: String
    let serviceIds: [String]
    let availablePoints: Int
}
