//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import FirebaseFirestore

final class OrdersService: OrdersServiceable {
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
        
        let menuItemsToProcess: [(ref: DocumentReference, totalQuantity: Int)] =
        quantitiesByMenuItemId.map { menuItemId, totalQuantity in
            (
                ref: self.db
                    .collection(FirestoreConstants.restaurant_menu_items)
                    .document(menuItemId),
                totalQuantity: totalQuantity
            )
        }
        
        let _ = try await db.runTransaction { transaction, errorPointer in
            do {
                // 1. Leer TODO primero
                var loadedItems: [(ref: DocumentReference, dto: MenuItemDto, totalQuantity: Int)] = []
                
                for item in menuItemsToProcess {
                    let snapshot = try transaction.getDocument(item.ref)
                    let dto = try snapshot.data(as: MenuItemDto.self)
                    
                    loadedItems.append((
                        ref: item.ref,
                        dto: dto,
                        totalQuantity: item.totalQuantity
                    ))
                }
                
                // 2. Validar y escribir DESPUÉS
                for item in loadedItems {
                    guard item.dto.isAvailable else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "\(item.dto.name) no está disponible."
                            ]
                        )
                    }
                    
                    guard item.dto.remainingQuantity >= item.totalQuantity else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 2,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Ya no hay suficiente stock de \(item.dto.name)."
                            ]
                        )
                    }
                    
                    let newRemainingQuantity = item.dto.remainingQuantity - item.totalQuantity
                    
                    transaction.updateData([
                        "remainingQuantity": newRemainingQuantity,
                        "isAvailable": newRemainingQuantity > 0,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: item.ref)
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
