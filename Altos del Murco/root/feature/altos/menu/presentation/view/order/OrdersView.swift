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
        let grouped = Dictionary(grouping: viewModel.state.orders) { $0.recalculatedStatus() }

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
        content
            .navigationTitle("Orders")
            .onAppear {
                viewModel.onEvent(.onAppear)
            }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.orders.isEmpty {
            ProgressView("Loading orders...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            ordersList
        }
    }

    private var ordersList: some View {
        List {
            summarySection

            ForEach(groupedOrders, id: \.status) { group in
                Section {
                    ForEach(group.orders) { order in
                        NavigationLink {
                            OrderDetailView(order: order)
                        } label: {
                            OrderRowView(order: order)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    HStack {
                        Text(group.status.title)
                        Spacer()
                        Text("\(group.orders.count)")
                            .foregroundStyle(.secondary)
                    }
                    .textCase(nil)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.onEvent(.refresh)
        }
    }

    private var summarySection: some View {
        Section {
            OrdersSummaryView(orders: viewModel.state.orders)
                .frame(maxWidth: .infinity, alignment: .leading)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                .listRowBackground(Color.clear)
        }
    }
}
