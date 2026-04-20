//
//  OrdersView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

private enum OrdersGroupingOption: String, CaseIterable, Identifiable {
    case byDate = "Date"
    case byStatus = "Status"
    var id: String { rawValue }
}

private enum OrdersSortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Newest"
    case oldestFirst = "Oldest"
    case highestTotal = "Highest total"
    var id: String { rawValue }
}

private enum OrdersStatusFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case confirmed = "Confirmed"
    case preparing = "Preparing"
    case completed = "Completed"
    case canceled = "Canceled"

    var id: String { rawValue }

    var status: OrderStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .confirmed: return .confirmed
        case .preparing: return .preparing
        case .completed: return .completed
        case .canceled: return .canceled
        }
    }
}

private struct OrdersGroup: Identifiable {
    let id: String
    let title: String
    let orders: [Order]
}

struct OrdersView: View {
    @ObservedObject var viewModel: OrdersViewModel
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedOrder: Order?
    @State private var grouping: OrdersGroupingOption = .byDate
    @State private var sortOption: OrdersSortOption = .newestFirst
    @State private var statusFilter: OrdersStatusFilter = .all

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var filteredOrders: [Order] {
        viewModel.state.orders.filter { order in
            guard let filterStatus = statusFilter.status else { return true }
            return order.recalculatedStatus() == filterStatus
        }
    }

    private var sortedOrders: [Order] {
        switch sortOption {
        case .newestFirst:
            return filteredOrders.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return filteredOrders.sorted { $0.createdAt < $1.createdAt }
        case .highestTotal:
            return filteredOrders.sorted { $0.totalAmount > $1.totalAmount }
        }
    }

    private var groupedOrders: [OrdersGroup] {
        switch grouping {
        case .byStatus:
            let orderedStatuses: [OrderStatus] = [.pending, .confirmed, .preparing, .completed, .canceled]

            let buckets = Dictionary(grouping: sortedOrders) { $0.recalculatedStatus() }
            return orderedStatuses.compactMap { status in
                guard let orders = buckets[status], !orders.isEmpty else { return nil }
                return OrdersGroup(
                    id: status.rawValue,
                    title: status.title,
                    orders: orders
                )
            }

        case .byDate:
            let calendar = Calendar.current
            let buckets = Dictionary(grouping: sortedOrders) { calendar.startOfDay(for: $0.createdAt) }

            return buckets
                .map { day, orders in
                    OrdersGroup(
                        id: ISO8601DateFormatter().string(from: day),
                        title: dateTitle(for: day),
                        orders: sortInsideGroup(orders)
                    )
                }
                .sorted { lhs, rhs in
                    guard let lhsDate = lhs.orders.first?.createdAt,
                          let rhsDate = rhs.orders.first?.createdAt else {
                        return lhs.title > rhs.title
                    }

                    switch sortOption {
                    case .oldestFirst:
                        return lhsDate < rhsDate
                    case .newestFirst, .highestTotal:
                        return lhsDate > rhsDate
                    }
                }
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
            if let nationalId = sessionViewModel.authenticatedProfile?.nationalId {
                viewModel.setNationalId(nationalId)
            }
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
            controlsSection

            ForEach(groupedOrders) { group in
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
                    sectionHeader(title: group.title, count: group.orders.count)
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
            OrdersSummaryView(orders: filteredOrders)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle(.restaurant, emphasized: false)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 10, trailing: 8))
                .listRowBackground(Color.clear)
        } header: {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Overview",
                subtitle: "Track your orders with date grouping, filters and sorting."
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
            .textCase(nil)
        }
    }

    private var controlsSection: some View {
        Section {
            VStack(spacing: 14) {
                Picker("Group", selection: $grouping) {
                    ForEach(OrdersGroupingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Status", selection: $statusFilter) {
                    ForEach(OrdersStatusFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Picker("Sort", selection: $sortOption) {
                    ForEach(OrdersSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            .padding(.vertical, 4)
            .appCardStyle(.restaurant, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 10, trailing: 8))
            .listRowBackground(Color.clear)
        } header: {
            Text("Order tools")
                .font(.headline)
                .foregroundStyle(palette.textSecondary)
                .textCase(nil)
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()

            BrandBadge(
                theme: .restaurant,
                title: "\(count)",
                selected: true
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .textCase(nil)
    }

    private func sortInsideGroup(_ orders: [Order]) -> [Order] {
        switch sortOption {
        case .newestFirst:
            return orders.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return orders.sorted { $0.createdAt < $1.createdAt }
        case .highestTotal:
            return orders.sorted { $0.totalAmount > $1.totalAmount }
        }
    }

    private func dateTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}
