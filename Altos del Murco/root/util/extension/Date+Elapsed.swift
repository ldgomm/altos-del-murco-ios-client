//
//  Date+Elapsed.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

extension Date {
    func elapsedTimeText(relativeTo now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: now)
    }
    
    func elapsedMinutes(relativeTo now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(self) / 60))
    }
}
