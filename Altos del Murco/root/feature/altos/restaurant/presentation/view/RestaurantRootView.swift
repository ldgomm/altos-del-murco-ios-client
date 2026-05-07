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

    init(
        ordersViewModel: OrdersViewModel,
        checkoutViewModel: CheckoutViewModel,
        adventureComboBuilderViewModel: AdventureComboBuilderViewModel,
        menuViewModel: MenuViewModel
    ) {
        self.ordersViewModel = ordersViewModel
        self.checkoutViewModel = checkoutViewModel
        self.adventureComboBuilderViewModel = adventureComboBuilderViewModel
        self.menuViewModel = menuViewModel
    }

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
                        menuViewModel: menuViewModel,
                        path: $path
                    )
                }
            }
            .navigationDestination(for: Route.self) { route in
                routeDestination(route)
            }
        }
        .onAppear {
            menuViewModel.onAppear()
            RemoteImageLoader.prefetch(urls: menuViewModel.state.sections.menuImageURLs)
        }
        .onChange(of: menuViewModel.state.sections) { _, sections in
            RemoteImageLoader.prefetch(urls: sections.menuImageURLs)
        }
    }

    @ViewBuilder
    private func routeDestination(_ route: Route) -> some View {
        switch route {
        case let .menuDetail(item, categoryTitle):
            MenuItemDetailView(
                item: item,
                categoryTitle: categoryTitle,
                rewardPresentationProvider: { item, quantity in
                    menuViewModel.rewardPresentation(for: item, quantity: quantity)
                },
                displayedPriceProvider: { item, quantity in
                    menuViewModel.displayedPrice(for: item, quantity: quantity)
                },
                incrementalDiscountProvider: { item, quantity in
                    menuViewModel.incrementalDiscount(for: item, quantity: quantity)
                }
            )

        case .cart:
            ProtectedAccessRequiredView(
                title: "Inicia sesión para finalizar tu pedido",
                message: "Puedes explorar el menú libremente. Para enviar el pedido necesitamos tu cuenta.",
                systemImage: "cart.fill",
                theme: .restaurant
            ) {
                CartView(viewModel: checkoutViewModel)
            }

        case .checkout:
            ProtectedAccessRequiredView(
                title: "Inicia sesión para finalizar tu pedido",
                message: "Puedes explorar el menú libremente. Para enviar el pedido necesitamos tu cuenta.",
                systemImage: "cart.fill",
                theme: .restaurant
            ) {
                CheckoutView(
                    viewModel: checkoutViewModel,
                    path: $path
                )
            }

        case .reservationBuilder:
            AdventureComboBuilderView(
                adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                menuViewModel: menuViewModel
            )
            .onAppear {
                adventureComboBuilderViewModel.prepareCustomDraftIfNeeded()
            }

        case let .orderSuccess(order):
            OrderSuccessView(
                order: order,
                path: $path
            )
        }
    }
}
