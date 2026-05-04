//
//  AdventureReservationsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct AdventureReservationsView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: AdventureBookingsViewModel
    @State private var selectedBooking: AdventureBooking?
    @State private var bookingToCancel: AdventureBooking?

    init(viewModelFactory: @escaping () -> AdventureBookingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    var body: some View {
        Group {
            if viewModel.state.isLoading && viewModel.state.allBookings.isEmpty {
                loadingView
            } else {
                contentView
            }
        }
        .navigationTitle("Reservas y eventos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .navigationDestination(item: $selectedBooking) { booking in
            ReserveViewDetail(
                booking: booking,
                onCancel: booking.status != .canceled
                    ? { viewModel.cancelBooking(booking.id) }
                    : nil
            )
        }
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: {
                    viewModel.state.errorMessage != nil
                    || viewModel.state.successMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissMessage()
                    }
                }
            )
        ) {
            Button("OK") {
                viewModel.dismissMessage()
            }
        } message: {
            Text(
                viewModel.state.errorMessage
                ?? viewModel.state.successMessage
                ?? ""
            )
        }
        .confirmationDialog(
            "Cancelar reserva",
            isPresented: Binding(
                get: { bookingToCancel != nil },
                set: { isPresented in
                    if !isPresented {
                        bookingToCancel = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Sí, cancelar", role: .destructive) {
                if let bookingToCancel {
                    viewModel.cancelBooking(bookingToCancel.id)
                }

                bookingToCancel = nil
            }

            Button("No", role: .cancel) {
                bookingToCancel = nil
            }
        } message: {
            Text("Esta acción marcará la reserva como cancelada.")
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(palette.primary)

            Text("Cargando reservas...")
                .font(.headline)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenStyle(.adventure)
    }

    private var contentView: some View {
        List {
            headerSection
            filtersSection
            reservationsSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .appScreenStyle(.adventure)
        .refreshable {
            viewModel.onAppear()
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(AdventureReservationSortOrder.allCases) { order in
                Button {
                    viewModel.setSortOrder(order)
                } label: {
                    Label(order.title, systemImage: order.systemImage)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(palette.primary)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    BrandIconBubble(
                        theme: .adventure,
                        systemImage: "calendar.badge.clock",
                        size: 54
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tus reservas")
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)

                        Text("Consulta reservas actuales, futuras y pasadas de aventura, comida, cumpleaños y eventos.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    summaryPill(
                        title: "Total",
                        value: viewModel.totalCount,
                        systemImage: "tray.full"
                    )

                    summaryPill(
                        title: "Ahora",
                        value: viewModel.currentCount,
                        systemImage: "clock.badge.checkmark"
                    )

                    summaryPill(
                        title: "Futuras",
                        value: viewModel.futureCount,
                        systemImage: "calendar.badge.plus"
                    )
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private func summaryPill(
        title: String,
        value: Int,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.primary)

            Text("\(value)")
                .font(.headline.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var filtersSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Filtros",
                    subtitle: "\(viewModel.displayedCount) de \(viewModel.totalCount) reserva(s) visibles."
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tiempo")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    horizontalTimelineFilters
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Estado")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    horizontalStatusFilters
                }

                HStack {
                    Label(viewModel.state.sortOrder.title, systemImage: viewModel.state.sortOrder.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    Spacer()

                    sortMenu
                }
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
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var horizontalTimelineFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AdventureReservationTimelineFilter.allCases) { filter in
                    filterChip(
                        title: filter.title,
                        systemImage: filter.systemImage,
                        isSelected: viewModel.state.selectedTimelineFilter == filter
                    ) {
                        viewModel.setTimelineFilter(filter)
                    }
                }
            }
        }
    }

    private var horizontalStatusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AdventureReservationStatusFilter.allCases) { filter in
                    filterChip(
                        title: filter.title,
                        systemImage: nil,
                        isSelected: viewModel.state.selectedStatusFilter == filter
                    ) {
                        viewModel.setStatusFilter(filter)
                    }
                }
            }
        }
    }

    private func filterChip(
        title: String,
        systemImage: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                }

                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isSelected ? palette.primary : palette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? palette.primary.opacity(0.16) : palette.elevatedCard)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? palette.primary.opacity(0.65) : palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var reservationsSection: some View {
        if viewModel.groupedBookings.isEmpty {
            Section {
                ContentUnavailableView(
                    "Sin reservas",
                    systemImage: "calendar",
                    description: Text("No hay reservas que coincidan con los filtros seleccionados.")
                )
                .foregroundStyle(palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .appCardStyle(.adventure)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } else {
            ForEach(viewModel.groupedBookings) { group in
                Section {
                    ForEach(group.bookings) { booking in
                        Button {
                            selectedBooking = booking
                        } label: {
                            AdventureReservationRow(booking: booking)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if booking.status != .canceled {
                                Button(role: .destructive) {
                                    bookingToCancel = booking
                                } label: {
                                    Label("Cancelar", systemImage: "xmark")
                                }
                            }
                        }
                    }
                } header: {
                    Text(group.title.capitalized)
                        .font(.headline)
                        .foregroundStyle(palette.textSecondary)
                        .textCase(nil)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

private struct AdventureReservationRow: View {
    let booking: AdventureBooking

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var iconName: String {
        if booking.hasActivities {
            return "figure.hiking"
        }

        if booking.hasFoodReservation {
            return "fork.knife"
        }

        return "calendar"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topBlock

            chipsBlock

            guestBlock

            if booking.hasActivities {
                activitiesBlock
            }

            if let food = booking.foodReservation, !food.items.isEmpty {
                foodBlock(food)
            }

            if !booking.appliedRewards.isEmpty {
                rewardsBlock
            }

            Divider()
                .overlay(palette.stroke)

            totalsBlock
        }
        .appCardStyle(.adventure)
    }

    private var topBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: .adventure,
                systemImage: iconName,
                size: 48
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(booking.eventDisplayTitle)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(booking.clientName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)

                Text(dateTimeText)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)

                Text("WhatsApp \(booking.whatsappNumber)")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            Spacer()

            statusBadge
        }
    }

    private var chipsBlock: some View {
        HStack(spacing: 8) {
            BrandBadge(theme: .adventure, title: booking.visitTypeTitle)

            BrandBadge(
                theme: .adventure,
                title: booking.eventType == .regularVisit ? "Visita" : "Evento",
                selected: booking.eventType != .regularVisit
            )
        }
    }

    private var guestBlock: some View {
        HStack(spacing: 8) {
            Label("\(booking.guestCount) invitado(s)", systemImage: "person.2.fill")
            Label("Cuenta \(booking.userId)", systemImage: "person.crop.circle.badge.checkmark")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(palette.textSecondary)
    }

    private var activitiesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actividades")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            ForEach(booking.items, id: \.id) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(palette.primary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text("\(item.title) — \(item.summaryText)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
    }

    private func foodBlock(_ food: ReservationFoodDraft) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comida reservada")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            ForEach(food.items, id: \.id) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text("\(item.quantity)x \(item.name)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            Text("Servicio: \(servingMomentText(food))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
    }

    private var rewardsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Premios aplicados")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            ForEach(booking.appliedRewards.prefix(2)) { reward in
                HStack(alignment: .top, spacing: 8) {
                    BrandBadge(theme: .adventure, title: "Premio", selected: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reward.title)
                            .font(.caption.bold())
                            .foregroundStyle(palette.textPrimary)

                        Text(reward.note)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text("-\(reward.amount.priceText)")
                        .font(.caption.bold())
                        .foregroundStyle(palette.success)
                }
            }

            if booking.appliedRewards.count > 2 {
                Text("+\(booking.appliedRewards.count - 2) premio(s) más")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textTertiary)
            }
        }
    }

    private var totalsBlock: some View {
        VStack(spacing: 10) {
            amountRow("Aventura", booking.adventureSubtotal)
            amountRow("Comida", booking.foodSubtotal)

            if booking.discountAmount > 0 {
                amountRow("Descuento", -booking.discountAmount)
            }

            if booking.loyaltyDiscountAmount > 0 {
                amountRow("Murco Loyalty", -booking.loyaltyDiscountAmount)
            }

            amountRow(
                "Total",
                booking.totalAmount,
                isPrimary: true
            )

            HStack {
                Spacer()

                Label("Ver detalle", systemImage: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(palette.textTertiary)
            }
        }
    }

    private var dateTimeText: String {
        let dateText = booking.startAt.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
        )

        let startText = booking.startAt.formatted(date: .omitted, time: .shortened)
        let endText = booking.endAt.formatted(date: .omitted, time: .shortened)

        return "\(dateText) • \(startText) - \(endText)"
    }

    private func servingMomentText(_ food: ReservationFoodDraft) -> String {
        switch food.servingMoment {
        case .onArrival:
            return "Al llegar"

        case .afterActivities:
            return "Después de actividades"

        case .specificTime:
            if let servingTime = food.servingTime {
                return "Hora específica • \(servingTime.formatted(date: .omitted, time: .shortened))"
            }

            return "Hora específica"
        }
    }

    private func amountRow(
        _ title: String,
        _ amount: Double,
        isPrimary: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(isPrimary ? .headline : .subheadline)
                .foregroundStyle(isPrimary ? palette.textPrimary : palette.textSecondary)

            Spacer()

            Text(amount.priceText)
                .font(isPrimary ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(isPrimary ? palette.primary : palette.textPrimary)
        }
    }

    private var statusBadge: some View {
        Text(booking.status.title)
            .font(.caption.bold())
            .foregroundStyle(statusTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusBackgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(statusBorderColor, lineWidth: 1)
            )
    }

    private var statusBackgroundColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .confirmed:
            return palette.success.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .completed:
            return Color.blue.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .canceled:
            return palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.14)
        }
    }

    private var statusBorderColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning.opacity(0.45)
        case .confirmed:
            return palette.success.opacity(0.45)
        case .completed:
            return Color.blue.opacity(0.45)
        case .canceled:
            return palette.destructive.opacity(0.45)
        }
    }

    private var statusTextColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.success
        case .completed:
            return .blue
        case .canceled:
            return palette.destructive
        }
    }
}
