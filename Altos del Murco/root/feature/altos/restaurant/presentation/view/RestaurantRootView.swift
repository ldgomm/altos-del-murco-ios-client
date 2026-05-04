//
//  RestaurantRootView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct RestaurantRootView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if menuViewModel.state.isLoading && menuViewModel.state.sections.isEmpty {
                    ProgressView("Cargando menú...")
                } else {
                    MenuListView(
                        sections: menuViewModel.state.sections,
                        checkoutViewModel: checkoutViewModel,
                        ordersViewModel: ordersViewModel,
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel,
                        path: $path
                    )
                }
            }
        }
        .onAppear {
            menuViewModel.onAppear()

            RemoteImageLoader.prefetch(
                urls: menuViewModel.state.sections.menuImageURLs
            )
        }
        .onChange(of: menuViewModel.state.sections) { _, sections in
            RemoteImageLoader.prefetch(urls: sections.menuImageURLs)
        }
    }
}
