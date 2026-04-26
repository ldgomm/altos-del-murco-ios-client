//
//  RestaurantOrderSchedulingModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum RestaurantOrderFulfillmentMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case asSoonAsPossible
    case scheduled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .asSoonAsPossible: return "Para ahora"
        case .scheduled: return "Programar"
        }
    }

    var subtitle: String {
        switch self {
        case .asSoonAsPossible:
            return "El restaurante recibe el pedido para prepararlo de inmediato."
        case .scheduled:
            return "Reserva solo comida para una fecha y hora específica, sin actividades de aventura."
        }
    }

    var icon: String {
        switch self {
        case .asSoonAsPossible: return "bolt.fill"
        case .scheduled: return "calendar.badge.clock"
        }
    }
}

enum RestaurantOrderSchedulingRules {
    static let openingHour = 7
    static let closingHour = 20
    static let minimumLeadMinutes = 30
    static let minuteStep = 15
    static let maximumAdvanceDays = 60

    static var calendar: Calendar { Calendar.current }

    static func defaultScheduledAt(from now: Date = Date()) -> Date {
        roundedToNextStep(
            calendar.date(byAdding: .minute, value: minimumLeadMinutes, to: now) ?? now
        )
    }

    static func minimumScheduledAt(from now: Date = Date()) -> Date {
        defaultScheduledAt(from: now)
    }

    static func maximumScheduledAt(from now: Date = Date()) -> Date {
        calendar.date(byAdding: .day, value: maximumAdvanceDays, to: now) ?? now
    }

    static func dayKey(from date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }

    static func roundedToNextStep(_ date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = components.minute ?? 0
        let remainder = minute % minuteStep
        let minutesToAdd = remainder == 0 ? 0 : minuteStep - remainder
        let withoutSeconds = calendar.date(
            from: DateComponents(
                year: components.year,
                month: components.month,
                day: components.day,
                hour: components.hour,
                minute: minute,
                second: 0
            )
        ) ?? date

        return calendar.date(byAdding: .minute, value: minutesToAdd, to: withoutSeconds) ?? withoutSeconds
    }

    static func normalizedScheduledAt(_ date: Date) -> Date {
        roundedToNextStep(date)
    }

    static func isInsideRestaurantWindow(_ date: Date) -> Bool {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let minutesFromStartOfDay = hour * 60 + minute
        let opening = openingHour * 60
        let closing = closingHour * 60
        return minutesFromStartOfDay >= opening && minutesFromStartOfDay <= closing
    }

    static func isFutureDay(_ date: Date, relativeTo now: Date = Date()) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: now)
    }

    static func validate(
        mode: RestaurantOrderFulfillmentMode,
        scheduledAt: Date?,
        now: Date = Date()
    ) -> String? {
        guard mode == .scheduled else { return nil }

        guard let scheduledAt else {
            return "Selecciona la fecha y hora para tu reserva de comida."
        }

        let minimum = minimumScheduledAt(from: now)
        guard scheduledAt >= minimum else {
            return "Programa tu pedido con al menos \(minimumLeadMinutes) minutos de anticipación."
        }

        guard scheduledAt <= maximumScheduledAt(from: now) else {
            return "Solo puedes programar pedidos hasta \(maximumAdvanceDays) días adelante."
        }

        guard isInsideRestaurantWindow(scheduledAt) else {
            return "Elige una hora entre \(openingHour):00 y \(closingHour):00."
        }

        return nil
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

extension Date {
    var restaurantShortDateTimeText: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var restaurantTimeText: String {
        formatted(date: .omitted, time: .shortened)
    }
}
