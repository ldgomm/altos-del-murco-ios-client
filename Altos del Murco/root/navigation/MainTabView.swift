//
//  MainTabBiew.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home
    
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    let adventureModuleFactory: AdventureModuleFactory
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, adventureModuleFactory: adventureModuleFactory)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(MainTab.home)
            
            RestaurantRootView(
                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel
            )
            .tabItem {
                Label("Restaurant", systemImage: "fork.knife")
            }
            .tag(MainTab.restaurant)
            ExperiencesView(adventureModuleFactory: adventureModuleFactory)
                .tabItem {
                    Label("Experiences", systemImage: "figure")
                }
                .tag(MainTab.experiences)

            BookingsView(
                ordersViewModel: ordersViewModel,
                adventureModuleFactory: adventureModuleFactory
            )
            .tabItem {
                Label("Bookings", systemImage: "calendar")
            }
            .tag(MainTab.bookings)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(MainTab.profile)
        }
    }
}

enum MainTab {
    case home
    case restaurant
    case experiences
    case bookings
    case profile
}
