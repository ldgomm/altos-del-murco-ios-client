//
//  MainTabBiew.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: MainTab = .home
    
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    private let adventureModuleFactory: AdventureModuleFactory
    @StateObject private var adventureComboBuilderViewModel: AdventureComboBuilderViewModel

    init(
        ordersViewModel: OrdersViewModel,
        checkoutViewModel: CheckoutViewModel,
        menuViewModel: MenuViewModel,
        adventureModuleFactory: AdventureModuleFactory
    ) {
        self.ordersViewModel = ordersViewModel
        self.checkoutViewModel = checkoutViewModel
        self.menuViewModel = menuViewModel
        self.adventureModuleFactory = adventureModuleFactory
        
        _adventureComboBuilderViewModel = StateObject(
            wrappedValue: adventureModuleFactory.makeBuilderViewModel()
        )
    }
    
    
    private var selectedPalette: ThemePalette {
        AppTheme.palette(for: selectedTab.theme, scheme: colorScheme)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
            )
            .tabItem {
                Label(MainTab.home.title, systemImage: MainTab.home.systemImage)
            }
            .tag(MainTab.home)
            
            RestaurantRootView(
                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel,
                adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                menuViewModel: menuViewModel
            )
            .tabItem {
                Label(MainTab.restaurant.title, systemImage: MainTab.restaurant.systemImage)
            }
            .tag(MainTab.restaurant)
            
            ExperiencesView(
                adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel
            )
            .tabItem {
                Label(MainTab.experiences.title, systemImage: MainTab.experiences.systemImage)
            }
            .tag(MainTab.experiences)

            BookingsView(
                ordersViewModel: ordersViewModel,
                adventureModuleFactory: adventureModuleFactory
            )
            .tabItem {
                Label(MainTab.bookings.title, systemImage: MainTab.bookings.systemImage)
            }
            .tag(MainTab.bookings)
            
            ProfileContainerView()
                .tabItem {
                    Label(MainTab.profile.title, systemImage: MainTab.profile.systemImage)
                }
                .tag(MainTab.profile)
        }
        .onAppear { menuViewModel.onAppear() }
        .onDisappear { menuViewModel.onDisappear() }
        .tint(selectedPalette.primary)
        .animation(.easeInOut(duration: 0.22), value: selectedTab)
    }
}

enum MainTab: Hashable {
    case home
    case restaurant
    case experiences
    case bookings
    case profile
    
    var title: String {
        switch self {
        case .home: return "Inicio"
        case .restaurant: return "Restaurante"
        case .experiences: return "Aventura"
        case .bookings: return "Reservas"
        case .profile: return "Perfil"
        }
    }
    
    var systemImage: String {
        switch self {
        case .home: return "house"
        case .restaurant: return "fork.knife"
        case .experiences: return "figure"
        case .bookings: return "calendar"
        case .profile: return "person.crop.circle"
        }
    }
    
    var theme: AppSectionTheme {
        switch self {
        case .home: return .neutral
        case .restaurant: return .restaurant
        case .experiences: return .adventure
        case .bookings: return .neutral
        case .profile: return .neutral
        }
    }
}
