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
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Seguir la apariencia del dispositivo"
        case .light: return "Usar siempre el modo claro"
        case .dark: return "Usar siempre el modo oscuro"
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
