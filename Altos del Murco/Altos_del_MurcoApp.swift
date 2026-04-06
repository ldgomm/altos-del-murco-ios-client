//
//  Altos_del_MurcoApp.swift
//  Altos del Murco
//
//  Created by José Ruiz on 7/3/26.
//

import SwiftUI
import FirebaseCore
import SwiftData

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

    private let sharedModelContainer: ModelContainer

    @StateObject private var cartManager: CartManager
    @StateObject private var router = AppRouter()
    @StateObject private var appPreferences = AppPreferences()

    @StateObject private var ordersViewModel: OrdersViewModel
    @StateObject private var checkoutViewModel: CheckoutViewModel
    @StateObject private var sessionViewModel: AppSessionViewModel

    private let adventureModuleFactory: AdventureModuleFactory

    init() {
        FirebaseApp.configure()
        ThemeAppearance.configure()

        do {
            let schema = Schema([
                CartDraftEntity.self,
                CartItemEntity.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            self.sharedModelContainer = container

            let cartPersistence = CartPersistenceService(context: container.mainContext)
            let sharedCartManager = CartManager(persistence: cartPersistence)

            _cartManager = StateObject(wrappedValue: sharedCartManager)

            let ordersService: OrdersServiceable = FirebaseOrdersService()
            let observeOrdersUseCase = ObserveOrdersUseCase(service: ordersService)
            let submitOrderUseCase = SubmitOrderUseCase(service: ordersService)

            let ordersVM = OrdersViewModel(observeOrdersUseCase: observeOrdersUseCase)
            let checkoutVM = CheckoutViewModel(
                submitOrderUseCase: submitOrderUseCase,
                cartManager: sharedCartManager
            )

            _ordersViewModel = StateObject(wrappedValue: ordersVM)
            _checkoutViewModel = StateObject(wrappedValue: checkoutVM)

            let adventureService = FirestoreAdventureBookingsService()
            self.adventureModuleFactory = AdventureModuleFactory(service: adventureService)

            let authRepository: AuthenticationRepositoriable = FirebaseAuthenticationRepository()
            let clientProfileRepository: ClientProfileRepositoriable = FirestoreClientProfileRepository()

            let signInWithAppleUseCase = SignInWithAppleUseCase(repository: authRepository)
            let resolveSessionUseCase = ResolveSessionUseCase(
                authRepository: authRepository,
                clientProfileRepository: clientProfileRepository
            )
            let completeClientProfileUseCase = CompleteClientProfileUseCase(
                repository: clientProfileRepository
            )
            let deleteCurrentAccountUseCase = DeleteCurrentAccountUseCase(
                authRepository: authRepository,
                clientProfileRepository: clientProfileRepository
            )
            let signOutUseCase = SignOutUseCase(repository: authRepository)

            let sessionVM = AppSessionViewModel(
                signInWithAppleUseCase: signInWithAppleUseCase,
                resolveSessionUseCase: resolveSessionUseCase,
                completeClientProfileUseCase: completeClientProfileUseCase,
                deleteCurrentAccountUseCase: deleteCurrentAccountUseCase,
                signOutUseCase: signOutUseCase
            )

            _sessionViewModel = StateObject(wrappedValue: sessionVM)

        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: sessionViewModel) {
                MainTabView(
                    ordersViewModel: ordersViewModel,
                    checkoutViewModel: checkoutViewModel,
                    adventureModuleFactory: adventureModuleFactory
                )
            }
            .environmentObject(cartManager)
            .environmentObject(router)
            .environmentObject(sessionViewModel)
            .environmentObject(appPreferences)
            .preferredColorScheme(appPreferences.preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
