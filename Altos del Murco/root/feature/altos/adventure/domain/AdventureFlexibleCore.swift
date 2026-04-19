//
//  AdventureModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

enum AdventureActivityType: String, Codable, CaseIterable, Identifiable, Hashable {
    case offRoad
    case paintball
    case goKarts
    case shootingRange
    case camping
    case extremeSlide

    var id: String { rawValue }

    var legacyTitle: String {
        switch self {
        case .offRoad: return "Off-road 4x4"
        case .paintball: return "Paintball"
        case .goKarts: return "Go karts"
        case .shootingRange: return "Campo de tiro"
        case .camping: return "Camping"
        case .extremeSlide: return "Resbaladera extrema"
        }
    }

    var legacySystemImage: String {
        switch self {
        case .offRoad: return "car.fill"
        case .paintball: return "shield.lefthalf.filled"
        case .goKarts: return "flag.checkered"
        case .shootingRange: return "target"
        case .camping: return "tent.fill"
        case .extremeSlide: return "figure.fall"
        }
    }

    var legacyDurationOptions: [Int] {
        switch self {
        case .offRoad:
            return [60, 120, 180]
        case .paintball, .goKarts, .shootingRange:
            return [30, 60, 90, 120]
        case .extremeSlide:
            return [30]
        case .camping:
            return []
        }
    }

    static func defaultDraft(for activity: AdventureActivityType) -> AdventureReservationItemDraft {
        switch activity {
        case .offRoad:
            return AdventureReservationItemDraft(
                activity: .offRoad,
                durationMinutes: 60,
                peopleCount: 0,
                vehicleCount: 1,
                offRoadRiderCount: 2,
                nights: 0
            )
        case .paintball:
            return AdventureReservationItemDraft(
                activity: .paintball,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        case .goKarts:
            return AdventureReservationItemDraft(
                activity: .goKarts,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        case .shootingRange:
            return AdventureReservationItemDraft(
                activity: .shootingRange,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        case .camping:
            return AdventureReservationItemDraft(
                activity: .camping,
                durationMinutes: 0,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 1
            )
        case .extremeSlide:
            return AdventureReservationItemDraft(
                activity: .extremeSlide,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        }
    }

    static func defaultDraft(
        for activity: AdventureActivityType,
        catalog: AdventureCatalogSnapshot?
    ) -> AdventureReservationItemDraft {
        guard let catalog,
              let config = catalog.activity(for: activity) else {
            return defaultDraft(for: activity)
        }

        return config.defaultDraft
    }
}

enum AdventureResourceType: String, Codable, Hashable {
    case offRoadVehicles
    case paintballPeople
    case goKartPeople
    case shootingPeople
    case campingPeople
    case extremeSlidePeople
}

enum AdventureBookingStatus: String, Codable, CaseIterable, Hashable, Identifiable {
    case pending
    case confirmed
    case completed
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .completed: return "Completada"
        case .canceled: return "Cancelada"
        }
    }
}

enum ReservationEventType: String, Codable, CaseIterable, Identifiable, Hashable {
    case regularVisit
    case birthday
    case anniversary
    case corporate
    case familyGathering
    case custom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .regularVisit: return "Visita regular"
        case .birthday: return "Cumpleaños"
        case .anniversary: return "Aniversario"
        case .corporate: return "Evento corporativo"
        case .familyGathering: return "Reunión familiar"
        case .custom: return "Otro"
        }
    }
}

enum ReservationServingMoment: String, Codable, CaseIterable, Identifiable, Hashable {
    case onArrival
    case afterActivities
    case specificTime
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .onArrival: return "Al llegar"
        case .afterActivities: return "Después de actividades"
        case .specificTime: return "Hora específica"
        }
    }
}

struct AdventureReservationItemDraft: Identifiable, Codable, Hashable {
    let id: String
    var activity: AdventureActivityType
    var durationMinutes: Int
    var peopleCount: Int
    var vehicleCount: Int
    var offRoadRiderCount: Int
    var nights: Int

    init(
        id: String = UUID().uuidString,
        activity: AdventureActivityType,
        durationMinutes: Int,
        peopleCount: Int,
        vehicleCount: Int,
        offRoadRiderCount: Int,
        nights: Int
    ) {
        self.id = id
        self.activity = activity
        self.durationMinutes = durationMinutes
        self.peopleCount = peopleCount
        self.vehicleCount = vehicleCount
        self.offRoadRiderCount = offRoadRiderCount
        self.nights = nights
    }

    var title: String { activity.legacyTitle }

    var summaryText: String {
        switch activity {
        case .offRoad:
            return "\(durationMinutes / 60)h • \(vehicleCount) vehículo(s) • \(offRoadRiderCount) persona(s)"
        case .paintball, .goKarts, .shootingRange:
            return "\(durationMinutes) min • \(peopleCount) persona(s)"
        case .camping:
            return "\(nights) noche(s) • \(peopleCount) persona(s)"
        case .extremeSlide:
            return "1 sesión • \(peopleCount) persona(s) • transporte incluido"
        }
    }
}

struct ReservationFoodItemDraft: Identifiable, Codable, Hashable {
    let id: String
    let menuItemId: String
    let name: String
    let unitPrice: Double
    var quantity: Int
    var notes: String?
    
    init(
        id: String = UUID().uuidString,
        menuItemId: String,
        name: String,
        unitPrice: Double,
        quantity: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.name = name
        self.unitPrice = unitPrice
        self.quantity = max(1, quantity)
        self.notes = notes
    }
    
    init(from menuItem: MenuItem, quantity: Int = 1, notes: String? = nil) {
        self.init(
            menuItemId: menuItem.id,
            name: menuItem.name,
            unitPrice: menuItem.finalPrice,
            quantity: quantity,
            notes: notes
        )
    }
    
    var subtotal: Double {
        Double(quantity) * unitPrice
    }
}

struct ReservationFoodDraft: Codable, Hashable {
    var items: [ReservationFoodItemDraft]
    var servingMoment: ReservationServingMoment
    var servingTime: Date?
    var notes: String?
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

struct AdventureBookingBlock: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let activity: AdventureActivityType
    let resourceType: AdventureResourceType
    let startAt: Date
    let endAt: Date
    let reservedUnits: Int
    let subtotal: Double
}

struct AdventureBuildPlan: Hashable {
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let adventureSubtotal: Double
    let foodSubtotal: Double
    let subtotal: Double
    let discountAmount: Double
    let nightPremium: Double
    let totalAmount: Double
    let hasNightPremium: Bool
}

struct AdventureAvailabilitySlot: Identifiable, Hashable {
    let id: String
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let adventureSubtotal: Double
    let foodSubtotal: Double
    let subtotal: Double
    let discountAmount: Double
    let nightPremium: Double
    let totalAmount: Double
}

struct AdventureBookingRequest: Hashable {
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let date: Date
    let selectedStartAt: Date
    let guestCount: Int
    let eventType: ReservationEventType
    let customEventTitle: String?
    let eventNotes: String?
    let items: [AdventureReservationItemDraft]
    let foodReservation: ReservationFoodDraft?
    let packageDiscountAmount: Double
    let notes: String?

    var hasActivities: Bool { !items.isEmpty }
    var hasFoodReservation: Bool { !(foodReservation?.isEmpty ?? true) }
}

struct AdventureBooking: Identifiable, Hashable {
    let id: String
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let startDayKey: String
    let startAt: Date
    let endAt: Date
    let guestCount: Int
    let eventType: ReservationEventType
    let customEventTitle: String?
    let eventNotes: String?
    let items: [AdventureReservationItemDraft]
    let foodReservation: ReservationFoodDraft?
    let blocks: [AdventureBookingBlock]
    let adventureSubtotal: Double
    let foodSubtotal: Double
    let subtotal: Double
    let discountAmount: Double
    let nightPremium: Double
    let totalAmount: Double
    let status: AdventureBookingStatus
    let createdAt: Date
    let notes: String?
    
    var hasActivities: Bool { !items.isEmpty }
    var hasFoodReservation: Bool { !(foodReservation?.isEmpty ?? true) }
    
    var eventDisplayTitle: String {
        if eventType == .custom {
            let clean = customEventTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return clean.isEmpty ? "Evento personalizado" : clean
        }
        return eventType.title
    }
    
    var visitTypeTitle: String {
        switch (hasActivities, hasFoodReservation) {
        case (true, true): return "Aventura + comida"
        case (true, false): return "Solo aventura"
        case (false, true): return "Solo comida"
        case (false, false): return "Reserva"
        }
    }
}

enum AdventureSchedule {
    static let slotMinutes = 30
    static let daytimeStartHour = 7
    static let daytimeEndHour = 20
    static let nightPremiumStartHour = 18
    static let offRoadPeoplePerVehicle = 2
    static let foodOnlyDefaultDurationMinutes = 90
    
    static func capacity(for resource: AdventureResourceType) -> Int {
        switch resource {
        case .offRoadVehicles:
            return 600
        case .paintballPeople:
            return 1000
        case .goKartPeople:
            return 1000
        case .shootingPeople:
            return 1000
        case .campingPeople:
            return 100
        case .extremeSlidePeople:
            return 100
        }
    }
}

enum AdventureDateHelper {
    static let calendar = Calendar.current
    
    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()
    
    static func dayKey(from date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }
    
    static func timeText(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
    
    static func date(on day: Date, hour: Int, minute: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
    
    static func addMinutes(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .minute, value: value, to: date) ?? date
    }
    
    static func addDays(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value, to: date) ?? date
    }
    
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func slotIndex(_ date: Date) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return (hour * 60 + minute) / AdventureSchedule.slotMinutes
    }
    
    static func isNightPremiumTime(_ startAt: Date, _ endAt: Date) -> Bool {
        let startHour = calendar.component(.hour, from: startAt)
        let endHour = calendar.component(.hour, from: endAt)
        return startHour >= AdventureSchedule.nightPremiumStartHour
            || endHour >= AdventureSchedule.nightPremiumStartHour
            || startHour < AdventureSchedule.daytimeStartHour
    }
}

enum AdventurePricingEngine {
    static let nightPremiumRate = 0.25

    static func finalUnitPrice(for config: AdventureActivityCatalogItem) -> Double {
        max(0, config.basePrice - config.discountAmount)
    }

    static func lineBaseSubtotal(
        for item: AdventureReservationItemDraft,
        config: AdventureActivityCatalogItem
    ) -> Double {
        switch item.activity {
        case .offRoad:
            let hours = Double(item.durationMinutes) / 60
            return config.basePrice * hours * Double(item.vehicleCount)

        case .paintball, .goKarts, .shootingRange:
            let blocks = Double(item.durationMinutes) / 30
            return config.basePrice * blocks * Double(item.peopleCount)

        case .camping:
            return config.basePrice * Double(item.peopleCount) * Double(item.nights)

        case .extremeSlide:
            return config.basePrice * Double(item.peopleCount)
        }
    }

    static func subtotal(
        for item: AdventureReservationItemDraft,
        config: AdventureActivityCatalogItem
    ) -> Double {
        switch item.activity {
        case .offRoad:
            let hours = Double(item.durationMinutes) / 60
            return finalUnitPrice(for: config) * hours * Double(item.vehicleCount)

        case .paintball, .goKarts, .shootingRange:
            let blocks = Double(item.durationMinutes) / 30
            return finalUnitPrice(for: config) * blocks * Double(item.peopleCount)

        case .camping:
            return finalUnitPrice(for: config) * Double(item.peopleCount) * Double(item.nights)

        case .extremeSlide:
            return finalUnitPrice(for: config) * Double(item.peopleCount)
        }
    }

    static func subtotal(
        for item: AdventureReservationItemDraft,
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        guard let config = catalog.activity(for: item.activity) else { return 0 }
        return subtotal(for: item, config: config)
    }

    static func lineDiscountAmount(
        for item: AdventureReservationItemDraft,
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        guard let config = catalog.activity(for: item.activity) else { return 0 }
        return max(0, lineBaseSubtotal(for: item, config: config) - subtotal(for: item, config: config))
    }

    static func estimatedSubtotal(
        items: [AdventureReservationItemDraft],
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        items.reduce(0) { partial, item in
            partial + subtotal(for: item, catalog: catalog)
        }
    }

    static func estimatedDiscountAmount(
        items: [AdventureReservationItemDraft],
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        items.reduce(0) { partial, item in
            partial + lineDiscountAmount(for: item, catalog: catalog)
        }
    }

    static func foodSubtotal(for foodReservation: ReservationFoodDraft?) -> Double {
        foodReservation?.subtotal ?? 0
    }

    static func packageTotal(
        items: [AdventureReservationItemDraft],
        packageDiscountAmount: Double,
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        let subtotal = estimatedSubtotal(items: items, catalog: catalog)
        return max(0, subtotal - packageDiscountAmount)
    }
}

enum AdventurePlanner {
    static func buildPlan(
        day: Date,
        startAt: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double,
        catalog: AdventureCatalogSnapshot
    ) -> AdventureBuildPlan? {
        let hasFood = !(foodReservation?.isEmpty ?? true)
        guard !items.isEmpty || hasFood else { return nil }

        let foodSubtotal = AdventurePricingEngine.foodSubtotal(for: foodReservation)
        let dayStart = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeStartHour,
            minute: 0
        )
        let dayEnd = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeEndHour,
            minute: 0
        )

        guard startAt >= dayStart else { return nil }

        if items.isEmpty {
            let end = AdventureDateHelper.addMinutes(
                AdventureSchedule.foodOnlyDefaultDurationMinutes,
                to: startAt
            )
            guard end <= dayEnd else { return nil }

            return AdventureBuildPlan(
                startAt: startAt,
                endAt: end,
                blocks: [],
                adventureSubtotal: 0,
                foodSubtotal: foodSubtotal,
                subtotal: foodSubtotal,
                discountAmount: 0,
                nightPremium: 0,
                totalAmount: foodSubtotal,
                hasNightPremium: false
            )
        }

        var cursor = startAt
        var blocks: [AdventureBookingBlock] = []
        var discountedAdventureSubtotal = 0.0
        var activityDiscountAmount = 0.0

        for (index, item) in items.enumerated() {
            guard catalog.activity(for: item.activity)?.isActive == true else {
                return nil
            }

            switch item.activity {
            case .offRoad:
                guard item.vehicleCount > 0 else { return nil }
                guard item.offRoadRiderCount > 0 else { return nil }
                guard item.offRoadRiderCount <= item.vehicleCount * AdventureSchedule.offRoadPeoplePerVehicle else { return nil }

                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .offRoad)?.title ?? "Off-Road 4x4",
                        activity: .offRoad,
                        resourceType: .offRoadVehicles,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.vehicleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .paintball:
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .paintball)?.title ?? "Paintball",
                        activity: .paintball,
                        resourceType: .paintballPeople,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .goKarts:
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .goKarts)?.title ?? "Go Karts",
                        activity: .goKarts,
                        resourceType: .goKartPeople,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .shootingRange:
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .shootingRange)?.title ?? "Campo de tiro",
                        activity: .shootingRange,
                        resourceType: .shootingPeople,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .extremeSlide:
                let transportVehicles = max(
                    1,
                    Int(ceil(Double(item.peopleCount) / Double(AdventureSchedule.offRoadPeoplePerVehicle)))
                )

                let transportEnd = AdventureDateHelper.addMinutes(30, to: cursor)
                let slideEnd = AdventureDateHelper.addMinutes(30, to: transportEnd)
                guard slideEnd <= dayEnd else { return nil }

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Transporte al columpio extremo",
                        activity: .extremeSlide,
                        resourceType: .offRoadVehicles,
                        startAt: cursor,
                        endAt: transportEnd,
                        reservedUnits: transportVehicles,
                        subtotal: 0
                    )
                )

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .extremeSlide)?.title ?? "Extreme Slide",
                        activity: .extremeSlide,
                        resourceType: .extremeSlidePeople,
                        startAt: transportEnd,
                        endAt: slideEnd,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = slideEnd

            case .camping:
                guard index == items.count - 1 else { return nil }
                let campingStart = AdventureDateHelper.date(on: day, hour: 19, minute: 0)
                guard cursor <= campingStart else { return nil }

                let config = catalog.activity(for: .camping)

                for night in 0..<max(1, item.nights) {
                    let start = AdventureDateHelper.addDays(night, to: campingStart)
                    let end = AdventureDateHelper.addMinutes(12 * 60, to: start)

                    let nightItem = AdventureReservationItemDraft(
                        activity: .camping,
                        durationMinutes: 0,
                        peopleCount: item.peopleCount,
                        vehicleCount: 0,
                        offRoadRiderCount: 0,
                        nights: 1
                    )

                    let nightSubtotal = AdventurePricingEngine.subtotal(for: nightItem, catalog: catalog)
                    let nightDiscount = AdventurePricingEngine.lineDiscountAmount(for: nightItem, catalog: catalog)

                    discountedAdventureSubtotal += nightSubtotal
                    activityDiscountAmount += nightDiscount

                    blocks.append(
                        AdventureBookingBlock(
                            id: UUID().uuidString,
                            title: "\(config?.title ?? "Camping") Night \(night + 1)",
                            activity: .camping,
                            resourceType: .campingPeople,
                            startAt: start,
                            endAt: end,
                            reservedUnits: item.peopleCount,
                            subtotal: nightSubtotal
                        )
                    )
                }

                cursor = blocks.last?.endAt ?? cursor
            }
        }

        guard let last = blocks.last else { return nil }

        let hasNightPremium =
            items.contains(where: { $0.activity == .camping }) ||
            blocks.contains { AdventureDateHelper.isNightPremiumTime($0.startAt, $0.endAt) }

        let totalDiscountAmount = activityDiscountAmount + max(0, packageDiscountAmount)
        let packageAdjustedAdventureSubtotal = max(0, discountedAdventureSubtotal - max(0, packageDiscountAmount))
        let totalSubtotal = discountedAdventureSubtotal + foodSubtotal
        let totalAmount = packageAdjustedAdventureSubtotal + foodSubtotal

        return AdventureBuildPlan(
            startAt: startAt,
            endAt: last.endAt,
            blocks: blocks,
            adventureSubtotal: discountedAdventureSubtotal,
            foodSubtotal: foodSubtotal,
            subtotal: totalSubtotal,
            discountAmount: totalDiscountAmount,
            nightPremium: 0,
            totalAmount: totalAmount,
            hasNightPremium: hasNightPremium
        )
    }

    static func affectedDayKeys(
        day: Date,
        items: [AdventureReservationItemDraft]
    ) -> [String] {
        let campingNights = items.first(where: { $0.activity == .camping })?.nights ?? 0
        let days = max(1, campingNights + 1)
        return (0..<days).map {
            AdventureDateHelper.dayKey(from: AdventureDateHelper.addDays($0, to: day))
        }
    }

    static func buildAvailability(
        day: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double,
        catalog: AdventureCatalogSnapshot
    ) -> [AdventureAvailabilitySlot] {
        let hasFood = !(foodReservation?.isEmpty ?? true)
        guard !items.isEmpty || hasFood else { return [] }

        let startWindow = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeStartHour,
            minute: 0
        )
        let endWindow = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeEndHour,
            minute: 0
        )

        let now = Date()
        let isToday = AdventureDateHelper.calendar.isDate(day, inSameDayAs: now)

        var current = startWindow
        var slots: [AdventureAvailabilitySlot] = []

        while current <= endWindow {
            if !(isToday && current < now),
               let plan = buildPlan(
                    day: day,
                    startAt: current,
                    items: items,
                    foodReservation: foodReservation,
                    packageDiscountAmount: packageDiscountAmount,
                    catalog: catalog
               ) {
                slots.append(
                    AdventureAvailabilitySlot(
                        id: UUID().uuidString,
                        startAt: plan.startAt,
                        endAt: plan.endAt,
                        blocks: plan.blocks,
                        adventureSubtotal: plan.adventureSubtotal,
                        foodSubtotal: plan.foodSubtotal,
                        subtotal: plan.subtotal,
                        discountAmount: plan.discountAmount,
                        nightPremium: plan.nightPremium,
                        totalAmount: plan.totalAmount
                    )
                )
            }

            current = AdventureDateHelper.addMinutes(AdventureSchedule.slotMinutes, to: current)
        }

        return slots
    }
}
