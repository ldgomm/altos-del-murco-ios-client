//
//  FirestoreRewardDTO.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation
import FirebaseFirestore

struct FirestoreRewardDTO: Codable {
    @DocumentID var documentId: String?
    
    let title: String
    let subtitle: String?
    let serviceId: String
    let providerId: String
    let pointsRequired: Int
    let settlementAmount: Double
    let imageURL: String?
    let isActive: Bool
}

extension FirestoreRewardDTO {
    func toDomain() -> Reward {
        Reward(
            id: documentId ?? UUID().uuidString,
            title: title,
            subtitle: subtitle ?? "",
            serviceId: serviceId,
            providerId: providerId,
            pointsRequired: pointsRequired,
            settlementAmount: settlementAmount,
            imageURL: imageURL,
            isActive: isActive
        )
    }
}
