//
//  AdventurePlanner.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

enum AdventurePricing {
    static let offRoadHourlyRatePerPerson = 20.0
    static let paintballRatePerPerson = 5.0
    static let shootingRatePerPerson = 5.0
    static let goKartsRatePerPerson = 5.0
    
    // Keep these at 0 now. If later you want combo discounts,
    // change these values without touching UI or service logic.
    static let comboDiscountPerPerson: [AdventurePackageType: Double] = [
        .offRoadPlusPaintball: 0,
        .fullAdventure: 0
    ]
    
    static func total(
        packageType: AdventurePackageType,
        offRoadHours: Int,
        peopleCount: Int
    ) -> Double {
        let perPersonBase: Double
        
        switch packageType {
        case .singleOffRoad:
            perPersonBase = Double(offRoadHours) * offRoadHourlyRatePerPerson
        case .singlePaintball:
            perPersonBase = paintballRatePerPerson
        case .singleGoKarts:
            perPersonBase = goKartsRatePerPerson
        case .singleShooting:
            perPersonBase = shootingRatePerPerson
        case .offRoadPlusPaintball:
            perPersonBase =
                (Double(offRoadHours) * offRoadHourlyRatePerPerson)
                + paintballRatePerPerson
                - (comboDiscountPerPerson[.offRoadPlusPaintball] ?? 0)
        case .fullAdventure:
            perPersonBase =
                (Double(offRoadHours) * offRoadHourlyRatePerPerson)
                + paintballRatePerPerson
                + goKartsRatePerPerson
                + shootingRatePerPerson
                - (comboDiscountPerPerson[.fullAdventure] ?? 0)
        }
        
        return perPersonBase * Double(peopleCount)
    }
}

enum AdventureScheduleConfig {
    static let openingHour = 9
    static let closingHour = 18
    static let slotMinutes = 30
    
    static var totalSlots: Int {
        ((closingHour - openingHour) * 60) / slotMinutes
    }
    
    static func capacity(for activity: AdventureActivityType) -> Int {
        switch activity {
        case .offRoad:
            return 6
        case .paintball:
            return 20
        case .goKarts:
            return 8
        case .shootingRange:
            return 6
        }
    }
}

enum AdventureDateHelper {
    static let calendar = Calendar.current
    
    static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    static func dayKey(from date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }
    
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func openTime(on day: Date) -> Date {
        calendar.date(
            bySettingHour: AdventureScheduleConfig.openingHour,
            minute: 0,
            second: 0,
            of: day
        ) ?? day
    }
    
    static func closeTime(on day: Date) -> Date {
        calendar.date(
            bySettingHour: AdventureScheduleConfig.closingHour,
            minute: 0,
            second: 0,
            of: day
        ) ?? day
    }
    
    static func slotStart(on day: Date, slotIndex: Int) -> Date {
        calendar.date(
            byAdding: .minute,
            value: slotIndex * AdventureScheduleConfig.slotMinutes,
            to: openTime(on: day)
        ) ?? day
    }
    
    static func slotIndex(for date: Date, on day: Date) -> Int {
        let minutes = Int(date.timeIntervalSince(openTime(on: day)) / 60)
        return minutes / AdventureScheduleConfig.slotMinutes
    }
    
    static func timeText(for date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

struct AdventureInventoryKey: Hashable {
    let activity: AdventureActivityType
    let slotIndex: Int
}

enum AdventurePlanner {
    static func buildPlan(
        day: Date,
        startAt: Date,
        packageType: AdventurePackageType,
        offRoadHours: Int,
        peopleCount: Int
    ) -> AdventureBuildPlan? {
        guard peopleCount > 0 else { return nil }
        guard offRoadHours >= 1 && offRoadHours <= 3 || !packageType.includesOffRoad else { return nil }
        
        var cursor = startAt
        var blocks: [AdventureBookingBlock] = []
        
        func appendBlock(
            activity: AdventureActivityType,
            durationMinutes: Int,
            unitPricePerPerson: Double
        ) {
            let end = AdventureDateHelper.calendar.date(
                byAdding: .minute,
                value: durationMinutes,
                to: cursor
            ) ?? cursor
            
            blocks.append(
                AdventureBookingBlock(
                    id: UUID().uuidString,
                    activity: activity,
                    startAt: cursor,
                    endAt: end,
                    durationMinutes: durationMinutes,
                    unitPricePerPerson: unitPricePerPerson
                )
            )
            cursor = end
        }
        
        switch packageType {
        case .singleOffRoad:
            appendBlock(
                activity: .offRoad,
                durationMinutes: offRoadHours * 60,
                unitPricePerPerson: AdventurePricing.offRoadHourlyRatePerPerson * Double(offRoadHours)
            )
            
        case .singlePaintball:
            appendBlock(
                activity: .paintball,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.paintballRatePerPerson
            )
            
        case .singleGoKarts:
            appendBlock(
                activity: .goKarts,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.goKartsRatePerPerson
            )
            
        case .singleShooting:
            appendBlock(
                activity: .shootingRange,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.shootingRatePerPerson
            )
            
        case .offRoadPlusPaintball:
            appendBlock(
                activity: .offRoad,
                durationMinutes: offRoadHours * 60,
                unitPricePerPerson: AdventurePricing.offRoadHourlyRatePerPerson * Double(offRoadHours)
            )
            appendBlock(
                activity: .paintball,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.paintballRatePerPerson
            )
            
        case .fullAdventure:
            appendBlock(
                activity: .offRoad,
                durationMinutes: offRoadHours * 60,
                unitPricePerPerson: AdventurePricing.offRoadHourlyRatePerPerson * Double(offRoadHours)
            )
            appendBlock(
                activity: .paintball,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.paintballRatePerPerson
            )
            appendBlock(
                activity: .goKarts,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.goKartsRatePerPerson
            )
            appendBlock(
                activity: .shootingRange,
                durationMinutes: 30,
                unitPricePerPerson: AdventurePricing.shootingRatePerPerson
            )
        }
        
        guard let endAt = blocks.last?.endAt else { return nil }
        guard endAt <= AdventureDateHelper.closeTime(on: day) else { return nil }
        
        return AdventureBuildPlan(
            day: day,
            packageType: packageType,
            offRoadHours: packageType.includesOffRoad ? offRoadHours : 0,
            peopleCount: peopleCount,
            startAt: startAt,
            endAt: endAt,
            blocks: blocks,
            totalAmount: AdventurePricing.total(
                packageType: packageType,
                offRoadHours: packageType.includesOffRoad ? offRoadHours : 0,
                peopleCount: peopleCount
            )
        )
    }
    
    static func slotIndices(
        for block: AdventureBookingBlock,
        on day: Date
    ) -> [Int] {
        let startIndex = AdventureDateHelper.slotIndex(for: block.startAt, on: day)
        let durationSlots = max(1, block.durationMinutes / AdventureScheduleConfig.slotMinutes)
        return Array(startIndex..<(startIndex + durationSlots))
    }
}

enum AdventureAvailabilityBuilder {
    static func buildSlots(
        day: Date,
        packageType: AdventurePackageType,
        offRoadHours: Int,
        peopleCount: Int,
        inventory: [AdventureInventoryKey: Int]
    ) -> [AdventureAvailabilitySlot] {
        let now = Date()
        let isToday = AdventureDateHelper.calendar.isDate(day, inSameDayAs: now)
        
        return (0..<AdventureScheduleConfig.totalSlots).compactMap { slotIndex in
            let startAt = AdventureDateHelper.slotStart(on: day, slotIndex: slotIndex)
            
            if isToday && startAt < now {
                return nil
            }
            
            guard let plan = AdventurePlanner.buildPlan(
                day: day,
                startAt: startAt,
                packageType: packageType,
                offRoadHours: packageType.includesOffRoad ? offRoadHours : 0,
                peopleCount: peopleCount
            ) else {
                return nil
            }
            
            for block in plan.blocks {
                let indices = AdventurePlanner.slotIndices(for: block, on: day)
                for index in indices {
                    let key = AdventureInventoryKey(activity: block.activity, slotIndex: index)
                    let reserved = inventory[key] ?? 0
                    let capacity = AdventureScheduleConfig.capacity(for: block.activity)
                    
                    if reserved + peopleCount > capacity {
                        return nil
                    }
                }
            }
            
            return AdventureAvailabilitySlot(
                id: "\(AdventureDateHelper.dayKey(from: day))-\(slotIndex)-\(packageType.rawValue)-\(peopleCount)-\(offRoadHours)",
                startAt: plan.startAt,
                endAt: plan.endAt,
                blocks: plan.blocks,
                totalAmount: plan.totalAmount
            )
        }
    }
}
