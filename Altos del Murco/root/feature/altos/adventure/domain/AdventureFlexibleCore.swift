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
    
    var title: String {
        switch self {
        case .offRoad: return "Off-Road"
        case .paintball: return "Paintball"
        case .goKarts: return "Go Karts"
        case .shootingRange: return "Shooting Range"
        case .camping: return "Camping"
        case .extremeSlide: return "Extreme Slide"
        }
    }
    
    var systemImage: String {
        switch self {
        case .offRoad: return "car.fill"
        case .paintball: return "shield.lefthalf.filled"
        case .goKarts: return "flag.checkered"
        case .shootingRange: return "target"
        case .camping: return "tent.fill"
        case .extremeSlide: return "figure.fall"
        }
    }
    
    var durationOptions: [Int] {
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
}

enum AdventureResourceType: String, Codable, Hashable {
    case offRoadVehicles
    case paintballPeople
    case goKartPeople
    case shootingPeople
    case campingPeople
    case extremeSlidePeople
}

enum AdventureBookingStatus: String, Codable, CaseIterable, Hashable {
    case pending
    case confirmed
    case canceled
    
    var title: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .canceled: return "Canceled"
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
    
    var title: String { activity.title }
    
    var summaryText: String {
        switch activity {
        case .offRoad:
            return "\(durationMinutes / 60)h • \(vehicleCount) vehicle(s) • \(offRoadRiderCount) rider(s)"
        case .paintball, .goKarts, .shootingRange:
            return "\(durationMinutes)m • \(peopleCount) people"
        case .camping:
            return "\(nights) night(s) • \(peopleCount) people"
        case .extremeSlide:
            return "1 session • \(peopleCount) people • transport included"
        }
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
    let items: [AdventureReservationItemDraft]
    let notes: String?
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
    let items: [AdventureReservationItemDraft]
    let blocks: [AdventureBookingBlock]
    let subtotal: Double
    let discountAmount: Double
    let nightPremium: Double
    let totalAmount: Double
    let status: AdventureBookingStatus
    let createdAt: Date
    let notes: String?
}

struct AdventureTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let items: [AdventureReservationItemDraft]
}

enum AdventureSchedule {
    static let slotMinutes = 30
    static let daytimeStartHour = 8
    static let daytimeEndHour = 22
    static let nightPremiumStartHour = 18
    static let offRoadPeoplePerVehicle = 2
    
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
    
    static func date(
        on day: Date,
        hour: Int,
        minute: Int
    ) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: day
        ) ?? day
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
    
    static func subtotal(for item: AdventureReservationItemDraft) -> Double {
        switch item.activity {
        case .offRoad:
            let hours = Double(item.durationMinutes) / 60
            return 20 * hours * Double(item.vehicleCount)
        case .paintball:
            return 5 * Double(item.durationMinutes / 30) * Double(item.peopleCount)
        case .goKarts:
            return 5 * Double(item.durationMinutes / 30) * Double(item.peopleCount)
        case .shootingRange:
            return 5 * Double(item.durationMinutes / 30) * Double(item.peopleCount)
        case .camping:
            return 30 * Double(item.peopleCount) * Double(item.nights)
        case .extremeSlide:
            return 15 * Double(item.peopleCount)
        }
    }
    
    static func estimatedSubtotal(items: [AdventureReservationItemDraft]) -> Double {
        items.reduce(0) { $0 + subtotal(for: $1) }
    }
    
    static func discount(for subtotal: Double) -> Double {
        let completeTenDollarSteps = Int(subtotal / 10)
        return Double(completeTenDollarSteps) * 0.5
    }

    static func discountedSubtotal(for subtotal: Double) -> Double {
        max(0, subtotal - discount(for: subtotal))
    }

    static func estimatedDiscountedSubtotal(items: [AdventureReservationItemDraft]) -> Double {
        let subtotal = estimatedSubtotal(items: items)
        return subtotal
    }
}

enum AdventurePlanner {
    static func buildPlan(
        day: Date,
        startAt: Date,
        items: [AdventureReservationItemDraft]
    ) -> AdventureBuildPlan? {
        guard !items.isEmpty else { return nil }
        
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
        
        var cursor = startAt
        var blocks: [AdventureBookingBlock] = []
        var subtotal = 0.0
        
        for (index, item) in items.enumerated() {
            switch item.activity {
            case .offRoad:
                guard item.vehicleCount > 0 else { return nil }
                guard item.offRoadRiderCount > 0 else { return nil }
                guard item.offRoadRiderCount <= item.vehicleCount * AdventureSchedule.offRoadPeoplePerVehicle else { return nil }
                
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                subtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Off-Road",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                subtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Paintball",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                subtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Go Karts",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                subtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Shooting Range",
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
                        title: "Extreme Slide Transport",
                        activity: .extremeSlide,
                        resourceType: .offRoadVehicles,
                        startAt: cursor,
                        endAt: transportEnd,
                        reservedUnits: transportVehicles,
                        subtotal: 0
                    )
                )
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                subtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Extreme Slide",
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
                
                for night in 0..<max(1, item.nights) {
                    let start = AdventureDateHelper.addDays(night, to: campingStart)
                    let end = AdventureDateHelper.addMinutes(12 * 60, to: start)
                    let nightSubtotal = 30 * Double(item.peopleCount)
                    subtotal += nightSubtotal
                    
                    blocks.append(
                        AdventureBookingBlock(
                            id: UUID().uuidString,
                            title: "Camping Night \(night + 1)",
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
        
        let hasMisalignedOffRoadBlock = blocks.contains {
            $0.activity == .offRoad &&
            AdventureDateHelper.calendar.component(.minute, from: $0.startAt) != 0
        }

        guard !hasMisalignedOffRoadBlock else { return nil }
        
        guard let last = blocks.last else { return nil }
        
        let hasNightPremium = blocks.contains {
            $0.activity == .camping
            || AdventureDateHelper.isNightPremiumTime($0.startAt, $0.endAt)
        }

        let discountAmount = AdventurePricingEngine.discount(for: subtotal)
        let discountedSubtotal = AdventurePricingEngine.discountedSubtotal(for: subtotal)
        let premium = hasNightPremium
            ? discountedSubtotal * AdventurePricingEngine.nightPremiumRate
            : 0

        return AdventureBuildPlan(
            startAt: startAt,
            endAt: last.endAt,
            blocks: blocks,
            subtotal: subtotal,
            discountAmount: discountAmount,
            nightPremium: premium,
            totalAmount: discountedSubtotal + premium,
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
        items: [AdventureReservationItemDraft]
    ) -> [AdventureAvailabilitySlot] {
        guard !items.isEmpty else { return [] }
        
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
               let plan = buildPlan(day: day, startAt: current, items: items) {
                slots.append(
                    AdventureAvailabilitySlot(
                        id: UUID().uuidString,
                        startAt: plan.startAt,
                        endAt: plan.endAt,
                        blocks: plan.blocks,
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

enum AdventureCatalogTemplates {
    static let featured: [AdventureTemplate] = [
        AdventureTemplate(
            id: "off-road-duo",
            title: "Off-Road Duo",
            subtitle: "1 hour off-road for 2 riders",
            badge: "Popular",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 60,
                    peopleCount: 0,
                    vehicleCount: 1,
                    offRoadRiderCount: 2,
                    nights: 0
                )
            ]
        ),
        AdventureTemplate(
            id: "adrenaline-mix",
            title: "Adrenaline Mix",
            subtitle: "1 hour off-road + 30 min karts + 30 min paintball",
            badge: "Featured",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 60,
                    peopleCount: 0,
                    vehicleCount: 2,
                    offRoadRiderCount: 4,
                    nights: 0
                ),
                AdventureActivityType.defaultDraft(for: .goKarts),
                AdventureActivityType.defaultDraft(for: .paintball)
            ]
        ),
        AdventureTemplate(
            id: "full-adventure",
            title: "Full Adventure",
            subtitle: "2h off-road + 1h karts + 30m paintball + 30m shooting",
            badge: "Best Seller",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 120,
                    peopleCount: 0,
                    vehicleCount: 2,
                    offRoadRiderCount: 4,
                    nights: 0
                ),
                AdventureReservationItemDraft(
                    activity: .goKarts,
                    durationMinutes: 60,
                    peopleCount: 4,
                    vehicleCount: 0,
                    offRoadRiderCount: 0,
                    nights: 0
                ),
                AdventureActivityType.defaultDraft(for: .paintball),
                AdventureActivityType.defaultDraft(for: .shootingRange)
            ]
        ),
        AdventureTemplate(
            id: "camp-night",
            title: "Camp Night",
            subtitle: "Day activities + camping night",
            badge: "Night Fun",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 60,
                    peopleCount: 0,
                    vehicleCount: 1,
                    offRoadRiderCount: 2,
                    nights: 0
                ),
                AdventureActivityType.defaultDraft(for: .camping)
            ]
        )
    ]
}
