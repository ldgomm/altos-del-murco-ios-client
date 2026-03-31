//
//  CallableRedemptionResultDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Foundation

struct CallableRedemptionResultDTO: Decodable {
    let redemptionId: String
    let newAvailablePoints: Int
    let rewardTitle: String
}

extension CallableRedemptionResultDTO {
    func toDomain() -> RedemptionResult {
        RedemptionResult(
            redemptionId: redemptionId,
            newAvailablePoints: newAvailablePoints,
            rewardTitle: rewardTitle
        )
    }
}
