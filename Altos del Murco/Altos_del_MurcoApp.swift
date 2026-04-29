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
        true
    }
}

@main
struct AltosDelMurcoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    private let sharedModelContainer: ModelContainer

    @Environment(\.scenePhase) private var scenePhase
    
    @StateObject private var cartManager: CartManager
    @StateObject private var router = AppRouter()
    @StateObject private var appPreferences = AppPreferences()

    @StateObject private var ordersViewModel: OrdersViewModel
    @StateObject private var checkoutViewModel: CheckoutViewModel
    @StateObject private var sessionViewModel: AppSessionViewModel
    @StateObject private var menuViewModel: MenuViewModel
    @StateObject private var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    
    @StateObject private var routeNavigator: RouteNavigationManager

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

            let loyaltyRewardsService: LoyaltyRewardsServiceable = LoyaltyRewardsService()

            let ordersService: OrdersServiceable = OrdersService(
                loyaltyRewardsService: loyaltyRewardsService
            )
            let observeOrdersUseCase = ObserveOrdersUseCase(service: ordersService)
            let submitOrderUseCase = SubmitOrderUseCase(service: ordersService)

            _ordersViewModel = StateObject(
                wrappedValue: OrdersViewModel(observeOrdersUseCase: observeOrdersUseCase)
            )
            _checkoutViewModel = StateObject(
                wrappedValue: CheckoutViewModel(
                    submitOrderUseCase: submitOrderUseCase,
                    cartManager: sharedCartManager,
                    loyaltyRewardsService: loyaltyRewardsService
                )
            )

            let adventureCatalogService = AdventureCatalogService()
            let adventureBookingsService = AdventureBookingsService(
                catalogService: adventureCatalogService,
                loyaltyRewardsService: loyaltyRewardsService
            )

            let factory = AdventureModuleFactory(
                bookingsService: adventureBookingsService,
                catalogService: adventureCatalogService,
                loyaltyRewardsService: loyaltyRewardsService
            )
            self.adventureModuleFactory = factory

            _adventureComboBuilderViewModel = StateObject(
                wrappedValue: factory.makeBuilderViewModel()
            )

            let authRepository: AuthenticationRepositoriable = AuthenticationRepository()
            let clientProfileRepository: ClientProfileRepositoriable = ClientProfileRepository()

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
            let verifyCurrentUserSessionUseCase = VerifyCurrentUserSessionUseCase(repository: authRepository)

            _sessionViewModel = StateObject(
                wrappedValue: AppSessionViewModel(
                    signInWithAppleUseCase: signInWithAppleUseCase,
                    resolveSessionUseCase: resolveSessionUseCase,
                    completeClientProfileUseCase: completeClientProfileUseCase,
                    deleteCurrentAccountUseCase: deleteCurrentAccountUseCase,
                    signOutUseCase: signOutUseCase,
                    verifyCurrentUserSessionUseCase: verifyCurrentUserSessionUseCase,
                    loyaltyRewardsService: loyaltyRewardsService
                )
            )

            let menuService = MenuService()
            _menuViewModel = StateObject(
                wrappedValue: MenuViewModel(
                    service: menuService,
                    loyaltyRewardsService: loyaltyRewardsService
                )
            )
            
            _routeNavigator = StateObject(wrappedValue: RouteNavigationManager())
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
                    menuViewModel: menuViewModel,
                    adventureModuleFactory: adventureModuleFactory,
                    adventureComboBuilderViewModel: adventureComboBuilderViewModel
                )
            }
            .environmentObject(cartManager)
            .environmentObject(router)
            .environmentObject(sessionViewModel)
            .environmentObject(appPreferences)
            .environmentObject(routeNavigator)
            .preferredColorScheme(appPreferences.preferredColorScheme)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    sessionViewModel.verifySessionStillValidFromSceneActivation()
                }
            }
            .onOpenURL { url in
                router.handleDeepLink(url)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
