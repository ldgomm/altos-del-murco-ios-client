//
//  Common.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Presentation: Identifiable, Hashable {
        case directions

        var id: String {
            switch self {
            case .directions:
                return "directions"
            }
        }
    }

    @Published var path = NavigationPath()
    @Published var presentation: Presentation?

    func goToRoot() {
        path = NavigationPath()
        presentation = nil
    }

    func openDirections() {
        presentation = .directions
    }

    func dismissPresentation() {
        presentation = nil
    }

    func handleDeepLink(_ url: URL) {
        guard RouteDeepLink.isDirectionsURL(url) else {
            return
        }

        openDirections()
    }
}
