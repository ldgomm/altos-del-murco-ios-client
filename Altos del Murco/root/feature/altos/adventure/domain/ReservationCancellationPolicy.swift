//
//  ReservationCancellationPolicy.swift
//  Altos del Murco
//
//  Created by José Ruiz on 27/4/26.
//

import Foundation

enum ReservationCancellationPolicy {
    static let minimumClientNotice: TimeInterval = 2 * 60 * 60

    static func canClientCancel(_ booking: AdventureBooking, now: Date = Date()) -> Bool {
        reasonClientCannotCancel(booking, now: now) == nil
    }

    static func reasonClientCannotCancel(_ booking: AdventureBooking, now: Date = Date()) -> String? {
        guard booking.status == .pending || booking.status == .confirmed else {
            return "Solo se pueden cancelar reservas pendientes o confirmadas."
        }

        guard booking.startAt > now else {
            return "Esta reserva ya inició o ya pasó."
        }

        let latestAllowedCancellation = booking.startAt.addingTimeInterval(-minimumClientNotice)
        guard now <= latestAllowedCancellation else {
            return "Para cancelar con menos de 2 horas de anticipación, por favor contáctanos por WhatsApp."
        }

        return nil
    }
}
