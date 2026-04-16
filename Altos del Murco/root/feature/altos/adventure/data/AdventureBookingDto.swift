//
//  AdventureBookingDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

protocol AdventureListenerToken {
    func remove()
}

final class FirestoreAdventureListenerToken: AdventureListenerToken {
    private var registration: ListenerRegistration?
    
    init(registration: ListenerRegistration) {
        self.registration = registration
    }
    
    func remove() {
        registration?.remove()
        registration = nil
    }
}

struct AdventureReservationItemDraftDTO: Codable {
    let id: String
    let activity: String
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int
    
    init(from item: AdventureReservationItemDraft) {
        self.id = item.id
        self.activity = item.activity.rawValue
        self.durationMinutes = item.durationMinutes
        self.peopleCount = item.peopleCount
        self.vehicleCount = item.vehicleCount
        self.offRoadRiderCount = item.offRoadRiderCount
        self.nights = item.nights
    }
    
    func toDomain() -> AdventureReservationItemDraft? {
        guard let activity = AdventureActivityType(rawValue: activity) else { return nil }
        
        return AdventureReservationItemDraft(
            id: id,
            activity: activity,
            durationMinutes: durationMinutes,
            peopleCount: peopleCount,
            vehicleCount: vehicleCount,
            offRoadRiderCount: offRoadRiderCount,
            nights: nights
        )
    }
}

struct ReservationFoodItemDraftDTO: Codable {
    let id: String
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let notes: String?
    
    init(from item: ReservationFoodItemDraft) {
        self.id = item.id
        self.menuItemId = item.menuItemId
        self.name = item.name
        self.unitPrice = item.unitPrice
        self.quantity = item.quantity
        self.notes = item.notes
    }
    
    func toDomain() -> ReservationFoodItemDraft {
        ReservationFoodItemDraft(
            id: id,
            menuItemId: menuItemId,
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            notes: notes
        )
    }
}

struct ReservationFoodDraftDTO: Codable {
    let items: [ReservationFoodItemDraftDTO]
    let servingMoment: String
    let servingTime: Timestamp?
    let notes: String?
    
    init(from food: ReservationFoodDraft) {
        self.items = food.items.map(ReservationFoodItemDraftDTO.init(from:))
        self.servingMoment = food.servingMoment.rawValue
        self.servingTime = food.servingTime.map(Timestamp.init(date:))
        self.notes = food.notes
    }
    
    func toDomain() -> ReservationFoodDraft {
        ReservationFoodDraft(
            items: items.map { $0.toDomain() },
            servingMoment: ReservationServingMoment(rawValue: servingMoment) ?? .afterActivities,
            servingTime: servingTime?.dateValue(),
            notes: notes
        )
    }
}

struct AdventureBookingBlockDTO: Codable {
    let id: String
    let title: String
    let activity: String
    let resourceType: String
    let startAt: Timestamp
    let endAt: Timestamp
    let reservedUnits: Int
    let subtotal: Double
    
    init(from block: AdventureBookingBlock) {
        self.id = block.id
        self.title = block.title
        self.activity = block.activity.rawValue
        self.resourceType = block.resourceType.rawValue
        self.startAt = Timestamp(date: block.startAt)
        self.endAt = Timestamp(date: block.endAt)
        self.reservedUnits = block.reservedUnits
        self.subtotal = block.subtotal
    }
    
    func toDomain() -> AdventureBookingBlock? {
        guard let activity = AdventureActivityType(rawValue: activity),
              let resource = AdventureResourceType(rawValue: resourceType) else {
            return nil
        }
        
        return AdventureBookingBlock(
            id: id,
            title: title,
            activity: activity,
            resourceType: resource,
            startAt: startAt.dateValue(),
            endAt: endAt.dateValue(),
            reservedUnits: reservedUnits,
            subtotal: subtotal
        )
    }
}

@MainActor
struct AdventureBookingDTO: Codable {
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let startDayKey: String
    let startAt: Timestamp
    let endAt: Timestamp
    let guestCount: Int?
    let eventType: String?
    let customEventTitle: String?
    let eventNotes: String?
    let items: [AdventureReservationItemDraftDTO]
    let foodReservation: ReservationFoodDraftDTO?
    let blocks: [AdventureBookingBlockDTO]
    let adventureSubtotal: Double?
    let foodSubtotal: Double?
    let subtotal: Double
    let discountAmount: Double
    let nightPremium: Double
    let totalAmount: Double
    let status: String
    let createdAt: Timestamp
    let notes: String?
    
    func toDomain(documentId: String) -> AdventureBooking {
        AdventureBooking(
            id: documentId,
            clientId: clientId,
            clientName: clientName,
            whatsappNumber: whatsappNumber,
            nationalId: nationalId,
            startDayKey: startDayKey,
            startAt: startAt.dateValue(),
            endAt: endAt.dateValue(),
            guestCount: guestCount ?? 1,
            eventType: ReservationEventType(rawValue: eventType ?? "") ?? .regularVisit,
            customEventTitle: customEventTitle,
            eventNotes: eventNotes,
            items: items.compactMap { $0.toDomain() },
            foodReservation: foodReservation?.toDomain(),
            blocks: blocks.compactMap { $0.toDomain() },
            adventureSubtotal: adventureSubtotal ?? subtotal,
            foodSubtotal: foodSubtotal ?? 0,
            subtotal: subtotal,
            discountAmount: discountAmount,
            nightPremium: nightPremium,
            totalAmount: totalAmount,
            status: AdventureBookingStatus(rawValue: status) ?? .confirmed,
            createdAt: createdAt.dateValue(),
            notes: notes
        )
    }
    
    static func from(
        bookingId: String,
        request: AdventureBookingRequest,
        plan: AdventureBuildPlan,
        createdAt: Date
    ) -> AdventureBookingDTO {
        AdventureBookingDTO(
            clientId: request.clientId,
            clientName: request.clientName,
            whatsappNumber: request.whatsappNumber,
            nationalId: request.nationalId,
            startDayKey: AdventureDateHelper.dayKey(from: plan.startAt),
            startAt: Timestamp(date: plan.startAt),
            endAt: Timestamp(date: plan.endAt),
            guestCount: request.guestCount,
            eventType: request.eventType.rawValue,
            customEventTitle: request.customEventTitle,
            eventNotes: request.eventNotes,
            items: request.items.map(AdventureReservationItemDraftDTO.init(from:)),
            foodReservation: request.foodReservation.map(ReservationFoodDraftDTO.init(from:)),
            blocks: plan.blocks.map(AdventureBookingBlockDTO.init(from:)),
            adventureSubtotal: plan.adventureSubtotal,
            foodSubtotal: plan.foodSubtotal,
            subtotal: plan.subtotal,
            discountAmount: plan.discountAmount,
            nightPremium: plan.nightPremium,
            totalAmount: plan.totalAmount,
            status: AdventureBookingStatus.confirmed.rawValue,
            createdAt: Timestamp(date: createdAt),
            notes: request.notes
        )
    }
}
