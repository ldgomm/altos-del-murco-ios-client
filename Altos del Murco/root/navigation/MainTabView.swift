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
    
    private let adventureModuleFactory: AdventureModuleFactory
    @StateObject private var comboBuilderViewModel: AdventureComboBuilderViewModel
    @StateObject private var adventureBookingsViewModel: AdventureBookingsViewModel
    
    init(
        ordersViewModel: OrdersViewModel,
        checkoutViewModel: CheckoutViewModel,
        adventureModuleFactory: AdventureModuleFactory
    ) {
        self.ordersViewModel = ordersViewModel
        self.checkoutViewModel = checkoutViewModel
        self.adventureModuleFactory = adventureModuleFactory
        
        _comboBuilderViewModel = StateObject(
            wrappedValue: adventureModuleFactory.makeBuilderViewModel()
        )
        
        _adventureBookingsViewModel = StateObject(
            wrappedValue: adventureModuleFactory.makeBookingsViewModel()
        )
    }
    
    private var selectedPalette: ThemePalette {
        AppTheme.palette(for: selectedTab.theme, scheme: colorScheme)
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
                comboBuilderViewModel: comboBuilderViewModel
            )
            .tabItem {
                Label(MainTab.home.title, systemImage: MainTab.home.systemImage)
            }
            .tag(MainTab.home)
            
            RestaurantRootView(
                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel
            )
            .tabItem {
                Label(MainTab.restaurant.title, systemImage: MainTab.restaurant.systemImage)
            }
            .tag(MainTab.restaurant)
            
            ExperiencesView(
                comboBuilderViewModel: comboBuilderViewModel
            )
            .tabItem {
                Label(MainTab.experiences.title, systemImage: MainTab.experiences.systemImage)
            }
            .tag(MainTab.experiences)

            BookingsView(
                ordersViewModel: ordersViewModel,
                adventureBookingsViewModel: adventureBookingsViewModel
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
        case .home: return "Home"
        case .restaurant: return "Restaurant"
        case .experiences: return "Experiences"
        case .bookings: return "Bookings"
        case .profile: return "Profile"
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
