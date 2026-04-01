//
//  AdventureBookingDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseFirestore

struct AdventureBookingBlockDTO: Codable {
    let id: String
    let activity: String
    let startAt: Timestamp
    let endAt: Timestamp
    let durationMinutes: Int
    let unitPricePerPerson: Double
    
    init(from block: AdventureBookingBlock) {
        self.id = block.id
        self.activity = block.activity.rawValue
        self.startAt = Timestamp(date: block.startAt)
        self.endAt = Timestamp(date: block.endAt)
        self.durationMinutes = block.durationMinutes
        self.unitPricePerPerson = block.unitPricePerPerson
    }
    
    func toDomain() -> AdventureBookingBlock? {
        guard let activityType = AdventureActivityType(rawValue: activity) else {
            return nil
        }
        
        return AdventureBookingBlock(
            id: id,
            activity: activityType,
            startAt: startAt.dateValue(),
            endAt: endAt.dateValue(),
            durationMinutes: durationMinutes,
            unitPricePerPerson: unitPricePerPerson
        )
    }
}

@MainActor
struct AdventureBookingDTO: Codable {
    @DocumentID var id: String?
    
    let clientId: String?
    let clientName: String
    let peopleCount: Int
    let dayKey: String
    let packageType: String
    let offRoadHours: Int
    let totalAmount: Double
    let currency: String
    let status: String
    let createdAt: Timestamp
    let startAt: Timestamp
    let endAt: Timestamp
    let blocks: [AdventureBookingBlockDTO]
    let notes: String?
    
    static func from(
        bookingId: String,
        request: AdventureBookingRequest,
        plan: AdventureBuildPlan,
        status: AdventureBookingStatus,
        createdAt: Date
    ) -> AdventureBookingDTO {
        AdventureBookingDTO(
            id: bookingId,
            clientId: request.clientId,
            clientName: request.clientName,
            peopleCount: request.peopleCount,
            dayKey: AdventureDateHelper.dayKey(from: request.date),
            packageType: request.packageType.rawValue,
            offRoadHours: plan.offRoadHours,
            totalAmount: plan.totalAmount,
            currency: "USD",
            status: status.rawValue,
            createdAt: Timestamp(date: createdAt),
            startAt: Timestamp(date: plan.startAt),
            endAt: Timestamp(date: plan.endAt),
            blocks: plan.blocks.map(AdventureBookingBlockDTO.init(from:)),
            notes: request.notes
        )
    }
    
    func toDomain() -> AdventureBooking {
        AdventureBooking(
            id: id ?? UUID().uuidString,
            clientId: clientId,
            clientName: clientName,
            peopleCount: peopleCount,
            dayKey: dayKey,
            packageType: AdventurePackageType(rawValue: packageType) ?? .singleOffRoad,
            offRoadHours: offRoadHours,
            totalAmount: totalAmount,
            currency: currency,
            status: AdventureBookingStatus(rawValue: status) ?? .pending,
            createdAt: createdAt.dateValue(),
            startAt: startAt.dateValue(),
            endAt: endAt.dateValue(),
            blocks: blocks.compactMap { $0.toDomain() },
            notes: notes
        )
    }
}

struct AdventureSlotInventoryDTO: Codable {
    @DocumentID var id: String?
    
    let dayKey: String
    let activityType: String
    let slotIndex: Int
    let reservedPeople: Int
    let capacity: Int
    let updatedAt: Timestamp
}
