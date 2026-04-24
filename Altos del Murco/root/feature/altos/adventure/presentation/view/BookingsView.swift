//
//  BookingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

private enum PremiumReservationFilter: String, CaseIterable, Identifiable {
    case upcoming
    case past
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .upcoming: return "Próximas"
        case .past: return "Pasadas"
        case .cancelled: return "Canceladas"
        }
    }
}

private enum UnifiedReservation: Identifiable, Hashable {
    case restaurant(Order)
    case experience(AdventureBooking)

    var id: String {
        switch self {
        case .restaurant(let order): return "restaurant-\(order.id)"
        case .experience(let booking): return "experience-\(booking.id)"
        }
    }

    var title: String {
        switch self {
        case .restaurant: return "Pedido restaurante"
        case .experience(let booking): return booking.visitTypeTitle
        }
    }

    var subtitle: String {
        switch self {
        case .restaurant(let order): return "\(order.totalItems) item(s) • Mesa \(order.tableNumber)"
        case .experience(let booking): return "\(booking.eventDisplayTitle) • \(booking.guestCount) invitado(s)"
        }
    }

    var date: Date {
        switch self {
        case .restaurant(let order): return order.createdAt
        case .experience(let booking): return booking.startAt
        }
    }

    var total: Double {
        switch self {
        case .restaurant(let order): return order.totalAmount
        case .experience(let booking): return booking.totalAmount
        }
    }

    var statusText: String {
        switch self {
        case .restaurant(let order): return order.status.title
        case .experience(let booking): return booking.status.title
        }
    }

    var systemImage: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .experience: return "mountain.2.fill"
        }
    }

    var isCancelled: Bool {
        switch self {
        case .restaurant(let order): return order.status == .canceled
        case .experience(let booking): return booking.status == .canceled
        }
    }

    var isCompleted: Bool {
        switch self {
        case .restaurant(let order): return order.status == .completed
        case .experience(let booking): return booking.status == .completed
        }
    }
}

struct BookingsView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    @StateObject private var adventureBookingsViewModel: AdventureBookingsViewModel
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel

    @State private var selectedFilter: PremiumReservationFilter = .upcoming

    init(
        ordersViewModel: OrdersViewModel,
        adventureModuleFactory: AdventureModuleFactory
    ) {
        self.ordersViewModel = ordersViewModel
        _adventureBookingsViewModel = StateObject(wrappedValue: adventureModuleFactory.makeBookingsViewModel())
    }

    private var profile: ClientProfile? { sessionViewModel.authenticatedProfile }

    private var allReservations: [UnifiedReservation] {
        ordersViewModel.state.orders.map(UnifiedReservation.restaurant) +
        adventureBookingsViewModel.state.allBookings.map(UnifiedReservation.experience)
    }

    private var filteredReservations: [UnifiedReservation] {
        let now = Date()
        return allReservations
            .filter { item in
                switch selectedFilter {
                case .upcoming:
                    return !item.isCancelled && !item.isCompleted && item.date >= now
                case .past:
                    return !item.isCancelled && (item.isCompleted || item.date < now)
                case .cancelled:
                    return item.isCancelled
                }
            }
            .sorted { lhs, rhs in
                switch selectedFilter {
                case .upcoming: return lhs.date < rhs.date
                case .past, .cancelled: return lhs.date > rhs.date
                }
            }
    }

    private var groupedReservations: [(date: Date, reservations: [UnifiedReservation])] {
        let grouped = Dictionary(grouping: filteredReservations) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { (date: $0.key, reservations: $0.value) }
            .sorted { lhs, rhs in
                switch selectedFilter {
                case .upcoming: return lhs.date < rhs.date
                case .past, .cancelled: return lhs.date > rhs.date
                }
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 20) {
                    PremiumSectionHeader(
                        title: "Reservas",
                        subtitle: "Tu agenda completa: pedidos del restaurante y experiencias en un solo lugar.",
                        systemImage: "calendar"
                    )

                    metricsSection
                    filterSection
                    contentSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Reservas")
            .appScreenStyle(.neutral)
        }
        .onAppear {
            if let nationalId = profile?.nationalId {
                ordersViewModel.setNationalId(nationalId)
                ordersViewModel.onEvent(.onAppear)
                adventureBookingsViewModel.setNationalId(nationalId)
            }
            adventureBookingsViewModel.onAppear()
        }
        .onDisappear {
            adventureBookingsViewModel.onDisappear()
        }
    }

    private var metricsSection: some View {
        let now = Date()
        return HStack(spacing: 12) {
            PremiumMetricTile(
                title: "Próximas",
                value: "\(allReservations.filter { !$0.isCancelled && !$0.isCompleted && $0.date >= now }.count)",
                systemImage: "clock.badge.checkmark"
            )
            PremiumMetricTile(
                title: "Pasadas",
                value: "\(allReservations.filter { !$0.isCancelled && ($0.isCompleted || $0.date < now) }.count)",
                systemImage: "checkmark.circle.fill"
            )
            PremiumMetricTile(
                title: "Canceladas",
                value: "\(allReservations.filter(\.isCancelled).count)",
                systemImage: "xmark.circle.fill"
            )
        }
    }

    private var filterSection: some View {
        Picker("Filtro", selection: $selectedFilter) {
            ForEach(PremiumReservationFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var contentSection: some View {
        if filteredReservations.isEmpty {
            PremiumCard {
                PremiumIconBubble(systemImage: "calendar.badge.exclamationmark", selected: true)
                Text("No hay reservas en \(selectedFilter.title.lowercased())")
                    .font(.headline)
                Text("Cuando hagas pedidos o reserves experiencias, aparecerán aquí agrupadas por fecha.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } else {
            ForEach(groupedReservations, id: \.date) { group in
                VStack(alignment: .leading, spacing: 12) {
                    PremiumSectionHeader(
                        title: group.date.longReservationDate,
                        subtitle: "\(group.reservations.count) movimiento(s)",
                        systemImage: "calendar"
                    )

                    ForEach(group.reservations) { reservation in
                        UnifiedReservationCard(reservation: reservation)
                    }
                }
            }
        }
    }
}

private struct UnifiedReservationCard: View {
    let reservation: UnifiedReservation

    var body: some View {
        PremiumCard {
            HStack(alignment: .top, spacing: 12) {
                PremiumIconBubble(systemImage: reservation.systemImage, selected: reservation.systemImage.contains("mountain"))

                VStack(alignment: .leading, spacing: 5) {
                    Text(reservation.title)
                        .font(.headline)
                    Text(reservation.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text(reservation.statusText)
                            .font(.caption.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12), in: Capsule())
                        Text(reservation.date.shortTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(reservation.total.priceText)
                    .font(.headline.bold())
                    .foregroundStyle(.green)
            }
        }
    }
}

private extension Date {
    var longReservationDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateFormat = "EEEE d 'de' MMMM"
        let text = formatter.string(from: self)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    var shortTime: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: self)
    }
}
