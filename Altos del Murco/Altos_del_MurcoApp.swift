//
//  Altos_del_MurcoApp.swift
//  Altos del Murco
//
//  Created by José Ruiz on 7/3/26.
//

import FirebaseCore
import SwiftUI

@main
struct AltosDelMurcoApp: App {
    @StateObject private var cartManager = CartManager()
    @StateObject private var router = AppRouter()

    @StateObject private var ordersViewModel: OrdersViewModel
    @StateObject private var checkoutViewModel: CheckoutViewModel

    init() {
        FirebaseApp.configure()

        let ordersService = FirebaseOrdersService()

        let observeOrdersUseCase = ObserveOrdersUseCase(service: ordersService)
        let submitOrderUseCase = SubmitOrderUseCase(service: ordersService)

        let cartManager = CartManager()

        _ordersViewModel = StateObject(
            wrappedValue: OrdersViewModel(
                observeOrdersUseCase: observeOrdersUseCase
            )
        )

        _checkoutViewModel = StateObject(
            wrappedValue: CheckoutViewModel(
                submitOrderUseCase: submitOrderUseCase,
                cartManager: cartManager
            )
        )

        _cartManager = StateObject(wrappedValue: cartManager)
    }

    var body: some Scene {
        WindowGroup {
            MenuListView(
                sections: MenuMockData.sections,
                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel
            )
            .environmentObject(cartManager)
            .environmentObject(router)
        }
    }
}
