//
//  AppPreferences.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Follow the device appearance"
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppPreferences: ObservableObject {
    private enum Keys {
        static let appearance = "altos_del_murco_app_appearance"
    }

    @Published var appearance: AppAppearance {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.string(forKey: Keys.appearance)
        self.appearance = AppAppearance(rawValue: storedValue ?? "") ?? .system
    }

    var preferredColorScheme: ColorScheme? {
        appearance.colorScheme
    }
}
