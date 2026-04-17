//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseFirestore

final class FirebaseOrdersService: OrdersServiceable {
    private lazy var db = Firestore.firestore()
    
    func submit(order: Order) async throws {
        let quantitiesByMenuItemId = Dictionary(
            grouping: order.items,
            by: \.menuItemId
        )
        .compactMapValues { items in
            let total = items.reduce(0) { $0 + $1.quantity }
            return total > 0 ? total : nil
        }
        
        let _ = try await db.runTransaction { transaction, errorPointer in
            do {
                for (menuItemId, totalQuantity) in quantitiesByMenuItemId {
                    let ref = self.db
                        .collection(FirestoreConstants.restaurant_menu_items)
                        .document(menuItemId)
                    
                    let snapshot = try transaction.getDocument(ref)
                    let dto = try snapshot.data(as: MenuItemDto.self)
                    
                    guard dto.isAvailable else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "\(dto.name) no está disponible."]
                        )
                    }
                    
                    guard dto.remainingQuantity >= totalQuantity else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Ya no hay suficiente stock de \(dto.name)."]
                        )
                    }
                    
                    let newRemainingQuantity = dto.remainingQuantity - totalQuantity
                    
                    transaction.updateData([
                        "remainingQuantity": newRemainingQuantity,
                        "isAvailable": newRemainingQuantity > 0,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: ref)
                }
                
                let dto = OrderDto(from: order)
                let orderData = try Firestore.Encoder().encode(dto)
                
                let orderRef = self.db
                    .collection(FirestoreConstants.restaurant_orders)
                    .document(order.id)
                
                transaction.setData(orderData, forDocument: orderRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return nil
        }
    }
    
    func observeOrders(for nationalId: String) -> AsyncThrowingStream<[Order], Error> {
        let nationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return AsyncThrowingStream { continuation in
            guard !nationalId.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }
            
            let listener = db
                .collection(FirestoreConstants.restaurant_orders)
                .whereField("nationalId", isEqualTo: nationalId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }
                    
                    let orders: [Order] = documents.compactMap { document in
                        do {
                            let dto = try document.data(as: OrderDto.self)
                            return dto.toDomain()
                        } catch {
                            return nil
                        }
                    }
                    
                    continuation.yield(orders)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}

