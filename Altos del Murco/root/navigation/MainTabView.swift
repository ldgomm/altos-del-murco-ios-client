//
//  MainTabBiew.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

//
//  MainTabView.swift
//  Altos del Murco
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    @EnvironmentObject private var routeNavigator: RouteNavigationManager
    
    @State private var selectedTab: MainTab = .home

    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel

    private let adventureModuleFactory: AdventureModuleFactory

    init(
        ordersViewModel: OrdersViewModel,
        checkoutViewModel: CheckoutViewModel,
        menuViewModel: MenuViewModel,
        adventureModuleFactory: AdventureModuleFactory,
        adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    ) {
        self.ordersViewModel = ordersViewModel
        self.checkoutViewModel = checkoutViewModel
        self.menuViewModel = menuViewModel
        self.adventureModuleFactory = adventureModuleFactory
        self.adventureComboBuilderViewModel = adventureComboBuilderViewModel
    }

    private var selectedPalette: ThemePalette {
        AppTheme.palette(for: selectedTab.theme, scheme: colorScheme)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
                menuViewModel: menuViewModel,
                adventureComboBuilderViewModel: adventureComboBuilderViewModel
            )
            
            .tabItem { Label(MainTab.home.title, systemImage: MainTab.home.systemImage) }
            .tag(MainTab.home)

            RestaurantRootView(
                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel,
                adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                menuViewModel: menuViewModel
            )
            .tabItem { Label(MainTab.restaurant.title, systemImage: MainTab.restaurant.systemImage) }
            .tag(MainTab.restaurant)

            ExperiencesView(
                adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                menuViewModel: menuViewModel
            )
            .tabItem { Label(MainTab.experiences.title, systemImage: MainTab.experiences.systemImage) }
            .tag(MainTab.experiences)

            BookingsView(
                ordersViewModel: ordersViewModel,
                adventureModuleFactory: adventureModuleFactory
            )
            .tabItem { Label(MainTab.bookings.title, systemImage: MainTab.bookings.systemImage) }
            .tag(MainTab.bookings)

            ProfileContainerView()
                .tabItem { Label(MainTab.profile.title, systemImage: MainTab.profile.systemImage) }
                .tag(MainTab.profile)
        }
        .tint(selectedPalette.primary)
        .safeAreaInset(edge: .bottom) {
            if routeNavigator.shouldShowGlobalBanner {
                RouteBottomBanner()
                    .environmentObject(routeNavigator)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: routeNavigator.shouldShowGlobalBanner)

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
        case .experiences: return "Experiencias"
        case .bookings: return "Reservas"
        case .profile: return "Perfil"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .restaurant: return "fork.knife"
        case .experiences: return "mountain.2.fill"
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
