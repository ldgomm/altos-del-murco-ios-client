//
//  OrderSuccessView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderSuccessView: View {
    let order: Order
    
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            
            VStack(spacing: 8) {
                Text("Order Sent")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your order was created successfully.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            VStack(spacing: 12) {
                InfoRow(title: "Order ID", value: String(order.id.prefix(7)))
                InfoRow(title: "Client", value: order.clientName)
                InfoRow(title: "Table", value: order.tableNumber)
                InfoRow(title: "Status", value: order.status.title)
                InfoRow(
                    title: "Time",
                    value: order.createdAt.formatted(date: .omitted, time: .shortened)
                )
                InfoRow(title: "Total", value: order.totalAmount.priceText)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            
            Button {
                router.goToRoot()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Success")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}
