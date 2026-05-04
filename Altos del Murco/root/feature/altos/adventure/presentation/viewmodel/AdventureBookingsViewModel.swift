//
//  AdventureBookingsViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Combine
import Foundation
import SwiftUI

enum AdventureReservationTimelineFilter: String, CaseIterable, Identifiable {
    case all
    case current
    case future
    case past

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todas"
        case .current: return "Actuales"
        case .future: return "Futuras"
        case .past: return "Pasadas"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "calendar"
        case .current: return "clock.badge.checkmark"
        case .future: return "calendar.badge.plus"
        case .past: return "clock.arrow.circlepath"
        }
    }
}

enum AdventureReservationStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case confirmed
    case completed
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todo"
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .completed: return "Completada"
        case .canceled: return "Cancelada"
        }
    }

    var bookingStatus: AdventureBookingStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .confirmed: return .confirmed
        case .completed: return .completed
        case .canceled: return .canceled
        }
    }
}

enum AdventureReservationSortOrder: String, CaseIterable, Identifiable {
    case nearestFirst
    case newestFirst
    case oldestFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nearestFirst: return "Próximas primero"
        case .newestFirst: return "Más recientes"
        case .oldestFirst: return "Más antiguas"
        }
    }

    var systemImage: String {
        switch self {
        case .nearestFirst: return "sparkles"
        case .newestFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        }
    }
}

struct AdventureBookingsDateGroup: Identifiable {
    let id: String
    let date: Date
    let bookings: [AdventureBooking]

    var title: String {
        if Calendar.current.isDateInToday(date) {
            return "Hoy"
        }

        if Calendar.current.isDateInTomorrow(date) {
            return "Mañana"
        }

        if Calendar.current.isDateInYesterday(date) {
            return "Ayer"
        }

        return date.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
        )
    }
}

struct AdventureBookingsState {
    var allBookings: [AdventureBooking] = []

    var selectedTimelineFilter: AdventureReservationTimelineFilter = .all
    var selectedStatusFilter: AdventureReservationStatusFilter = .all
    var sortOrder: AdventureReservationSortOrder = .nearestFirst

    var now: Date = Date()

    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
}

@MainActor
final class AdventureBookingsViewModel: ObservableObject {
    @Published private(set) var state = AdventureBookingsState()

    private let observeBookingsUseCase: ObserveAdventureBookingsUseCase
    private let cancelBookingUseCase: CancelAdventureBookingUseCase

    private var listenerToken: AdventureListenerToken?

    init(
        observeBookingsUseCase: ObserveAdventureBookingsUseCase,
        cancelBookingUseCase: CancelAdventureBookingUseCase
    ) {
        self.observeBookingsUseCase = observeBookingsUseCase
        self.cancelBookingUseCase = cancelBookingUseCase
    }

    func onAppear() {
        state.now = Date()
        startListening()
    }

    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
    }

    func setTimelineFilter(_ filter: AdventureReservationTimelineFilter) {
        state.now = Date()
        state.selectedTimelineFilter = filter
    }

    func setStatusFilter(_ filter: AdventureReservationStatusFilter) {
        state.selectedStatusFilter = filter
    }

    func setSortOrder(_ sortOrder: AdventureReservationSortOrder) {
        state.sortOrder = sortOrder
    }

    func dismissMessage() {
        state.errorMessage = nil
        state.successMessage = nil
    }

    func cancelBooking(_ id: String) {

        Task {
            do {
                try await cancelBookingUseCase.execute(id: id)

                state.successMessage = "Reserva cancelada correctamente."
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    var displayedBookings: [AdventureBooking] {
        let filtered = state.allBookings.filter { booking in
            matchesTimelineFilter(booking)
            && matchesStatusFilter(booking)
        }

        return sorted(filtered)
    }

    var groupedBookings: [AdventureBookingsDateGroup] {
        let sortedBookings = displayedBookings

        var groups: [(id: String, date: Date, bookings: [AdventureBooking])] = []
        var indexByDayKey: [String: Int] = [:]

        for booking in sortedBookings {
            let day = Calendar.current.startOfDay(for: booking.startAt)
            let key = AdventureDateHelper.dayKey(from: day)

            if let index = indexByDayKey[key] {
                groups[index].bookings.append(booking)
            } else {
                indexByDayKey[key] = groups.count
                groups.append(
                    (
                        id: key,
                        date: day,
                        bookings: [booking]
                    )
                )
            }
        }

        return groups.map {
            AdventureBookingsDateGroup(
                id: $0.id,
                date: $0.date,
                bookings: $0.bookings
            )
        }
    }

    var totalCount: Int {
        state.allBookings.count
    }

    var displayedCount: Int {
        displayedBookings.count
    }

    var currentCount: Int {
        state.allBookings.filter { isCurrent($0, now: state.now) }.count
    }

    var futureCount: Int {
        state.allBookings.filter { isFuture($0, now: state.now) }.count
    }

    var pastCount: Int {
        state.allBookings.filter { isPast($0, now: state.now) }.count
    }

    private func startListening() {

        state.isLoading = true
        state.errorMessage = nil
        state.now = Date()

        listenerToken?.remove()

        listenerToken = observeBookingsUseCase.execute(
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case let .success(bookings):
                    self.state.allBookings = bookings
                    self.state.isLoading = false
                    self.state.errorMessage = nil
                    self.state.now = Date()

                case let .failure(error):
                    self.state.allBookings = []
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
    }

    private func matchesTimelineFilter(_ booking: AdventureBooking) -> Bool {
        switch state.selectedTimelineFilter {
        case .all:
            return true

        case .current:
            return isCurrent(booking, now: state.now)

        case .future:
            return isFuture(booking, now: state.now)

        case .past:
            return isPast(booking, now: state.now)
        }
    }

    private func matchesStatusFilter(_ booking: AdventureBooking) -> Bool {
        guard let selectedStatus = state.selectedStatusFilter.bookingStatus else {
            return true
        }

        return booking.status == selectedStatus
    }

    private func sorted(_ bookings: [AdventureBooking]) -> [AdventureBooking] {
        switch state.sortOrder {
        case .nearestFirst:
            return bookings.sorted { lhs, rhs in
                let lhsRank = timelineRank(lhs, now: state.now)
                let rhsRank = timelineRank(rhs, now: state.now)

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                if lhsRank == 2 {
                    return lhs.startAt > rhs.startAt
                }

                return lhs.startAt < rhs.startAt
            }

        case .newestFirst:
            return bookings.sorted {
                if $0.startAt != $1.startAt {
                    return $0.startAt > $1.startAt
                }

                return $0.createdAt > $1.createdAt
            }

        case .oldestFirst:
            return bookings.sorted {
                if $0.startAt != $1.startAt {
                    return $0.startAt < $1.startAt
                }

                return $0.createdAt < $1.createdAt
            }
        }
    }

    private func timelineRank(_ booking: AdventureBooking, now: Date) -> Int {
        if isCurrent(booking, now: now) {
            return 0
        }

        if isFuture(booking, now: now) {
            return 1
        }

        return 2
    }

    private func isCurrent(_ booking: AdventureBooking, now: Date) -> Bool {
        booking.startAt <= now && booking.endAt >= now
    }

    private func isFuture(_ booking: AdventureBooking, now: Date) -> Bool {
        booking.startAt > now
    }

    private func isPast(_ booking: AdventureBooking, now: Date) -> Bool {
        booking.endAt < now
    }
}
