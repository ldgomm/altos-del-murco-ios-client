//
//  OrdersView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrdersView: View {
    @ObservedObject var viewModel: OrdersViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedOrder: Order?
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

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
        ZStack {
            BrandScreenBackground(theme: .restaurant)
            content
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.large)
        .tint(palette.primary)
        .onAppear {
            viewModel.onEvent(.onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.orders.isEmpty {
            loadingView
        } else if let error = viewModel.state.errorMessage, viewModel.state.orders.isEmpty {
            stateCard(
                title: "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: error
            )
        } else if viewModel.state.orders.isEmpty {
            stateCard(
                title: "No orders yet",
                systemImage: "tray",
                description: "Orders will appear here once customers place them."
            )
        } else {
            ordersList
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView("Loading orders...")
                .tint(palette.primary)
                .foregroundStyle(palette.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func stateCard(
        title: String,
        systemImage: String,
        description: String
    ) -> some View {
        VStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(description)
            )
            .foregroundStyle(palette.textSecondary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .appCardStyle(.restaurant, emphasized: true)
        .padding()
    }

    private var ordersList: some View {
        List {
            summarySection

            ForEach(groupedOrders, id: \.status) { group in
                Section {
                    ForEach(group.orders) { order in
                        Button {
                            selectedOrder = order
                        } label: {
                            OrderRowView(order: order)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appListRowStyle(.restaurant)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    sectionHeader(for: group.status, count: group.orders.count)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable {
            viewModel.onEvent(.refresh)
        }
        .navigationDestination(item: $selectedOrder) { order in
            OrderDetailView(order: order)
        }
    }
 
    private var summarySection: some View {
        Section {
            OrdersSummaryView(orders: viewModel.state.orders)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle(.restaurant, emphasized: false)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 10, trailing: 8))
                .listRowBackground(Color.clear)
        } header: {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Overview",
                subtitle: "Track today’s and recent restaurant orders."
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
            .textCase(nil)
        }
    }

    private func sectionHeader(for status: OrderStatus, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(status.title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()

            BrandBadge(
                theme: .restaurant,
                title: "\(count)",
                selected: status == .pending || status == .preparing
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .textCase(nil)
    }
}
