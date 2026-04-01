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
            nightPremium: plan.nightPremium,
            totalAmount: plan.totalAmount,
            status: AdventureBookingStatus.confirmed.rawValue,
            createdAt: Timestamp(date: createdAt),
            notes: request.notes
        )
    }
}

struct AdventureInventoryDTO: Codable {
    @DocumentID var id: String?
    
    let dayKey: String
    let resourceType: String
    let slotIndex: Int
    let reservedUnits: Int
    let capacity: Int
    let updatedAt: Timestamp
}


final class FirestoreAdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = "adventure_bookings"
    private let inventoryCollection = "adventure_slot_inventory"
    
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
        let inventory = try await fetchInventoryMap(for: date, items: items)
        return AdventurePlanner.buildAvailability(day: date, items: items, inventory: inventory)
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
        
        let deltas = aggregatedInventoryDeltas(from: plan.blocks)
        
        try await runVoidTransaction { transaction, errorPointer in
            do {
                // 1) READ EVERYTHING FIRST
                var currentReservedByKey: [AdventureInventoryKey: Int] = [:]
                var capacityByKey: [AdventureInventoryKey: Int] = [:]
                
                for key in deltas.keys {
                    let ref = self.inventoryDocument(for: key)
                    let snapshot = try transaction.getDocument(ref)
                    
                    currentReservedByKey[key] = snapshot.data()?["reservedUnits"] as? Int ?? 0
                    capacityByKey[key] = snapshot.data()?["capacity"] as? Int
                        ?? AdventureSchedule.capacity(for: key.resourceType)
                }
                
                // 2) VALIDATE
                for (key, delta) in deltas {
                    let currentReserved = currentReservedByKey[key] ?? 0
                    let capacity = capacityByKey[key]
                        ?? AdventureSchedule.capacity(for: key.resourceType)
                    
                    guard currentReserved + delta <= capacity else {
                        errorPointer?.pointee = self.makeError("This time slot is no longer available.")
                        return nil
                    }
                }
                
                // 3) WRITE INVENTORY
                for (key, delta) in deltas {
                    let ref = self.inventoryDocument(for: key)
                    let currentReserved = currentReservedByKey[key] ?? 0
                    let capacity = capacityByKey[key]
                        ?? AdventureSchedule.capacity(for: key.resourceType)
                    
                    let inventoryDTO = AdventureInventoryDTO(
                        id: ref.documentID,
                        dayKey: key.dayKey,
                        resourceType: key.resourceType.rawValue,
                        slotIndex: key.slotIndex,
                        reservedUnits: currentReserved + delta,
                        capacity: capacity,
                        updatedAt: Timestamp(date: createdAt)
                    )
                    
                    let encodedInventory = try Firestore.Encoder().encode(inventoryDTO)
                    transaction.setData(encodedInventory, forDocument: ref)
                }
                
                // 4) WRITE BOOKING
                let encodedBooking = try Firestore.Encoder().encode(dto)
                transaction.setData(encodedBooking, forDocument: bookingRef)
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        return dto.toDomain(documentId: bookingRef.documentID)
    }
    
    func cancelBooking(id: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(id)
        
        try await runVoidTransaction { transaction, errorPointer in
            do {
                // 1) READ BOOKING FIRST
                let bookingSnapshot = try transaction.getDocument(bookingRef)
                guard bookingSnapshot.exists else {
                    errorPointer?.pointee = self.makeError("Booking not found.")
                    return nil
                }
                
                let dto = try bookingSnapshot.data(as: AdventureBookingDTO.self)
                let booking = dto.toDomain(documentId: bookingRef.documentID)
                
                guard booking.status != .canceled else {
                    return nil
                }
                
                let deltas = self.aggregatedInventoryDeltas(from: booking.blocks)
                
                // 2) READ ALL INVENTORY DOCS BEFORE ANY WRITE
                var currentReservedByKey: [AdventureInventoryKey: Int] = [:]
                var capacityByKey: [AdventureInventoryKey: Int] = [:]
                
                for key in deltas.keys {
                    let ref = self.inventoryDocument(for: key)
                    let snapshot = try transaction.getDocument(ref)
                    
                    currentReservedByKey[key] = snapshot.data()?["reservedUnits"] as? Int ?? 0
                    capacityByKey[key] = snapshot.data()?["capacity"] as? Int
                        ?? AdventureSchedule.capacity(for: key.resourceType)
                }
                
                // 3) WRITE INVENTORY
                for (key, delta) in deltas {
                    let ref = self.inventoryDocument(for: key)
                    let currentReserved = currentReservedByKey[key] ?? 0
                    let capacity = capacityByKey[key]
                        ?? AdventureSchedule.capacity(for: key.resourceType)
                    
                    let inventoryDTO = AdventureInventoryDTO(
                        id: ref.documentID,
                        dayKey: key.dayKey,
                        resourceType: key.resourceType.rawValue,
                        slotIndex: key.slotIndex,
                        reservedUnits: max(0, currentReserved - delta),
                        capacity: capacity,
                        updatedAt: Timestamp(date: Date())
                    )
                    
                    let encodedInventory = try Firestore.Encoder().encode(inventoryDTO)
                    transaction.setData(encodedInventory, forDocument: ref)
                }
                
                // 4) WRITE BOOKING STATUS
                transaction.updateData(
                    ["status": AdventureBookingStatus.canceled.rawValue],
                    forDocument: bookingRef
                )
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    // MARK: - Helpers
    
    private func fetchInventoryMap(
        for date: Date,
        items: [AdventureReservationItemDraft]
    ) async throws -> [AdventureInventoryKey: Int] {
        let dayKeys = AdventurePlanner.affectedDayKeys(day: date, items: items)
        var result: [AdventureInventoryKey: Int] = [:]
        
        for dayKey in dayKeys {
            let snapshot = try await getDocuments(
                query: db.collection(inventoryCollection)
                    .whereField("dayKey", isEqualTo: dayKey)
            )
            
            for doc in snapshot.documents {
                let dto = try doc.data(as: AdventureInventoryDTO.self)
                guard let resourceType = AdventureResourceType(rawValue: dto.resourceType) else { continue }
                
                result[
                    AdventureInventoryKey(
                        dayKey: dto.dayKey,
                        resourceType: resourceType,
                        slotIndex: dto.slotIndex
                    )
                ] = dto.reservedUnits
            }
        }
        
        return result
    }
    
    private func inventoryDocument(
        dayKey: String,
        resourceType: AdventureResourceType,
        slotIndex: Int
    ) -> DocumentReference {
        db.collection(inventoryCollection)
            .document("\(dayKey)_\(resourceType.rawValue)_\(slotIndex)")
    }
    
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
    
    private func runVoidTransaction(
        _ updateBlock: @escaping (Transaction, NSErrorPointer) -> Any?
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.runTransaction(updateBlock) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
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
    
    private func aggregatedInventoryDeltas(
        from blocks: [AdventureBookingBlock]
    ) -> [AdventureInventoryKey: Int] {
        var deltas: [AdventureInventoryKey: Int] = [:]
        
        for block in blocks {
            for key in AdventurePlanner.inventoryKeys(for: block) {
                deltas[key, default: 0] += block.reservedUnits
            }
        }
        
        return deltas
    }

    private func inventoryDocument(
        for key: AdventureInventoryKey
    ) -> DocumentReference {
        db.collection(inventoryCollection)
            .document("\(key.dayKey)_\(key.resourceType.rawValue)_\(key.slotIndex)")
    }
}

