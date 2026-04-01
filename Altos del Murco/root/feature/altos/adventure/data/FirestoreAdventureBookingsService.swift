//
//  FirestoreAdventureBookingsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseFirestore

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
            .whereField("dayKey", isEqualTo: dayKey)
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
                    let bookings = try snapshot.documents.map {
                        try $0.data(as: AdventureBookingDTO.self).toDomain()
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
        packageType: AdventurePackageType,
        offRoadHours: Int,
        peopleCount: Int
    ) async throws -> [AdventureAvailabilitySlot] {
        let inventory = try await fetchInventoryMap(for: date)
        
        return AdventureAvailabilityBuilder.buildSlots(
            day: date,
            packageType: packageType,
            offRoadHours: offRoadHours,
            peopleCount: peopleCount,
            inventory: inventory
        )
    }
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        guard let plan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            packageType: request.packageType,
            offRoadHours: request.packageType.includesOffRoad ? request.offRoadHours : 0,
            peopleCount: request.peopleCount
        ) else {
            throw makeError("Invalid reservation configuration.")
        }
        
        let bookingRef = db.collection(bookingsCollection).document()
        let bookingId = bookingRef.documentID
        let createdAt = Date()
        let dto = AdventureBookingDTO.from(
            bookingId: bookingId,
            request: request,
            plan: plan,
            status: .confirmed,
            createdAt: createdAt
        )
        
        try await runVoidTransaction { transaction, errorPointer in
            do {
                for block in plan.blocks {
                    let slotIndices = AdventurePlanner.slotIndices(for: block, on: request.date)
                    
                    for slotIndex in slotIndices {
                        let inventoryRef = self.inventoryDocument(
                            dayKey: dto.dayKey,
                            activity: block.activity,
                            slotIndex: slotIndex
                        )
                        
                        let snapshot = try transaction.getDocument(inventoryRef)
                        let existingReserved = snapshot.data()?["reservedPeople"] as? Int ?? 0
                        let capacity = snapshot.data()?["capacity"] as? Int
                            ?? AdventureScheduleConfig.capacity(for: block.activity)
                        
                        guard existingReserved + request.peopleCount <= capacity else {
                            errorPointer?.pointee = self.makeError("This time slot is no longer available.")
                            return nil
                        }
                    }
                }
                
                for block in plan.blocks {
                    let slotIndices = AdventurePlanner.slotIndices(for: block, on: request.date)
                    
                    for slotIndex in slotIndices {
                        let inventoryRef = self.inventoryDocument(
                            dayKey: dto.dayKey,
                            activity: block.activity,
                            slotIndex: slotIndex
                        )
                        
                        let snapshot = try transaction.getDocument(inventoryRef)
                        let existingReserved = snapshot.data()?["reservedPeople"] as? Int ?? 0
                        let capacity = snapshot.data()?["capacity"] as? Int
                            ?? AdventureScheduleConfig.capacity(for: block.activity)
                        
                        let inventoryDTO = AdventureSlotInventoryDTO(
                            id: inventoryRef.documentID,
                            dayKey: dto.dayKey,
                            activityType: block.activity.rawValue,
                            slotIndex: slotIndex,
                            reservedPeople: existingReserved + request.peopleCount,
                            capacity: capacity,
                            updatedAt: Timestamp(date: createdAt)
                        )
                        
                        let encodedInventory = try Firestore.Encoder().encode(inventoryDTO)
                        transaction.setData(encodedInventory, forDocument: inventoryRef)
                    }
                }
                
                let encodedBooking = try Firestore.Encoder().encode(dto)
                transaction.setData(encodedBooking, forDocument: bookingRef)
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
        
        return dto.toDomain()
    }
    
    func cancelBooking(id: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(id)
        
        try await runVoidTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(bookingRef)
                
                guard snapshot.exists else {
                    errorPointer?.pointee = self.makeError("Booking not found.")
                    return nil
                }
                
                let dto = try snapshot.data(as: AdventureBookingDTO.self)
                let booking = dto.toDomain()
                
                guard booking.status != .canceled else {
                    return nil
                }
                
                for block in booking.blocks {
                    let slotIndices = AdventurePlanner.slotIndices(
                        for: block,
                        on: booking.startAt
                    )
                    
                    for slotIndex in slotIndices {
                        let inventoryRef = self.inventoryDocument(
                            dayKey: booking.dayKey,
                            activity: block.activity,
                            slotIndex: slotIndex
                        )
                        
                        let inventorySnapshot = try transaction.getDocument(inventoryRef)
                        let existingReserved = inventorySnapshot.data()?["reservedPeople"] as? Int ?? 0
                        let newReserved = max(0, existingReserved - booking.peopleCount)
                        let capacity = inventorySnapshot.data()?["capacity"] as? Int
                            ?? AdventureScheduleConfig.capacity(for: block.activity)
                        
                        let inventoryDTO = AdventureSlotInventoryDTO(
                            id: inventoryRef.documentID,
                            dayKey: booking.dayKey,
                            activityType: block.activity.rawValue,
                            slotIndex: slotIndex,
                            reservedPeople: newReserved,
                            capacity: capacity,
                            updatedAt: Timestamp(date: Date())
                        )
                        
                        let encodedInventory = try Firestore.Encoder().encode(inventoryDTO)
                        transaction.setData(encodedInventory, forDocument: inventoryRef)
                    }
                }
                
                transaction.updateData([
                    "status": AdventureBookingStatus.canceled.rawValue
                ], forDocument: bookingRef)
                
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }
    
    // MARK: - Private
    
    private func inventoryDocument(
        dayKey: String,
        activity: AdventureActivityType,
        slotIndex: Int
    ) -> DocumentReference {
        db.collection(inventoryCollection)
            .document("\(dayKey)_\(activity.rawValue)_\(slotIndex)")
    }
    
    private func fetchInventoryMap(for day: Date) async throws -> [AdventureInventoryKey: Int] {
        let dayKey = AdventureDateHelper.dayKey(from: day)
        
        let snapshot = try await getDocuments(
            query: db.collection(inventoryCollection)
                .whereField("dayKey", isEqualTo: dayKey)
        )
        
        var map: [AdventureInventoryKey: Int] = [:]
        
        for document in snapshot.documents {
            let dto = try document.data(as: AdventureSlotInventoryDTO.self)
            guard let activity = AdventureActivityType(rawValue: dto.activityType) else { continue }
            map[AdventureInventoryKey(activity: activity, slotIndex: dto.slotIndex)] = dto.reservedPeople
        }
        
        return map
    }
    
    private func getDocuments(query: Query) async throws -> QuerySnapshot {
        try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    continuation.resume(throwing: self.makeError("Could not fetch documents."))
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
}
