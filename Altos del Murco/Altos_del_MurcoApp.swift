//
//  Altos_del_MurcoApp.swift
//  Altos del Murco
//
//  Created by José Ruiz on 7/3/26.
//

import SwiftUI
import FirebaseCore

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        return true
    }
}

@main
struct AltosDelMurcoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var cartManager = CartManager()
    @StateObject private var router = AppRouter()

    @StateObject private var ordersViewModel: OrdersViewModel
    @StateObject private var checkoutViewModel: CheckoutViewModel
    private let adventureModuleFactory: AdventureModuleFactory

    init() {
        FirebaseApp.configure()
        // Build services and use cases using local temporaries to avoid capturing self
        let ordersService: OrdersServiceable = FirebaseOrdersService()
        let observeOrdersUseCase = ObserveOrdersUseCase(service: ordersService)
        let submitOrderUseCase = SubmitOrderUseCase(service: ordersService)

        // Build view models without referencing self
        let ordersVM = OrdersViewModel(observeOrdersUseCase: observeOrdersUseCase)
        let checkoutVM = CheckoutViewModel(submitOrderUseCase: submitOrderUseCase, cartManager: CartManager())

        // Assign to StateObjects
        _ordersViewModel = StateObject(wrappedValue: ordersVM)
        _checkoutViewModel = StateObject(wrappedValue: checkoutVM)

        // Build other dependencies
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
            .environmentObject(router)
        }
    }
}
//
//import FirebaseCore
//import SwiftUI
//
//@main
//struct AltosDelMurcoApp: App {
//    @StateObject private var cartManager = CartManager()
//    @StateObject private var router = AppRouter()
//
//    @StateObject private var ordersViewModel: OrdersViewModel
//    @StateObject private var checkoutViewModel: CheckoutViewModel
//    private let adventureModuleFactory: AdventureModuleFactory
//    
//    init() {
//        FirebaseApp.configure()
//
//        let ordersService = FirebaseOrdersService()
//
//        let observeOrdersUseCase = ObserveOrdersUseCase(service: ordersService)
//        let submitOrderUseCase = SubmitOrderUseCase(service: ordersService)
//
//        let cartManager = CartManager()
//
//        _ordersViewModel = StateObject(
//            wrappedValue: OrdersViewModel(
//                observeOrdersUseCase: observeOrdersUseCase
//            )
//        )
//
//        _checkoutViewModel = StateObject(
//            wrappedValue: CheckoutViewModel(
//                submitOrderUseCase: submitOrderUseCase,
//                cartManager: cartManager
//            )
//        )
//
//        _cartManager = StateObject(wrappedValue: cartManager)
//        
//        let adventureModuleFactory: AdventureModuleFactory
//        let adventureService = FirestoreAdventureBookingsService()
//        self.adventureModuleFactory = AdventureModuleFactory(service: adventureService)
//          
//    }
//
//    var body: some Scene {
//            WindowGroup {
//                MainTabView(
//                    ordersViewModel: ordersViewModel,
//                    checkoutViewModel: checkoutViewModel,
//                    adventureModuleFactory: adventureModuleFactory
//                )
//                .environmentObject(cartManager)
////                .environmentObject(router)
//            }
//        }
//}
