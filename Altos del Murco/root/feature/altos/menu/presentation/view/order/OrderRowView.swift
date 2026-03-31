//
//  OrderRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderRowView: View {
    let order: Order
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(order.clientName)
                    .font(.headline)
                
                Spacer()
                
                Text(order.status.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(order.status.badgeColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            HStack {
                Text("Table \(order.tableNumber)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(order.createdAt.elapsedTimeText())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("\(order.totalItems) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(order.totalAmount.priceText)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            if order.createdAt.elapsedMinutes() >= 20 && order.status != .completed && order.status != .canceled {
                Text("Older order")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 6)
    }
}
