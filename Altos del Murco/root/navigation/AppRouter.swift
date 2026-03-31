//
//  Common.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import SwiftUI

final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func goToRoot() {
        path = NavigationPath()
    }
}
