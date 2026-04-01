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
    private let adventureModuleFactory: AdventureModuleFactory
    
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
        
        let adventureModuleFactory: AdventureModuleFactory
        let adventureService = FirestoreAdventureBookingsService()
        self.adventureModuleFactory = AdventureModuleFactory(service: adventureService)
          
    }

    var body: some Scene {
            WindowGroup {
                MainTabView(
                    ordersViewModel: ordersViewModel,
                    checkoutViewModel: checkoutViewModel,
                    adventureModuleFactory: adventureModuleFactory
                )
                .environmentObject(cartManager)
//                .environmentObject(router)
            }
        }
}
