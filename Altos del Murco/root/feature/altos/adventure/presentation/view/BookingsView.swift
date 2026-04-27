//
//  BookingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

private enum BookingsTimelineScope: String, CaseIterable, Identifiable {
    case today
    case upcoming
    case history
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Hoy"
        case .upcoming: return "Próximas"
        case .history: return "Historial"
        case .all: return "Todas"
        }
    }

    var shortTitle: String {
        switch self {
        case .today: return "Hoy"
        case .upcoming: return "Próximas"
        case .history: return "Historial"
        case .all: return "Todas"
        }
    }

    var subtitle: String {
        switch self {
        case .today:
            return "Pedidos y reservas que deben atenderse hoy."
        case .upcoming:
            return "Reservas futuras de restaurante, aventura o eventos."
        case .history:
            return "Reservas pasadas, completadas o canceladas."
        case .all:
            return "Agenda completa de tus pedidos y experiencias."
        }
    }

    var systemImage: String {
        switch self {
        case .today: return "calendar.badge.clock"
        case .upcoming: return "calendar.badge.plus"
        case .history: return "clock.arrow.circlepath"
        case .all: return "tray.full"
        }
    }
}

private enum BookingsGroupingOption: String, CaseIterable, Identifiable {
    case byDate
    case byStatus
    case byType

    var id: String { rawValue }

    var title: String {
        switch self {
        case .byDate: return "Fecha"
        case .byStatus: return "Estado"
        case .byType: return "Tipo"
        }
    }
}

private enum BookingsSortOption: String, CaseIterable, Identifiable {
    case serviceTimeAscending
    case serviceTimeDescending
    case newestCreated
    case highestTotal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .serviceTimeAscending: return "Más cercana"
        case .serviceTimeDescending: return "Más lejana"
        case .newestCreated: return "Más reciente"
        case .highestTotal: return "Mayor total"
        }
    }
}

private enum UnifiedReservationStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case confirmed
    case preparing
    case completed
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todo"
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .preparing: return "Preparando"
        case .completed: return "Completada"
        case .canceled: return "Cancelada"
        }
    }

    func matches(_ reservation: UnifiedReservation) -> Bool {
        switch self {
        case .all:
            return true
        case .pending:
            return reservation.normalizedStatus == .pending
        case .confirmed:
            return reservation.normalizedStatus == .confirmed
        case .preparing:
            return reservation.normalizedStatus == .preparing
        case .completed:
            return reservation.normalizedStatus == .completed
        case .canceled:
            return reservation.normalizedStatus == .canceled
        }
    }
}

private enum UnifiedReservationStatus: String, CaseIterable, Identifiable {
    case pending
    case confirmed
    case preparing
    case completed
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .preparing: return "Preparando"
        case .completed: return "Completada"
        case .canceled: return "Cancelada"
        }
    }

    var systemImage: String {
        switch self {
        case .pending: return "hourglass"
        case .confirmed: return "checkmark.seal.fill"
        case .preparing: return "flame.fill"
        case .completed: return "checkmark.circle.fill"
        case .canceled: return "xmark.circle.fill"
        }
    }
}

private enum UnifiedReservationKind: String, CaseIterable, Identifiable {
    case restaurant
    case adventure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .adventure: return "Aventura"
        }
    }

    var subtitle: String {
        switch self {
        case .restaurant: return "Pedidos y reservas de comida"
        case .adventure: return "Experiencias, eventos y combos"
        }
    }

    var systemImage: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .adventure: return "mountain.2.fill"
        }
    }

    var theme: AppSectionTheme {
        switch self {
        case .restaurant: return .restaurant
        case .adventure: return .adventure
        }
    }
}

private enum UnifiedReservation: Identifiable, Hashable {
    case restaurant(Order)
    case adventure(AdventureBooking)

    var id: String {
        switch self {
        case .restaurant(let order): return "restaurant-\(order.id)"
        case .adventure(let booking): return "adventure-\(booking.id)"
        }
    }

    var kind: UnifiedReservationKind {
        switch self {
        case .restaurant: return .restaurant
        case .adventure: return .adventure
        }
    }

    var title: String {
        switch self {
        case .restaurant(let order):
            return order.isScheduledForLater ? "Reserva de comida" : "Pedido restaurante"
        case .adventure(let booking):
            return booking.visitTypeTitle
        }
    }

    var subtitle: String {
        switch self {
        case .restaurant(let order):
            return "\(order.totalItems) item(s) • Mesa \(order.tableNumber)"
        case .adventure(let booking):
            return "\(booking.eventDisplayTitle) • \(booking.guestCount) invitado(s)"
        }
    }

    var clientName: String {
        switch self {
        case .restaurant(let order):
            return order.clientName.isEmpty ? "Cliente" : order.clientName
        case .adventure(let booking):
            return booking.clientName.isEmpty ? "Cliente" : booking.clientName
        }
    }

    var serviceDate: Date {
        switch self {
        case .restaurant(let order): return order.scheduledAt
        case .adventure(let booking): return booking.startAt
        }
    }

    var endDate: Date {
        switch self {
        case .restaurant(let order):
            return Calendar.current.date(byAdding: .minute, value: 90, to: order.scheduledAt) ?? order.scheduledAt
        case .adventure(let booking):
            return booking.endAt
        }
    }

    var createdAt: Date {
        switch self {
        case .restaurant(let order): return order.createdAt
        case .adventure(let booking): return booking.createdAt
        }
    }

    var total: Double {
        switch self {
        case .restaurant(let order): return order.totalAmount
        case .adventure(let booking): return booking.totalAmount
        }
    }

    var normalizedStatus: UnifiedReservationStatus {
        switch self {
        case .restaurant(let order):
            switch order.recalculatedStatus() {
            case .pending: return .pending
            case .confirmed: return .confirmed
            case .preparing: return .preparing
            case .completed: return .completed
            case .canceled: return .canceled
            }

        case .adventure(let booking):
            switch booking.status {
            case .pending: return .pending
            case .confirmed: return .confirmed
            case .completed: return .completed
            case .canceled: return .canceled
            }
        }
    }

    var isTerminal: Bool {
        normalizedStatus == .completed || normalizedStatus == .canceled
    }

    var isCanceled: Bool {
        normalizedStatus == .canceled
    }

    var searchableText: String {
        switch self {
        case .restaurant(let order):
            return [
                order.id,
                order.clientName,
                order.tableNumber,
                order.nationalId ?? "",
                order.serviceMode.title,
                order.items.map(\.name).joined(separator: " ")
            ]
            .joined(separator: " ")
            .lowercased()

        case .adventure(let booking):
            return [
                booking.id,
                booking.clientName,
                booking.whatsappNumber,
                booking.nationalId,
                booking.eventDisplayTitle,
                booking.visitTypeTitle,
                booking.items.map(\.title).joined(separator: " "),
                booking.foodReservation?.items.map(\.name).joined(separator: " ") ?? ""
            ]
            .joined(separator: " ")
            .lowercased()
        }
    }

    func occurs(on day: Date, calendar: Calendar) -> Bool {
        let startOfDay = calendar.startOfDay(for: day)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        return serviceDate < nextDay && endDate >= startOfDay
    }
}

private struct UnifiedReservationsGroup: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let reservations: [UnifiedReservation]
}

struct BookingsView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    @StateObject private var adventureBookingsViewModel: AdventureBookingsViewModel

    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var selectedScope: BookingsTimelineScope = .today
    @State private var grouping: BookingsGroupingOption = .byDate
    @State private var sortOption: BookingsSortOption = .serviceTimeAscending
    @State private var statusFilter: UnifiedReservationStatusFilter = .all
    @State private var selectedReservation: UnifiedReservation?
    @State private var adventureBookingToCancel: AdventureBooking?

    private let calendar = Calendar.current

    init(
        ordersViewModel: OrdersViewModel,
        adventureModuleFactory: AdventureModuleFactory
    ) {
        self.ordersViewModel = ordersViewModel
        _adventureBookingsViewModel = StateObject(
            wrappedValue: adventureModuleFactory.makeBookingsViewModel()
        )
    }

    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    private var profile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    private var isLoading: Bool {
        ordersViewModel.state.isLoading || adventureBookingsViewModel.state.isLoading
    }

    private var allReservations: [UnifiedReservation] {
        ordersViewModel.state.orders.map(UnifiedReservation.restaurant)
        + adventureBookingsViewModel.state.allBookings.map(UnifiedReservation.adventure)
    }

    private var visibleReservations: [UnifiedReservation] {
        sortedReservations(filteredReservations(scopedReservations))
    }

    private var scopedReservations: [UnifiedReservation] {
        let now = Date()
        let today = calendar.startOfDay(for: now)

        return allReservations.filter { reservation in
            let serviceDay = calendar.startOfDay(for: reservation.serviceDate)
            let isFutureDay = serviceDay > today
            let isPastServiceDay = reservation.endDate < today

            switch selectedScope {
            case .today:
                return !reservation.isTerminal && reservation.occurs(on: today, calendar: calendar)

            case .upcoming:
                return !reservation.isTerminal && isFutureDay

            case .history:
                return reservation.isTerminal || isPastServiceDay

            case .all:
                return true
            }
        }
    }

    private var groupedReservations: [UnifiedReservationsGroup] {
        switch grouping {
        case .byDate:
            return groupedByDate(visibleReservations)
        case .byStatus:
            return groupedByStatus(visibleReservations)
        case .byType:
            return groupedByType(visibleReservations)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && allReservations.isEmpty {
                    loadingView
                } else {
                    contentView
                }
            }
            .navigationTitle("Reservas")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar por cliente, cédula, plato o actividad"
            )
            .navigationDestination(item: $selectedReservation) { reservation in
                switch reservation {
                case .restaurant(let order):
                    OrderDetailView(order: order)

                case .adventure(let booking):
                    ReserveViewDetail(
                        booking: booking,
                        onCancel: booking.status != .canceled
                            ? { adventureBookingsViewModel.cancelBooking(booking.id) }
                            : nil
                    )
                }
            }
            .confirmationDialog(
                "Cancelar reserva",
                isPresented: Binding(
                    get: { adventureBookingToCancel != nil },
                    set: { isPresented in
                        if !isPresented { adventureBookingToCancel = nil }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Sí, cancelar", role: .destructive) {
                    if let adventureBookingToCancel {
                        adventureBookingsViewModel.cancelBooking(adventureBookingToCancel.id)
                    }

                    adventureBookingToCancel = nil
                }

                Button("No", role: .cancel) {
                    adventureBookingToCancel = nil
                }
            } message: {
                Text("Esta acción marcará la reserva de aventura como cancelada.")
            }
            .alert(
                "Mensaje",
                isPresented: Binding(
                    get: {
                        adventureBookingsViewModel.state.errorMessage != nil
                        || adventureBookingsViewModel.state.successMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            adventureBookingsViewModel.dismissMessage()
                        }
                    }
                )
            ) {
                Button("OK") {
                    adventureBookingsViewModel.dismissMessage()
                }
            } message: {
                Text(
                    adventureBookingsViewModel.state.errorMessage
                    ?? adventureBookingsViewModel.state.successMessage
                    ?? ""
                )
            }
            .onAppear {
                syncNationalIdFromSession(forceRefresh: false)
            }
            .onChange(of: profile?.nationalId) { _, _ in
                syncNationalIdFromSession(forceRefresh: true)
            }
            .onDisappear {
                adventureBookingsViewModel.onDisappear()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(palette.primary)

            Text("Cargando tus reservas...")
                .font(.headline)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenStyle(.neutral)
    }

    private var contentView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 18) {
                heroCard
                scopePicker
                metricsSection
                controlsSection

                if let orderError = ordersViewModel.state.errorMessage {
                    errorBanner(orderError)
                }

                if let adventureError = adventureBookingsViewModel.state.errorMessage {
                    errorBanner(adventureError)
                }

                if visibleReservations.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedReservations) { group in
                        reservationsSection(group)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .appScreenStyle(.neutral)
        .refreshable {
            syncNationalIdFromSession(forceRefresh: true)
        }
    }

    private func syncNationalIdFromSession(forceRefresh: Bool) {
        guard let nationalId = profile?.nationalId else {
            return
        }

        ordersViewModel.setNationalId(nationalId)
        adventureBookingsViewModel.setNationalId(nationalId)

        ordersViewModel.onEvent(forceRefresh ? .refresh : .onAppear)
        adventureBookingsViewModel.onAppear()
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: .neutral,
                    systemImage: selectedScope.systemImage,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 5) {
                    Text(selectedScope.title)
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(selectedScope.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                infoPill("Visibles", "\(visibleReservations.count)")
                infoPill("Pendientes", "\(count(status: .pending, in: visibleReservations))")
                infoPill("Total", visibleReservations.visibleTotal.priceText)
            }
        }
        .appCardStyle(.neutral, emphasized: false)
    }

    private var scopePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Agenda",
                subtitle: "Elige qué parte de tus reservas quieres revisar."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(BookingsTimelineScope.allCases) { scope in
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                selectedScope = scope

                                if scope == .upcoming {
                                    grouping = .byDate
                                    sortOption = .serviceTimeAscending
                                }

                                if scope == .history {
                                    sortOption = .serviceTimeDescending
                                }
                            }
                        } label: {
                            Label(scope.shortTitle, systemImage: scope.systemImage)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(selectedScope == scope ? palette.primary : palette.textSecondary)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedScope == scope ? palette.primary.opacity(0.16) : palette.elevatedCard)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedScope == scope ? palette.primary.opacity(0.55) : palette.stroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .appCardStyle(.neutral)
    }

    private var metricsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricCard(
                title: "Hoy",
                value: "\(todayCount)",
                subtitle: "Por atender",
                systemImage: "sun.max.fill",
                tint: .orange
            )

            metricCard(
                title: "Próximas",
                value: "\(upcomingCount)",
                subtitle: "Futuras",
                systemImage: "calendar.badge.plus",
                tint: .green
            )

            metricCard(
                title: "Historial",
                value: "\(historyCount)",
                subtitle: "Pasadas o cerradas",
                systemImage: "clock.arrow.circlepath",
                tint: .blue
            )

            metricCard(
                title: "Canceladas",
                value: "\(canceledCount)",
                subtitle: "No activas",
                systemImage: "xmark.circle.fill",
                tint: .red
            )
        }
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Organizar",
                subtitle: "\(visibleReservations.count) de \(allReservations.count) reserva(s) visibles."
            )

            Picker("Agrupar", selection: $grouping) {
                ForEach(BookingsGroupingOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Menu {
                    ForEach(BookingsSortOption.allCases) { option in
                        Button(option.title) {
                            sortOption = option
                        }
                    }
                } label: {
                    controlLabel(
                        title: "Orden",
                        value: sortOption.title,
                        systemImage: "arrow.up.arrow.down"
                    )
                }

                Menu {
                    ForEach(UnifiedReservationStatusFilter.allCases) { filter in
                        Button(filter.title) {
                            statusFilter = filter
                        }
                    }
                } label: {
                    controlLabel(
                        title: "Estado",
                        value: statusFilter.title,
                        systemImage: "line.3.horizontal.decrease.circle"
                    )
                }
            }
        }
        .appCardStyle(.neutral)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            BrandIconBubble(
                theme: .neutral,
                systemImage: "calendar.badge.exclamationmark",
                size: 58
            )

            Text("No hay reservas aquí")
                .font(.title3.bold())
                .foregroundStyle(palette.textPrimary)

            Text(emptyDescription)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .appCardStyle(.neutral)
    }

    private var emptyDescription: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No encontramos reservas que coincidan con tu búsqueda en esta sección."
        }

        switch selectedScope {
        case .today:
            return "Tus pedidos y reservas de hoy aparecerán aquí."
        case .upcoming:
            return "Las próximas reservas de comida, aventura o eventos aparecerán aquí."
        case .history:
            return "Tus reservas completadas, pasadas o canceladas aparecerán aquí."
        case .all:
            return "Cuando hagas pedidos o reserves experiencias, aparecerán aquí."
        }
    }

    private func reservationsSection(_ group: UnifiedReservationsGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(group.title)
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    if let subtitle = group.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                    }
                }

                Spacer()

                Text("\(group.reservations.count)")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textSecondary)
            }
            .padding(.horizontal, 2)

            ForEach(group.reservations) { reservation in
                UnifiedReservationAgendaCard(
                    reservation: reservation,
                    onOpen: { selectedReservation = reservation },
                    onCancelAdventure: { booking in
                        adventureBookingToCancel = booking
                    }
                )
            }
        }
    }

    private func filteredReservations(_ reservations: [UnifiedReservation]) -> [UnifiedReservation] {
        let statusFiltered = reservations.filter { statusFilter.matches($0) }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return statusFiltered }

        return statusFiltered.filter {
            $0.searchableText.contains(query)
        }
    }

    private func sortedReservations(_ reservations: [UnifiedReservation]) -> [UnifiedReservation] {
        switch sortOption {
        case .serviceTimeAscending:
            return reservations.sorted {
                if $0.serviceDate != $1.serviceDate { return $0.serviceDate < $1.serviceDate }
                return $0.createdAt < $1.createdAt
            }

        case .serviceTimeDescending:
            return reservations.sorted {
                if $0.serviceDate != $1.serviceDate { return $0.serviceDate > $1.serviceDate }
                return $0.createdAt > $1.createdAt
            }

        case .newestCreated:
            return reservations.sorted {
                if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                return $0.serviceDate > $1.serviceDate
            }

        case .highestTotal:
            return reservations.sorted {
                if $0.total != $1.total { return $0.total > $1.total }
                return $0.serviceDate < $1.serviceDate
            }
        }
    }

    private func groupedByDate(_ reservations: [UnifiedReservation]) -> [UnifiedReservationsGroup] {
        let buckets = Dictionary(grouping: reservations) {
            calendar.startOfDay(for: $0.serviceDate)
        }

        let days = buckets.keys.sorted { lhs, rhs in
            switch sortOption {
            case .serviceTimeDescending, .newestCreated:
                return lhs > rhs
            case .serviceTimeAscending, .highestTotal:
                return selectedScope == .history ? lhs > rhs : lhs < rhs
            }
        }

        return days.map { day in
            let reservations = sortedReservations(buckets[day] ?? [])

            return UnifiedReservationsGroup(
                id: "date-\(BookingsDateFormatter.key(day))",
                title: BookingsDateFormatter.sectionTitle(day),
                subtitle: "Fecha de servicio o visita",
                reservations: reservations
            )
        }
    }

    private func groupedByStatus(_ reservations: [UnifiedReservation]) -> [UnifiedReservationsGroup] {
        let order: [UnifiedReservationStatus] = [.pending, .confirmed, .preparing, .completed, .canceled]
        let buckets = Dictionary(grouping: reservations) { $0.normalizedStatus }

        return order.compactMap { status in
            guard let reservations = buckets[status], !reservations.isEmpty else {
                return nil
            }

            return UnifiedReservationsGroup(
                id: "status-\(status.rawValue)",
                title: status.title,
                subtitle: statusSubtitle(status),
                reservations: sortedReservations(reservations)
            )
        }
    }

    private func groupedByType(_ reservations: [UnifiedReservation]) -> [UnifiedReservationsGroup] {
        UnifiedReservationKind.allCases.compactMap { kind in
            let items = reservations.filter { $0.kind == kind }
            guard !items.isEmpty else { return nil }

            return UnifiedReservationsGroup(
                id: "kind-\(kind.rawValue)",
                title: kind.title,
                subtitle: kind.subtitle,
                reservations: sortedReservations(items)
            )
        }
    }

    private func statusSubtitle(_ status: UnifiedReservationStatus) -> String {
        switch status {
        case .pending:
            return "Esperando confirmación"
        case .confirmed:
            return "Reserva aceptada"
        case .preparing:
            return "Pedido en preparación"
        case .completed:
            return "Reserva finalizada"
        case .canceled:
            return "Reserva cancelada"
        }
    }

    private var todayCount: Int {
        let today = calendar.startOfDay(for: Date())
        return allReservations.filter {
            !$0.isTerminal && $0.occurs(on: today, calendar: calendar)
        }.count
    }

    private var upcomingCount: Int {
        let today = calendar.startOfDay(for: Date())
        return allReservations.filter {
            !$0.isTerminal && calendar.startOfDay(for: $0.serviceDate) > today
        }.count
    }

    private var historyCount: Int {
        let today = calendar.startOfDay(for: Date())
        return allReservations.filter {
            $0.isTerminal || $0.endDate < today
        }.count
    }

    private var canceledCount: Int {
        allReservations.filter(\.isCanceled).count
    }

    private func count(status: UnifiedReservationStatus, in reservations: [UnifiedReservation]) -> Int {
        reservations.filter { $0.normalizedStatus == status }.count
    }

    private func infoPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(palette.textSecondary)

            Text(value)
                .font(.caption.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(palette.elevatedCard)
        )
        .overlay(
            Capsule()
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func metricCard(
        title: String,
        value: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(.neutral, emphasized: false)
    }

    private func controlLabel(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(palette.textSecondary)

                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.18 : 0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct UnifiedReservationAgendaCard: View {
    let reservation: UnifiedReservation
    let onOpen: () -> Void
    let onCancelAdventure: (AdventureBooking) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var neutralPalette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    private var kindPalette: ThemePalette {
        AppTheme.palette(for: reservation.kind.theme, scheme: colorScheme)
    }

    private var statusColor: Color {
        switch reservation.normalizedStatus {
        case .pending: return .orange
        case .confirmed: return .green
        case .preparing: return .purple
        case .completed: return .blue
        case .canceled: return .red
        }
    }

    var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 14) {
                topBlock
                scheduleBlock

                switch reservation {
                case .restaurant(let order):
                    restaurantPreview(order)

                case .adventure(let booking):
                    adventurePreview(booking)
                }

                Divider()
                    .overlay(neutralPalette.stroke)

                bottomBlock
            }
            .appCardStyle(.neutral)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(
                        reservation.normalizedStatus == .canceled
                            ? Color.red.opacity(0.35)
                            : neutralPalette.stroke,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var topBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: reservation.kind.theme,
                systemImage: reservation.kind.systemImage,
                size: 50
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(reservation.title)
                    .font(.headline)
                    .foregroundStyle(neutralPalette.textPrimary)

                Text(reservation.clientName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(neutralPalette.textSecondary)

                Text(reservation.subtitle)
                    .font(.caption)
                    .foregroundStyle(neutralPalette.textTertiary)
            }

            Spacer()

            statusBadge
        }
    }

    private var scheduleBlock: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "clock")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(kindPalette.primary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(scheduleLabel)
                    .font(.caption.bold())
                    .foregroundStyle(neutralPalette.textSecondary)

                Text(serviceDateText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(neutralPalette.textPrimary)

                Text("Creada \(BookingsDateFormatter.shortDateTime(reservation.createdAt))")
                    .font(.caption2)
                    .foregroundStyle(neutralPalette.textTertiary)
            }

            Spacer()

            BrandBadge(
                theme: reservation.kind.theme,
                title: reservation.kind.title,
                selected: true
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(neutralPalette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(neutralPalette.stroke, lineWidth: 1)
        )
    }

    private func restaurantPreview(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(order.serviceMode.title, systemImage: order.isScheduledForLater ? "calendar.badge.clock" : "bolt.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(kindPalette.primary)

                Spacer()

                Text("Mesa \(order.tableNumber)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(neutralPalette.textSecondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(order.items.prefix(3)) { item in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(item.quantity)x")
                            .font(.caption.bold())
                            .foregroundStyle(neutralPalette.textSecondary)
                            .frame(width: 34, alignment: .leading)

                        Text(item.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(neutralPalette.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        Text(item.totalPrice.priceText)
                            .font(.caption.bold())
                            .foregroundStyle(neutralPalette.textSecondary)
                    }
                }

                if order.items.count > 3 {
                    Text("+\(order.items.count - 3) producto(s) más")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(neutralPalette.textTertiary)
                }
            }

            preparationProgress(order)
        }
    }

    private func adventurePreview(_ booking: AdventureBooking) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("\(booking.guestCount) invitado(s)", systemImage: "person.2.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(kindPalette.primary)

                Spacer()

                Text(booking.eventDisplayTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(neutralPalette.textSecondary)
                    .lineLimit(1)
            }

            if booking.hasActivities {
                VStack(alignment: .leading, spacing: 7) {
                    ForEach(booking.items.prefix(3)) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: item.activity.legacySystemImage)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(kindPalette.primary)
                                .frame(width: 18)

                            Text("\(item.title) • \(item.summaryText)")
                                .font(.caption)
                                .foregroundStyle(neutralPalette.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    if booking.items.count > 3 {
                        Text("+\(booking.items.count - 3) actividad(es) más")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(neutralPalette.textTertiary)
                    }
                }
            }

            if let food = booking.foodReservation, !food.items.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(kindPalette.primary)
                        .frame(width: 18)

                    Text(food.items.prefix(3).map { "\($0.quantity)x \($0.name)" }.joined(separator: " • "))
                        .font(.caption)
                        .foregroundStyle(neutralPalette.textSecondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func preparationProgress(_ order: Order) -> some View {
        let total = max(1, order.totalItems)
        let prepared = order.preparedItemsCount
        let value = Double(prepared) / Double(total)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Preparación")
                    .font(.caption.bold())
                    .foregroundStyle(neutralPalette.textSecondary)

                Spacer()

                Text("\(prepared)/\(order.totalItems)")
                    .font(.caption.bold())
                    .foregroundStyle(neutralPalette.textSecondary)
            }

            ProgressView(value: value)
                .tint(statusColor)
        }
    }

    private var bottomBlock: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(reservation.total.priceText)
                .font(.title3.bold())
                .foregroundStyle(kindPalette.primary)

            switch reservation {
            case .restaurant(let order):
                if order.loyaltyDiscountAmount > 0 {
                    loyaltyBadge(order.loyaltyDiscountAmount)
                }

            case .adventure(let booking):
                if booking.loyaltyDiscountAmount > 0 {
                    loyaltyBadge(booking.loyaltyDiscountAmount)
                }
            }

            Spacer()

            Menu {
                Button("Ver detalle") {
                    onOpen()
                }

                if case .adventure(let booking) = reservation,
                   booking.status != .canceled,
                   booking.status != .completed {
                    Button(role: .destructive) {
                        onCancelAdventure(booking)
                    } label: {
                        Label("Cancelar reserva", systemImage: "xmark.circle")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(kindPalette.primary)
            }
            .buttonStyle(.plain)
        }
    }

    private func loyaltyBadge(_ amount: Double) -> some View {
        Text("-\(amount.priceText) loyalty")
            .font(.caption.bold())
            .foregroundStyle(.green)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.green.opacity(colorScheme == .dark ? 0.20 : 0.12))
            )
    }

    private var statusBadge: some View {
        Text(reservation.normalizedStatus.title)
            .font(.caption.bold())
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusColor.opacity(colorScheme == .dark ? 0.22 : 0.13))
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.42), lineWidth: 1)
            )
    }

    private var scheduleLabel: String {
        switch reservation {
        case .restaurant(let order):
            return order.isScheduledForLater ? "Reserva para" : "Pedido para"
        case .adventure:
            return "Visita para"
        }
    }

    private var serviceDateText: String {
        switch reservation {
        case .restaurant(let order):
            return order.scheduledDateText
        case .adventure(let booking):
            let start = BookingsDateFormatter.shortDateTime(booking.startAt)
            let end = booking.endAt.formatted(date: .omitted, time: .shortened)
            return "\(start) - \(end)"
        }
    }
}

private enum BookingsDateFormatter {
    static func key(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func sectionTitle(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Hoy"
        }

        if calendar.isDateInTomorrow(date) {
            return "Mañana"
        }

        if calendar.isDateInYesterday(date) {
            return "Ayer"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateStyle = .full
        formatter.timeStyle = .none

        let text = formatter.string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    static func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_EC")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private extension Array where Element == UnifiedReservation {
    var visibleTotal: Double {
        filter { !$0.isCanceled }
            .reduce(0) { $0 + $1.total }
    }
}
