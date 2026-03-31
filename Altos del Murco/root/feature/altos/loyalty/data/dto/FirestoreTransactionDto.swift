//
//  FirestoreTransactionDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreTransactionDTO: Codable {
    @DocumentID var documentId: String?
    
    let kind: String
    let serviceId: String
    let serviceName: String
    let providerId: String
    let providerName: String
    let points: Int
    let note: String?
    let createdAt: Date?
}

extension FirestoreTransactionDTO {
    func toDomain() -> LoyaltyTransaction {
        LoyaltyTransaction(
            id: documentId ?? UUID().uuidString,
            kind: LoyaltyTransactionKind(rawValue: kind) ?? .adjustment,
            serviceId: serviceId,
            serviceName: serviceName,
            providerId: providerId,
            providerName: providerName,
            points: points,
            note: note,
            createdAt: createdAt ?? .now
        )
    }
}
