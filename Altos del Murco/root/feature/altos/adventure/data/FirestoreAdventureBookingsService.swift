//
//  FirestoreAdventureBookingsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
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

protocol AdventureBookingsServiceable {
    func observeBookings(
        for day: Date,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken
    
    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft]
    ) async throws -> [AdventureAvailabilitySlot]
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking
    
    func cancelBooking(id: String) async throws
}

// MARK: - DTOs

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
//    var id: String?
    
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let startDayKey: String
    let startAt: Timestamp
    let endAt: Timestamp
    let items: [AdventureReservationItemDraftDTO]
    let blocks: [AdventureBookingBlockDTO]
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
            items: items.compactMap { $0.toDomain() },
            blocks: blocks.compactMap { $0.toDomain() },
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
//            id: bookingId,
            clientId: request.clientId,
            clientName: request.clientName,
            whatsappNumber: request.whatsappNumber,
            nationalId: request.nationalId,
            startDayKey: AdventureDateHelper.dayKey(from: plan.startAt),
            startAt: Timestamp(date: plan.startAt),
            endAt: Timestamp(date: plan.endAt),
            items: request.items.map(AdventureReservationItemDraftDTO.init(from:)),
            blocks: plan.blocks.map(AdventureBookingBlockDTO.init(from:)),
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

final class FirestoreAdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = "adventure_bookings"
//    private let inventoryCollection = "adventure_slot_inventory"
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func observeBookings(
        for day: Date,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        let dayKey = AdventureDateHelper.dayKey(from: day)
        
        let registration = db.collection(bookingsCollection)
            .whereField("startDayKey", isEqualTo: dayKey)
            .order(by: "startAt")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }
                
                guard let snapshot else {
                    onChange(.success([]))
                    return
                }
                
                do {
                    let bookings = try snapshot.documents.map { document in
                        let dto = try document.data(as: AdventureBookingDTO.self)
                        return dto.toDomain(documentId: document.documentID)
                    }
                    onChange(.success(bookings))
                } catch {
                    onChange(.failure(error))
                }
            }
        
        return FirestoreAdventureListenerToken(registration: registration)
    }
    
    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft]
    ) async throws -> [AdventureAvailabilitySlot] {
        AdventurePlanner.buildAvailability(day: date, items: items)
    }
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        guard let plan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            items: request.items
        ) else {
            throw makeError("Invalid reservation configuration.")
        }
        
        let createdAt = Date()

        let bookingRef = db.collection(bookingsCollection).document()
        let dto = AdventureBookingDTO.from(
            bookingId: bookingRef.documentID,
            request: request,
            plan: plan,
            createdAt: createdAt
        )
        
        let encodedBooking = try Firestore.Encoder().encode(dto)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in            bookingRef.setData(encodedBooking) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        return dto.toDomain(documentId: bookingRef.documentID)
    }
    
    func cancelBooking(id: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(id)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            bookingRef.updateData(
                ["status": AdventureBookingStatus.canceled.rawValue]
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func getDocuments(query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: self.makeError("Failed to fetch inventory."))
                }
            }
        }
    }
    
    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "AdventureBookingsService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}
