//
//  LiveOrderDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/5/26.
//

import SwiftUI

struct LiveOrderDetailView: View {
    let orderId: String
    let fallbackOrder: Order

    @ObservedObject var ordersViewModel: OrdersViewModel

    private var liveOrder: Order {
        ordersViewModel.state.orders.first { $0.id == orderId } ?? fallbackOrder
    }

    var body: some View {
        OrderDetailView(order: liveOrder)
            .onAppear {
                ordersViewModel.onEvent(.onAppear)
            }
    }
}
