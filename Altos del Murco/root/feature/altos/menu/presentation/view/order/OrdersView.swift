//
//  OrdersView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrdersView: View {
    @ObservedObject var viewModel: OrdersViewModel

    private var groupedOrders: [(status: OrderStatus, orders: [Order])] {
        let grouped = Dictionary(grouping: viewModel.state.orders) { $0.status }

        let orderedStatuses: [OrderStatus] = [
            .pending,
            .confirmed,
            .preparing,
            .completed,
            .canceled
        ]

        return orderedStatuses.compactMap { status in
            guard let orders = grouped[status], !orders.isEmpty else { return nil }
            return (status, orders.sorted { $0.createdAt > $1.createdAt })
        }
    }

    var body: some View {
        Group {
            if viewModel.state.isLoading && viewModel.state.orders.isEmpty {
                ProgressView("Loading orders...")
            } else if let error = viewModel.state.errorMessage, viewModel.state.orders.isEmpty {
                ContentUnavailableView(
                    "Something went wrong",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if viewModel.state.orders.isEmpty {
                ContentUnavailableView(
                    "No orders yet",
                    systemImage: "tray",
                    description: Text("Orders will appear here once customers place them.")
                )
            } else {
                List {
                    ForEach(groupedOrders, id: \.status) { group in
                        Section {
                            ForEach(group.orders) { order in
                                OrderRowView(order: order)
                            }
                        } header: {
                            HStack {
                                Text(group.status.title)
                                Spacer()
                                Text("\(group.orders.count)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Orders")
        .onAppear {
            viewModel.onEvent(.onAppear)
        }
    }
}
