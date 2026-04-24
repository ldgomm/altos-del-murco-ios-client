# Altos del Murco/Altos_del_MurcoApp.swift

```swift
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

    @StateObject private var cartManager: CartManager
    @StateObject private var router = AppRouter()
    @StateObject private var appPreferences = AppPreferences()

    @StateObject private var ordersViewModel: OrdersViewModel
    @StateObject private var checkoutViewModel: CheckoutViewModel
    @StateObject private var sessionViewModel: AppSessionViewModel
    @StateObject private var menuViewModel: MenuViewModel
    @StateObject private var adventureComboBuilderViewModel: AdventureComboBuilderViewModel

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

            _sessionViewModel = StateObject(
                wrappedValue: AppSessionViewModel(
                    signInWithAppleUseCase: signInWithAppleUseCase,
                    resolveSessionUseCase: resolveSessionUseCase,
                    completeClientProfileUseCase: completeClientProfileUseCase,
                    deleteCurrentAccountUseCase: deleteCurrentAccountUseCase,
                    signOutUseCase: signOutUseCase,
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
            .preferredColorScheme(appPreferences.preferredColorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}

```

---

# Altos del Murco/ContentView.swift

```swift
//
//  ContentView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 7/3/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("")
//        MenuListView(sections: MenuMockData.sections)
    }
}

#Preview {
    ContentView()
}

```

---

# Altos del Murco/root/feature/altos/adventure/data/AdventureBookingDto.swift

```swift
//
//  AdventureBookingDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

protocol AdventureListenerToken {
    func remove()
}

final class FirestoreAdventureListenerToken: AdventureListenerToken {
    private var registration: ListenerRegistration?
    
    init(registration: ListenerRegistration) {
        self.registration = registration
    }
    
    func remove() {
        registration?.remove()
        registration = nil
    }
}

struct AdventureReservationItemDraftDto: Codable {
    let id: String
    let activity: String
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int
    
    init(from item: AdventureReservationItemDraft) {
        self.id = item.id
        self.activity = item.activity.rawValue
        self.durationMinutes = item.durationMinutes
        self.peopleCount = item.peopleCount
        self.vehicleCount = item.vehicleCount
        self.offRoadRiderCount = item.offRoadRiderCount
        self.nights = item.nights
    }
    
    func toDomain() -> AdventureReservationItemDraft? {
        guard let activity = AdventureActivityType(rawValue: activity) else { return nil }
        
        return AdventureReservationItemDraft(
            id: id,
            activity: activity,
            durationMinutes: durationMinutes,
            peopleCount: peopleCount,
            vehicleCount: vehicleCount,
            offRoadRiderCount: offRoadRiderCount,
            nights: nights
        )
    }
}

struct ReservationFoodItemDraftDto: Codable {
    let id: String
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let notes: String?
    
    init(from item: ReservationFoodItemDraft) {
        self.id = item.id
        self.menuItemId = item.menuItemId
        self.name = item.name
        self.unitPrice = item.unitPrice
        self.quantity = item.quantity
        self.notes = item.notes
    }
    
    func toDomain() -> ReservationFoodItemDraft {
        ReservationFoodItemDraft(
            id: id,
            menuItemId: menuItemId,
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            notes: notes
        )
    }
}

struct ReservationFoodDraftDto: Codable {
    let items: [ReservationFoodItemDraftDto]
    let servingMoment: String
    let servingTime: Timestamp?
    let notes: String?
    
    init(from food: ReservationFoodDraft) {
        self.items = food.items.map(ReservationFoodItemDraftDto.init(from:))
        self.servingMoment = food.servingMoment.rawValue
        self.servingTime = food.servingTime.map(Timestamp.init(date:))
        self.notes = food.notes
    }
    
    func toDomain() -> ReservationFoodDraft {
        ReservationFoodDraft(
            items: items.map { $0.toDomain() },
            servingMoment: ReservationServingMoment(rawValue: servingMoment) ?? .afterActivities,
            servingTime: servingTime?.dateValue(),
            notes: notes
        )
    }
}

struct AdventureBookingBlockDto: Codable {
    let id: String
    let title: String
    let activity: String
    let resourceType: String
    let startAt: Timestamp
    let endAt: Timestamp
    let reservedUnits: Int
    let subtotal: Double
    
    init(from block: AdventureBookingBlock) {
        self.id = block.id
        self.title = block.title
        self.activity = block.activity.rawValue
        self.resourceType = block.resourceType.rawValue
        self.startAt = Timestamp(date: block.startAt)
        self.endAt = Timestamp(date: block.endAt)
        self.reservedUnits = block.reservedUnits
        self.subtotal = block.subtotal
    }
    
    func toDomain() -> AdventureBookingBlock? {
        guard let activity = AdventureActivityType(rawValue: activity),
              let resource = AdventureResourceType(rawValue: resourceType) else {
            return nil
        }
        
        return AdventureBookingBlock(
            id: id,
            title: title,
            activity: activity,
            resourceType: resource,
            startAt: startAt.dateValue(),
            endAt: endAt.dateValue(),
            reservedUnits: reservedUnits,
            subtotal: subtotal
        )
    }
}

struct AdventureAppliedRewardDto: Codable {
    let id: String
    let templateId: String
    let title: String
    let amount: Double
    let note: String
    let affectedMenuItemIds: [String]
    let affectedActivityIds: [String]

    init(domain: AppliedReward) {
        self.id = domain.id
        self.templateId = domain.templateId
        self.title = domain.title
        self.amount = domain.amount
        self.note = domain.note
        self.affectedMenuItemIds = domain.affectedMenuItemIds
        self.affectedActivityIds = domain.affectedActivityIds
    }

    func toDomain() -> AppliedReward {
        AppliedReward(
            id: id,
            templateId: templateId,
            title: title,
            amount: amount,
            note: note,
            affectedMenuItemIds: affectedMenuItemIds,
            affectedActivityIds: affectedActivityIds
        )
    }
}

@MainActor
struct AdventureBookingDto: Codable {
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let startDayKey: String
    let startAt: Timestamp
    let endAt: Timestamp
    let guestCount: Int?
    let eventType: String?
    let customEventTitle: String?
    let eventNotes: String?
    let items: [AdventureReservationItemDraftDto]
    let foodReservation: ReservationFoodDraftDto?
    let blocks: [AdventureBookingBlockDto]
    let adventureSubtotal: Double?
    let foodSubtotal: Double?
    let subtotal: Double
    let discountAmount: Double
    let loyaltyDiscountAmount: Double?
    let appliedRewards: [AdventureAppliedRewardDto]?
    let nightPremium: Double
    let totalAmount: Double
    let status: String
    let createdAt: Timestamp
    let notes: String?

    func toDomain(documentId: String) -> AdventureBooking {
        AdventureBooking(
            id: documentId,
            clientId: clientId,
            clientName: clientName,
            whatsappNumber: whatsappNumber,
            nationalId: nationalId,
            startDayKey: startDayKey,
            startAt: startAt.dateValue(),
            endAt: endAt.dateValue(),
            guestCount: guestCount ?? 1,
            eventType: ReservationEventType(rawValue: eventType ?? "") ?? .regularVisit,
            customEventTitle: customEventTitle,
            eventNotes: eventNotes,
            items: items.compactMap { $0.toDomain() },
            foodReservation: foodReservation?.toDomain(),
            blocks: blocks.compactMap { $0.toDomain() },
            adventureSubtotal: adventureSubtotal ?? subtotal,
            foodSubtotal: foodSubtotal ?? 0,
            subtotal: subtotal,
            discountAmount: discountAmount,
            loyaltyDiscountAmount: loyaltyDiscountAmount ?? 0,
            appliedRewards: appliedRewards?.compactMap { $0.toDomain() } ?? [],
            nightPremium: nightPremium,
            totalAmount: totalAmount,
            status: AdventureBookingStatus(rawValue: status) ?? .confirmed,
            createdAt: createdAt.dateValue(),
            notes: notes
        )
    }

    static func from(
        bookingId: String,
        request: AdventureBookingRequest,
        plan: AdventureBuildPlan,
        createdAt: Date,
        status: AdventureBookingStatus = .pending
    ) -> AdventureBookingDto {
        AdventureBookingDto(
            clientId: request.clientId,
            clientName: request.clientName,
            whatsappNumber: request.whatsappNumber,
            nationalId: request.nationalId,
            startDayKey: AdventureDateHelper.dayKey(from: plan.startAt),
            startAt: Timestamp(date: plan.startAt),
            endAt: Timestamp(date: plan.endAt),
            guestCount: request.guestCount,
            eventType: request.eventType.rawValue,
            customEventTitle: request.customEventTitle,
            eventNotes: request.eventNotes,
            items: request.items.map(AdventureReservationItemDraftDto.init(from:)),
            foodReservation: request.foodReservation.map(ReservationFoodDraftDto.init(from:)),
            blocks: plan.blocks.map(AdventureBookingBlockDto.init(from:)),
            adventureSubtotal: plan.adventureSubtotal,
            foodSubtotal: plan.foodSubtotal,
            subtotal: plan.subtotal,
            discountAmount: plan.discountAmount,
            loyaltyDiscountAmount: request.loyaltyDiscountAmount,
            appliedRewards: request.appliedRewards.map(AdventureAppliedRewardDto.init(domain:)),
            nightPremium: plan.nightPremium,
            totalAmount: plan.totalAmount,
            status: status.rawValue,
            createdAt: Timestamp(date: createdAt),
            notes: request.notes
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/data/AdventureBookingsService.swift

```swift
//
//  FirestoreAdventureBookingsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation
import FirebaseFirestore

private final class EmptyAdventureListenerToken: AdventureListenerToken {
    func remove() { }
}

final class AdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = "adventure_bookings"
    private let catalogService: AdventureCatalogServiceable
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        catalogService: AdventureCatalogServiceable,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.catalogService = catalogService
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func observeBookings(
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            onChange(.success([]))
            return EmptyAdventureListenerToken()
        }

        let registration = db.collection(bookingsCollection)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .order(by: "startAt", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    onChange(.success([]))
                    return
                }

                do {
                    let bookings = try snapshot.documents.map { document in
                        let dto = try document.data(as: AdventureBookingDto.self)
                        return dto.toDomain(documentId: document.documentID)
                    }

                    onChange(.success(bookings))
                } catch {
                    onChange(.failure(error))
                }
            }

        return FirestoreAdventureListenerToken(registration: registration)
    }

    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double
    ) async throws -> [AdventureAvailabilitySlot] {
        let catalog = try await catalogService.fetchCatalog()

        return AdventurePlanner.buildAvailability(
            day: date,
            items: items,
            foodReservation: foodReservation,
            packageDiscountAmount: packageDiscountAmount,
            catalog: catalog
        )
    }

    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        let catalog = try await catalogService.fetchCatalog()

        guard let basePlan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            items: request.items,
            foodReservation: request.foodReservation,
            packageDiscountAmount: request.packageDiscountAmount,
            catalog: catalog
        ) else {
            throw makeError("Invalid reservation configuration.")
        }

        let rewardPreview = try await loyaltyRewardsService.previewAdventureRewards(
            for: request.nationalId,
            activityItems: request.items,
            foodItems: request.foodReservation?.items ?? [],
            catalog: catalog
        )

        let finalPlan = AdventureBuildPlan(
            startAt: basePlan.startAt,
            endAt: basePlan.endAt,
            blocks: basePlan.blocks,
            adventureSubtotal: basePlan.adventureSubtotal,
            foodSubtotal: basePlan.foodSubtotal,
            subtotal: basePlan.subtotal,
            discountAmount: basePlan.discountAmount,
            loyaltyDiscountAmount: rewardPreview.totalDiscount,
            appliedRewards: rewardPreview.appliedRewards,
            nightPremium: basePlan.nightPremium,
            totalAmount: max(0, basePlan.totalAmount - rewardPreview.totalDiscount),
            hasNightPremium: basePlan.hasNightPremium
        )

        let normalizedRequest = AdventureBookingRequest(
            clientId: request.clientId,
            clientName: request.clientName,
            whatsappNumber: request.whatsappNumber,
            nationalId: request.nationalId,
            date: request.date,
            selectedStartAt: request.selectedStartAt,
            guestCount: request.guestCount,
            eventType: request.eventType,
            customEventTitle: request.customEventTitle,
            eventNotes: request.eventNotes,
            items: request.items,
            foodReservation: request.foodReservation,
            packageDiscountAmount: request.packageDiscountAmount,
            loyaltyDiscountAmount: rewardPreview.totalDiscount,
            appliedRewards: rewardPreview.appliedRewards,
            notes: request.notes
        )

        let createdAt = Date()
        let bookingRef = db.collection(bookingsCollection).document()

        let dto = AdventureBookingDto.from(
            bookingId: bookingRef.documentID,
            request: normalizedRequest,
            plan: finalPlan,
            createdAt: createdAt
        )

        let encodedBooking = try Firestore.Encoder().encode(dto)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            bookingRef.setData(encodedBooking) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        try await loyaltyRewardsService.reserveRewards(
            nationalId: normalizedRequest.nationalId,
            referenceType: .booking,
            referenceId: bookingRef.documentID,
            appliedRewards: normalizedRequest.appliedRewards
        )

        return dto.toDomain(documentId: bookingRef.documentID)
    }

    func cancelBooking(id: String, nationalId: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(id)
        let snapshot = try await bookingRef.getDocument()

        guard snapshot.exists else {
            throw makeError("Booking not found.")
        }

        let dto = try snapshot.data(as: AdventureBookingDto.self)

        guard dto.nationalId == nationalId else {
            throw makeError("You are not allowed to cancel this booking.")
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            bookingRef.updateData(
                ["status": AdventureBookingStatus.canceled.rawValue]
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        try await loyaltyRewardsService.releaseRewards(
            nationalId: dto.nationalId,
            referenceId: id
        )
    }

    private func makeError(_ message: String) -> NSError {
        NSError(
            domain: "AdventureBookingsService",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/data/AdventureCatalogDtos.swift

```swift
//
//  AdventureCatalogDtos.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

struct AdventureActivityDefaultsDto: Codable {
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int

    func toDomain() -> AdventureActivityDefaults {
        AdventureActivityDefaults(
            durationMinutes: durationMinutes,
            peopleCount: peopleCount,
            vehicleCount: vehicleCount,
            offRoadRiderCount: offRoadRiderCount,
            nights: nights
        )
    }
}

struct AdventureActivityCatalogDto: Codable {
    let id: String
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let includes: [String]
    let durationOptions: [Int]
    let pricingMode: String
    let basePrice: Double
    let discountAmount: Double
    let currency: String
    let defaults: AdventureActivityDefaultsDto
    let isActive: Bool
    let sortOrder: Int
    let updatedAt: Timestamp

    func toDomain() -> AdventureActivityCatalogItem? {
        guard let activityType = AdventureActivityType(rawValue: id),
              let pricingMode = AdventurePricingMode(rawValue: pricingMode) else {
            return nil
        }

        return AdventureActivityCatalogItem(
            id: id,
            activityType: activityType,
            title: title,
            systemImage: systemImage,
            shortDescription: shortDescription,
            fullDescription: fullDescription,
            includes: includes,
            durationOptions: durationOptions,
            pricingMode: pricingMode,
            basePrice: basePrice,
            discountAmount: discountAmount,
            currency: currency,
            defaults: defaults.toDomain(),
            isActive: isActive,
            sortOrder: sortOrder,
            updatedAt: updatedAt.dateValue()
        )
    }
}

struct AdventureFeaturedPackageItemDto: Codable {
    let activity: String
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int

    func toDomain() -> AdventureReservationItemDraft? {
        guard let activity = AdventureActivityType(rawValue: activity) else {
            return nil
        }

        return AdventureReservationItemDraft(
            activity: activity,
            durationMinutes: durationMinutes,
            peopleCount: peopleCount,
            vehicleCount: vehicleCount,
            offRoadRiderCount: offRoadRiderCount,
            nights: nights
        )
    }
}

struct AdventureFeaturedPackageFoodItemDto: Codable {
    let menuItemId: String
    let quantity: Int

    func toDomain() -> AdventureFeaturedPackageFoodItem? {
        let cleanId = menuItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanId.isEmpty else { return nil }

        return AdventureFeaturedPackageFoodItem(
            menuItemId: cleanId,
            quantity: max(1, quantity)
        )
    }
}

struct AdventureFeaturedPackageDto: Codable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let isActive: Bool
    let sortOrder: Int
    let packageDiscountAmount: Double
    let items: [AdventureFeaturedPackageItemDto]
    let foodItems: [AdventureFeaturedPackageFoodItemDto]
    let updatedAt: Timestamp

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case subtitle
        case badge
        case isActive
        case sortOrder
        case packageDiscountAmount
        case items
        case foodItems
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        badge = try container.decodeIfPresent(String.self, forKey: .badge)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        packageDiscountAmount = try container.decode(Double.self, forKey: .packageDiscountAmount)
        items = try container.decode([AdventureFeaturedPackageItemDto].self, forKey: .items)
        foodItems = try container.decodeIfPresent([AdventureFeaturedPackageFoodItemDto].self, forKey: .foodItems) ?? []
        updatedAt = try container.decode(Timestamp.self, forKey: .updatedAt)
    }

    func toDomain() -> AdventureFeaturedPackage? {
        let mappedItems = items.compactMap { $0.toDomain() }
        guard mappedItems.count == items.count else { return nil }

        let mappedFoodItems = foodItems.compactMap { $0.toDomain() }
        guard mappedFoodItems.count == foodItems.count else { return nil }

        return AdventureFeaturedPackage(
            id: id,
            title: title,
            subtitle: subtitle,
            badge: badge,
            isActive: isActive,
            sortOrder: sortOrder,
            packageDiscountAmount: packageDiscountAmount,
            items: mappedItems,
            foodItems: mappedFoodItems,
            updatedAt: updatedAt.dateValue()
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/data/AdventureCatalogService.swift

```swift
//
//  AdventureCatalogService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

private final class CompositeAdventureListenerToken: AdventureListenerToken {
    private var registrations: [ListenerRegistration]

    init(registrations: [ListenerRegistration]) {
        self.registrations = registrations
    }

    func remove() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
    }
}

private final class AdventureCatalogObservationCoordinator {
    private let makeSnapshot: (QuerySnapshot, QuerySnapshot) throws -> AdventureCatalogSnapshot
    private let onChange: (Result<AdventureCatalogSnapshot, Error>) -> Void

    private var activitiesSnapshot: QuerySnapshot?
    private var packagesSnapshot: QuerySnapshot?

    init(
        makeSnapshot: @escaping (QuerySnapshot, QuerySnapshot) throws -> AdventureCatalogSnapshot,
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) {
        self.makeSnapshot = makeSnapshot
        self.onChange = onChange
    }

    func receiveActivities(snapshot: QuerySnapshot?, error: Error?) {
        if let error {
            onChange(.failure(error))
            return
        }

        guard let snapshot else { return }
        activitiesSnapshot = snapshot
        emitIfReady()
    }

    func receivePackages(snapshot: QuerySnapshot?, error: Error?) {
        if let error {
            onChange(.failure(error))
            return
        }

        guard let snapshot else { return }
        packagesSnapshot = snapshot
        emitIfReady()
    }

    private func emitIfReady() {
        guard let activitiesSnapshot, let packagesSnapshot else { return }

        do {
            let snapshot = try makeSnapshot(activitiesSnapshot, packagesSnapshot)
            onChange(.success(snapshot))
        } catch {
            onChange(.failure(error))
        }
    }
}

final class AdventureCatalogService: AdventureCatalogServiceable {
    private let db: Firestore
    private let activitiesCollection = "adventure_activities"
    private let packagesCollection = "adventure_featured_packages"

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func fetchCatalog() async throws -> AdventureCatalogSnapshot {
        async let activitiesTask = db.collection(activitiesCollection).getDocuments()
        async let packagesTask = db.collection(packagesCollection).getDocuments()

        let activitiesSnapshot = try await activitiesTask
        let packagesSnapshot = try await packagesTask

        return try makeCatalogSnapshot(
            activitiesSnapshot: activitiesSnapshot,
            packagesSnapshot: packagesSnapshot
        )
    }

    func observeCatalog(
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) -> AdventureListenerToken {
        let coordinator = AdventureCatalogObservationCoordinator(
            makeSnapshot: { [weak self] activitiesSnapshot, packagesSnapshot in
                guard let self else {
                    throw NSError(
                        domain: "AdventureCatalogService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "AdventureCatalogService is no longer available."]
                    )
                }

                return try self.makeCatalogSnapshot(
                    activitiesSnapshot: activitiesSnapshot,
                    packagesSnapshot: packagesSnapshot
                )
            },
            onChange: onChange
        )

        let activitiesRegistration = db.collection(activitiesCollection)
            .addSnapshotListener { snapshot, error in
                coordinator.receiveActivities(snapshot: snapshot, error: error)
            }

        let packagesRegistration = db.collection(packagesCollection)
            .addSnapshotListener { snapshot, error in
                coordinator.receivePackages(snapshot: snapshot, error: error)
            }

        return CompositeAdventureListenerToken(
            registrations: [activitiesRegistration, packagesRegistration]
        )
    }

    private func makeCatalogSnapshot(
        activitiesSnapshot: QuerySnapshot,
        packagesSnapshot: QuerySnapshot
    ) throws -> AdventureCatalogSnapshot {
        let activities = try activitiesSnapshot.documents.compactMap { document -> AdventureActivityCatalogItem? in
            let dto = try document.data(as: AdventureActivityCatalogDto.self)
            return dto.toDomain()
        }

        let activitiesByType = Dictionary(uniqueKeysWithValues: activities.map { ($0.activityType, $0) })

        let packages: [AdventureFeaturedPackage] = try packagesSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureFeaturedPackageDto.self)

            guard dto.isActive else { return nil }
            guard let package = dto.toDomain() else { return nil }

            let allItemsActive = package.items.allSatisfy { item in
                activitiesByType[item.activity]?.isActive == true
            }
            guard allItemsActive else { return nil }

            return package
        }

        return AdventureCatalogSnapshot(
            activities: activities.sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            },
            featuredPackages: packages.sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            }
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/data/AdventureService.swift

```swift
//
//  AdventureService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

struct AdventureService: Identifiable, Hashable {
    let id: String
    let activityType: AdventureActivityType
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let priceText: String
    let durationText: String
    let includes: [String]
    
    init(
        id: String = UUID().uuidString,
        activityType: AdventureActivityType,
        title: String,
        systemImage: String,
        shortDescription: String,
        fullDescription: String,
        priceText: String,
        durationText: String,
        includes: [String]
    ) {
        self.id = id
        self.activityType = activityType
        self.title = title
        self.systemImage = systemImage
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription
        self.priceText = priceText
        self.durationText = durationText
        self.includes = includes
    }
    
    var defaultDraft: AdventureReservationItemDraft {
        AdventureActivityType.defaultDraft(for: activityType)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureBookingsServiceable.swift

```swift
//
//  AdventureBookingsServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation

protocol AdventureBookingsServiceable {
    func observeBookings(
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken

    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double
    ) async throws -> [AdventureAvailabilitySlot]

    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking

    func cancelBooking(id: String, nationalId: String) async throws
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureCatalogModels.swift

```swift
//
//  AdventureCatalogModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

enum AdventurePricingMode: String, Codable, Hashable {
    case perHourPerVehicle
    case per30MinPerPerson
    case perNightPerPerson
    case fixedPerPerson
}

struct AdventureActivityDefaults: Codable, Hashable {
    let durationMinutes: Int
    let peopleCount: Int
    let vehicleCount: Int
    let offRoadRiderCount: Int
    let nights: Int
}

struct AdventureActivityCatalogItem: Identifiable, Codable, Hashable {
    let id: String
    let activityType: AdventureActivityType
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let includes: [String]
    let durationOptions: [Int]
    let pricingMode: AdventurePricingMode
    let basePrice: Double
    let discountAmount: Double
    let currency: String
    let defaults: AdventureActivityDefaults
    let isActive: Bool
    let sortOrder: Int
    let updatedAt: Date

    var finalUnitPrice: Double {
        max(0, basePrice - discountAmount)
    }

    var hasDiscount: Bool {
        discountAmount > 0
    }

    var defaultDraft: AdventureReservationItemDraft {
        AdventureReservationItemDraft(
            activity: activityType,
            durationMinutes: defaults.durationMinutes,
            peopleCount: defaults.peopleCount,
            vehicleCount: defaults.vehicleCount,
            offRoadRiderCount: defaults.offRoadRiderCount,
            nights: defaults.nights
        )
    }
}

struct AdventureFeaturedPackageFoodItem: Identifiable, Codable, Hashable {
    let menuItemId: String
    let quantity: Int

    var id: String { menuItemId }

    init(menuItemId: String, quantity: Int) {
        self.menuItemId = menuItemId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.quantity = max(1, quantity)
    }
}

struct AdventureFeaturedPackage: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let isActive: Bool
    let sortOrder: Int
    let packageDiscountAmount: Double
    let items: [AdventureReservationItemDraft]
    let foodItems: [AdventureFeaturedPackageFoodItem]
    let updatedAt: Date
}

struct AdventureCatalogSnapshot: Hashable {
    let activities: [AdventureActivityCatalogItem]
    let featuredPackages: [AdventureFeaturedPackage]

    var activitiesByType: [AdventureActivityType: AdventureActivityCatalogItem] {
        Dictionary(uniqueKeysWithValues: activities.map { ($0.activityType, $0) })
    }

    func activity(for activity: AdventureActivityType) -> AdventureActivityCatalogItem? {
        activitiesByType[activity]
    }

    var activeActivitiesSorted: [AdventureActivityCatalogItem] {
        activities
            .filter(\.isActive)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            }
    }

    var activePackagesSorted: [AdventureFeaturedPackage] {
        featuredPackages
            .filter(\.isActive)
            .sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.title < $1.title
            }
    }

    static let empty = AdventureCatalogSnapshot(
        activities: [],
        featuredPackages: []
    )
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureCatalogServiceable.swift

```swift
//
//  AdventureCatalogServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

protocol AdventureCatalogServiceable {
    func fetchCatalog() async throws -> AdventureCatalogSnapshot

    func observeCatalog(
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) -> AdventureListenerToken
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureCatalogUseCases.swift

```swift
//
//  AdventureCatalogUseCases.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

struct FetchAdventureCatalogUseCase {
    let service: AdventureCatalogServiceable

    func execute() async throws -> AdventureCatalogSnapshot {
        try await service.fetchCatalog()
    }
}

struct ObserveAdventureCatalogUseCase {
    let service: AdventureCatalogServiceable

    func execute(
        onChange: @escaping (Result<AdventureCatalogSnapshot, Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeCatalog(onChange: onChange)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureFlexibleCore.swift

```swift
//
//  AdventureModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

enum AdventureActivityType: String, Codable, CaseIterable, Identifiable, Hashable {
    case offRoad
    case paintball
    case goKarts
    case shootingRange
    case camping
    case extremeSlide

    var id: String { rawValue }

    var legacyTitle: String {
        switch self {
        case .offRoad: return "Off-road 4x4"
        case .paintball: return "Paintball"
        case .goKarts: return "Go karts"
        case .shootingRange: return "Campo de tiro"
        case .camping: return "Camping"
        case .extremeSlide: return "Resbaladera extrema"
        }
    }

    var legacySystemImage: String {
        switch self {
        case .offRoad: return "car.fill"
        case .paintball: return "shield.lefthalf.filled"
        case .goKarts: return "flag.checkered"
        case .shootingRange: return "target"
        case .camping: return "tent.fill"
        case .extremeSlide: return "figure.fall"
        }
    }

    var legacyDurationOptions: [Int] {
        switch self {
        case .offRoad:
            return [60, 120, 180]
        case .paintball, .goKarts, .shootingRange:
            return [30, 60, 90, 120]
        case .extremeSlide:
            return [30]
        case .camping:
            return []
        }
    }

    static func defaultDraft(for activity: AdventureActivityType) -> AdventureReservationItemDraft {
        switch activity {
        case .offRoad:
            return AdventureReservationItemDraft(
                activity: .offRoad,
                durationMinutes: 60,
                peopleCount: 0,
                vehicleCount: 1,
                offRoadRiderCount: 2,
                nights: 0
            )
        case .paintball:
            return AdventureReservationItemDraft(
                activity: .paintball,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        case .goKarts:
            return AdventureReservationItemDraft(
                activity: .goKarts,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        case .shootingRange:
            return AdventureReservationItemDraft(
                activity: .shootingRange,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        case .camping:
            return AdventureReservationItemDraft(
                activity: .camping,
                durationMinutes: 0,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 1
            )
        case .extremeSlide:
            return AdventureReservationItemDraft(
                activity: .extremeSlide,
                durationMinutes: 30,
                peopleCount: 2,
                vehicleCount: 0,
                offRoadRiderCount: 0,
                nights: 0
            )
        }
    }

    static func defaultDraft(
        for activity: AdventureActivityType,
        catalog: AdventureCatalogSnapshot?
    ) -> AdventureReservationItemDraft {
        guard let catalog,
              let config = catalog.activity(for: activity) else {
            return defaultDraft(for: activity)
        }

        return config.defaultDraft
    }
}

enum AdventureResourceType: String, Codable, Hashable {
    case offRoadVehicles
    case paintballPeople
    case goKartPeople
    case shootingPeople
    case campingPeople
    case extremeSlidePeople
}

enum AdventureBookingStatus: String, Codable, CaseIterable, Hashable, Identifiable {
    case pending
    case confirmed
    case completed
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .completed: return "Completada"
        case .canceled: return "Cancelada"
        }
    }
}

enum ReservationEventType: String, Codable, CaseIterable, Identifiable, Hashable {
    case regularVisit
    case birthday
    case anniversary
    case corporate
    case familyGathering
    case custom
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .regularVisit: return "Visita regular"
        case .birthday: return "Cumpleaños"
        case .anniversary: return "Aniversario"
        case .corporate: return "Evento corporativo"
        case .familyGathering: return "Reunión familiar"
        case .custom: return "Otro"
        }
    }
}

enum ReservationServingMoment: String, Codable, CaseIterable, Identifiable, Hashable {
    case onArrival
    case afterActivities
    case specificTime
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .onArrival: return "Al llegar"
        case .afterActivities: return "Después de actividades"
        case .specificTime: return "Hora específica"
        }
    }
}

struct AdventureReservationItemDraft: Identifiable, Codable, Hashable {
    let id: String
    var activity: AdventureActivityType
    var durationMinutes: Int
    var peopleCount: Int
    var vehicleCount: Int
    var offRoadRiderCount: Int
    var nights: Int

    init(
        id: String = UUID().uuidString,
        activity: AdventureActivityType,
        durationMinutes: Int,
        peopleCount: Int,
        vehicleCount: Int,
        offRoadRiderCount: Int,
        nights: Int
    ) {
        self.id = id
        self.activity = activity
        self.durationMinutes = durationMinutes
        self.peopleCount = peopleCount
        self.vehicleCount = vehicleCount
        self.offRoadRiderCount = offRoadRiderCount
        self.nights = nights
    }

    var title: String { activity.legacyTitle }

    var summaryText: String {
        switch activity {
        case .offRoad:
            return "\(durationMinutes / 60)h • \(vehicleCount) vehículo(s) • \(offRoadRiderCount) persona(s)"
        case .paintball, .goKarts, .shootingRange:
            return "\(durationMinutes) min • \(peopleCount) persona(s)"
        case .camping:
            return "\(nights) noche(s) • \(peopleCount) persona(s)"
        case .extremeSlide:
            return "1 sesión • \(peopleCount) persona(s) • transporte incluido"
        }
    }
}

struct ReservationFoodItemDraft: Identifiable, Codable, Hashable {
    let id: String
    let menuItemId: String
    let name: String
    let unitPrice: Double
    var quantity: Int
    var notes: String?
    
    init(
        id: String = UUID().uuidString,
        menuItemId: String,
        name: String,
        unitPrice: Double,
        quantity: Int,
        notes: String? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.name = name
        self.unitPrice = unitPrice
        self.quantity = max(1, quantity)
        self.notes = notes
    }
    
    init(from menuItem: MenuItem, quantity: Int = 1, notes: String? = nil) {
        self.init(
            menuItemId: menuItem.id,
            name: menuItem.name,
            unitPrice: menuItem.finalPrice,
            quantity: quantity,
            notes: notes
        )
    }
    
    var subtotal: Double {
        Double(quantity) * unitPrice
    }
}

struct ReservationFoodDraft: Codable, Hashable {
    var items: [ReservationFoodItemDraft]
    var servingMoment: ReservationServingMoment
    var servingTime: Date?
    var notes: String?
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

struct AdventureBookingBlock: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let activity: AdventureActivityType
    let resourceType: AdventureResourceType
    let startAt: Date
    let endAt: Date
    let reservedUnits: Int
    let subtotal: Double
}

struct AdventureBuildPlan: Hashable {
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let adventureSubtotal: Double
    let foodSubtotal: Double
    let subtotal: Double
    let discountAmount: Double
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedReward]
    let nightPremium: Double
    let totalAmount: Double
    let hasNightPremium: Bool
}

struct AdventureAvailabilitySlot: Identifiable, Hashable {
    let id: String
    let startAt: Date
    let endAt: Date
    let blocks: [AdventureBookingBlock]
    let adventureSubtotal: Double
    let foodSubtotal: Double
    let subtotal: Double
    let discountAmount: Double
    let nightPremium: Double
    let totalAmount: Double
}

struct AdventureBookingRequest: Hashable {
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let date: Date
    let selectedStartAt: Date
    let guestCount: Int
    let eventType: ReservationEventType
    let customEventTitle: String?
    let eventNotes: String?
    let items: [AdventureReservationItemDraft]
    let foodReservation: ReservationFoodDraft?
    let packageDiscountAmount: Double
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedReward]
    let notes: String?

    init(
        clientId: String?,
        clientName: String,
        whatsappNumber: String,
        nationalId: String,
        date: Date,
        selectedStartAt: Date,
        guestCount: Int,
        eventType: ReservationEventType,
        customEventTitle: String?,
        eventNotes: String?,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double = 0,
        loyaltyDiscountAmount: Double = 0,
        appliedRewards: [AppliedReward] = [],
        notes: String?
    ) {
        self.clientId = clientId
        self.clientName = clientName
        self.whatsappNumber = whatsappNumber
        self.nationalId = nationalId
        self.date = date
        self.selectedStartAt = selectedStartAt
        self.guestCount = guestCount
        self.eventType = eventType
        self.customEventTitle = customEventTitle
        self.eventNotes = eventNotes
        self.items = items
        self.foodReservation = foodReservation
        self.packageDiscountAmount = max(0, packageDiscountAmount)
        self.loyaltyDiscountAmount = max(0, loyaltyDiscountAmount)
        self.appliedRewards = appliedRewards
        self.notes = notes
    }

    var hasActivities: Bool { !items.isEmpty }
    var hasFoodReservation: Bool { !(foodReservation?.isEmpty ?? true) }
}

struct AdventureBooking: Identifiable, Hashable {
    let id: String
    let clientId: String?
    let clientName: String
    let whatsappNumber: String
    let nationalId: String
    let startDayKey: String
    let startAt: Date
    let endAt: Date
    let guestCount: Int
    let eventType: ReservationEventType
    let customEventTitle: String?
    let eventNotes: String?
    let items: [AdventureReservationItemDraft]
    let foodReservation: ReservationFoodDraft?
    let blocks: [AdventureBookingBlock]
    let adventureSubtotal: Double
    let foodSubtotal: Double
    let subtotal: Double
    let discountAmount: Double
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedReward]
    let nightPremium: Double
    let totalAmount: Double
    let status: AdventureBookingStatus
    let createdAt: Date
    let notes: String?

    var hasActivities: Bool { !items.isEmpty }
    var hasFoodReservation: Bool { !(foodReservation?.isEmpty ?? true) }

    var eventDisplayTitle: String {
        if eventType == .custom {
            let clean = customEventTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return clean.isEmpty ? "Evento personalizado" : clean
        }
        return eventType.title
    }

    var visitTypeTitle: String {
        switch (hasActivities, hasFoodReservation) {
        case (true, true): return "Aventura + comida"
        case (true, false): return "Solo aventura"
        case (false, true): return "Solo comida"
        case (false, false): return "Reserva"
        }
    }
}

enum AdventureSchedule {
    static let slotMinutes = 30
    static let daytimeStartHour = 7
    static let daytimeEndHour = 20
    static let nightPremiumStartHour = 18
    static let offRoadPeoplePerVehicle = 2
    static let foodOnlyDefaultDurationMinutes = 90
    
    static func capacity(for resource: AdventureResourceType) -> Int {
        switch resource {
        case .offRoadVehicles:
            return 600
        case .paintballPeople:
            return 1000
        case .goKartPeople:
            return 1000
        case .shootingPeople:
            return 1000
        case .campingPeople:
            return 100
        case .extremeSlidePeople:
            return 100
        }
    }
}

enum AdventureDateHelper {
    static let calendar = Calendar.current
    
    static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f
    }()
    
    static func dayKey(from date: Date) -> String {
        dayKeyFormatter.string(from: date)
    }
    
    static func timeText(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
    
    static func date(on day: Date, hour: Int, minute: Int) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
    
    static func addMinutes(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .minute, value: value, to: date) ?? date
    }
    
    static func addDays(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value, to: date) ?? date
    }
    
    static func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    static func slotIndex(_ date: Date) -> Int {
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        return (hour * 60 + minute) / AdventureSchedule.slotMinutes
    }
    
    static func isNightPremiumTime(_ startAt: Date, _ endAt: Date) -> Bool {
        let startHour = calendar.component(.hour, from: startAt)
        let endHour = calendar.component(.hour, from: endAt)
        return startHour >= AdventureSchedule.nightPremiumStartHour
            || endHour >= AdventureSchedule.nightPremiumStartHour
            || startHour < AdventureSchedule.daytimeStartHour
    }
}

enum AdventurePricingEngine {
    static let nightPremiumRate = 0.25

    static func finalUnitPrice(for config: AdventureActivityCatalogItem) -> Double {
        max(0, config.basePrice - config.discountAmount)
    }

    static func lineBaseSubtotal(
        for item: AdventureReservationItemDraft,
        config: AdventureActivityCatalogItem
    ) -> Double {
        switch item.activity {
        case .offRoad:
            let hours = Double(item.durationMinutes) / 60
            return config.basePrice * hours * Double(item.vehicleCount)

        case .paintball, .goKarts, .shootingRange:
            let blocks = Double(item.durationMinutes) / 30
            return config.basePrice * blocks * Double(item.peopleCount)

        case .camping:
            return config.basePrice * Double(item.peopleCount) * Double(item.nights)

        case .extremeSlide:
            return config.basePrice * Double(item.peopleCount)
        }
    }

    static func subtotal(
        for item: AdventureReservationItemDraft,
        config: AdventureActivityCatalogItem
    ) -> Double {
        switch item.activity {
        case .offRoad:
            let hours = Double(item.durationMinutes) / 60
            return finalUnitPrice(for: config) * hours * Double(item.vehicleCount)

        case .paintball, .goKarts, .shootingRange:
            let blocks = Double(item.durationMinutes) / 30
            return finalUnitPrice(for: config) * blocks * Double(item.peopleCount)

        case .camping:
            return finalUnitPrice(for: config) * Double(item.peopleCount) * Double(item.nights)

        case .extremeSlide:
            return finalUnitPrice(for: config) * Double(item.peopleCount)
        }
    }

    static func subtotal(
        for item: AdventureReservationItemDraft,
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        guard let config = catalog.activity(for: item.activity) else { return 0 }
        return subtotal(for: item, config: config)
    }

    static func lineDiscountAmount(
        for item: AdventureReservationItemDraft,
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        guard let config = catalog.activity(for: item.activity) else { return 0 }
        return max(0, lineBaseSubtotal(for: item, config: config) - subtotal(for: item, config: config))
    }

    static func estimatedSubtotal(
        items: [AdventureReservationItemDraft],
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        items.reduce(0) { partial, item in
            partial + subtotal(for: item, catalog: catalog)
        }
    }

    static func estimatedDiscountAmount(
        items: [AdventureReservationItemDraft],
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        items.reduce(0) { partial, item in
            partial + lineDiscountAmount(for: item, catalog: catalog)
        }
    }

    static func foodSubtotal(for foodReservation: ReservationFoodDraft?) -> Double {
        foodReservation?.subtotal ?? 0
    }

    static func packageTotal(
        items: [AdventureReservationItemDraft],
        packageDiscountAmount: Double,
        catalog: AdventureCatalogSnapshot
    ) -> Double {
        let subtotal = estimatedSubtotal(items: items, catalog: catalog)
        return max(0, subtotal - packageDiscountAmount)
    }
}

enum AdventurePlanner {
    static func buildPlan(
        day: Date,
        startAt: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double,
        catalog: AdventureCatalogSnapshot
    ) -> AdventureBuildPlan? {
        let hasFood = !(foodReservation?.isEmpty ?? true)
        guard !items.isEmpty || hasFood else { return nil }

        let foodSubtotal = AdventurePricingEngine.foodSubtotal(for: foodReservation)
        let dayStart = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeStartHour,
            minute: 0
        )
        let dayEnd = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeEndHour,
            minute: 0
        )

        guard startAt >= dayStart else { return nil }

        if items.isEmpty {
            let end = AdventureDateHelper.addMinutes(
                AdventureSchedule.foodOnlyDefaultDurationMinutes,
                to: startAt
            )
            guard end <= dayEnd else { return nil }

            return AdventureBuildPlan(
                startAt: startAt,
                endAt: end,
                blocks: [],
                adventureSubtotal: 0,
                foodSubtotal: foodSubtotal,
                subtotal: foodSubtotal,
                discountAmount: 0,
                loyaltyDiscountAmount: 0,
                appliedRewards: [],
                nightPremium: 0,
                totalAmount: foodSubtotal,
                hasNightPremium: false
            )
        }

        var cursor = startAt
        var blocks: [AdventureBookingBlock] = []
        var discountedAdventureSubtotal = 0.0
        var activityDiscountAmount = 0.0

        for (index, item) in items.enumerated() {
            guard catalog.activity(for: item.activity)?.isActive == true else {
                return nil
            }

            switch item.activity {
            case .offRoad:
                guard item.vehicleCount > 0 else { return nil }
                guard item.offRoadRiderCount > 0 else { return nil }
                guard item.offRoadRiderCount <= item.vehicleCount * AdventureSchedule.offRoadPeoplePerVehicle else { return nil }

                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .offRoad)?.title ?? "Off-Road 4x4",
                        activity: .offRoad,
                        resourceType: .offRoadVehicles,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.vehicleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .paintball:
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .paintball)?.title ?? "Paintball",
                        activity: .paintball,
                        resourceType: .paintballPeople,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .goKarts:
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .goKarts)?.title ?? "Go Karts",
                        activity: .goKarts,
                        resourceType: .goKartPeople,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .shootingRange:
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .shootingRange)?.title ?? "Campo de tiro",
                        activity: .shootingRange,
                        resourceType: .shootingPeople,
                        startAt: cursor,
                        endAt: end,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = end

            case .extremeSlide:
                let transportVehicles = max(
                    1,
                    Int(ceil(Double(item.peopleCount) / Double(AdventureSchedule.offRoadPeoplePerVehicle)))
                )

                let transportEnd = AdventureDateHelper.addMinutes(30, to: cursor)
                let slideEnd = AdventureDateHelper.addMinutes(30, to: transportEnd)
                guard slideEnd <= dayEnd else { return nil }

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Transporte al columpio extremo",
                        activity: .extremeSlide,
                        resourceType: .offRoadVehicles,
                        startAt: cursor,
                        endAt: transportEnd,
                        reservedUnits: transportVehicles,
                        subtotal: 0
                    )
                )

                let lineSubtotal = AdventurePricingEngine.subtotal(for: item, catalog: catalog)
                let lineDiscount = AdventurePricingEngine.lineDiscountAmount(for: item, catalog: catalog)

                discountedAdventureSubtotal += lineSubtotal
                activityDiscountAmount += lineDiscount

                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: catalog.activity(for: .extremeSlide)?.title ?? "Extreme Slide",
                        activity: .extremeSlide,
                        resourceType: .extremeSlidePeople,
                        startAt: transportEnd,
                        endAt: slideEnd,
                        reservedUnits: item.peopleCount,
                        subtotal: lineSubtotal
                    )
                )
                cursor = slideEnd

            case .camping:
                guard index == items.count - 1 else { return nil }
                let campingStart = AdventureDateHelper.date(on: day, hour: 19, minute: 0)
                guard cursor <= campingStart else { return nil }

                let config = catalog.activity(for: .camping)

                for night in 0..<max(1, item.nights) {
                    let start = AdventureDateHelper.addDays(night, to: campingStart)
                    let end = AdventureDateHelper.addMinutes(12 * 60, to: start)

                    let nightItem = AdventureReservationItemDraft(
                        activity: .camping,
                        durationMinutes: 0,
                        peopleCount: item.peopleCount,
                        vehicleCount: 0,
                        offRoadRiderCount: 0,
                        nights: 1
                    )

                    let nightSubtotal = AdventurePricingEngine.subtotal(for: nightItem, catalog: catalog)
                    let nightDiscount = AdventurePricingEngine.lineDiscountAmount(for: nightItem, catalog: catalog)

                    discountedAdventureSubtotal += nightSubtotal
                    activityDiscountAmount += nightDiscount

                    blocks.append(
                        AdventureBookingBlock(
                            id: UUID().uuidString,
                            title: "\(config?.title ?? "Camping") Night \(night + 1)",
                            activity: .camping,
                            resourceType: .campingPeople,
                            startAt: start,
                            endAt: end,
                            reservedUnits: item.peopleCount,
                            subtotal: nightSubtotal
                        )
                    )
                }

                cursor = blocks.last?.endAt ?? cursor
            }
        }

        guard let last = blocks.last else { return nil }

        let hasNightPremium =
            items.contains(where: { $0.activity == .camping }) ||
            blocks.contains { AdventureDateHelper.isNightPremiumTime($0.startAt, $0.endAt) }

        let totalDiscountAmount = activityDiscountAmount + max(0, packageDiscountAmount)
        let packageAdjustedAdventureSubtotal = max(0, discountedAdventureSubtotal - max(0, packageDiscountAmount))
        let totalSubtotal = discountedAdventureSubtotal + foodSubtotal
        let totalAmount = packageAdjustedAdventureSubtotal + foodSubtotal

        return AdventureBuildPlan(
            startAt: startAt,
            endAt: last.endAt,
            blocks: blocks,
            adventureSubtotal: discountedAdventureSubtotal,
            foodSubtotal: foodSubtotal,
            subtotal: totalSubtotal,
            discountAmount: totalDiscountAmount,
            loyaltyDiscountAmount: 0,
            appliedRewards: [],
            nightPremium: 0,
            totalAmount: totalAmount,
            hasNightPremium: hasNightPremium
        )
    }

    static func affectedDayKeys(
        day: Date,
        items: [AdventureReservationItemDraft]
    ) -> [String] {
        let campingNights = items.first(where: { $0.activity == .camping })?.nights ?? 0
        let days = max(1, campingNights + 1)
        return (0..<days).map {
            AdventureDateHelper.dayKey(from: AdventureDateHelper.addDays($0, to: day))
        }
    }

    static func buildAvailability(
        day: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double,
        catalog: AdventureCatalogSnapshot
    ) -> [AdventureAvailabilitySlot] {
        let hasFood = !(foodReservation?.isEmpty ?? true)
        guard !items.isEmpty || hasFood else { return [] }

        let startWindow = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeStartHour,
            minute: 0
        )
        let endWindow = AdventureDateHelper.date(
            on: day,
            hour: AdventureSchedule.daytimeEndHour,
            minute: 0
        )

        let now = Date()
        let isToday = AdventureDateHelper.calendar.isDate(day, inSameDayAs: now)

        var current = startWindow
        var slots: [AdventureAvailabilitySlot] = []

        while current <= endWindow {
            if !(isToday && current < now),
               let plan = buildPlan(
                    day: day,
                    startAt: current,
                    items: items,
                    foodReservation: foodReservation,
                    packageDiscountAmount: packageDiscountAmount,
                    catalog: catalog
               ) {
                slots.append(
                    AdventureAvailabilitySlot(
                        id: UUID().uuidString,
                        startAt: plan.startAt,
                        endAt: plan.endAt,
                        blocks: plan.blocks,
                        adventureSubtotal: plan.adventureSubtotal,
                        foodSubtotal: plan.foodSubtotal,
                        subtotal: plan.subtotal,
                        discountAmount: plan.discountAmount,
                        nightPremium: plan.nightPremium,
                        totalAmount: plan.totalAmount
                    )
                )
            }

            current = AdventureDateHelper.addMinutes(AdventureSchedule.slotMinutes, to: current)
        }

        return slots
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureModuleFactory.swift

```swift
//
//  AdventureModelFactory.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

final class AdventureModuleFactory {
    private let bookingsService: AdventureBookingsServiceable
    private let catalogService: AdventureCatalogServiceable
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        bookingsService: AdventureBookingsServiceable,
        catalogService: AdventureCatalogServiceable,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.bookingsService = bookingsService
        self.catalogService = catalogService
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func makeBuilderViewModel(
        prefilledItems: [AdventureReservationItemDraft] = [],
        packageDiscountAmount: Double = 0
    ) -> AdventureComboBuilderViewModel {
        AdventureComboBuilderViewModel(
            prefilledItems: prefilledItems,
            initialPackageDiscountAmount: packageDiscountAmount,
            getAvailabilityUseCase: GetAdventureAvailabilityUseCase(service: bookingsService),
            createBookingUseCase: CreateAdventureBookingUseCase(service: bookingsService),
            fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase(service: catalogService),
            observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase(service: catalogService),
            loyaltyRewardsService: loyaltyRewardsService
        )
    }

    func makeCatalogViewModel() -> AdventureCatalogViewModel {
        AdventureCatalogViewModel(service: catalogService)
    }

    func makeBookingsViewModel() -> AdventureBookingsViewModel {
        AdventureBookingsViewModel(
            observeBookingsUseCase: ObserveAdventureBookingsUseCase(service: bookingsService),
            cancelBookingUseCase: CancelAdventureBookingUseCase(service: bookingsService)
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/domain/AdventureUseCases.swift

```swift
//
//  AdventureUseCases.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

struct GetAdventureAvailabilityUseCase {
    let service: AdventureBookingsServiceable

    func execute(
        date: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?,
        packageDiscountAmount: Double
    ) async throws -> [AdventureAvailabilitySlot] {
        try await service.fetchAvailability(
            for: date,
            items: items,
            foodReservation: foodReservation,
            packageDiscountAmount: packageDiscountAmount
        )
    }
}

struct CreateAdventureBookingUseCase {
    let service: AdventureBookingsServiceable

    func execute(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        try await service.createBooking(request)
    }
}

struct ObserveAdventureBookingsUseCase {
    let service: AdventureBookingsServiceable

    func execute(
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeBookings(
            nationalId: nationalId,
            onChange: onChange
        )
    }
}

struct CancelAdventureBookingUseCase {
    let service: AdventureBookingsServiceable

    func execute(
        id: String,
        nationalId: String
    ) async throws {
        try await service.cancelBooking(id: id, nationalId: nationalId)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/AdventureCatalogView.swift

```swift
//
//  AdventureCatalogView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

@MainActor
struct AdventureCatalogView: View {
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @EnvironmentObject private var sessionViewModel: AppSessionViewModel

    @StateObject private var catalogViewModel = AdventureCatalogViewModel(
        service: AdventureCatalogService()
    )

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection

                    if catalogViewModel.state.isLoading && catalogViewModel.state.catalog.activities.isEmpty {
                        ProgressView("Cargando actividades...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if let error = catalogViewModel.state.errorMessage,
                              catalogViewModel.state.catalog.activities.isEmpty {
                        ContentUnavailableView(
                            "No se pudo cargar el catálogo",
                            systemImage: "wifi.exclamationmark",
                            description: Text(error)
                        )
                    } else {
                        featuredSection
                        singlesSection
                        customComboSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Aventura en Los Altos")
            .navigationBarTitleDisplayMode(.large)
            .appScreenStyle(.adventure)
        }
        .onAppear {
            if let profile = sessionViewModel.authenticatedProfile {
                adventureComboBuilderViewModel.setClientName(profile.fullName)
                adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
                adventureComboBuilderViewModel.setNationalId(profile.nationalId)
            }

            catalogViewModel.onAppear()
            menuViewModel.onAppear()
        }
        .onDisappear {
            catalogViewModel.onDisappear()
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
                )
                .shadow(
                    color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
                    radius: 22,
                    x: 0,
                    y: 12
                )

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    BrandIconBubble(theme: .adventure, systemImage: "mountain.2.fill", size: 56)
                    Spacer()
                    BrandBadge(theme: .adventure, title: "Outdoor", selected: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Construye tu combo perfecto")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)

                    Text("Ahora el catálogo, los paquetes y la comida incluida se cargan desde Firestore.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.92))
                }

                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.prepareCustomDraftIfNeeded()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                        Text("Iniciar combo personalizado")
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
            }
            .padding(22)
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Paquetes destacados",
                subtitle: "Combos sugeridos cargados desde Firestore."
            )

            let packages = catalogViewModel.state.catalog.activePackagesSorted

            if packages.isEmpty {
                Text("No hay paquetes destacados disponibles por ahora.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .appCardStyle(.adventure, emphasized: false)
            } else {
                ForEach(packages) { package in
                    NavigationLink {
                        AdventureComboBuilderView(
                            adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                            menuViewModel: menuViewModel
                        )
                        .onAppear {
                            adventureComboBuilderViewModel.replacePackage(
                                package,
                                menuSections: menuViewModel.state.sections
                            )
                        }
                    } label: {
                        FeaturedPackageCard(
                            package: package,
                            catalog: catalogViewModel.state.catalog,
                            menuSections: menuViewModel.state.sections,
                            rewardPresentation: adventureComboBuilderViewModel.packageRewardPresentation(
                                for: package,
                                menuSections: menuViewModel.state.sections
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var singlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades individuales",
                subtitle: "Actividades activas ordenadas por sortOrder."
            )

            ForEach(catalogViewModel.state.catalog.activeActivitiesSorted) { activity in
                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.replaceItems(
                            with: [activity.defaultDraft],
                            packageDiscountAmount: 0
                        )
                    }
                } label: {
                    SingleActivityCatalogCard(
                        activity: activity,
                        rewardPresentation: adventureComboBuilderViewModel.catalogRewardPresentation(for: activity)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var customComboSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "¿Necesitas algo diferente?",
                subtitle: "Crea una combinación a medida con tiempos y cantidades personalizadas."
            )

            VStack(alignment: .leading, spacing: 14) {
                Text("Las reglas de agenda siguen en código, pero el catálogo y precios vienen de Firestore.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)

                NavigationLink {
                    AdventureComboBuilderView(
                        adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                        menuViewModel: menuViewModel
                    )
                    .onAppear {
                        adventureComboBuilderViewModel.prepareCustomDraftIfNeeded()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                        Text("Abrir creador de aventuras")
                    }
                }
                .buttonStyle(BrandSecondaryButtonStyle(theme: .adventure))
            }
            .appCardStyle(.adventure)
        }
    }
}

private struct FeaturedPackageCard: View {
    let package: AdventureFeaturedPackage
    let catalog: AdventureCatalogSnapshot
    let menuSections: [MenuSection]
    let rewardPresentation: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var menuItemsById: [String: MenuItem] {
        Dictionary(
            uniqueKeysWithValues: menuSections
                .flatMap(\.items)
                .map { ($0.id, $0) }
        )
    }

    private var activitySubtotal: Double {
        AdventurePricingEngine.estimatedSubtotal(items: package.items, catalog: catalog)
    }

    private var foodSubtotal: Double {
        package.foodItems.reduce(0) { partial, item in
            let unitPrice = menuItemsById[item.menuItemId]?.finalPrice ?? 0
            return partial + (Double(item.quantity) * unitPrice)
        }
    }

    private var subtotal: Double {
        activitySubtotal + foodSubtotal
    }

    private var total: Double {
        max(0, subtotal - package.packageDiscountAmount)
    }

    private var foodSummary: String {
        package.foodItems.map { item in
            let name = menuItemsById[item.menuItemId]?.name ?? item.menuItemId
            return "\(item.quantity)x \(name)"
        }
        .joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(theme: .adventure, systemImage: "figure.hiking", size: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text(package.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(package.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if let badge = package.badge, !badge.isEmpty {
                    BrandBadge(theme: .adventure, title: badge)
                }
            }

            if !foodSummary.isEmpty {
                Text(foodSummary)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(3)
            }

            HStack(spacing: 8) {
                Text("Aventura \(activitySubtotal.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)

                if foodSubtotal > 0 {
                    Text("Comida \(foodSubtotal.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)
                }
            }

            if package.packageDiscountAmount > 0 {
                Text("Descuento del paquete: \(package.packageDiscountAmount.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }

            if let rewardPresentation {
                rewardInfoCard(rewardPresentation)
            }

            HStack {
                Label("Desde \(total.priceText)", systemImage: "dollarsign.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.primary)

                Spacer()

                Label("Ver combo", systemImage: "arrow.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private func rewardInfoCard(_ reward: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .adventure, title: reward.badge, selected: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(reward.message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

private struct SingleActivityCatalogCard: View {
    let activity: AdventureActivityCatalogItem
    let rewardPresentation: RewardPresentation?

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(
                theme: .adventure,
                systemImage: activity.systemImage,
                size: 56
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(activity.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text("Desde \(activity.finalUnitPrice.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primary)

                    if activity.hasDiscount {
                        Text("Antes \(activity.basePrice.priceText)")
                            .font(.caption)
                            .foregroundStyle(palette.textTertiary)
                            .strikethrough()
                    }
                }

                if let rewardPresentation {
                    HStack(spacing: 8) {
                        BrandBadge(theme: .adventure, title: rewardPresentation.badge, selected: true)

                        Text(rewardPresentation.message)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(palette.primary)

                Text("Reservar")
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.adventure)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/AdventureComboBuilderView.swift

```swift
//
//  AdventureComboBuilderView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

struct AdventureComboBuilderView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @State private var editingItem: AdventureReservationItemDraft?
    @State private var isFoodPickerPresented = false
    @State private var editingFoodItem: ReservationFoodItemDraft?
    @State private var isContactSectionExpanded = false
    @State private var showAddedMessage = false

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    @Environment(\.colorScheme) private var colorScheme
    private let theme: AppSectionTheme = .adventure

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        List {
            schedulingSection
            availabilitySection
            eventSection
            comboSection
            foodSection
            contactSection
            summarySection
            confirmSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .appScreenStyle(.adventure)
        .navigationTitle("Crear reserva")
        .toolbar {
            EditButton()
        }
        .onAppear {
            syncProfileFieldsFromSession()
            adventureComboBuilderViewModel.onAppear()
        }
        .onDisappear {
            adventureComboBuilderViewModel.onDisappear()
        }
        .onChange(of: authenticatedProfile?.id) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: authenticatedProfile?.updatedAt) { _, _ in
            syncProfileFieldsFromSession()
        }
        .sheet(item: $editingItem) { item in
            AdventureItemEditorView(
                item: item,
                config: adventureComboBuilderViewModel.config(for: item.activity),
                linePrice: AdventurePricingEngine.subtotal(
                    for: item,
                    catalog: adventureComboBuilderViewModel.state.catalog
                )
            ) { updated in
                adventureComboBuilderViewModel.updateItem(updated)
            }
        }
        .sheet(item: $editingFoodItem, onDismiss: {
            editingFoodItem = nil
        }) { item in
            ReservationFoodItemEditorView(item: item) { updated in
                adventureComboBuilderViewModel.updateFoodItem(updated)
                editingFoodItem = nil
            }
        }
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: {
                    adventureComboBuilderViewModel.state.errorMessage != nil
                    || adventureComboBuilderViewModel.state.successMessage != nil
                },
                set: {
                    if !$0 { adventureComboBuilderViewModel.dismissMessage() }
                }
            )
        ) {
            Button("OK") {
                adventureComboBuilderViewModel.dismissMessage()
            }
        } message: {
            Text(
                adventureComboBuilderViewModel.state.errorMessage
                ?? adventureComboBuilderViewModel.state.successMessage
                ?? ""
            )
        }
    }

    private var menuItemsById: [String: MenuItem] {
        Dictionary(
            uniqueKeysWithValues: menuViewModel.state.sections
                .flatMap(\.items)
                .map { ($0.id, $0) }
        )
    }

    private var blockedFoodItemsForToday: [ReservationFoodItemDraft] {
        guard AdventureDateHelper.calendar.isDateInToday(adventureComboBuilderViewModel.state.selectedDate) else {
            return []
        }

        return adventureComboBuilderViewModel.state.foodItems.filter { draft in
            guard let menuItem = menuItemsById[draft.menuItemId] else { return false }
            return !menuItem.canBeOrdered
        }
    }

    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }

        adventureComboBuilderViewModel.setClientName(profile.fullName)
        adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
        adventureComboBuilderViewModel.setNationalId(profile.nationalId)
    }

    private var schedulingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Fecha",
                    subtitle: "Elige el día de la visita y luego revisa horarios disponibles."
                )

                DatePicker(
                    "Día de la reserva",
                    selection: Binding(
                        get: { adventureComboBuilderViewModel.state.selectedDate },
                        set: { adventureComboBuilderViewModel.setDate($0) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)

                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "clock")

                    Text("Si reservas solo comida, estos horarios se usan como hora preferida de llegada. Si agregas actividades, representan el inicio del combo.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var availabilitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Horarios disponibles",
                    subtitle: "Selecciona el mejor horario de inicio o llegada para tu reserva."
                )

                if adventureComboBuilderViewModel.state.isLoadingAvailability {
                    ProgressView("Verificando disponibilidad...")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else if adventureComboBuilderViewModel.state.availableSlots.isEmpty {
                    ContentUnavailableView(
                        "Sin horarios disponibles",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Agrega una actividad o comida, o prueba otra fecha.")
                    )
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(adventureComboBuilderViewModel.state.availableSlots) { slot in
                                Button {
                                    adventureComboBuilderViewModel.selectSlot(slot)
                                } label: {
                                    AdventureSlotCard(
                                        slot: slot,
                                        isSelected: adventureComboBuilderViewModel.state.selectedSlot?.id == slot.id,
                                        effectiveTotal: adventureComboBuilderViewModel.effectiveTotal(for: slot),
                                        hasLoyaltyDiscount: adventureComboBuilderViewModel.state.rewardPreview.totalDiscount > 0
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var eventSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Evento",
                    subtitle: "Añade el tipo de evento, número de invitados y notas especiales."
                )

                Stepper(
                    "Invitados: \(adventureComboBuilderViewModel.state.guestCount)",
                    value: Binding(
                        get: { adventureComboBuilderViewModel.state.guestCount },
                        set: { adventureComboBuilderViewModel.setGuestCount($0) }
                    ),
                    in: 1...300
                )

                Picker(
                    "Tipo de evento",
                    selection: Binding(
                        get: { adventureComboBuilderViewModel.state.eventType },
                        set: { adventureComboBuilderViewModel.setEventType($0) }
                    )
                ) {
                    ForEach(ReservationEventType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }

                if adventureComboBuilderViewModel.state.eventType == .custom {
                    TextField(
                        "Nombre del evento",
                        text: Binding(
                            get: { adventureComboBuilderViewModel.state.customEventTitle },
                            set: { adventureComboBuilderViewModel.setCustomEventTitle($0) }
                        )
                    )
                    .appTextFieldStyle(.adventure)
                }

                TextField(
                    "Notas del evento (decoración, pastel, sorpresa, niños, etc.)",
                    text: Binding(
                        get: { adventureComboBuilderViewModel.state.eventNotes },
                        set: { adventureComboBuilderViewModel.setEventNotes($0) }
                    ),
                    axis: .vertical
                )
                .lineLimit(3...5)
                .appTextFieldStyle(.adventure)
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var comboSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Actividades",
                    subtitle: "Opcionales. Puedes reservar aventura, comida o ambas. Cada actividad solo puede agregarse una vez por reserva."
                )

                if adventureComboBuilderViewModel.state.items.isEmpty {
                    Text("No hay actividades agregadas. Eso está bien si quieres una reserva solo de comida o evento.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }

                if adventureComboBuilderViewModel.state.items.contains(where: { $0.activity == .offRoad }) {
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(theme: .adventure, systemImage: "info.circle", size: 34)

                        Text("Cada vehículo off-road admite 1 o 2 personas. El precio es por vehículo, no por persona.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .appCardStyle(.adventure)
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(adventureComboBuilderViewModel.state.items) { item in
                Button {
                    editingItem = item
                } label: {
                    ComboItemCard(
                        item: item,
                        rewardPresentation: adventureComboBuilderViewModel.appliedRewardPresentation(for: item),
                        baseSubtotal: adventureComboBuilderViewModel.baseAdventureSubtotal(for: item),
                        discountedSubtotal: adventureComboBuilderViewModel.displayedAdventureSubtotal(for: item)
                    )
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: adventureComboBuilderViewModel.removeItem)
            .onMove(perform: adventureComboBuilderViewModel.moveItems)

            Menu {
                if adventureComboBuilderViewModel.availableActivitiesToAdd.isEmpty {
                    Button("Todas las actividades ya fueron agregadas") { }
                        .disabled(true)
                } else {
                    ForEach(adventureComboBuilderViewModel.availableActivitiesToAdd) { activity in
                        Button(
                            adventureComboBuilderViewModel.config(for: activity)?.title ?? activity.legacyTitle
                        ) {
                            adventureComboBuilderViewModel.addItem(activity)
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "plus")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Agregar actividad")
                            .font(.headline)
                        Text("Añade una experiencia distinta a esta reserva.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .appCardStyle(.adventure, emphasized: false)
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var foodSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Comida",
                    subtitle: "También puedes hacer una reserva solo de comida para cumpleaños, reuniones o visitas futuras."
                )
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if adventureComboBuilderViewModel.state.foodItems.isEmpty {
                Text("No hay platos agregados todavía.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .appCardStyle(.adventure)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(adventureComboBuilderViewModel.state.foodItems) { item in
                    ReservationFoodRow(
                        item: item,
                        rewardPresentation: adventureComboBuilderViewModel.appliedRewardPresentation(for: item),
                        displayedSubtotal: adventureComboBuilderViewModel.displayedFoodSubtotal(for: item),
                        rewardAmount: adventureComboBuilderViewModel.rewardAmount(for: item),
                        onEdit: { editingFoodItem = item },
                        onIncrease: { adventureComboBuilderViewModel.increaseFoodQuantity(item.id) },
                        onDecrease: { adventureComboBuilderViewModel.decreaseFoodQuantity(item.id) },
                        onRemove: { adventureComboBuilderViewModel.removeFoodItem(item.id) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingFoodItem = item
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            editingFoodItem = item
                        } label: {
                            Label("Editar", systemImage: "pencil")
                        }
                        .tint(.blue)

                        Button(role: .destructive) {
                            adventureComboBuilderViewModel.removeFoodItem(item.id)
                        } label: {
                            Label("Quitar", systemImage: "trash")
                        }
                    }
                }
            }

            Button {
                isFoodPickerPresented = true
            } label: {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "fork.knife")

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Agregar comida")
                            .font(.headline)

                        Text("Explora platos, ingredientes y detalles antes de agregarlos.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .appCardStyle(.adventure, emphasized: false)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $isFoodPickerPresented) {
                AdventureFoodPickerSheet(
                    menuSections: menuViewModel.state.sections,
                    selectedDate: adventureComboBuilderViewModel.state.selectedDate,
                    rewardPresentationProvider: { item, quantity in
                        adventureComboBuilderViewModel.foodPickerRewardPresentation(for: item, quantity: quantity)
                    },
                    displayedPriceProvider: { item, quantity in
                        adventureComboBuilderViewModel.foodPickerDisplayedPrice(for: item, quantity: quantity)
                    },
                    incrementalDiscountProvider: { item, quantity in
                        adventureComboBuilderViewModel.foodPickerIncrementalDiscount(for: item, quantity: quantity)
                    }
                ) { item, quantity, notes in
                    adventureComboBuilderViewModel.addFoodItem(
                        item,
                        quantity: quantity,
                        notes: notes,
                        for: adventureComboBuilderViewModel.state.selectedDate
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if !adventureComboBuilderViewModel.state.foodItems.isEmpty {
                foodServingOptionsCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
    }

    private var foodServingOptionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Servicio de comida",
                subtitle: "Define cuándo debe servirse lo agregado."
            )

            Picker(
                "Momento de servicio",
                selection: Binding(
                    get: { adventureComboBuilderViewModel.state.foodServingMoment },
                    set: { adventureComboBuilderViewModel.setFoodServingMoment($0) }
                )
            ) {
                ForEach(ReservationServingMoment.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            if adventureComboBuilderViewModel.state.foodServingMoment == .specificTime {
                DatePicker(
                    "Hora de servicio",
                    selection: Binding(
                        get: { adventureComboBuilderViewModel.state.foodServingTime },
                        set: { adventureComboBuilderViewModel.setFoodServingTime($0) }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }

            TextField(
                "Notas de comida (opcional)",
                text: Binding(
                    get: { adventureComboBuilderViewModel.state.foodNotes },
                    set: { adventureComboBuilderViewModel.setFoodNotes($0) }
                ),
                axis: .vertical
            )
            .lineLimit(2...4)
            .appTextFieldStyle(.adventure)
        }
        .appCardStyle(.adventure)
    }

    private var contactSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        isContactSectionExpanded.toggle()
                    }
                } label: {
                    HStack {
                        BrandSectionHeader(
                            theme: .adventure,
                            title: "Contacto",
                            subtitle: "La información de tu perfil se utiliza automáticamente para esta reserva."
                        )

                        Spacer(minLength: 12)

                        Image(systemName: "chevron.down")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isContactSectionExpanded ? 180 : 0))
                            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isContactSectionExpanded)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isContactSectionExpanded {
                    VStack(alignment: .leading, spacing: 16) {
                        TextField(
                            "",
                            text: Binding(
                                get: { authenticatedProfile?.nationalId ?? adventureComboBuilderViewModel.state.nationalId },
                                set: { _ in }
                            ),
                            prompt: Text("Cédula")
                        )
                        .disabled(true)
                        .keyboardType(.numberPad)
                        .appTextFieldStyle(.adventure)

                        TextField(
                            "",
                            text: Binding(
                                get: { authenticatedProfile?.fullName ?? adventureComboBuilderViewModel.state.clientName },
                                set: { _ in }
                            ),
                            prompt: Text("Nombre")
                        )
                        .disabled(true)
                        .appTextFieldStyle(.adventure)

                        TextField(
                            "",
                            text: Binding(
                                get: { authenticatedProfile?.phoneNumber ?? adventureComboBuilderViewModel.state.whatsappNumber },
                                set: { _ in }
                            ),
                            prompt: Text("WhatsApp")
                        )
                        .disabled(true)
                        .keyboardType(.phonePad)
                        .appTextFieldStyle(.adventure)

                        HStack(alignment: .top, spacing: 12) {
                            BrandIconBubble(theme: .adventure, systemImage: "person.crop.circle.badge.checkmark", size: 38)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("¿Necesitas actualizar tu información?")
                                    .font(.subheadline.weight(.semibold))

                                Text("Por favor, cambia tus datos personales desde la página Editar perfil.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .appCardStyle(.adventure)

                        TextField(
                            "Notas generales (opcional)",
                            text: Binding(
                                get: { adventureComboBuilderViewModel.state.notes },
                                set: { adventureComboBuilderViewModel.setNotes($0) }
                            ),
                            axis: .vertical
                        )
                        .lineLimit(3...5)
                        .appTextFieldStyle(.adventure)
                    }
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .top))
                        )
                    )
                }
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Resumen",
                    subtitle: "Revisa el total antes de confirmar."
                )

                if let slot = adventureComboBuilderViewModel.state.selectedSlot {
                    summaryRow("Aventura", slot.adventureSubtotal.priceText)
                    summaryRow("Comida", slot.foodSubtotal.priceText)
                    summaryRow("Subtotal", slot.subtotal.priceText)
                    summaryRow("Descuento aventura", "-\(slot.discountAmount.priceText)")

                    if adventureComboBuilderViewModel.state.rewardPreview.totalDiscount > 0 {
                        summaryRow(
                            "Murco Loyalty",
                            "-\(adventureComboBuilderViewModel.state.rewardPreview.totalDiscount.priceText)"
                        )
                    }

                    Divider()

                    summaryRow(
                        "Total",
                        max(0, slot.totalAmount - adventureComboBuilderViewModel.state.rewardPreview.totalDiscount).priceText,
                        bold: true
                    )
                } else {
                    summaryRow("Aventura estimada", adventureComboBuilderViewModel.estimatedAdventureSubtotal.priceText)
                    summaryRow("Comida estimada", adventureComboBuilderViewModel.estimatedFoodSubtotal.priceText)
                    summaryRow("Descuento estimado", "-\(adventureComboBuilderViewModel.estimatedDiscountAmount.priceText)")

                    if adventureComboBuilderViewModel.state.rewardPreview.totalDiscount > 0 {
                        summaryRow(
                            "Murco Loyalty",
                            "-\(adventureComboBuilderViewModel.state.rewardPreview.totalDiscount.priceText)"
                        )
                    }

                    Divider()

                    summaryRow("Total estimado", adventureComboBuilderViewModel.estimatedTotal.priceText, bold: true)
                }

                if !adventureComboBuilderViewModel.activeRewardPresentations.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Premios aplicados")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)

                        ForEach(adventureComboBuilderViewModel.activeRewardPresentations) { reward in
                            HStack(alignment: .top, spacing: 10) {
                                BrandBadge(theme: .adventure, title: reward.badge, selected: true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(reward.title)
                                        .font(.caption.bold())
                                        .foregroundStyle(palette.textPrimary)

                                    Text(reward.message)
                                        .font(.caption)
                                        .foregroundStyle(palette.textSecondary)
                                }

                                Spacer()

                                if let amountText = reward.amountText {
                                    Text("-\(amountText)")
                                        .font(.caption.bold())
                                        .foregroundStyle(palette.success)
                                }
                            }
                        }
                    }
                }
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var confirmSection: some View {
        Section {
            VStack(spacing: 12) {
                if showAddedMessage {
                    Text("Reserva agregada")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(palette.success)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    guard blockedFoodItemsForToday.isEmpty else {
                        adventureComboBuilderViewModel.presentError(
                            "Por hoy, algunos productos seleccionados están agotados y no se pueden pedir. Elige mañana u otro día futuro."
                        )
                        return
                    }

                    syncProfileFieldsFromSession()
                    adventureComboBuilderViewModel.submit(clientId: authenticatedProfile?.id)

                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAddedMessage = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAddedMessage = false
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            dismiss()
                        }
                    }
                } label: {
                    if adventureComboBuilderViewModel.state.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Confirmar reserva", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
                .disabled(
                    adventureComboBuilderViewModel.state.isSubmitting
                    || adventureComboBuilderViewModel.state.selectedSlot == nil
                )
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 28, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
    }

    private func summaryRow(_ title: String, _ value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(bold ? .bold : .semibold)
                .foregroundStyle(.primary)
        }
        .font(bold ? .headline : .subheadline)
    }
}

private struct ReservationFoodItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var item: ReservationFoodItemDraft
    let onSave: (ReservationFoodItemDraft) -> Void

    init(
        item: ReservationFoodItemDraft,
        onSave: @escaping (ReservationFoodItemDraft) -> Void
    ) {
        _item = State(initialValue: item)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Plato") {
                    Text(item.name)
                    Text("Unitario: \(item.unitPrice.priceText)")
                        .foregroundStyle(.secondary)
                }

                Section("Cantidad") {
                    Stepper("Cantidad: \(item.quantity)", value: $item.quantity, in: 1...50)
                }

                Section("Notas") {
                    TextField(
                        "Sin cebolla, más cocido, etc.",
                        text: Binding(
                            get: { item.notes ?? "" },
                            set: { item.notes = $0 }
                        ),
                        axis: .vertical
                    )
                    .lineLimit(3...5)
                }
            }
            .navigationTitle("Editar comida")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .appScreenStyle(.adventure)
        }
    }
}

private struct ReservationFoodRow: View {
    let item: ReservationFoodItemDraft
    let rewardPresentation: RewardPresentation?
    let displayedSubtotal: Double
    let rewardAmount: Double
    let onEdit: () -> Void
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                Text("Unitario: \(item.unitPrice.priceText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if rewardAmount > 0 {
                    Text("Subtotal: \(item.subtotal.priceText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()

                    Text("Con premio: \(displayedSubtotal.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                } else {
                    Text("Subtotal: \(item.subtotal.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let rewardPresentation {
                    HStack(spacing: 8) {
                        BrandBadge(theme: .adventure, title: rewardPresentation.badge, selected: true)

                        Text(rewardPresentation.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 10) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button(action: onDecrease) {
                        Image(systemName: "minus.circle.fill")
                    }
                    .buttonStyle(.plain)

                    Text("\(item.quantity)")
                        .font(.headline)
                        .frame(minWidth: 20)

                    Button(action: onIncrease) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .appCardStyle(.adventure)
    }
}

private struct AdventureFoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let menuSections: [MenuSection]
    let selectedDate: Date
    let rewardPresentationProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double
    let onAdd: (MenuItem, Int, String?) -> Void

    @State private var selectedCategoryId: String? = nil
    @State private var searchText = ""

    private let categoryDisplayOrder: [String] = [
        "Entradas",
        "Sopas",
        "Platos Fuertes",
        "Extras",
        "Postres",
        "Bebidas",
        "Bebidas Alcohólicas"
    ]

    private func categoryRank(for title: String) -> Int {
        categoryDisplayOrder.firstIndex(of: title) ?? Int.max
    }

    private var orderedSections: [MenuSection] {
        menuSections.sorted { lhs, rhs in
            let lhsRank = categoryRank(for: lhs.category.title)
            let rhsRank = categoryRank(for: rhs.category.title)

            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }

            return lhs.category.title < rhs.category.title
        }
    }

    private var categories: [MenuCategory] {
        orderedSections.map(\.category)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    categorySelector

                    if filteredSections.isEmpty {
                        ContentUnavailableView(
                            "No se encontraron platos",
                            systemImage: "magnifyingglass",
                            description: Text("Prueba otra búsqueda o cambia la categoría.")
                        )
                        .padding(.top, 32)
                    } else {
                        ForEach(filteredSections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.category.title)
                                    .font(.title3.bold())

                                ForEach(section.items) { item in
                                    let rewardPresentation = rewardPresentationProvider(item, 1)
                                    let displayedPrice = displayedPriceProvider(item, 1)
                                    let incrementalDiscount = incrementalDiscountProvider(item, 1)

                                    NavigationLink {
                                        AdventureFoodDetailView(
                                            item: item,
                                            selectedDate: selectedDate,
                                            rewardPresentationProvider: rewardPresentationProvider,
                                            displayedPriceProvider: displayedPriceProvider,
                                            incrementalDiscountProvider: incrementalDiscountProvider
                                        ) { quantity, notes in
                                            onAdd(item, quantity, notes)
                                            dismiss()
                                        }
                                    } label: {
                                        AdventureFoodMenuRow(
                                            item: item,
                                            selectedDate: selectedDate,
                                            rewardPresentation: rewardPresentation,
                                            displayedPrice: displayedPrice,
                                            incrementalDiscount: incrementalDiscount
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Menú del restaurante")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Buscar plato, bebida o ingrediente")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .appScreenStyle(.adventure)
        }
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryChip(title: "Todo", isSelected: selectedCategoryId == nil) {
                    selectedCategoryId = nil
                }

                ForEach(categories) { category in
                    categoryChip(
                        title: category.title,
                        isSelected: selectedCategoryId == category.id
                    ) {
                        selectedCategoryId = category.id
                    }
                }
            }
        }
    }

    private func categoryChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var filteredSections: [MenuSection] {
        let categoryFiltered = orderedSections.filter { section in
            selectedCategoryId == nil || section.category.id == selectedCategoryId
        }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return categoryFiltered
        }

        let query = searchText.lowercased()

        return categoryFiltered.compactMap { section in
            let items = section.items.filter { item in
                item.name.lowercased().contains(query)
                || item.description.lowercased().contains(query)
                || item.ingredients.contains(where: { $0.lowercased().contains(query) })
            }

            guard !items.isEmpty else { return nil }

            return MenuSection(
                id: section.id,
                category: section.category,
                items: items
            )
        }
    }
}

private struct AdventureFoodMenuRow: View {
    let item: MenuItem
    let selectedDate: Date
    let rewardPresentation: RewardPresentation?
    let displayedPrice: Double
    let incrementalDiscount: Double

    private var isBlockedForSelectedDate: Bool {
        AdventureDateHelper.calendar.isDateInToday(selectedDate) && !item.canBeOrdered
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)

                        if item.isFeatured {
                            Text("Destacado")
                                .font(.caption.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.accentColor.opacity(0.16)))
                        }
                    }

                    Text(item.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if incrementalDiscount > 0 {
                        Text(item.finalPrice.priceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }

                    Text((incrementalDiscount > 0 ? displayedPrice : item.finalPrice).priceText)
                        .font(.subheadline.bold())
                }
            }

            if let rewardPresentation {
                HStack(spacing: 8) {
                    BrandBadge(theme: .adventure, title: rewardPresentation.badge, selected: true)

                    Text(rewardPresentation.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            if isBlockedForSelectedDate {
                Text("Por hoy está agotado y no se puede pedir")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(item.ingredients.prefix(4)), id: \.self) { ingredient in
                        Text(ingredient)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.10))
                            )
                    }

                    if item.ingredients.count > 4 {
                        Text("+\(item.ingredients.count - 4)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.10))
                            )
                    }
                }
            }
        }
        .appCardStyle(.adventure, emphasized: false)
        .opacity(isBlockedForSelectedDate ? 0.82 : 1)
    }
}

private struct AdventureFoodDetailView: View {
    let item: MenuItem
    let selectedDate: Date
    let rewardPresentationProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double
    let onAdd: (Int, String?) -> Void

    private var isBlockedForSelectedDate: Bool {
        AdventureDateHelper.calendar.isDateInToday(selectedDate) && !item.canBeOrdered
    }

    @State private var quantity = 1
    @State private var notes = ""

    private var rewardPresentation: RewardPresentation? {
        rewardPresentationProvider(item, quantity)
    }

    private var displayedPrice: Double {
        displayedPriceProvider(item, quantity)
    }

    private var incrementalDiscount: Double {
        incrementalDiscountProvider(item, quantity)
    }

    private var baseSubtotal: Double {
        item.finalPrice * Double(quantity)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerCard
                descriptionCard
                ingredientsCard
                priceCard

                if let rewardPresentation {
                    rewardCard(rewardPresentation)
                }

                if isBlockedForSelectedDate {
                    VStack(alignment: .leading, spacing: 10) {
                        BrandSectionHeader(
                            theme: .adventure,
                            title: "Disponibilidad",
                            subtitle: "Esta restricción solo aplica para las reservas de hoy."
                        )

                        Text("Por hoy está agotado y no se puede pedir. Selecciona mañana u otro día futuro para reservarlo.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .appCardStyle(.adventure, emphasized: false)
                }

                quantityCard
                notesCard

                Button {
                    let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    onAdd(quantity, trimmedNotes.isEmpty ? nil : trimmedNotes)
                } label: {
                    Label("Agregar a la reserva", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
                .disabled(isBlockedForSelectedDate)
            }
            .padding(20)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.adventure)
    }

    private var headerCard: some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(.title3.bold())

                if incrementalDiscount > 0 {
                    Text(displayedPrice.priceText)
                        .font(.headline)
                        .foregroundStyle(.green)
                } else {
                    Text(item.finalPrice.priceText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .appCardStyle(.adventure)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Descripción",
                subtitle: "Qué incluye este plato."
            )

            Text(item.description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Ingredientes",
                subtitle: "Componentes principales."
            )

            ForEach(item.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)

                    Text(ingredient)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .appCardStyle(.adventure)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Precio",
                subtitle: item.hasOffer ? "Precio promocional disponible." : "Precio actual."
            )

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if incrementalDiscount > 0 {
                    Text(baseSubtotal.priceText)
                        .foregroundStyle(.secondary)
                        .strikethrough()

                    Text(displayedPrice.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                } else if item.hasOffer, let offerPrice = item.offerPrice {
                    Text((item.price * Double(quantity)).priceText)
                        .foregroundStyle(.secondary)
                        .strikethrough()

                    Text((offerPrice * Double(quantity)).priceText)
                        .font(.title2.bold())
                } else {
                    Text(baseSubtotal.priceText)
                        .font(.title2.bold())
                }
            }
        }
        .appCardStyle(.adventure)
    }

    private func rewardCard(_ rewardPresentation: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .adventure, title: rewardPresentation.badge, selected: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(rewardPresentation.title)
                    .font(.caption.bold())

                Text(rewardPresentation.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var quantityCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Cantidad",
                subtitle: "Cuántas unidades deseas reservar."
            )

            QuantitySelectorView(
                quantity: $quantity,
                isEnabled: !isBlockedForSelectedDate,
                theme: .adventure
            )
        }
        .appCardStyle(.adventure)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Notas",
                subtitle: "Indicaciones especiales para cocina."
            )

            TextField("Sin cebolla, más cocido, sin ají, etc.", text: $notes, axis: .vertical)
                .lineLimit(3, reservesSpace: true)
                .appTextFieldStyle(.adventure)
        }
        .appCardStyle(.adventure)
    }
}

private struct ComboItemCard: View {
    let item: AdventureReservationItemDraft
    let rewardPresentation: RewardPresentation?
    let baseSubtotal: Double
    let discountedSubtotal: Double

    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: .adventure, systemImage: item.activity.legacySystemImage, size: 52)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if discountedSubtotal < baseSubtotal {
                    HStack(spacing: 8) {
                        Text(baseSubtotal.priceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .strikethrough()

                        Text("Con premio \(discountedSubtotal.priceText)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(baseSubtotal.priceText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                if let rewardPresentation {
                    HStack(spacing: 8) {
                        BrandBadge(theme: .adventure, title: rewardPresentation.badge, selected: true)

                        Text(rewardPresentation.message)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(.adventure)
    }
}

private struct AdventureSlotCard: View {
    let slot: AdventureAvailabilitySlot
    let isSelected: Bool
    let effectiveTotal: Double
    let hasLoyaltyDiscount: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .adventure, scheme: colorScheme)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AdventureDateHelper.timeText(slot.startAt))
                    .font(.headline)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(palette.primary)
                }
            }

            Text("Termina \(AdventureDateHelper.timeText(slot.endAt))")
                .font(.caption)
                .foregroundStyle(.secondary)

            if slot.adventureSubtotal == 0 && slot.foodSubtotal > 0 {
                Text("Reserva de comida")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            } else if slot.foodSubtotal > 0 {
                Text("Aventura + comida")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }

            Divider()

            if hasLoyaltyDiscount {
                Text(slot.totalAmount.priceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .strikethrough()
            }

            Text(effectiveTotal.priceText)
                .font(.headline.weight(.bold))
                .foregroundStyle(isSelected ? palette.primary : .primary)
        }
        .padding(16)
        .frame(width: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSelected ? AnyShapeStyle(palette.chipGradient) : AnyShapeStyle(palette.cardGradient))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? palette.primary : palette.stroke, lineWidth: isSelected ? 1.5 : 1)
        )
        .shadow(
            color: palette.shadow.opacity(
                isSelected
                    ? (colorScheme == .dark ? 0.28 : 0.14)
                    : (colorScheme == .dark ? 0.14 : 0.06)
            ),
            radius: isSelected ? 14 : 8,
            x: 0,
            y: isSelected ? 8 : 4
        )
    }
}

private struct AdventureItemEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var item: AdventureReservationItemDraft
    let config: AdventureActivityCatalogItem?
    let linePrice: Double
    let onSave: (AdventureReservationItemDraft) -> Void

    init(
        item: AdventureReservationItemDraft,
        config: AdventureActivityCatalogItem?,
        linePrice: Double,
        onSave: @escaping (AdventureReservationItemDraft) -> Void
    ) {
        _item = State(initialValue: item)
        self.config = config
        self.linePrice = linePrice
        self.onSave = onSave
    }

    private var durationOptions: [Int] {
        config?.durationOptions ?? item.activity.legacyDurationOptions
    }

    private var activityTitle: String {
        config?.title ?? item.activity.legacyTitle
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    Text(activityTitle)
                }

                switch item.activity {
                case .offRoad:
                    Section("Off-road") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes / 60) hora(s)").tag(minutes)
                            }
                        }

                        Stepper("Vehículos: \(item.vehicleCount)", value: $item.vehicleCount, in: 1...50)
                        Stepper("Personas: \(item.offRoadRiderCount)", value: $item.offRoadRiderCount, in: 1...100)

                        Text("Cada vehículo admite 1 o 2 personas. El precio es por vehículo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                case .paintball, .goKarts, .shootingRange:
                    Section("Configuración") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(durationOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }

                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...100)
                    }

                case .camping:
                    Section("Camping") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...100)
                        Stepper("Noches: \(item.nights)", value: $item.nights, in: 1...30)

                        Text("El camping se mantiene al final del combo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                case .extremeSlide:
                    Section("Resbaladera extrema") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...100)

                        Text("Incluye transporte off-road en la lógica del planificador.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Precio") {
                    if let config {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Base: \(config.basePrice.priceText)")
                            Text("Descuento unitario: \(config.discountAmount.priceText)")
                            Text("Precio final: \(linePrice.priceText)")
                                .font(.headline)
                        }
                    } else {
                        Text(linePrice.priceText)
                            .font(.headline)
                    }
                }
            }
            .navigationTitle("Editar actividad")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        onSave(item)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/AdventureReservationsView.swift

```swift
//
//  AdventureReservationsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct AdventureReservationsView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: AdventureBookingsViewModel
    @State private var selectedBooking: AdventureBooking?
    @State private var bookingToCancel: AdventureBooking?

    init(viewModelFactory: @escaping () -> AdventureBookingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    var body: some View {
        Group {
            if viewModel.state.isLoading && viewModel.state.allBookings.isEmpty {
                loadingView
            } else {
                contentView
            }
        }
        .navigationTitle("Reservas y eventos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                sortMenu
            }
        }
        .navigationDestination(item: $selectedBooking) { booking in
            ReserveViewDetail(
                booking: booking,
                onCancel: booking.status != .canceled
                    ? { viewModel.cancelBooking(booking.id) }
                    : nil
            )
        }
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: {
                    viewModel.state.errorMessage != nil
                    || viewModel.state.successMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissMessage()
                    }
                }
            )
        ) {
            Button("OK") {
                viewModel.dismissMessage()
            }
        } message: {
            Text(
                viewModel.state.errorMessage
                ?? viewModel.state.successMessage
                ?? ""
            )
        }
        .confirmationDialog(
            "Cancelar reserva",
            isPresented: Binding(
                get: { bookingToCancel != nil },
                set: { isPresented in
                    if !isPresented {
                        bookingToCancel = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("Sí, cancelar", role: .destructive) {
                if let bookingToCancel {
                    viewModel.cancelBooking(bookingToCancel.id)
                }

                bookingToCancel = nil
            }

            Button("No", role: .cancel) {
                bookingToCancel = nil
            }
        } message: {
            Text("Esta acción marcará la reserva como cancelada.")
        }
        .onAppear {
            syncNationalIdFromSession()
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: authenticatedProfile?.nationalId) { _, _ in
            syncNationalIdFromSession()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
                .tint(palette.primary)

            Text("Cargando reservas...")
                .font(.headline)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appScreenStyle(.adventure)
    }

    private var contentView: some View {
        List {
            headerSection
            filtersSection
            reservationsSection
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .appScreenStyle(.adventure)
        .refreshable {
            syncNationalIdFromSession()
            viewModel.onAppear()
        }
    }

    private func syncNationalIdFromSession() {
        guard let nationalId = authenticatedProfile?.nationalId else {
            return
        }

        viewModel.setNationalId(nationalId)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(AdventureReservationSortOrder.allCases) { order in
                Button {
                    viewModel.setSortOrder(order)
                } label: {
                    Label(order.title, systemImage: order.systemImage)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle.fill")
                .font(.title3)
                .foregroundStyle(palette.primary)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    BrandIconBubble(
                        theme: .adventure,
                        systemImage: "calendar.badge.clock",
                        size: 54
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tus reservas")
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)

                        Text("Consulta reservas actuales, futuras y pasadas de aventura, comida, cumpleaños y eventos.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    summaryPill(
                        title: "Total",
                        value: viewModel.totalCount,
                        systemImage: "tray.full"
                    )

                    summaryPill(
                        title: "Ahora",
                        value: viewModel.currentCount,
                        systemImage: "clock.badge.checkmark"
                    )

                    summaryPill(
                        title: "Futuras",
                        value: viewModel.futureCount,
                        systemImage: "calendar.badge.plus"
                    )
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private func summaryPill(
        title: String,
        value: Int,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.primary)

            Text("\(value)")
                .font(.headline.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var filtersSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Filtros",
                    subtitle: "\(viewModel.displayedCount) de \(viewModel.totalCount) reserva(s) visibles."
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tiempo")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    horizontalTimelineFilters
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Estado")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    horizontalStatusFilters
                }

                HStack {
                    Label(viewModel.state.sortOrder.title, systemImage: viewModel.state.sortOrder.systemImage)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.textSecondary)

                    Spacer()

                    sortMenu
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }

    private var horizontalTimelineFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AdventureReservationTimelineFilter.allCases) { filter in
                    filterChip(
                        title: filter.title,
                        systemImage: filter.systemImage,
                        isSelected: viewModel.state.selectedTimelineFilter == filter
                    ) {
                        viewModel.setTimelineFilter(filter)
                    }
                }
            }
        }
    }

    private var horizontalStatusFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AdventureReservationStatusFilter.allCases) { filter in
                    filterChip(
                        title: filter.title,
                        systemImage: nil,
                        isSelected: viewModel.state.selectedStatusFilter == filter
                    ) {
                        viewModel.setStatusFilter(filter)
                    }
                }
            }
        }
    }

    private func filterChip(
        title: String,
        systemImage: String?,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.caption.weight(.bold))
                }

                Text(title)
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(isSelected ? palette.primary : palette.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(isSelected ? palette.primary.opacity(0.16) : palette.elevatedCard)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? palette.primary.opacity(0.65) : palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var reservationsSection: some View {
        if viewModel.groupedBookings.isEmpty {
            Section {
                ContentUnavailableView(
                    "Sin reservas",
                    systemImage: "calendar",
                    description: Text("No hay reservas que coincidan con los filtros seleccionados.")
                )
                .foregroundStyle(palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .appCardStyle(.adventure)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } else {
            ForEach(viewModel.groupedBookings) { group in
                Section {
                    ForEach(group.bookings) { booking in
                        Button {
                            selectedBooking = booking
                        } label: {
                            AdventureReservationRow(booking: booking)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if booking.status != .canceled {
                                Button(role: .destructive) {
                                    bookingToCancel = booking
                                } label: {
                                    Label("Cancelar", systemImage: "xmark")
                                }
                            }
                        }
                    }
                } header: {
                    Text(group.title.capitalized)
                        .font(.headline)
                        .foregroundStyle(palette.textSecondary)
                        .textCase(nil)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

private struct AdventureReservationRow: View {
    let booking: AdventureBooking

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    private var iconName: String {
        if booking.hasActivities {
            return "figure.hiking"
        }

        if booking.hasFoodReservation {
            return "fork.knife"
        }

        return "calendar"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            topBlock

            chipsBlock

            guestBlock

            if booking.hasActivities {
                activitiesBlock
            }

            if let food = booking.foodReservation, !food.items.isEmpty {
                foodBlock(food)
            }

            if !booking.appliedRewards.isEmpty {
                rewardsBlock
            }

            Divider()
                .overlay(palette.stroke)

            totalsBlock
        }
        .appCardStyle(.adventure)
    }

    private var topBlock: some View {
        HStack(alignment: .top, spacing: 12) {
            BrandIconBubble(
                theme: .adventure,
                systemImage: iconName,
                size: 48
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(booking.eventDisplayTitle)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(booking.clientName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textSecondary)

                Text(dateTimeText)
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)

                Text("WhatsApp \(booking.whatsappNumber)")
                    .font(.caption)
                    .foregroundStyle(palette.textTertiary)
            }

            Spacer()

            statusBadge
        }
    }

    private var chipsBlock: some View {
        HStack(spacing: 8) {
            BrandBadge(theme: .adventure, title: booking.visitTypeTitle)

            BrandBadge(
                theme: .adventure,
                title: booking.eventType == .regularVisit ? "Visita" : "Evento",
                selected: booking.eventType != .regularVisit
            )
        }
    }

    private var guestBlock: some View {
        HStack(spacing: 8) {
            Label("\(booking.guestCount) invitado(s)", systemImage: "person.2.fill")
            Label("Cédula \(booking.nationalId)", systemImage: "person.text.rectangle")
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(palette.textSecondary)
    }

    private var activitiesBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actividades")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            ForEach(booking.items, id: \.id) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(palette.primary)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text("\(item.title) — \(item.summaryText)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
    }

    private func foodBlock(_ food: ReservationFoodDraft) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Comida reservada")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            ForEach(food.items, id: \.id) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text("\(item.quantity)x \(item.name)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }
            }

            Text("Servicio: \(servingMomentText(food))")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
    }

    private var rewardsBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Premios aplicados")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            ForEach(booking.appliedRewards.prefix(2)) { reward in
                HStack(alignment: .top, spacing: 8) {
                    BrandBadge(theme: .adventure, title: "Premio", selected: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(reward.title)
                            .font(.caption.bold())
                            .foregroundStyle(palette.textPrimary)

                        Text(reward.note)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Text("-\(reward.amount.priceText)")
                        .font(.caption.bold())
                        .foregroundStyle(palette.success)
                }
            }

            if booking.appliedRewards.count > 2 {
                Text("+\(booking.appliedRewards.count - 2) premio(s) más")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.textTertiary)
            }
        }
    }

    private var totalsBlock: some View {
        VStack(spacing: 10) {
            amountRow("Aventura", booking.adventureSubtotal)
            amountRow("Comida", booking.foodSubtotal)

            if booking.discountAmount > 0 {
                amountRow("Descuento", -booking.discountAmount)
            }

            if booking.loyaltyDiscountAmount > 0 {
                amountRow("Murco Loyalty", -booking.loyaltyDiscountAmount)
            }

            amountRow(
                "Total",
                booking.totalAmount,
                isPrimary: true
            )

            HStack {
                Spacer()

                Label("Ver detalle", systemImage: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(palette.textTertiary)
            }
        }
    }

    private var dateTimeText: String {
        let dateText = booking.startAt.formatted(
            .dateTime
                .day()
                .month(.abbreviated)
                .year()
        )

        let startText = booking.startAt.formatted(date: .omitted, time: .shortened)
        let endText = booking.endAt.formatted(date: .omitted, time: .shortened)

        return "\(dateText) • \(startText) - \(endText)"
    }

    private func servingMomentText(_ food: ReservationFoodDraft) -> String {
        switch food.servingMoment {
        case .onArrival:
            return "Al llegar"

        case .afterActivities:
            return "Después de actividades"

        case .specificTime:
            if let servingTime = food.servingTime {
                return "Hora específica • \(servingTime.formatted(date: .omitted, time: .shortened))"
            }

            return "Hora específica"
        }
    }

    private func amountRow(
        _ title: String,
        _ amount: Double,
        isPrimary: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(isPrimary ? .headline : .subheadline)
                .foregroundStyle(isPrimary ? palette.textPrimary : palette.textSecondary)

            Spacer()

            Text(amount.priceText)
                .font(isPrimary ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(isPrimary ? palette.primary : palette.textPrimary)
        }
    }

    private var statusBadge: some View {
        Text(booking.status.title)
            .font(.caption.bold())
            .foregroundStyle(statusTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusBackgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(statusBorderColor, lineWidth: 1)
            )
    }

    private var statusBackgroundColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .confirmed:
            return palette.success.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .completed:
            return Color.blue.opacity(colorScheme == .dark ? 0.22 : 0.14)
        case .canceled:
            return palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.14)
        }
    }

    private var statusBorderColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning.opacity(0.45)
        case .confirmed:
            return palette.success.opacity(0.45)
        case .completed:
            return Color.blue.opacity(0.45)
        case .canceled:
            return palette.destructive.opacity(0.45)
        }
    }

    private var statusTextColor: Color {
        switch booking.status {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.success
        case .completed:
            return .blue
        case .canceled:
            return palette.destructive
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/BookingsView.swift

```swift
//
//  BookingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct BookingsView: View {
    @ObservedObject var ordersViewModel: OrdersViewModel
    let adventureModuleFactory: AdventureModuleFactory
    @Environment(\.colorScheme) private var colorScheme

    private var neutralPalette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection

                    NavigationLink {
                        OrdersView(viewModel: ordersViewModel)
                    } label: {
                        bookingCard(
                            theme: .restaurant,
                            badge: "Restaurante",
                            title: "Pedidos del restaurante",
                            subtitle: "Revisa tus pedidos actuales y anteriores de comida.",
                            systemImage: "fork.knife"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AdventureReservationsView(
                            viewModelFactory: adventureModuleFactory.makeBookingsViewModel
                        )
                    } label: {
                        bookingCard(
                            theme: .adventure,
                            badge: "Aventura",
                            title: "Reservas de aventura",
                            subtitle: "Mira combos, actividades individuales, camping y reservas nocturnas.",
                            systemImage: "calendar.badge.clock"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .appScreenStyle(.neutral)
            .navigationTitle("Reservas")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Gestiona tus reservas",
                subtitle: "Accede rápidamente a tus pedidos del restaurante y a tus reservas de aventura."
            )

            Text("Todo en un solo lugar, con acceso claro para cada experiencia.")
                .font(.subheadline)
                .foregroundStyle(neutralPalette.textSecondary)
        }
        .appCardStyle(.neutral, emphasized: false)
    }

    private func bookingCard(
        theme: AppSectionTheme,
        badge: String,
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)

        return HStack(spacing: 16) {
            BrandIconBubble(
                theme: theme,
                systemImage: systemImage,
                size: 54
            )

            VStack(alignment: .leading, spacing: 8) {
                BrandBadge(theme: theme, title: badge)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.headline.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
        .appCardStyle(theme, emphasized: false)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/ExperiencesView.swift

```swift
//
//  ExperiencesView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ExperiencesView: View {
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    var body: some View {
        AdventureCatalogView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/ReserveViewDetail.swift

```swift
//
//  ReserveViewDetail.swift
//  Altos del Murco
//
//  Created by José Ruiz on 18/4/26.
//

import SwiftUI

struct ReserveViewDetail: View {
    let booking: AdventureBooking
    let onCancel: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showCancelConfirmation = false

    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                heroSection
                scheduleSection
                contactSection

                if booking.hasActivities {
                    activitiesSection
                    timelineSection
                }

                if let food = booking.foodReservation, !food.items.isEmpty {
                    foodSection(food)
                }

                if hasAnyNotes {
                    notesSection
                }

                totalsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .navigationTitle("Detalle de reserva")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.adventure)
        .safeAreaInset(edge: .bottom) {
            if let onCancel, booking.status != .canceled {
                bottomBar(onCancel: onCancel)
            }
        }
        .alert("Cancelar reserva", isPresented: $showCancelConfirmation) {
            Button("No", role: .cancel) { }
            Button("Sí, cancelar", role: .destructive) {
                onCancel?()
                dismiss()
            }
        } message: {
            Text("Esta acción marcará la reserva como cancelada.")
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18), lineWidth: 1)
                )

            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18))
                .frame(width: 150, height: 150)
                .blur(radius: 12)
                .offset(x: 36, y: -24)

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    BrandIconBubble(
                        theme: .adventure,
                        systemImage: iconName,
                        size: 58
                    )

                    Spacer()

                    statusBadge
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(booking.eventDisplayTitle)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(booking.visitTypeTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.92))

                    Text(
                        "\(booking.startAt.formatted(date: .abbreviated, time: .shortened)) • \(booking.endAt.formatted(date: .omitted, time: .shortened))"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.88))
                }

                HStack(spacing: 8) {
                    infoChip("\(booking.guestCount) invitado(s)")
                    infoChip(booking.status.title)
                }
            }
            .padding(22)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.30 : 0.14),
            radius: 22,
            x: 0,
            y: 12
        )
    }

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Horario",
                subtitle: "Resumen de fecha y duración de la reserva."
            )

            detailRow("Inicio", booking.startAt.formatted(date: .complete, time: .shortened))
            detailRow("Fin", booking.endAt.formatted(date: .complete, time: .shortened))
            detailRow("Creada", booking.createdAt.formatted(date: .abbreviated, time: .shortened))
            detailRow("Tipo", booking.visitTypeTitle)
            detailRow("Evento", booking.eventDisplayTitle)
        }
        .appCardStyle(.adventure)
    }

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Cliente",
                subtitle: "Datos asociados a la reserva."
            )

            detailRow("Nombre", booking.clientName)
            detailRow("WhatsApp", booking.whatsappNumber)
            detailRow("Cédula", booking.nationalId)
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades reservadas",
                subtitle: "Configuración principal del combo."
            )

            VStack(spacing: 12) {
                ForEach(booking.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(
                            theme: .adventure,
                            systemImage: item.activity.legacySystemImage,
                            size: 42
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)

                            Text(item.summaryText)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)

                            let priceText = itemPriceText(item)
                            if !priceText.isEmpty {
                                Text(priceText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.primary)
                            }
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                }
            }
        }
        .appCardStyle(.adventure)
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Itinerario",
                subtitle: "Bloques reales programados dentro de la reserva."
            )

            VStack(spacing: 12) {
                ForEach(booking.blocks) { block in
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(palette.primary)
                                .frame(width: 10, height: 10)

                            Rectangle()
                                .fill(palette.stroke)
                                .frame(width: 2, height: 42)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text(block.title)
                                .font(.headline)
                                .foregroundStyle(palette.textPrimary)

                            Text(
                                "\(block.startAt.formatted(date: .omitted, time: .shortened)) - \(block.endAt.formatted(date: .omitted, time: .shortened))"
                            )
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                            Text(unitsText(for: block))
                                .font(.caption)
                                .foregroundStyle(palette.textTertiary)

                            if block.subtotal > 0 {
                                Text(block.subtotal.priceText)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.primary)
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private func foodSection(_ food: ReservationFoodDraft) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Comida reservada",
                subtitle: "Platos agregados a esta reserva."
            )

            VStack(spacing: 12) {
                ForEach(food.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(theme: .adventure, systemImage: "fork.knife", size: 40)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(item.quantity)x \(item.name)")
                                .font(.headline)

                            Text("Unitario: \(item.unitPrice.priceText)")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)

                            Text("Subtotal: \(item.subtotal.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.primary)

                            if let notes = item.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(palette.textTertiary)
                            }
                        }

                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                }
            }

            Divider()

            detailRow("Servicio", servingMomentText(food))
            if let notes = food.notes, !notes.isEmpty {
                detailRow("Notas cocina", notes)
            }
        }
        .appCardStyle(.adventure)
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Notas",
                subtitle: "Indicaciones adicionales asociadas a la reserva."
            )

            if let eventNotes = booking.eventNotes, !eventNotes.isEmpty {
                noteCard(title: "Notas del evento", text: eventNotes)
            }

            if let notes = booking.notes, !notes.isEmpty {
                noteCard(title: "Notas generales", text: notes)
            }
        }
        .appCardStyle(.adventure, emphasized: false)
    }

    private var totalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Totales",
                subtitle: "Resumen económico de la reserva."
            )

            amountRow("Aventura", booking.adventureSubtotal)
            amountRow("Comida", booking.foodSubtotal)
            amountRow("Subtotal", booking.subtotal)
            amountRow("Descuento", -booking.discountAmount)

            if booking.loyaltyDiscountAmount > 0 {
                amountRow("Murco Loyalty", -booking.loyaltyDiscountAmount)
            }

            amountRow(
                "Total",
                booking.totalAmount,
                isPrimary: true
            )

            if !booking.appliedRewards.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Premios aplicados")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    ForEach(booking.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: .adventure, title: "Premio", selected: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reward.title)
                                    .font(.caption.bold())
                                    .foregroundStyle(palette.textPrimary)

                                Text(reward.note)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Text("-\(reward.amount.priceText)")
                                .font(.caption.bold())
                                .foregroundStyle(palette.success)
                        }
                    }
                }
            }
        }
        .appCardStyle(.adventure)
    }

    private func bottomBar(onCancel: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            Button(role: .destructive) {
                showCancelConfirmation = true
            } label: {
                Label("Cancelar reserva", systemImage: "xmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .adventure))
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 90, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func amountRow(_ title: String, _ amount: Double, isPrimary: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isPrimary ? .headline : .subheadline)
                .foregroundStyle(isPrimary ? palette.textPrimary : palette.textSecondary)

            Spacer()

            Text(amount.priceText)
                .font(isPrimary ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(isPrimary ? palette.primary : palette.textPrimary)
        }
    }

    private func noteCard(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func infoChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.16))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
    }

    private func unitsText(for block: AdventureBookingBlock) -> String {
        switch block.resourceType {
        case .offRoadVehicles:
            return "\(block.reservedUnits) vehículo(s)"
        case .paintballPeople, .goKartPeople, .shootingPeople, .campingPeople, .extremeSlidePeople:
            return "\(block.reservedUnits) persona(s)"
        }
    }

    private func itemPriceText(_ item: AdventureReservationItemDraft) -> String {
        if let block = booking.blocks.first(where: { $0.activity == item.activity && $0.subtotal > 0 }) {
            return block.subtotal.priceText
        }
        return ""
    }

    private func servingMomentText(_ food: ReservationFoodDraft) -> String {
        switch food.servingMoment {
        case .onArrival:
            return "Al llegar"
        case .afterActivities:
            return "Después de actividades"
        case .specificTime:
            if let time = food.servingTime {
                return "Hora específica • \(time.formatted(date: .omitted, time: .shortened))"
            }
            return "Hora específica"
        }
    }

    private var hasAnyNotes: Bool {
        let eventNotes = booking.eventNotes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let notes = booking.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !eventNotes.isEmpty || !notes.isEmpty
    }

    private var iconName: String {
        if booking.hasActivities { return "figure.hiking" }
        if booking.hasFoodReservation { return "fork.knife" }
        return "calendar"
    }

    private var statusBadge: some View {
        Text(booking.status.title)
            .font(.caption.bold())
            .foregroundStyle(statusTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusBackgroundColor)
            )
            .overlay(
                Capsule()
                    .stroke(statusBorderColor, lineWidth: 1)
            )
    }

    private var statusBackgroundColor: Color {
        switch booking.status {
        case .pending:
            return Color.orange.opacity(colorScheme == .dark ? 0.25 : 0.16)
        case .confirmed:
            return Color.green.opacity(colorScheme == .dark ? 0.25 : 0.16)
        case .completed:
            return Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.16)
        case .canceled:
            return Color.red.opacity(colorScheme == .dark ? 0.25 : 0.16)
        }
    }

    private var statusBorderColor: Color {
        switch booking.status {
        case .pending:
            return Color.orange.opacity(0.45)
        case .confirmed:
            return Color.green.opacity(0.45)
        case .completed:
            return Color.blue.opacity(0.45)
        case .canceled:
            return Color.red.opacity(0.45)
        }
    }

    private var statusTextColor: Color {
        switch booking.status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
        case .completed:
            return .blue
        case .canceled:
            return .red
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/ServiceCardView.swift

```swift
//
//  ServiceCardView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ServiceCardView: View {
    let service: AdventureService
    var theme: AppSectionTheme = .adventure
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        HStack(alignment: .top, spacing: 14) {
            BrandIconBubble(
                theme: theme,
                systemImage: service.systemImage,
                size: 60
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(service.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                
                Text(service.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    metadataChip(
                        title: service.priceText,
                        systemImage: "dollarsign.circle"
                    )
                    
                    metadataChip(
                        title: service.durationText,
                        systemImage: "clock"
                    )
                }
                .padding(.top, 2)
            }
            
            Spacer(minLength: 8)
            
            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
                .padding(.top, 4)
        }
//        .appCardStyle(theme, emphasized: false)
    }
    
    private func metadataChip(title: String, systemImage: String) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        return HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            
            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(palette.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(palette.chipGradient)
        )
        .overlay(
            Capsule()
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/view/ServiceDetailView.swift

```swift
//
//  ServiceDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ServiceDetailView: View {
    let service: AdventureService
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let theme: AppSectionTheme = .adventure
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                descriptionSection
                infoSection
                includesSection
                actionSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .appScreenStyle(theme)
        .navigationTitle(service.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    BrandBadge(theme: theme, title: "Aventura", selected: true)
                    
                    Text(service.title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(palette.textPrimary)
                    
                    Text(service.shortDescription)
                        .font(.body)
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 12)
                
                BrandIconBubble(
                    theme: theme,
                    systemImage: service.systemImage,
                    size: 64
                )
            }
            
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .fill(palette.heroGradient)
                    .frame(height: 190)
                
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .fill(.white.opacity(colorScheme == .dark ? 0.05 : 0.12))
                
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.22 : 0.18))
                    .frame(width: 150, height: 150)
                    .blur(radius: 20)
                    .offset(x: 85, y: -35)
                
                VStack(spacing: 12) {
                    Image(systemName: service.systemImage)
                        .font(.system(size: 58, weight: .medium))
                        .foregroundStyle(.white)
                    
                    Text("Experiencia destacada")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .stroke(.white.opacity(colorScheme == .dark ? 0.10 : 0.20), lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.26 : 0.12),
                radius: 18,
                x: 0,
                y: 10
            )
        }
        .appCardStyle(theme, emphasized: false)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Sobre la experiencia",
                subtitle: "Detalles generales de la actividad."
            )
            
            Text(service.fullDescription)
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle(theme)
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Información rápida"
            )
            
            HStack(spacing: 14) {
                infoCard(
                    title: "Precio",
                    value: service.priceText,
                    systemImage: "dollarsign.circle.fill"
                )
                
                infoCard(
                    title: "Duración",
                    value: service.durationText,
                    systemImage: "clock.fill"
                )
            }
        }
    }
    
    private func infoCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandIconBubble(
                theme: theme,
                systemImage: systemImage,
                size: 42
            )
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textSecondary)
            
            Text(value)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(theme)
    }
    
    private var includesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Incluye",
                subtitle: "Lo que forma parte de esta experiencia."
            )
            
            VStack(spacing: 12) {
                ForEach(service.includes, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(palette.primary)
                            .padding(.top, 1)
                        
                        Text(item)
                            .font(.body)
                            .foregroundStyle(palette.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                }
            }
        }
        .appCardStyle(theme)
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                    .onAppear {
                        adventureComboBuilderViewModel.replaceItems(with: [service.defaultDraft])
                    }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                    Text("Reservar ahora")
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            
            Text("Podrás elegir fecha, horario y completar tus datos antes de confirmar.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/viewmodel/AdventureBookingsViewModel.swift

```swift
//
//  AdventureBookingsViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Combine
import Foundation
import SwiftUI

enum AdventureReservationTimelineFilter: String, CaseIterable, Identifiable {
    case all
    case current
    case future
    case past

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todas"
        case .current: return "Actuales"
        case .future: return "Futuras"
        case .past: return "Pasadas"
        }
    }

    var systemImage: String {
        switch self {
        case .all: return "calendar"
        case .current: return "clock.badge.checkmark"
        case .future: return "calendar.badge.plus"
        case .past: return "clock.arrow.circlepath"
        }
    }
}

enum AdventureReservationStatusFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case confirmed
    case completed
    case canceled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todo"
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .completed: return "Completada"
        case .canceled: return "Cancelada"
        }
    }

    var bookingStatus: AdventureBookingStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .confirmed: return .confirmed
        case .completed: return .completed
        case .canceled: return .canceled
        }
    }
}

enum AdventureReservationSortOrder: String, CaseIterable, Identifiable {
    case nearestFirst
    case newestFirst
    case oldestFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nearestFirst: return "Próximas primero"
        case .newestFirst: return "Más recientes"
        case .oldestFirst: return "Más antiguas"
        }
    }

    var systemImage: String {
        switch self {
        case .nearestFirst: return "sparkles"
        case .newestFirst: return "arrow.down"
        case .oldestFirst: return "arrow.up"
        }
    }
}

struct AdventureBookingsDateGroup: Identifiable {
    let id: String
    let date: Date
    let bookings: [AdventureBooking]

    var title: String {
        if Calendar.current.isDateInToday(date) {
            return "Hoy"
        }

        if Calendar.current.isDateInTomorrow(date) {
            return "Mañana"
        }

        if Calendar.current.isDateInYesterday(date) {
            return "Ayer"
        }

        return date.formatted(
            .dateTime
                .weekday(.wide)
                .day()
                .month(.wide)
                .year()
        )
    }
}

struct AdventureBookingsState {
    var nationalId: String = ""

    var allBookings: [AdventureBooking] = []

    var selectedTimelineFilter: AdventureReservationTimelineFilter = .all
    var selectedStatusFilter: AdventureReservationStatusFilter = .all
    var sortOrder: AdventureReservationSortOrder = .nearestFirst

    var now: Date = Date()

    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
}

@MainActor
final class AdventureBookingsViewModel: ObservableObject {
    @Published private(set) var state = AdventureBookingsState()

    private let observeBookingsUseCase: ObserveAdventureBookingsUseCase
    private let cancelBookingUseCase: CancelAdventureBookingUseCase

    private var listenerToken: AdventureListenerToken?

    init(
        observeBookingsUseCase: ObserveAdventureBookingsUseCase,
        cancelBookingUseCase: CancelAdventureBookingUseCase
    ) {
        self.observeBookingsUseCase = observeBookingsUseCase
        self.cancelBookingUseCase = cancelBookingUseCase
    }

    func onAppear() {
        state.now = Date()
        startListening()
    }

    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
    }

    func setNationalId(_ nationalId: String) {
        let cleanNationalId = nationalId.filter(\.isNumber)

        guard state.nationalId != cleanNationalId else {
            return
        }

        state.nationalId = cleanNationalId

        if listenerToken != nil {
            startListening()
        }
    }

    func setTimelineFilter(_ filter: AdventureReservationTimelineFilter) {
        state.now = Date()
        state.selectedTimelineFilter = filter
    }

    func setStatusFilter(_ filter: AdventureReservationStatusFilter) {
        state.selectedStatusFilter = filter
    }

    func setSortOrder(_ sortOrder: AdventureReservationSortOrder) {
        state.sortOrder = sortOrder
    }

    func dismissMessage() {
        state.errorMessage = nil
        state.successMessage = nil
    }

    func cancelBooking(_ id: String) {
        let nationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nationalId.isEmpty else {
            state.errorMessage = "No se encontró una cédula asociada a esta cuenta."
            return
        }

        Task {
            do {
                try await cancelBookingUseCase.execute(
                    id: id,
                    nationalId: nationalId
                )

                state.successMessage = "Reserva cancelada correctamente."
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    var displayedBookings: [AdventureBooking] {
        let filtered = state.allBookings.filter { booking in
            matchesTimelineFilter(booking)
            && matchesStatusFilter(booking)
        }

        return sorted(filtered)
    }

    var groupedBookings: [AdventureBookingsDateGroup] {
        let sortedBookings = displayedBookings

        var groups: [(id: String, date: Date, bookings: [AdventureBooking])] = []
        var indexByDayKey: [String: Int] = [:]

        for booking in sortedBookings {
            let day = Calendar.current.startOfDay(for: booking.startAt)
            let key = AdventureDateHelper.dayKey(from: day)

            if let index = indexByDayKey[key] {
                groups[index].bookings.append(booking)
            } else {
                indexByDayKey[key] = groups.count
                groups.append(
                    (
                        id: key,
                        date: day,
                        bookings: [booking]
                    )
                )
            }
        }

        return groups.map {
            AdventureBookingsDateGroup(
                id: $0.id,
                date: $0.date,
                bookings: $0.bookings
            )
        }
    }

    var totalCount: Int {
        state.allBookings.count
    }

    var displayedCount: Int {
        displayedBookings.count
    }

    var currentCount: Int {
        state.allBookings.filter { isCurrent($0, now: state.now) }.count
    }

    var futureCount: Int {
        state.allBookings.filter { isFuture($0, now: state.now) }.count
    }

    var pastCount: Int {
        state.allBookings.filter { isPast($0, now: state.now) }.count
    }

    private func startListening() {
        let nationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nationalId.isEmpty else {
            listenerToken?.remove()
            listenerToken = nil
            state.allBookings = []
            state.isLoading = false
            state.errorMessage = nil
            return
        }

        state.isLoading = true
        state.errorMessage = nil
        state.now = Date()

        listenerToken?.remove()

        listenerToken = observeBookingsUseCase.execute(
            nationalId: nationalId
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case let .success(bookings):
                    self.state.allBookings = bookings
                    self.state.isLoading = false
                    self.state.errorMessage = nil
                    self.state.now = Date()

                case let .failure(error):
                    self.state.allBookings = []
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
    }

    private func matchesTimelineFilter(_ booking: AdventureBooking) -> Bool {
        switch state.selectedTimelineFilter {
        case .all:
            return true

        case .current:
            return isCurrent(booking, now: state.now)

        case .future:
            return isFuture(booking, now: state.now)

        case .past:
            return isPast(booking, now: state.now)
        }
    }

    private func matchesStatusFilter(_ booking: AdventureBooking) -> Bool {
        guard let selectedStatus = state.selectedStatusFilter.bookingStatus else {
            return true
        }

        return booking.status == selectedStatus
    }

    private func sorted(_ bookings: [AdventureBooking]) -> [AdventureBooking] {
        switch state.sortOrder {
        case .nearestFirst:
            return bookings.sorted { lhs, rhs in
                let lhsRank = timelineRank(lhs, now: state.now)
                let rhsRank = timelineRank(rhs, now: state.now)

                if lhsRank != rhsRank {
                    return lhsRank < rhsRank
                }

                if lhsRank == 2 {
                    return lhs.startAt > rhs.startAt
                }

                return lhs.startAt < rhs.startAt
            }

        case .newestFirst:
            return bookings.sorted {
                if $0.startAt != $1.startAt {
                    return $0.startAt > $1.startAt
                }

                return $0.createdAt > $1.createdAt
            }

        case .oldestFirst:
            return bookings.sorted {
                if $0.startAt != $1.startAt {
                    return $0.startAt < $1.startAt
                }

                return $0.createdAt < $1.createdAt
            }
        }
    }

    private func timelineRank(_ booking: AdventureBooking, now: Date) -> Int {
        if isCurrent(booking, now: now) {
            return 0
        }

        if isFuture(booking, now: now) {
            return 1
        }

        return 2
    }

    private func isCurrent(_ booking: AdventureBooking, now: Date) -> Bool {
        booking.startAt <= now && booking.endAt >= now
    }

    private func isFuture(_ booking: AdventureBooking, now: Date) -> Bool {
        booking.startAt > now
    }

    private func isPast(_ booking: AdventureBooking, now: Date) -> Bool {
        booking.endAt < now
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/viewmodel/AdventureCatalogViewModel.swift

```swift
//
//  AdventureCatalogViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Combine
import Foundation

struct AdventureCatalogState {
    var catalog: AdventureCatalogSnapshot = .empty
    var isLoading = false
    var errorMessage: String?
}

@MainActor
final class AdventureCatalogViewModel: ObservableObject {
    @Published private(set) var state = AdventureCatalogState()

    private let fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase
    private let observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase
    private var listenerToken: AdventureListenerToken?

    init(service: AdventureCatalogServiceable) {
        self.fetchAdventureCatalogUseCase = FetchAdventureCatalogUseCase(service: service)
        self.observeAdventureCatalogUseCase = ObserveAdventureCatalogUseCase(service: service)
    }

    init(
        fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase,
        observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase
    ) {
        self.fetchAdventureCatalogUseCase = fetchAdventureCatalogUseCase
        self.observeAdventureCatalogUseCase = observeAdventureCatalogUseCase
    }

    func onAppear() {
        guard listenerToken == nil else { return }

        state.isLoading = true
        state.errorMessage = nil

        listenerToken = observeAdventureCatalogUseCase.execute { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let catalog):
                    self.state.catalog = catalog
                    self.state.isLoading = false

                case .failure(let error):
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
    }

    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
    }

    func refresh() {
        Task { await load() }
    }

    private func load() async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.catalog = try await fetchAdventureCatalogUseCase.execute()
        } catch {
            state.errorMessage = error.localizedDescription
        }

        state.isLoading = false
    }
}

```

---

# Altos del Murco/root/feature/altos/adventure/presentation/viewmodel/AdventureComboBuilderViewModel.swift

```swift
//
//  AdventureComboBuilderViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import Combine
import SwiftUI

struct AdventureComboBuilderState {
    var selectedDate: Date = Date()
    var items: [AdventureReservationItemDraft]

    var guestCount: Int = 2
    var eventType: ReservationEventType = .regularVisit
    var customEventTitle: String = ""
    var eventNotes: String = ""

    var foodItems: [ReservationFoodItemDraft] = []
    var foodServingMoment: ReservationServingMoment = .afterActivities
    var foodServingTime: Date = Date()
    var foodNotes: String = ""

    var clientName: String = ""
    var whatsappNumber: String = ""
    var nationalId: String = ""
    var notes: String = ""

    var packageDiscountAmount: Double = 0
    var catalog: AdventureCatalogSnapshot = .empty

    var availableSlots: [AdventureAvailabilitySlot] = []
    var selectedSlot: AdventureAvailabilitySlot?

    var isLoadingCatalog = false
    var isLoadingAvailability = false
    var isSubmitting = false
    var isLoadingRewards = false
    var errorMessage: String?
    var successMessage: String?

    var rewardPreview: RewardComputationResult =
        .empty(wallet: .empty(nationalId: ""))
}

@MainActor
final class AdventureComboBuilderViewModel: ObservableObject {
    @Published private(set) var state: AdventureComboBuilderState

    private let getAvailabilityUseCase: GetAdventureAvailabilityUseCase
    private let createBookingUseCase: CreateAdventureBookingUseCase
    private let fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase
    private let observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    private var hasLoadedCatalog = false
    private var catalogListenerToken: AdventureListenerToken?
    private var rewardsListenerToken: LoyaltyRewardsListenerToken?

    init(
        prefilledItems: [AdventureReservationItemDraft],
        initialPackageDiscountAmount: Double,
        getAvailabilityUseCase: GetAdventureAvailabilityUseCase,
        createBookingUseCase: CreateAdventureBookingUseCase,
        fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase,
        observeAdventureCatalogUseCase: ObserveAdventureCatalogUseCase,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.state = AdventureComboBuilderState(
            items: prefilledItems.isEmpty
                ? [AdventureActivityType.defaultDraft(for: .offRoad)]
                : prefilledItems,
            packageDiscountAmount: max(0, initialPackageDiscountAmount)
        )
        self.getAvailabilityUseCase = getAvailabilityUseCase
        self.createBookingUseCase = createBookingUseCase
        self.fetchAdventureCatalogUseCase = fetchAdventureCatalogUseCase
        self.observeAdventureCatalogUseCase = observeAdventureCatalogUseCase
        self.loyaltyRewardsService = loyaltyRewardsService

        keepCampingAtEnd()
    }

    func onAppear() {
        startCatalogObservationIfNeeded()
        startRewardsObservation()

        Task {
            await loadCatalogIfNeeded()
            await loadAvailability()
        }
    }

    func onDisappear() {
        catalogListenerToken?.remove()
        catalogListenerToken = nil

        rewardsListenerToken?.remove()
        rewardsListenerToken = nil
    }

    private func startCatalogObservationIfNeeded() {
        guard catalogListenerToken == nil else { return }

        catalogListenerToken = observeAdventureCatalogUseCase.execute { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let catalog):
                    self.applyCatalog(catalog)
                    await self.loadAvailability()

                case .failure(let error):
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoadingCatalog = false
                }
            }
        }
    }

    private func startRewardsObservation() {
        rewardsListenerToken?.remove()
        rewardsListenerToken = nil

        let cleanNationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else {
            state.rewardPreview = .empty(wallet: .empty(nationalId: ""))
            state.isLoadingRewards = false
            return
        }

        state.isLoadingRewards = true

        rewardsListenerToken = loyaltyRewardsService.observeWalletSnapshot(
            for: cleanNationalId
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let wallet):
                    await self.refreshRewardPreview()
                case .failure(let error):
                    self.state.isLoadingRewards = false
                    self.state.errorMessage = error.localizedDescription
                    self.state.rewardPreview = .empty(
                        wallet: .empty(nationalId: cleanNationalId)
                    )
                }
            }
        }
    }
    
    func prepareCustomDraftIfNeeded() {
        guard !hasMeaningfulDraft else { return }

        if state.items.isEmpty {
            state.items = [
                AdventureActivityType.defaultDraft(for: .offRoad, catalog: state.catalog)
            ]
        }

        keepCampingAtEnd()
        state.selectedSlot = nil

        Task { await refreshRewardPreview() }
        Task { await loadAvailability() }
    }

    func prepareFoodOnlyDraftIfNeeded() {
        guard !hasMeaningfulDraft else { return }
        resetForFoodOnly()
    }

    private var hasMeaningfulDraft: Bool {
        if !state.foodItems.isEmpty { return true }
        if state.selectedSlot != nil { return true }
        if state.packageDiscountAmount > 0 { return true }

        if state.guestCount != 2 { return true }
        if state.eventType != .regularVisit { return true }

        if !normalizedText(state.customEventTitle).isEmpty { return true }
        if !normalizedText(state.eventNotes).isEmpty { return true }
        if !normalizedText(state.foodNotes).isEmpty { return true }
        if !normalizedText(state.notes).isEmpty { return true }

        if !Calendar.current.isDateInToday(state.selectedDate) { return true }

        guard !state.items.isEmpty else { return false }
        guard state.items.count == 1 else { return true }

        let defaultItem = AdventureActivityType.defaultDraft(
            for: .offRoad,
            catalog: state.catalog
        )
        let currentItem = state.items[0]

        return currentItem.activity != defaultItem.activity
            || currentItem.durationMinutes != defaultItem.durationMinutes
            || currentItem.peopleCount != defaultItem.peopleCount
            || currentItem.vehicleCount != defaultItem.vehicleCount
            || currentItem.offRoadRiderCount != defaultItem.offRoadRiderCount
            || currentItem.nights != defaultItem.nights
    }

    func refreshRewardPreview() async {
        let cleanNationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else {
            state.rewardPreview = .empty(wallet: .empty(nationalId: ""))
            state.isLoadingRewards = false
            return
        }

        state.isLoadingRewards = true
        defer { state.isLoadingRewards = false }

        do {

            let result = try await loyaltyRewardsService.previewAdventureRewards(
                for: cleanNationalId,
                activityItems: state.items,
                foodItems: state.foodItems,
                catalog: state.catalog
            )

            state.rewardPreview = result
            state.errorMessage = nil

        } catch {
            state.errorMessage = error.localizedDescription
            state.rewardPreview = .empty(
                wallet: .empty(nationalId: cleanNationalId)
            )
        }
    }

    private func applyCatalog(_ catalog: AdventureCatalogSnapshot) {
        state.catalog = catalog

        state.items = state.items.map { current in
            guard let config = catalog.activity(for: current.activity) else {
                return current
            }

            return AdventureReservationItemDraft(
                id: current.id,
                activity: current.activity,
                durationMinutes: normalizeDuration(current.durationMinutes, for: config),
                peopleCount: max(current.peopleCount, config.defaults.peopleCount),
                vehicleCount: max(current.vehicleCount, config.defaults.vehicleCount),
                offRoadRiderCount: max(current.offRoadRiderCount, config.defaults.offRoadRiderCount),
                nights: max(current.nights, config.defaults.nights)
            )
        }

        keepCampingAtEnd()
        refreshPackageDiscount()
        state.isLoadingCatalog = false

        Task { await refreshRewardPreview() }
    }

    var activeActivityConfigs: [AdventureActivityCatalogItem] {
        state.catalog.activeActivitiesSorted
    }

    var availableActivitiesToAdd: [AdventureActivityType] {
        activeActivityConfigs
            .map(\.activityType)
            .filter { canAddItem($0) }
    }

    func config(for activity: AdventureActivityType) -> AdventureActivityCatalogItem? {
        state.catalog.activity(for: activity)
    }

    func canAddItem(_ activity: AdventureActivityType) -> Bool {
        !state.items.contains(where: { $0.activity == activity })
    }

    func addItem(_ activity: AdventureActivityType) {
        guard canAddItem(activity) else {
            state.errorMessage = "\(activity.legacyTitle) ya fue agregada a esta reserva."
            state.successMessage = nil
            return
        }

        state.items.append(
            AdventureActivityType.defaultDraft(for: activity, catalog: state.catalog)
        )
        refreshAfterActivitiesChanged()
    }

    func updateItem(_ item: AdventureReservationItemDraft) {
        guard let index = state.items.firstIndex(where: { $0.id == item.id }) else { return }
        state.items[index] = item
        refreshAfterActivitiesChanged()
    }

    func removeItem(at offsets: IndexSet) {
        state.items.remove(atOffsets: offsets)
        refreshAfterActivitiesChanged()
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        state.items.move(fromOffsets: source, toOffset: destination)
        refreshAfterActivitiesChanged()
    }

    func addFoodItem(
        _ menuItem: MenuItem,
        quantity: Int = 1,
        notes: String? = nil,
        for selectedDate: Date
    ) {
        let isTodayReservation = AdventureDateHelper.calendar.isDateInToday(selectedDate)

        guard !(isTodayReservation && !menuItem.canBeOrdered) else {
            state.errorMessage = "Para hoy este producto está agotado y no se puede pedir."
            state.successMessage = nil
            return
        }

        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil
        let safeQuantity = max(1, quantity)

        if let index = state.foodItems.firstIndex(where: {
            $0.menuItemId == menuItem.id && $0.notes == finalNotes
        }) {
            let current = state.foodItems[index]
            state.foodItems[index] = ReservationFoodItemDraft(
                id: current.id,
                menuItemId: current.menuItemId,
                name: current.name,
                unitPrice: current.unitPrice,
                quantity: current.quantity + safeQuantity,
                notes: current.notes
            )
        } else {
            state.foodItems.append(
                ReservationFoodItemDraft(
                    from: menuItem,
                    quantity: safeQuantity,
                    notes: finalNotes
                )
            )
        }

        refreshAfterFoodChanged()
    }

    func increaseFoodQuantity(_ id: String) {
        guard let index = state.foodItems.firstIndex(where: { $0.id == id }) else { return }

        let current = state.foodItems[index]
        state.foodItems[index] = ReservationFoodItemDraft(
            id: current.id,
            menuItemId: current.menuItemId,
            name: current.name,
            unitPrice: current.unitPrice,
            quantity: current.quantity + 1,
            notes: current.notes
        )

        refreshAfterFoodChanged()
    }

    func decreaseFoodQuantity(_ id: String) {
        guard let index = state.foodItems.firstIndex(where: { $0.id == id }) else { return }

        let nextValue = state.foodItems[index].quantity - 1
        if nextValue <= 0 {
            state.foodItems.remove(at: index)
        } else {
            let current = state.foodItems[index]
            state.foodItems[index] = ReservationFoodItemDraft(
                id: current.id,
                menuItemId: current.menuItemId,
                name: current.name,
                unitPrice: current.unitPrice,
                quantity: nextValue,
                notes: current.notes
            )
        }

        refreshAfterFoodChanged()
    }

    func removeFoodItem(_ id: String) {
        state.foodItems.removeAll { $0.id == id }
        refreshAfterFoodChanged()
    }

    func updateFoodItem(_ item: ReservationFoodItemDraft) {
        let trimmedNotes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil

        let updatedItem = ReservationFoodItemDraft(
            id: item.id,
            menuItemId: item.menuItemId,
            name: item.name,
            unitPrice: item.unitPrice,
            quantity: max(1, item.quantity),
            notes: finalNotes
        )

        if let index = state.foodItems.firstIndex(where: { $0.id == item.id }) {
            state.foodItems[index] = updatedItem
        } else {
            state.foodItems.append(updatedItem)
        }

        refreshAfterFoodChanged()
    }

    func setDate(_ date: Date) {
        state.selectedDate = date
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }

    func setGuestCount(_ value: Int) {
        state.guestCount = max(1, value)
    }

    func setEventType(_ value: ReservationEventType) {
        state.eventType = value
        if value != .custom {
            state.customEventTitle = ""
        }
    }

    func setCustomEventTitle(_ value: String) {
        state.customEventTitle = value
    }

    func setEventNotes(_ value: String) {
        state.eventNotes = value
    }

    func setFoodServingMoment(_ value: ReservationServingMoment) {
        state.foodServingMoment = value
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }

    func setFoodServingTime(_ value: Date) {
        state.foodServingTime = value
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }

    func setFoodNotes(_ value: String) {
        state.foodNotes = value
    }

    func setClientName(_ value: String) {
        state.clientName = value
    }

    func setWhatsapp(_ value: String) {
        state.whatsappNumber = value
    }

    func setNationalId(_ value: String) {
        let cleanNationalId = value.filter(\.isNumber)
        let shouldRestartObservation =
            cleanNationalId != state.nationalId || rewardsListenerToken == nil

        state.nationalId = cleanNationalId

        if shouldRestartObservation {
            startRewardsObservation()
        }
    }

    func setNotes(_ value: String) {
        state.notes = value
    }

    func selectSlot(_ slot: AdventureAvailabilitySlot) {
        state.selectedSlot = slot
    }

    func dismissMessage() {
        state.errorMessage = nil
        state.successMessage = nil
    }

    func presentError(_ message: String) {
        state.errorMessage = message
        state.successMessage = nil
    }

    var activeRewardPresentations: [RewardPresentation] {
        state.rewardPreview.appliedRewards.map(RewardPresentation.from(appliedReward:))
    }

    func catalogRewardPresentation(for activity: AdventureActivityCatalogItem) -> RewardPresentation? {
        RewardPresentationFactory.activityPresentation(
            for: activity,
            wallet: state.rewardPreview.walletSnapshot
        )
    }

    func packageRewardPresentation(
        for package: AdventureFeaturedPackage,
        menuSections: [MenuSection]
    ) -> RewardPresentation? {
        let menuItemsById = Dictionary(
            uniqueKeysWithValues: menuSections
                .flatMap(\.items)
                .map { ($0.id, $0) }
        )

        return RewardPresentationFactory.packagePresentation(
            for: package,
            catalog: state.catalog,
            menuItemsById: menuItemsById,
            wallet: state.rewardPreview.walletSnapshot
        )
    }

    func appliedRewardPresentation(for item: AdventureReservationItemDraft) -> RewardPresentation? {
        let activityId = config(for: item.activity)?.id ?? item.activity.rawValue

        guard rewardAmount(for: item) > 0 else { return nil }

        guard let reward = state.rewardPreview.appliedRewards.first(where: {
            $0.affectedActivityIds.contains(activityId)
        }) else {
            return nil
        }

        return RewardPresentation.from(appliedReward: reward)
    }

    func appliedRewardPresentation(for foodItem: ReservationFoodItemDraft) -> RewardPresentation? {
        guard rewardAmount(for: foodItem) > 0 else { return nil }

        guard let reward = state.rewardPreview.appliedRewards.first(where: {
            $0.affectedMenuItemIds.contains(foodItem.menuItemId)
        }) else {
            return nil
        }

        return RewardPresentation.from(appliedReward: reward)
    }

    func foodPickerRewardPresentation(for menuItem: MenuItem, quantity: Int = 1) -> RewardPresentation? {
        let projected = projectedRewardResult(adding: menuItem, quantity: quantity)

        let matchingRewards = projected.appliedRewards.filter {
            $0.affectedMenuItemIds.contains(menuItem.id)
        }

        guard let reward = matchingRewards.first else {
            return nil
        }

        return RewardPresentation.from(appliedReward: reward)
    }

    func foodPickerIncrementalDiscount(for menuItem: MenuItem, quantity: Int = 1) -> Double {
        let projected = projectedRewardResult(adding: menuItem, quantity: quantity)
        let value = max(
            0,
            roundMoney(projected.totalDiscount - state.rewardPreview.totalDiscount)
        )

        return value
    }

    func foodPickerDisplayedPrice(for menuItem: MenuItem, quantity: Int = 1) -> Double {
        let subtotal = roundMoney(menuItem.finalPrice * Double(max(1, quantity)))
        return max(0, subtotal - foodPickerIncrementalDiscount(for: menuItem, quantity: quantity))
    }

    func submit(clientId: String?) {
        Task { await submitReservation(clientId: clientId) }
    }

    var estimatedAdventureSubtotal: Double {
        AdventurePricingEngine.estimatedSubtotal(
            items: state.items,
            catalog: state.catalog
        )
    }

    var estimatedFoodSubtotal: Double {
        state.foodItems.reduce(0) { $0 + $1.subtotal }
    }

    var estimatedDiscountAmount: Double {
        AdventurePricingEngine.estimatedDiscountAmount(
            items: state.items,
            catalog: state.catalog
        ) + state.packageDiscountAmount
    }

    var estimatedTotal: Double {
        max(
            0,
            max(0, estimatedAdventureSubtotal - state.packageDiscountAmount)
            + estimatedFoodSubtotal
            - state.rewardPreview.totalDiscount
        )
    }

    func reset() {
        let defaultItem = AdventureActivityType.defaultDraft(
            for: .offRoad,
            catalog: state.catalog
        )

        state = makeFreshBuilderState(
            items: [defaultItem],
            packageDiscountAmount: 0
        )

        keepCampingAtEnd()
        startRewardsObservation()

        Task { await refreshRewardPreview() }
        Task { await loadAvailability() }
    }

    func resetForFoodOnly() {
        state = makeFreshBuilderState(
            items: [],
            foodItems: [],
            foodServingMoment: .afterActivities,
            packageDiscountAmount: 0
        )

        startRewardsObservation()

        Task { await refreshRewardPreview() }
        Task { await loadAvailability() }
    }

    func replaceItems(with items: [AdventureReservationItemDraft], packageDiscountAmount: Double = 0) {
        let uniqueItems = items.reduce(into: [AdventureReservationItemDraft]()) { result, item in
            guard !result.contains(where: { $0.activity == item.activity }) else { return }
            result.append(item)
        }

        state.items = uniqueItems.isEmpty ? [] : uniqueItems
        state.foodItems = []
        state.foodServingMoment = .afterActivities
        state.foodServingTime = state.selectedDate
        state.foodNotes = ""
        state.packageDiscountAmount = max(0, packageDiscountAmount)
        keepCampingAtEnd()
        refreshPackageDiscount()
        state.selectedSlot = nil
        state.errorMessage = nil
        state.successMessage = nil

        Task { await loadAvailability() }
        Task { await refreshRewardPreview() }
    }

    func replacePackage(_ package: AdventureFeaturedPackage, menuSections: [MenuSection]) {
        let uniqueItems = package.items.reduce(into: [AdventureReservationItemDraft]()) { result, item in
            guard !result.contains(where: { $0.activity == item.activity }) else { return }
            result.append(item)
        }

        state.items = uniqueItems
        state.foodItems = materializePackageFoodItems(from: package, menuSections: menuSections)
        state.foodServingMoment = state.items.isEmpty ? .onArrival : .afterActivities
        state.foodServingTime = state.selectedDate
        state.foodNotes = ""
        state.packageDiscountAmount = max(0, package.packageDiscountAmount)
        keepCampingAtEnd()
        refreshPackageDiscount()
        state.selectedSlot = nil
        state.errorMessage = nil
        state.successMessage = nil

        Task { await loadAvailability() }
        Task { await refreshRewardPreview() }
    }

    private func materializePackageFoodItems(
        from package: AdventureFeaturedPackage,
        menuSections: [MenuSection]
    ) -> [ReservationFoodItemDraft] {
        let menuItemsById = Dictionary(
            uniqueKeysWithValues: menuSections
                .flatMap(\.items)
                .map { ($0.id, $0) }
        )

        return package.foodItems.map { packageItem in
            if let menuItem = menuItemsById[packageItem.menuItemId] {
                return ReservationFoodItemDraft(
                    menuItemId: menuItem.id,
                    name: menuItem.name,
                    unitPrice: menuItem.finalPrice,
                    quantity: packageItem.quantity,
                    notes: nil
                )
            }

            return ReservationFoodItemDraft(
                menuItemId: packageItem.menuItemId,
                name: packageItem.menuItemId,
                unitPrice: 0,
                quantity: packageItem.quantity,
                notes: nil
            )
        }
    }

    private func loadCatalogIfNeeded() async {
        guard !hasLoadedCatalog else { return }
        hasLoadedCatalog = true

        state.isLoadingCatalog = true

        do {
            let catalog = try await fetchAdventureCatalogUseCase.execute()
            applyCatalog(catalog)
        } catch {
            state.errorMessage = error.localizedDescription
            state.isLoadingCatalog = false
        }
    }

    private func normalizeDuration(_ value: Int, for config: AdventureActivityCatalogItem) -> Int {
        guard !config.durationOptions.isEmpty else { return value }
        if config.durationOptions.contains(value) { return value }
        return config.defaults.durationMinutes
    }

    private func loadAvailability() async {
        state.isLoadingAvailability = true
        state.errorMessage = nil

        let foodDraft = buildFoodDraft()
        let hasFood = !(foodDraft?.isEmpty ?? true)
        let hasActivities = !state.items.isEmpty

        guard hasActivities || hasFood else {
            state.availableSlots = []
            state.selectedSlot = nil
            state.isLoadingAvailability = false
            return
        }

        do {
            let slots = try await getAvailabilityUseCase.execute(
                date: state.selectedDate,
                items: state.items,
                foodReservation: foodDraft,
                packageDiscountAmount: state.packageDiscountAmount
            )
            state.availableSlots = slots

            if let selected = state.selectedSlot {
                state.selectedSlot = slots.first(where: {
                    $0.startAt == selected.startAt && $0.endAt == selected.endAt
                })
            } else {
                state.selectedSlot = slots.first
            }
        } catch {
            state.availableSlots = []
            state.selectedSlot = nil
            state.errorMessage = error.localizedDescription
        }

        state.isLoadingAvailability = false
    }

    private struct PackageSignature: Hashable, Comparable {
        let activity: AdventureActivityType
        let durationMinutes: Int
        let peopleCount: Int
        let vehicleCount: Int
        let offRoadRiderCount: Int
        let nights: Int

        static func < (lhs: PackageSignature, rhs: PackageSignature) -> Bool {
            if lhs.activity.rawValue != rhs.activity.rawValue { return lhs.activity.rawValue < rhs.activity.rawValue }
            if lhs.durationMinutes != rhs.durationMinutes { return lhs.durationMinutes < rhs.durationMinutes }
            if lhs.peopleCount != rhs.peopleCount { return lhs.peopleCount < rhs.peopleCount }
            if lhs.vehicleCount != rhs.vehicleCount { return lhs.vehicleCount < rhs.vehicleCount }
            if lhs.offRoadRiderCount != rhs.offRoadRiderCount { return lhs.offRoadRiderCount < rhs.offRoadRiderCount }
            return lhs.nights < rhs.nights
        }
    }

    private struct PackageCandidate: Hashable {
        let matchedItemIDs: Set<String>
        let consumedFoodQuantities: [String: Int]
        let discountAmount: Double
    }

    private struct PreservedBuilderContext {
        let clientName: String
        let whatsappNumber: String
        let nationalId: String
        let catalog: AdventureCatalogSnapshot
        let rewardPreview: RewardComputationResult
    }

    private func preservedBuilderContext() -> PreservedBuilderContext {
        PreservedBuilderContext(
            clientName: state.clientName,
            whatsappNumber: state.whatsappNumber,
            nationalId: state.nationalId,
            catalog: state.catalog,
            rewardPreview: state.rewardPreview
        )
    }

    private func makeFreshBuilderState(
        items: [AdventureReservationItemDraft],
        foodItems: [ReservationFoodItemDraft] = [],
        foodServingMoment: ReservationServingMoment = .afterActivities,
        packageDiscountAmount: Double = 0
    ) -> AdventureComboBuilderState {
        let preserved = preservedBuilderContext()

        return AdventureComboBuilderState(
            selectedDate: state.selectedDate,
            items: items,
            foodItems: foodItems,
            foodServingMoment: foodServingMoment,
            foodServingTime: state.selectedDate,
            clientName: preserved.clientName,
            whatsappNumber: preserved.whatsappNumber,
            nationalId: preserved.nationalId,
            packageDiscountAmount: max(0, packageDiscountAmount),
            catalog: preserved.catalog,
            rewardPreview: preserved.rewardPreview
        )
    }

    private func signature(for item: AdventureReservationItemDraft) -> PackageSignature {
        PackageSignature(
            activity: item.activity,
            durationMinutes: item.durationMinutes,
            peopleCount: item.peopleCount,
            vehicleCount: item.vehicleCount,
            offRoadRiderCount: item.offRoadRiderCount,
            nights: item.nights
        )
    }

    private func availableFoodQuantities() -> [String: Int] {
        state.foodItems.reduce(into: [String: Int]()) { result, item in
            result[item.menuItemId, default: 0] += item.quantity
        }
    }

    private func matchingPackageCandidates() -> [PackageCandidate] {
        let availableItems = state.items.map { (id: $0.id, signature: signature(for: $0)) }
        let availableFood = availableFoodQuantities()

        return state.catalog.activePackagesSorted.compactMap { package in
            guard package.packageDiscountAmount > 0 else { return nil }
            guard package.items.count >= 2 || !package.foodItems.isEmpty else { return nil }

            var remainingItems = availableItems
            var matchedIDs: Set<String> = []

            for packageItem in package.items {
                let target = signature(for: packageItem)

                guard let index = remainingItems.firstIndex(where: { $0.signature == target }) else {
                    return nil
                }

                matchedIDs.insert(remainingItems[index].id)
                remainingItems.remove(at: index)
            }

            let requiredFood = package.foodItems.reduce(into: [String: Int]()) { result, item in
                result[item.menuItemId, default: 0] += item.quantity
            }

            for (menuItemId, requiredQuantity) in requiredFood {
                guard availableFood[menuItemId, default: 0] >= requiredQuantity else {
                    return nil
                }
            }

            return PackageCandidate(
                matchedItemIDs: matchedIDs,
                consumedFoodQuantities: requiredFood,
                discountAmount: package.packageDiscountAmount
            )
        }
    }

    private func canTake(
        _ candidate: PackageCandidate,
        usedItemIDs: Set<String>,
        usedFoodQuantities: [String: Int],
        availableFoodQuantities: [String: Int]
    ) -> Bool {
        guard usedItemIDs.isDisjoint(with: candidate.matchedItemIDs) else {
            return false
        }

        for (menuItemId, quantityToConsume) in candidate.consumedFoodQuantities {
            let alreadyUsed = usedFoodQuantities[menuItemId, default: 0]
            let available = availableFoodQuantities[menuItemId, default: 0]

            guard alreadyUsed + quantityToConsume <= available else {
                return false
            }
        }

        return true
    }

    private func applying(
        _ candidate: PackageCandidate,
        to usedFoodQuantities: [String: Int]
    ) -> [String: Int] {
        var next = usedFoodQuantities

        for (menuItemId, quantityToConsume) in candidate.consumedFoodQuantities {
            next[menuItemId, default: 0] += quantityToConsume
        }

        return next
    }

    private func bestPackageDiscountAmount() -> Double {
        let candidates = matchingPackageCandidates()
        let availableFood = availableFoodQuantities()

        guard !candidates.isEmpty else { return 0 }

        func solve(from index: Int, usedItems: Set<String>, usedFood: [String: Int]) -> Double {
            guard index < candidates.count else { return 0 }

            let skip = solve(from: index + 1, usedItems: usedItems, usedFood: usedFood)
            let candidate = candidates[index]

            guard canTake(
                candidate,
                usedItemIDs: usedItems,
                usedFoodQuantities: usedFood,
                availableFoodQuantities: availableFood
            ) else {
                return skip
            }

            let take = candidate.discountAmount + solve(
                from: index + 1,
                usedItems: usedItems.union(candidate.matchedItemIDs),
                usedFood: applying(candidate, to: usedFood)
            )

            return max(skip, take)
        }

        return solve(from: 0, usedItems: [], usedFood: [:])
    }

    private func refreshPackageDiscount() {
        state.packageDiscountAmount = bestPackageDiscountAmount()
    }

    private func refreshAfterActivitiesChanged() {
        keepCampingAtEnd()
        refreshPackageDiscount()
        state.selectedSlot = nil

        Task { await loadAvailability() }
        Task { await refreshRewardPreview() }
    }

    private func refreshAfterFoodChanged() {
        refreshPackageDiscount()
        state.selectedSlot = nil

        Task { await loadAvailability() }
        Task { await refreshRewardPreview() }
    }

    private func submitReservation(clientId: String?) async {
        guard !state.isSubmitting else { return }

        let foodDraft = buildFoodDraft()
        let hasFood = !(foodDraft?.isEmpty ?? true)

        state.errorMessage = nil
        state.successMessage = nil

        do {
            let validated = try validateReservationInput(hasFood: hasFood)

            state.isSubmitting = true
            defer { state.isSubmitting = false }

            let request = AdventureBookingRequest(
                clientId: clientId,
                clientName: validated.clientName,
                whatsappNumber: validated.whatsappNumber,
                nationalId: validated.nationalId,
                date: state.selectedDate,
                selectedStartAt: validated.selectedStartAt,
                guestCount: state.guestCount,
                eventType: state.eventType,
                customEventTitle: validated.customEventTitle,
                eventNotes: validated.eventNotes,
                items: state.items,
                foodReservation: foodDraft,
                packageDiscountAmount: state.packageDiscountAmount,
                loyaltyDiscountAmount: state.rewardPreview.totalDiscount,
                appliedRewards: state.rewardPreview.appliedRewards,
                notes: validated.notes
            )

            let booking = try await createBookingUseCase.execute(request)
            state.successMessage = "Reserva confirmada para \(booking.clientName) a las \(AdventureDateHelper.timeText(booking.startAt))."
            await loadAvailability()
        } catch {
            state.errorMessage = error.localizedDescription
        }
    }

    private struct ValidatedReservationInput {
        let clientName: String
        let whatsappNumber: String
        let nationalId: String
        let selectedStartAt: Date
        let customEventTitle: String?
        let eventNotes: String?
        let notes: String?
    }

    private struct ReservationValidationError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    private func validateReservationInput(hasFood: Bool) throws -> ValidatedReservationInput {
        let hasActivities = !state.items.isEmpty

        guard hasActivities || hasFood else {
            throw ReservationValidationError(message: "Agrega al menos una actividad o un producto de comida.")
        }

        let cleanClientName = normalizedText(state.clientName)
        guard isValidPersonName(cleanClientName) else {
            throw ReservationValidationError(message: "Ingresa un nombre válido del cliente.")
        }

        guard let normalizedWhatsApp = normalizeEcuadorWhatsApp(state.whatsappNumber) else {
            throw ReservationValidationError(message: "Ingresa un número de WhatsApp de Ecuador válido.")
        }

        guard let normalizedNationalId = normalizeEcuadorNationalId(state.nationalId) else {
            throw ReservationValidationError(message: "Ingresa una cédula ecuatoriana o un RUC personal válido.")
        }

        guard state.guestCount > 0 else {
            throw ReservationValidationError(message: "Ingresa al menos un invitado.")
        }

        let cleanCustomEventTitle = normalizedText(state.customEventTitle)
        if state.eventType == .custom {
            guard cleanCustomEventTitle.count >= 3 else {
                throw ReservationValidationError(message: "Ingresa un título válido para el evento personalizado.")
            }

            guard cleanCustomEventTitle.count <= 80 else {
                throw ReservationValidationError(message: "El título del evento personalizado es demasiado largo.")
            }
        }

        let cleanNotes = normalizedText(state.notes)
        guard cleanNotes.count <= 500 else {
            throw ReservationValidationError(message: "Las notas de la reserva son demasiado largas.")
        }

        let cleanEventNotes = normalizedText(state.eventNotes)
        guard cleanEventNotes.count <= 300 else {
            throw ReservationValidationError(message: "Las notas del evento son demasiado largas.")
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: state.selectedDate)

        guard selectedDay >= today else {
            throw ReservationValidationError(message: "No puedes crear una reserva para una fecha pasada.")
        }

        guard let slot = state.selectedSlot else {
            throw ReservationValidationError(message: "Selecciona una hora de inicio disponible.")
        }

        guard calendar.isDate(slot.startAt, inSameDayAs: state.selectedDate) else {
            throw ReservationValidationError(message: "La hora seleccionada no pertenece a la fecha elegida.")
        }

        guard slot.startAt > Date() else {
            throw ReservationValidationError(message: "La hora de inicio seleccionada ya pasó. Elige otra hora.")
        }

        return ValidatedReservationInput(
            clientName: cleanClientName,
            whatsappNumber: normalizedWhatsApp,
            nationalId: normalizedNationalId,
            selectedStartAt: slot.startAt,
            customEventTitle: state.eventType == .custom ? cleanCustomEventTitle : nil,
            eventNotes: cleanEventNotes.isEmpty ? nil : cleanEventNotes,
            notes: cleanNotes.isEmpty ? nil : cleanNotes
        )
    }

    private func normalizedText(_ value: String) -> String {
        value
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidPersonName(_ name: String) -> Bool {
        let allowedSymbols: Set<Character> = [" ", "-", "'", "."]
        let letterCount = name.unicodeScalars.filter { CharacterSet.letters.contains($0) }.count

        guard letterCount >= 3 else { return false }
        guard name.count >= 3 else { return false }

        return name.allSatisfy { character in
            if allowedSymbols.contains(character) { return true }
            return character.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
        }
    }

    private func normalizeEcuadorWhatsApp(_ rawValue: String) -> String? {
        let digits = rawValue.filter(\.isNumber)

        let normalized: String?

        switch digits.count {
        case 10:
            normalized = digits.hasPrefix("09") ? digits : nil
        case 12:
            if digits.hasPrefix("593"), digits.dropFirst(3).hasPrefix("9") {
                normalized = "0" + digits.dropFirst(3)
            } else {
                normalized = nil
            }
        default:
            normalized = nil
        }

        guard let normalized else { return nil }
        guard Set(normalized).count > 1 else { return nil }

        return normalized
    }

    private func normalizeEcuadorNationalId(_ rawValue: String) -> String? {
        let digits = rawValue.filter(\.isNumber)

        if isValidEcuadorCedula(digits) {
            return digits
        }

        if isValidEcuadorPersonalRUC(digits) {
            return digits
        }

        return nil
    }

    private func isValidEcuadorCedula(_ digits: String) -> Bool {
        guard digits.count == 10 else { return false }
        guard Set(digits).count > 1 else { return false }

        let numbers = digits.compactMap(\.wholeNumberValue)
        guard numbers.count == 10 else { return false }

        let provinceCode = numbers[0] * 10 + numbers[1]
        guard (1...24).contains(provinceCode) else { return false }

        let thirdDigit = numbers[2]
        guard (0...5).contains(thirdDigit) else { return false }

        var sum = 0

        for index in 0..<9 {
            var value = numbers[index]

            if index.isMultiple(of: 2) {
                value *= 2
                if value > 9 { value -= 9 }
            }

            sum += value
        }

        let verifier = sum % 10 == 0 ? 0 : 10 - (sum % 10)
        return verifier == numbers[9]
    }

    private func isValidEcuadorPersonalRUC(_ digits: String) -> Bool {
        guard digits.count == 13 else { return false }
        guard String(digits.suffix(3)) != "000" else { return false }

        let cedulaPart = String(digits.prefix(10))
        return isValidEcuadorCedula(cedulaPart)
    }

    private func keepCampingAtEnd() {
        let campingItems = state.items.filter { $0.activity == .camping }
        let otherItems = state.items.filter { $0.activity != .camping }
        state.items = otherItems + campingItems
    }

    private func buildFoodDraft() -> ReservationFoodDraft? {
        guard !state.foodItems.isEmpty else { return nil }

        let trimmedNotes = state.foodNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return ReservationFoodDraft(
            items: state.foodItems,
            servingMoment: state.foodServingMoment,
            servingTime: combinedServingTime(),
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
    }

    private func combinedServingTime() -> Date? {
        guard state.foodServingMoment == .specificTime else { return nil }

        let calendar = AdventureDateHelper.calendar
        let timeComponents = calendar.dateComponents([.hour, .minute], from: state.foodServingTime)

        return calendar.date(
            bySettingHour: timeComponents.hour ?? 12,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: state.selectedDate
        )
    }

    private func projectedFoodItems(
        adding menuItem: MenuItem,
        quantity: Int
    ) -> [ReservationFoodItemDraft] {
        var projected = state.foodItems
        let safeQuantity = max(1, quantity)

        projected.append(
            ReservationFoodItemDraft(
                menuItemId: menuItem.id,
                name: menuItem.name,
                unitPrice: menuItem.finalPrice,
                quantity: safeQuantity,
                notes: nil
            )
        )

        return projected
    }

    private func rewardResult(
        activityItems: [AdventureReservationItemDraft],
        foodItems: [ReservationFoodItemDraft]
    ) -> RewardComputationResult {
        let wallet = state.rewardPreview.walletSnapshot

        let activityLines = activityItems.compactMap { item -> RewardActivityLine? in
            guard let activity = state.catalog.activity(for: item.activity) else {
                return nil
            }

            return RewardActivityLine(
                activityId: activity.id,
                title: activity.title,
                linePrice: AdventurePricingEngine.subtotal(
                    for: item,
                    catalog: state.catalog
                )
            )
        }

        let foodLines = foodItems.map {
            RewardMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity
            )
        }

        let result = LoyaltyRewardEngine.evaluateAdventure(
            templates: wallet.availableTemplates,
            wallet: wallet,
            activityLines: activityLines,
            foodLines: foodLines
        )

        return result
    }

    private func projectedRewardResult(
        adding menuItem: MenuItem,
        quantity: Int
    ) -> RewardComputationResult {
        rewardResult(
            activityItems: state.items,
            foodItems: projectedFoodItems(adding: menuItem, quantity: quantity)
        )
    }

    func effectiveTotal(for slot: AdventureAvailabilitySlot) -> Double {
        max(0, slot.totalAmount - state.rewardPreview.totalDiscount)
    }

    func baseAdventureSubtotal(for item: AdventureReservationItemDraft) -> Double {
        AdventurePricingEngine.subtotal(for: item, catalog: state.catalog)
    }

    func rewardAmount(for item: AdventureReservationItemDraft) -> Double {
        let activityId = config(for: item.activity)?.id ?? item.activity.rawValue

        return roundMoney(
            state.rewardPreview.appliedRewards
                .filter { $0.affectedActivityIds.contains(activityId) }
                .reduce(0) { $0 + $1.amount }
        )
    }

    func displayedAdventureSubtotal(for item: AdventureReservationItemDraft) -> Double {
        max(0, baseAdventureSubtotal(for: item) - rewardAmount(for: item))
    }

    func rewardAmount(for foodItem: ReservationFoodItemDraft) -> Double {
        allocatedFoodDiscountByDraftId()[foodItem.id, default: 0]
    }

    func displayedFoodSubtotal(for foodItem: ReservationFoodItemDraft) -> Double {
        max(0, foodItem.subtotal - rewardAmount(for: foodItem))
    }

    private func allocatedFoodDiscountByDraftId() -> [String: Double] {
        let menuDiscounts = state.rewardPreview.appliedRewards.reduce(into: [String: Double]()) { partial, reward in
            for menuItemId in reward.affectedMenuItemIds {
                partial[menuItemId, default: 0] += reward.amount
            }
        }

        guard !menuDiscounts.isEmpty, !state.foodItems.isEmpty else {
            return [:]
        }

        let grouped = Dictionary(
            grouping: Array(state.foodItems.enumerated()),
            by: { $0.element.menuItemId }
        )

        var result: [String: Double] = [:]

        for (menuItemId, entries) in grouped {
            let totalDiscount = roundMoney(menuDiscounts[menuItemId, default: 0])
            guard totalDiscount > 0 else {
                continue
            }

            let subtotal = entries.reduce(0.0) { $0 + $1.element.subtotal }
            guard subtotal > 0 else {
                continue
            }

            var remainingDiscount = totalDiscount

            for offset in entries.indices {
                let item = entries[offset].element
                let allocation: Double

                if offset == entries.count - 1 {
                    allocation = min(item.subtotal, max(0, roundMoney(remainingDiscount)))
                } else {
                    let share = item.subtotal / subtotal
                    allocation = min(
                        item.subtotal,
                        max(0, roundMoney(totalDiscount * share))
                    )
                    remainingDiscount = roundMoney(remainingDiscount - allocation)
                }

                result[item.id] = allocation
            }
        }
        return result
    }

    private func roundMoney(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/data/AutheticationRepository.swift

```swift
//
//  FirebaseAutheticationRepository.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import FirebaseAuth

final class AuthenticationRepository: AuthenticationRepositoriable {
    func currentUser() -> AuthenticatedUser? {
        guard let user = Auth.auth().currentUser else {
            return nil
        }

        let appleProviderUID = user.providerData.first(where: { $0.providerID == "apple.com" })?.uid ?? ""

        return AuthenticatedUser(
            uid: user.uid,
            email: user.email ?? "",
            displayName: user.displayName ?? "",
            appleUserIdentifier: appleProviderUID
        )
    }

    func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: String?,
        email: String?,
        appleUserIdentifier: String
    ) async throws -> AuthenticatedUser {
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: rawNonce
        )

        let authResult: AuthDataResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "FirebaseAuthenticationRepository",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Unknown authentication error."]
                    ))
                }
            }
        }

        let firebaseUser = authResult.user
        let finalDisplayName = fullName?.trimmed.nilIfEmpty ?? firebaseUser.displayName ?? ""
        let finalEmail = email?.trimmed.nilIfEmpty ?? firebaseUser.email ?? ""
        let providerUID = firebaseUser.providerData.first(where: { $0.providerID == "apple.com" })?.uid
        let finalAppleIdentifier = providerUID?.nilIfEmpty ?? appleUserIdentifier

        return AuthenticatedUser(
            uid: firebaseUser.uid,
            email: finalEmail,
            displayName: finalDisplayName,
            appleUserIdentifier: finalAppleIdentifier
        )
    }

    func reauthenticateCurrentUser(
        idToken: String,
        rawNonce: String
    ) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(
                domain: "FirebaseAuthenticationRepository",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found."]
            )
        }

        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idToken,
            rawNonce: rawNonce
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentUser.reauthenticate(with: credential) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func deleteCurrentUser() async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(
                domain: "FirebaseAuthenticationRepository",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user to delete."]
            )
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            currentUser.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/data/ClientProfileRepository.swift

```swift
//
//  FirestoreClientProfileRepository.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import FirebaseFirestore

final class ClientProfileRepository: ClientProfileRepositoriable {
    private let collection = Firestore.firestore().collection("clients")

    func fetchProfile(uid: String) async throws -> ClientProfile? {
        try await withCheckedThrowingContinuation { continuation in
            collection.document(uid).getDocument { snapshot, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let snapshot, snapshot.exists else {
                    continuation.resume(returning: nil)
                    return
                }

                do {
                    let document = try snapshot.data(as: ClientProfileDocument.self)
                    continuation.resume(returning: document.toDomain())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveProfile(_ profile: ClientProfile) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                let document = ClientProfileDocument(profile: profile)

                try collection.document(profile.id).setData(from: document, merge: true) { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func deleteProfile(uid: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            collection.document(uid).delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/AuthenticationRepositoriable.swift

```swift
//
//  AuthenticationRepositoriable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

protocol AuthenticationRepositoriable {
    func currentUser() -> AuthenticatedUser?
    func signInWithApple(
        idToken: String,
        rawNonce: String,
        fullName: String?,
        email: String?,
        appleUserIdentifier: String
    ) async throws -> AuthenticatedUser

    func reauthenticateCurrentUser(
        idToken: String,
        rawNonce: String
    ) async throws

    func deleteCurrentUser() async throws
    func signOut() throws
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/AutheticatedUser.swift

```swift
//
//  AutheticatedUser.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct AuthenticatedUser: Equatable {
    let uid: String
    let email: String
    let displayName: String
    let appleUserIdentifier: String
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/ClientProfile.swift

```swift
//
//  ClientProfile.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct ClientProfile: Identifiable, Codable, Equatable {
    let id: String
    let email: String
    let appleUserIdentifier: String
    let fullName: String
    let nationalId: String
    let phoneNumber: String
    let birthday: Date
    let address: String
    let emergencyContactName: String
    let emergencyContactPhone: String
    let isProfileComplete: Bool
    let createdAt: Date
    let updatedAt: Date
    let profileCompletedAt: Date?
    let profileImageURL: String?
    let profileImagePath: String?

    var isComplete: Bool {
        isProfileComplete &&
        !fullName.trimmed.isEmpty &&
        !nationalId.trimmed.isEmpty &&
        !phoneNumber.trimmed.isEmpty &&
        !address.trimmed.isEmpty &&
        !emergencyContactName.trimmed.isEmpty &&
        !emergencyContactPhone.trimmed.isEmpty
    }

    var hasProfileImage: Bool {
        let url = profileImageURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !url.isEmpty
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/ClientProfileRepositoriable.swift

```swift
//
//  ClientProfileRepositoriable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

protocol ClientProfileRepositoriable {
    func fetchProfile(uid: String) async throws -> ClientProfile?
    func saveProfile(_ profile: ClientProfile) async throws
    func deleteProfile(uid: String) async throws
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/CompleteClientProfileUseCase.swift

```swift
//
//  CompleteClientProfileUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class CompleteClientProfileUseCase {
    private let repository: ClientProfileRepositoriable

    init(repository: ClientProfileRepositoriable) {
        self.repository = repository
    }

    func execute(profile: ClientProfile) async throws {
        try await repository.saveProfile(profile)
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/DeleteCurrentUserUseCase.swift

```swift
//
//  DeleteCurrentUserUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class DeleteCurrentAccountUseCase {
    private let authRepository: AuthenticationRepositoriable
    private let clientProfileRepository: ClientProfileRepositoriable

    init(
        authRepository: AuthenticationRepositoriable,
        clientProfileRepository: ClientProfileRepositoriable
    ) {
        self.authRepository = authRepository
        self.clientProfileRepository = clientProfileRepository
    }

    func execute(
        currentUserId: String,
        idToken: String,
        rawNonce: String
    ) async throws {
        try await authRepository.reauthenticateCurrentUser(
            idToken: idToken,
            rawNonce: rawNonce
        )

        try await clientProfileRepository.deleteProfile(uid: currentUserId)
        try await authRepository.deleteCurrentUser()
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/ResolveSessionUseCase.swift

```swift
//
//  ResolveSessionUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

enum SessionDestination {
    case signedOut
    case needsProfile(AuthenticatedUser, ClientProfile?)
    case authenticated(ClientProfile)
}

final class ResolveSessionUseCase {
    private let authRepository: AuthenticationRepositoriable
    private let clientProfileRepository: ClientProfileRepositoriable

    init(
        authRepository: AuthenticationRepositoriable,
        clientProfileRepository: ClientProfileRepositoriable
    ) {
        self.authRepository = authRepository
        self.clientProfileRepository = clientProfileRepository
    }

    func execute() async throws -> SessionDestination {
        guard let user = authRepository.currentUser() else {
            return .signedOut
        }

        return try await execute(for: user)
    }

    func execute(for user: AuthenticatedUser) async throws -> SessionDestination {
        let profile = try await clientProfileRepository.fetchProfile(uid: user.uid)

        guard let profile else {
            return .needsProfile(user, nil)
        }

        if profile.isComplete {
            return .authenticated(profile)
        } else {
            return .needsProfile(user, profile)
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/SignInWithAppleUseCase.swift

```swift
//
//  SignInWithAppleUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class SignInWithAppleUseCase {
    private let repository: AuthenticationRepositoriable

    init(repository: AuthenticationRepositoriable) {
        self.repository = repository
    }

    func execute(
        idToken: String,
        rawNonce: String,
        fullName: String?,
        email: String?,
        appleUserIdentifier: String
    ) async throws -> AuthenticatedUser {
        try await repository.signInWithApple(
            idToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName,
            email: email,
            appleUserIdentifier: appleUserIdentifier
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/SignOutUseCase.swift

```swift
//
//  SignOutUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

final class SignOutUseCase {
    private let repository: AuthenticationRepositoriable

    init(repository: AuthenticationRepositoriable) {
        self.repository = repository
    }

    func execute() throws {
        try repository.signOut()
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/presentation/view/AuthenticationView.swift

```swift
//
//  uthenticationView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @ObservedObject var viewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        ZStack {
            BrandScreenBackground(theme: .neutral)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    Spacer(minLength: 24)

                    headerSection
                    featureCard
                    signInCard

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .tint(palette.primary)
    }
    
    private var headerSection: some View {
        VStack(spacing: 18) {
//            Image("logo")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 110, height: 110)

            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 96, height: 96)
                
                Circle()
                    .stroke(palette.stroke, lineWidth: 1)
                    .frame(width: 96, height: 96)
                
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(palette.primary)
            }
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                radius: 16,
                x: 0,
                y: 8
            )
            
            VStack(spacing: 8) {
                Text("Altos del Murco")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)

                Text("Restaurante, aventura y recompensas en una sola cuenta.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            
            HStack(spacing: 10) {
                BrandBadge(theme: .restaurant, title: "Restaurante")
                BrandBadge(theme: .adventure, title: "Aventura")
                BrandBadge(theme: .neutral, title: "Recompensas")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Todo en un solo lugar",
                subtitle: "Tu cuenta conecta pedidos, reservas, recompensas y ofertas personalizadas."
            )
            
            VStack(spacing: 14) {
                FeatureRow(
                    theme: .restaurant,
                    icon: "fork.knife",
                    text: "Pedidos del restaurante y fidelización"
                )

                FeatureRow(
                    theme: .neutral,
                    icon: "birthday.cake.fill",
                    text: "Descuentos de cumpleaños y promociones especiales"
                )

                FeatureRow(
                    theme: .adventure,
                    icon: "figure.outdoor.cycle",
                    text: "Reservas de aventura en un solo lugar"
                )

                FeatureRow(
                    theme: .neutral,
                    icon: "lock.shield.fill",
                    text: "Inicio de sesión con Apple seguro y privado"
                )
            }
        }
        .appCardStyle(.neutral, emphasized: true)
    }
    
    private var signInCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Inicia sesión para continuar")
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("Tu perfil nos ayuda a personalizar tus reservas, descuentos y datos de contacto.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.textSecondary)
            }
            
            SignInWithAppleButton(
                onRequest: viewModel.onRequestSignIn,
                onCompletion: viewModel.onCompletionSignIn
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                radius: 14,
                x: 0,
                y: 8
            )
            
            Text("Al continuar, tu cuenta se vinculará con tu inicio de sesión de Apple.")
                .font(.footnote)
                .foregroundStyle(palette.textTertiary)
                .multilineTextAlignment(.center)
        }
        .appCardStyle(.neutral)
        .padding(.top, 4)
    }
}

private struct FeatureRow: View {
    let theme: AppSectionTheme
    let icon: String
    let text: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: theme, systemImage: icon, size: 42)

            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(palette.textPrimary)

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/presentation/view/CompleteProfileView.swift

```swift
//
//  CompleteProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct CompleteProfileView: View {
    @StateObject private var viewModel: CompleteProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let theme: AppSectionTheme = .neutral
    
    init(viewModelFactory: @escaping () -> CompleteProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                header
                personalInfoSection
                addressSection
                emergencySection

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(palette.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appCardStyle(theme)
                }

                Text("This step is required before entering the app.")
                    .font(.footnote)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(theme)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            BrandIconBubble(
                theme: theme,
                systemImage: "person.crop.circle.badge.checkmark",
                size: 62
            )

            Text("Complete your profile")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(palette.textPrimary)

            Text("We need a few details before you can continue to Altos del Murco.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.textSecondary)
                .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme, emphasized: true)
    }

    private var personalInfoSection: some View {
        VStack(spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Personal information",
                subtitle: "Basic identity and contact details."
            )

            ProfileInputField(
                theme: theme,
                title: "Full name",
                placeholder: "Enter your full name",
                text: $viewModel.fullName,
                keyboardType: .default,
                autocapitalization: .words
            )

            ProfileInputField(
                theme: theme,
                title: "National unique number",
                placeholder: "Example: 0501234567",
                text: $viewModel.nationalId,
                keyboardType: .numberPad,
                autocapitalization: .never
            )

            ProfileInputField(
                theme: theme,
                title: "Phone number",
                placeholder: "Example: 0987654321",
                text: $viewModel.phoneNumber,
                keyboardType: .phonePad,
                autocapitalization: .never
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Birthday")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)

                DatePicker(
                    "",
                    selection: $viewModel.birthday,
                    in: viewModel.validBirthdayRange,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(palette.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(minHeight: AppTheme.Metrics.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            }
        }
        .appCardStyle(theme)
    }

    private var addressSection: some View {
        VStack(spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Address",
                subtitle: "Where you live or where we can identify your location."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Address")
                    .font(.subheadline.bold())
                    .foregroundStyle(palette.textPrimary)

                TextField("Street, reference, sector...", text: $viewModel.address, axis: .vertical)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(palette.textPrimary)
                    .tint(palette.primary)
                    .padding(16)
                    .frame(minHeight: 110, alignment: .topLeading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
            }
        }
        .appCardStyle(theme)
    }

    private var emergencySection: some View {
        VStack(spacing: 14) {
            BrandSectionHeader(
                theme: theme,
                title: "Emergency contact",
                subtitle: "Someone we can reach if needed."
            )

            ProfileInputField(
                theme: theme,
                title: "Emergency contact name",
                placeholder: "Who should we contact if needed?",
                text: $viewModel.emergencyContactName,
                keyboardType: .default,
                autocapitalization: .words
            )

            ProfileInputField(
                theme: theme,
                title: "Emergency contact phone",
                placeholder: "Example: 0999999999",
                text: $viewModel.emergencyContactPhone,
                keyboardType: .phonePad,
                autocapitalization: .never
            )
        }
        .appCardStyle(theme)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Button(action: viewModel.saveProfile) {
                HStack(spacing: 10) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(palette.onPrimary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.headline)
                    }

                    Text(viewModel.isSaving ? "Saving profile..." : "Save and continue")
                        .font(.headline)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            .disabled(!viewModel.canSubmit || viewModel.isSaving)
            .padding(.horizontal, 16)
            .padding(.top, 10)

            Text("You cannot skip this step.")
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
                .padding(.bottom, 6)
        }
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
}

private struct ProfileInputField: View {
    let theme: AppSectionTheme
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    var autocapitalization: TextInputAutocapitalization = .words
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(palette.textPrimary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .appTextFieldStyle(theme)
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/presentation/viewmodel/AppNonce.swift

```swift
//
//  AppNonce.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import CryptoKit
import SwiftUI

enum AppleNonce {
    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                guard remainingLength > 0 else { return }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var digitsOnly: String {
        filter(\.isNumber)
    }

//    var nilIfEmpty: String? {
//        trimmed.isEmpty ? nil : trimmed
//    }

    var initials: String {
        let parts = trimmed
            .split(separator: " ")
            .prefix(2)

        let result = parts.compactMap { $0.first }.map(String.init).joined()
        return result.isEmpty ? "GU" : result.uppercased()
    }
}

struct PrimaryFilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(hex: "#B86A2A"))
                    .opacity(configuration.isPressed ? 0.82 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}

struct SecondaryOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.28), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white.opacity(configuration.isPressed ? 0.08 : 0.04))
                    )
            )
    }
}


extension Bundle {
    var appVersionDescription: String {
        let version = object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/presentation/viewmodel/AppSessionViewModel.swift

```swift
//
//  AppSessionViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import AuthenticationServices

@MainActor
final class AppSessionViewModel: ObservableObject {
    @Published private(set) var state: AppSessionState = .loading
    @Published private(set) var rewardWalletSnapshot: RewardWalletSnapshot = .empty(nationalId: "")

    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let resolveSessionUseCase: ResolveSessionUseCase
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let signOutUseCase: SignOutUseCase
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    private var currentNonce: String?

    init(
        signInWithAppleUseCase: SignInWithAppleUseCase,
        resolveSessionUseCase: ResolveSessionUseCase,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        signOutUseCase: SignOutUseCase,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.resolveSessionUseCase = resolveSessionUseCase
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.signOutUseCase = signOutUseCase
        self.loyaltyRewardsService = loyaltyRewardsService

        Task { await bootstrap() }
    }

    var screenKey: String {
        switch state {
        case .loading:
            return "loading"
        case .signedOut:
            return "signedOut"
        case .needsProfile:
            return "needsProfile"
        case .authenticated:
            return "authenticated"
        case .error:
            return "error"
        }
    }

    var authenticatedProfile: ClientProfile? {
        guard case .authenticated(let profile) = state else { return nil }
        return profile
    }

    func bootstrap() async {
        state = .loading

        do {
            let destination = try await resolveSessionUseCase.execute()
            state = map(destination)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func onRequestSignIn(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]

        let nonce = AppleNonce.randomNonceString()
        currentNonce = nonce
        request.nonce = AppleNonce.sha256(nonce)
    }

    func onCompletionSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                await handleAuthorization(authorization)
            }

        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            state = .error(error.localizedDescription)
        }
    }

    func signOut() {
        Task {
            do {
                try signOutUseCase.execute()
                state = .signedOut
            } catch {
                state = .error(error.localizedDescription)
            }
        }
    }

    func makeCompleteProfileViewModel(
        user: AuthenticatedUser,
        existingProfile: ClientProfile?
    ) -> CompleteProfileViewModel {
        CompleteProfileViewModel(
            authenticatedUser: user,
            existingProfile: existingProfile,
            completeClientProfileUseCase: completeClientProfileUseCase,
            onCompleted: { [weak self] profile in
                self?.state = .authenticated(profile)
            }
        )
    }

    func makeProfileViewModelFactory(appPreferences: AppPreferences) -> (() -> ProfileViewModel)? {
        guard let profile = authenticatedProfile else { return nil }

        let saveUseCase = completeClientProfileUseCase
        let deleteUseCase = deleteCurrentAccountUseCase
        let imageStorageService = ProfileImageStorageService()
        let statsService = ProfileStatsService(loyaltyRewardsService: loyaltyRewardsService)

        return { [weak self] in
            ProfileViewModel(
                initialProfile: profile,
                appPreferences: appPreferences,
                completeClientProfileUseCase: saveUseCase,
                deleteCurrentAccountUseCase: deleteUseCase,
                profileImageStorageService: imageStorageService,
                profileStatsService: statsService,
                onProfileUpdated: { [weak self] updatedProfile in
                    self?.state = .authenticated(updatedProfile)
                },
                onSignOut: { [weak self] in
                    self?.signOut()
                },
                onAccountDeleted: { [weak self] in
                    self?.state = .signedOut
                }
            )
        }
    }

    private func handleAuthorization(_ authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            state = .error("Could not read the Apple credential.")
            return
        }

        guard let nonce = currentNonce else {
            state = .error("Invalid sign in state. Please try again.")
            return
        }

        guard let identityToken = credential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            state = .error("Unable to read the Apple identity token.")
            return
        }

        let formatter = PersonNameComponentsFormatter()
        let formattedName = credential.fullName
            .map { formatter.string(from: $0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let finalName = (formattedName?.isEmpty == false) ? formattedName : nil

        state = .loading

        do {
            let user = try await signInWithAppleUseCase.execute(
                idToken: idToken,
                rawNonce: nonce,
                fullName: finalName,
                email: credential.email,
                appleUserIdentifier: credential.user
            )

            let destination = try await resolveSessionUseCase.execute(for: user)
            state = map(destination)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func map(_ destination: SessionDestination) -> AppSessionState {
        switch destination {
        case .signedOut:
            return .signedOut
        case .needsProfile(let user, let existingProfile):
            return .needsProfile(user, existingProfile)
        case .authenticated(let profile):
            return .authenticated(profile)
        }
    }
}

enum AppSessionState {
    case loading
    case signedOut
    case needsProfile(AuthenticatedUser, ClientProfile?)
    case authenticated(ClientProfile)
    case error(String)
}

```

---

# Altos del Murco/root/feature/altos/home/data/FeaturedFeedRepository.swift

```swift
//
//  FeaturedFeedRepository.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

final class FeaturedFeedRepository: FeaturedFeedRepositoriable {
    private let db: Firestore
    private let collectionName = "featured_posts"

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func observeLatest(
        limit: Int,
        onChange: @escaping (Result<FeaturedFeedPage, Error>) -> Void
    ) -> ListenerRegistration {
        baseActiveQuery()
            .limit(to: limit)
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let snapshot else {
                    onChange(.success(FeaturedFeedPage(posts: [], lastSnapshot: nil, hasMore: false)))
                    return
                }

                do {
                    let posts = try snapshot.documents.compactMap { document in
                        try document.data(as: FeaturedPostDto.self).toDomain()
                    }

                    let page = FeaturedFeedPage(
                        posts: posts,
                        lastSnapshot: snapshot.documents.last,
                        hasMore: snapshot.documents.count == limit
                    )
                    onChange(.success(page))
                } catch {
                    onChange(.failure(error))
                }
            }
    }

    func fetchNextPage(limit: Int, after lastSnapshot: DocumentSnapshot?) async throws -> FeaturedFeedPage {
        var query: Query = baseActiveQuery().limit(to: limit)

        if let lastSnapshot {
            query = query.start(afterDocument: lastSnapshot)
        }

        let snapshot = try await query.getDocuments()
        let posts = try snapshot.documents.compactMap { document in
            try document.data(as: FeaturedPostDto.self).toDomain()
        }

        return FeaturedFeedPage(
            posts: posts,
            lastSnapshot: snapshot.documents.last ?? lastSnapshot,
            hasMore: snapshot.documents.count == limit
        )
    }

    private func baseActiveQuery() -> Query {
        db.collection(collectionName)
            .whereField("isVisible", isEqualTo: true)
            .whereField("expiresAt", isGreaterThan: Date())
            .order(by: "expiresAt", descending: true)
    }
}

```

---

# Altos del Murco/root/feature/altos/home/data/FeaturedPostModels.swift

```swift
//
//  FeaturedPostModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

enum FeaturedPostCategory: String, Codable, CaseIterable, Identifiable {
    case restaurant
    case adventure
    case clients

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .adventure: return "Aventura"
        case .clients: return "Clientes"
        }
    }
}

struct FeaturedPostMediaDto: Codable, Hashable, Identifiable {
    let id: String
    let downloadURL: String
    let storagePath: String
    let width: CGFloat
    let height: CGFloat
    let position: Int
}

struct FeaturedPostDto: Codable {
    @DocumentID var id: String?
    let category: String
    let description: String?
    let media: [FeaturedPostMediaDto]
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    let isVisible: Bool
}

struct FeaturedPostMedia: Identifiable, Hashable {
    let id: String
    let downloadURL: URL?
    let storagePath: String
    let width: CGFloat
    let height: CGFloat
    let position: Int

    var aspectRatio: CGFloat {
        guard height > 0 else { return 1 }
        return width / height
    }
}

struct FeaturedPost: Identifiable, Hashable {
    let id: String
    let category: FeaturedPostCategory
    let description: String?
    let media: [FeaturedPostMedia]
    let createdAt: Date
    let updatedAt: Date
    let expiresAt: Date
    let isVisible: Bool

    var isExpired: Bool {
        expiresAt <= Date()
    }

    var orderedMedia: [FeaturedPostMedia] {
        media.sorted { $0.position < $1.position }
    }
}

extension FeaturedPostDto {
    func toDomain() -> FeaturedPost? {
        guard let id else { return nil }
        guard let category = FeaturedPostCategory(rawValue: category) else { return nil }

        return FeaturedPost(
            id: id,
            category: category,
            description: description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            media: media
                .sorted(by: { $0.position < $1.position })
                .map {
                    FeaturedPostMedia(
                        id: $0.id,
                        downloadURL: URL(string: $0.downloadURL),
                        storagePath: $0.storagePath,
                        width: $0.width,
                        height: $0.height,
                        position: $0.position
                    )
                },
            createdAt: createdAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt,
            isVisible: isVisible
        )
    }
}

extension FeaturedPost {
    func toDto() -> FeaturedPostDto {
        FeaturedPostDto(
            id: id,
            category: category.rawValue,
            description: description,
            media: orderedMedia.map {
                FeaturedPostMediaDto(
                    id: $0.id,
                    downloadURL: $0.downloadURL?.absoluteString ?? "",
                    storagePath: $0.storagePath,
                    width: $0.width,
                    height: $0.height,
                    position: $0.position
                )
            },
            createdAt: createdAt,
            updatedAt: updatedAt,
            expiresAt: expiresAt,
            isVisible: isVisible
        )
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

```

---

# Altos del Murco/root/feature/altos/home/domain/FeaturedFeedRepositoriable.swift

```swift
//
//  FeaturedFeedRepositoriable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

struct FeaturedFeedPage {
    let posts: [FeaturedPost]
    let lastSnapshot: DocumentSnapshot?
    let hasMore: Bool
}

protocol FeaturedFeedRepositoriable {
    func observeLatest(limit: Int, onChange: @escaping (Result<FeaturedFeedPage, Error>) -> Void) -> ListenerRegistration
    func fetchNextPage(limit: Int, after lastSnapshot: DocumentSnapshot?) async throws -> FeaturedFeedPage
}

```

---

# Altos del Murco/root/feature/altos/home/domain/FetchFeaturedPostsPageUseCase.swift

```swift
//
//  FetchFeaturedPostsPageUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

struct FetchFeaturedPostsPageUseCase {
    private let repository: FeaturedFeedRepositoriable

    init(repository: FeaturedFeedRepositoriable) {
        self.repository = repository
    }

    func execute(limit: Int, after lastSnapshot: DocumentSnapshot?) async throws -> FeaturedFeedPage {
        try await repository.fetchNextPage(limit: limit, after: lastSnapshot)
    }
}

```

---

# Altos del Murco/root/feature/altos/home/domain/ObserveLatestFeaturedPostsUseCase.swift

```swift
//
//  ObserveLatestFeaturedPostsUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation
import FirebaseFirestore

struct ObserveLatestFeaturedPostsUseCase {
    private let repository: FeaturedFeedRepositoriable

    init(repository: FeaturedFeedRepositoriable) {
        self.repository = repository
    }

    func execute(
        limit: Int,
        onChange: @escaping (Result<FeaturedFeedPage, Error>) -> Void
    ) -> ListenerRegistration {
        repository.observeLatest(limit: limit, onChange: onChange)
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/FeaturedMediaCollageView.swift

```swift
//
//  FeaturedMediaCollageView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedMediaCollageView: View {
    let media: [FeaturedPostMedia]
    let onTap: (Int) -> Void

    var body: some View {
        Group {
            switch media.count {
            case 0:
                EmptyView()

            case 1:
                itemView(media[0], index: 0)
                    .frame(height: 300)

            case 2:
                HStack(spacing: 8) {
                    itemView(media[0], index: 0)
                    itemView(media[1], index: 1)
                }
                .frame(height: 250)

            case 3:
                HStack(spacing: 8) {
                    itemView(media[0], index: 0)

                    VStack(spacing: 8) {
                        itemView(media[1], index: 1)
                        itemView(media[2], index: 2)
                    }
                }
                .frame(height: 280)

            default:
                let displayed = Array(media.prefix(4))
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ],
                    spacing: 8
                ) {
                    ForEach(Array(displayed.enumerated()), id: \.element.id) { index, item in
                        ZStack {
                            itemView(item, index: index)

                            if index == 3 && media.count > 4 {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.black.opacity(0.38))

                                Text("+\(media.count - 4)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(height: 150)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func itemView(_ item: FeaturedPostMedia, index: Int) -> some View {
        Button {
            onTap(index)
        } label: {
            GeometryReader { proxy in
                RemoteImageView(
                    url: item.downloadURL,
                    contentMode: .fill,
                    targetPixelSize: CGSize(width: 420, height: 420)
                ) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.secondary.opacity(0.12))
                        .overlay(ProgressView())
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/FeaturedMediaViewer.swift

```swift
//
//  FeaturedMediaViewer.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedMediaViewer: View {
    let media: [FeaturedPostMedia]
    let selectedIndex: Int

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int
    @State private var verticalDismissOffset: CGFloat = 0

    private var backgroundOpacity: Double {
        let progress = min(abs(verticalDismissOffset) / 260, 1)
        return 1 - (progress * 0.5)
    }


    init(media: [FeaturedPostMedia], selectedIndex: Int) {
        self.media = media
        self.selectedIndex = selectedIndex
        _currentIndex = State(initialValue: selectedIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    ZoomableRemoteImageView(url: item.downloadURL) { _ in }
                    .tag(index)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: 12) {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.45), in: Circle())
                    }
                }

                HStack {
                    Spacer()

                    Text("\(currentIndex + 1) / \(media.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.45), in: Capsule())
                }
            }
            .padding()
        }
        .statusBarHidden()
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/FeaturedPostCardView.swift

```swift
//
//  FeaturedPostCardView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedPostCardView: View {
    let post: FeaturedPost

    @State private var selectedMediaIndex = 0
    @State private var isViewerPresented = false

    private var theme: AppSectionTheme {
        switch post.category {
        case .restaurant: return .restaurant
        case .adventure: return .adventure
        case .clients: return .neutral
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                BrandIconBubble(
                    theme: theme,
                    systemImage: iconName(for: post.category),
                    size: 42
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.category.title)
                        .font(.headline)

                    Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                BrandBadge(theme: theme, title: "Nuevo", selected: true)
            }

            FeaturedMediaCollageView(
                media: post.orderedMedia,
                onTap: { index in
                    selectedMediaIndex = index
                    isViewerPresented = true
                }
            )

            if let description = post.description, !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
        }
        .appCardStyle(theme, emphasized: false)
        .fullScreenCover(isPresented: $isViewerPresented) {
            FeaturedMediaViewer(
                media: post.orderedMedia,
                selectedIndex: selectedMediaIndex
            )
        }
    }

    private func iconName(for category: FeaturedPostCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .adventure: return "figure.hiking"
        case .clients: return "person.3.fill"
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/FeaturedPostFullScreenViewer.swift

```swift
//
//  FeaturedPostFullScreenViewer.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

import SwiftUI

struct FeaturedPostFullScreenViewer: View {
    let media: [FeaturedPostMedia]
    
    @State var selectedIndex: Int
    @State private var currentScale: CGFloat = 1

    @Environment(\.dismiss) private var dismiss

    @State private var verticalDismissOffset: CGFloat = 0

    private var backgroundOpacity: Double {
        let progress = min(abs(verticalDismissOffset) / 260, 1)
        return 1 - (progress * 0.5)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .opacity(backgroundOpacity)
                .ignoresSafeArea()

            TabView(selection: $selectedIndex) {
                ForEach(Array(media.enumerated()), id: \.element.id) { index, item in
                    ZoomableRemoteImageView(
                        url: item.downloadURL,
                        onScaleChanged: { scale in
                            if selectedIndex == index {
                                currentScale = scale
                            }
                        }
                    )
                    .tag(index)
                    .ignoresSafeArea()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .offset(y: verticalDismissOffset)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16)
        }
        .simultaneousGesture(
            dismissDragGesture,
            including: .subviews
        )
        .onChange(of: selectedIndex) { _, _ in
            currentScale = 1
            verticalDismissOffset = 0
        }
        .statusBarHidden()
    }

    private var dismissDragGesture: some Gesture {
        DragGesture(minimumDistance: 22, coordinateSpace: .local)
            .onChanged { value in
                guard currentScale <= 1.01 else { return }

                let vertical = value.translation.height
                let horizontal = value.translation.width

                let isMostlyVertical = abs(vertical) > abs(horizontal) * 1.35
                guard isMostlyVertical else { return }

                verticalDismissOffset = vertical
            }
            .onEnded { value in
                guard currentScale <= 1.01 else { return }

                let vertical = value.translation.height
                let predicted = value.predictedEndTranslation.height
                let horizontal = value.translation.width

                let isMostlyVertical = abs(vertical) > abs(horizontal) * 1.35

                guard isMostlyVertical else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        verticalDismissOffset = 0
                    }
                    return
                }

                let shouldDismiss =
                    abs(vertical) > 140 ||
                    abs(predicted) > 240

                if shouldDismiss {
                    dismiss()
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        verticalDismissOffset = 0
                    }
                }
            }
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/FeaturedPostsSectionView.swift

```swift
//
//  FeaturedPostsSectionView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct FeaturedPostsSectionView: View {
    @StateObject private var viewModel = FeaturedFeedModule.makeViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Destacados",
                subtitle: "Fotos recientes del restaurante, aventura y momentos de nuestros clientes."
            )

            content
        }
        .task {
            viewModel.start()
        }
        .alert("No se pudo cargar destacados", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Aceptar") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingInitial && viewModel.posts.isEmpty {
            VStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(height: 320)
                        .redacted(reason: .placeholder)
                }
            }
        } else if viewModel.posts.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 34))
                    .foregroundStyle(.secondary)

                Text("Aún no hay publicaciones activas.")
                    .font(.headline)

                Text("Cuando ADM publique nuevas fotos aparecerán aquí automáticamente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .appCardStyle(.neutral)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.posts) { post in
                    FeaturedPostCardView(post: post)
                        .onAppear {
                            viewModel.loadMoreIfNeeded(currentPost: post)
                        }
                }

                if viewModel.isLoadingMore {
                    ProgressView("Cargando más")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/HomeView.swift

```swift
//
//  HomeView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection
//                    quickAccessSection
                    featuredSection
                }
                .padding()
            }
            .navigationTitle("Altos del Murco")
            .navigationBarTitleDisplayMode(.large)
            .appScreenStyle(.neutral)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Bienvenido")
                .font(.title2.bold())

            Text("Restaurante y aventura en un solo lugar. Explora experiencias, revisa tus reservas y accede rápido a cada sección.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .appCardStyle(.neutral, emphasized: false)
    }

    /*
    private var quickAccessSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Acceso rápido",
                subtitle: "Tus secciones principales, con identidad visual propia."
            )

            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Restaurante",
                    systemImage: "fork.knife",
                    theme: .restaurant,
                    action: { selectedTab = .restaurant }
                )

                quickAccessCard(
                    title: "Experiencias",
                    systemImage: "figure",
                    theme: .adventure,
                    action: { selectedTab = .experiences }
                )
            }

            HStack(spacing: 12) {
                quickAccessCard(
                    title: "Reservas",
                    systemImage: "calendar",
                    theme: .adventure,
                    action: { selectedTab = .bookings }
                )

                quickAccessCard(
                    title: "Perfil",
                    systemImage: "person.crop.circle",
                    theme: .neutral,
                    action: { selectedTab = .profile }
                )
            }
        }
    }
     */

    private func quickAccessCard(
        title: String,
        systemImage: String,
        theme: AppSectionTheme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                BrandIconBubble(theme: theme, systemImage: systemImage, size: 50)

                Spacer(minLength: 0)

                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Text("Abrir")
                        .font(.caption.weight(.semibold))

                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 138, alignment: .topLeading)
            .appCardStyle(theme)
        }
        .buttonStyle(.plain)
    }

    private var featuredSection: some View {
        FeaturedPostsSectionView()
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/RemoreImageView.swift

```swift
//
//  RemoreImageView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct RemoteImageView<Placeholder: View>: View {
    let url: URL?
    let contentMode: ContentMode
    let targetPixelSize: CGSize?
    let placeholder: () -> Placeholder

    @StateObject private var loader = RemoteImageLoader()

    init(
        url: URL?,
        contentMode: ContentMode = .fill,
        targetPixelSize: CGSize? = nil,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.contentMode = contentMode
        self.targetPixelSize = targetPixelSize
        self.placeholder = placeholder
    }

    var body: some View {
        ZStack {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                placeholder()
                    .allowsHitTesting(false)
            }
        }
        .onAppear {
            loader.load(from: url, targetPixelSize: targetPixelSize)
        }
        .onChange(of: url) { _, newURL in
            loader.load(from: newURL, targetPixelSize: targetPixelSize)
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/view/ZoomableRemoteImageView.swift

```swift
//
//  ZoomableRemoteImageView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import SwiftUI

struct ZoomableRemoteImageView: View {
    let url: URL?
    let onScaleChanged: (CGFloat) -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1

    @State private var imageOffset: CGSize = .zero
    @State private var lastImageOffset: CGSize = .zero

    private var isZoomed: Bool {
        scale > 1.01
    }

    var body: some View {
        GeometryReader { proxy in
            RemoteImageView(
                url: url,
                contentMode: .fit,
                targetPixelSize: CGSize(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
            ) {
                ZStack {
                    Color.black
                    ProgressView()
                        .tint(.white)
                }
            }
            .scaleEffect(scale)
            .offset(imageOffset)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .contentShape(Rectangle())
            .background(Color.black)
            .gesture(magnificationGesture)
            .simultaneousGesture(isZoomed ? imagePanGesture : nil)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    if isZoomed {
                        resetZoom()
                    } else {
                        scale = 2
                        lastScale = 2
                        onScaleChanged(scale)
                    }
                }
            }
        }
        .background(Color.black)
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let next = lastScale * value.magnification
                scale = min(max(next, 1), 4)
                onScaleChanged(scale)
            }
            .onEnded { _ in
                if scale <= 1 {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        resetZoom()
                    }
                } else {
                    lastScale = scale
                    onScaleChanged(scale)
                }
            }
    }

    private var imagePanGesture: some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                guard isZoomed else { return }

                imageOffset = CGSize(
                    width: lastImageOffset.width + value.translation.width,
                    height: lastImageOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                guard isZoomed else { return }
                lastImageOffset = imageOffset
            }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        imageOffset = .zero
        lastImageOffset = .zero
        onScaleChanged(1)
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/viewmodel/FeaturedFeedModule.swift

```swift
//
//  FeaturedFeedModule.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Foundation

enum FeaturedFeedModule {
    @MainActor
    static func makeViewModel() -> FeaturedFeedViewModel {
        let repository = FeaturedFeedRepository()
        return FeaturedFeedViewModel(
            fetchNextPageUseCase: FetchFeaturedPostsPageUseCase(repository: repository),
            observeLatestUseCase: ObserveLatestFeaturedPostsUseCase(repository: repository)
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/viewmodel/FeaturedFeedViewModel.swift

```swift
//
//  FeaturedFeedViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Combine
import FirebaseFirestore

@MainActor
final class FeaturedFeedViewModel: ObservableObject {
    @Published private(set) var posts: [FeaturedPost] = []
    @Published private(set) var isLoadingInitial = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var hasMore = true
    @Published var errorMessage: String?

    private let fetchNextPageUseCase: FetchFeaturedPostsPageUseCase
    private let observeLatestUseCase: ObserveLatestFeaturedPostsUseCase

    private var latestListener: ListenerRegistration?
    private var lastSnapshot: DocumentSnapshot?
    private let pageSize = 5

    init(
        fetchNextPageUseCase: FetchFeaturedPostsPageUseCase,
        observeLatestUseCase: ObserveLatestFeaturedPostsUseCase
    ) {
        self.fetchNextPageUseCase = fetchNextPageUseCase
        self.observeLatestUseCase = observeLatestUseCase
    }

    deinit {
        latestListener?.remove()
    }

    func start() {
        guard latestListener == nil else { return }
        isLoadingInitial = true
        observeLatest()
    }

    func refresh() {
        latestListener?.remove()
        latestListener = nil
        posts = []
        lastSnapshot = nil
        hasMore = true
        errorMessage = nil
        start()
    }

    func loadMoreIfNeeded(currentPost post: FeaturedPost?) {
        guard let post else { return }
        guard let last = posts.last, last.id == post.id else { return }
        guard !isLoadingInitial, !isLoadingMore, hasMore else { return }

        Task {
            await loadMore()
        }
    }

    private func observeLatest() {
        latestListener = observeLatestUseCase.execute(limit: pageSize) { [weak self] result in
            guard let self else { return }

            Task { @MainActor in
                switch result {
                case .success(let page):
                    self.posts = self.mergeKeepingNewest(current: self.posts, incomingTopPage: page.posts)
                    self.lastSnapshot = page.lastSnapshot
                    self.hasMore = page.hasMore || self.posts.count > page.posts.count
                    self.isLoadingInitial = false

                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.isLoadingInitial = false
                }
            }
        }
    }

    private func loadMore() async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchNextPageUseCase.execute(limit: pageSize, after: lastSnapshot)
            lastSnapshot = page.lastSnapshot
            hasMore = page.hasMore
            posts = mergeAppendingOlder(current: posts, incomingOlderPage: page.posts)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func mergeKeepingNewest(current: [FeaturedPost], incomingTopPage: [FeaturedPost]) -> [FeaturedPost] {
        var map = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        incomingTopPage.forEach { map[$0.id] = $0 }

        let result = Array(map.values)
            .filter { !$0.isExpired && $0.isVisible }
            .sorted { lhs, rhs in
                if lhs.expiresAt != rhs.expiresAt { return lhs.expiresAt > rhs.expiresAt }
                return lhs.createdAt > rhs.createdAt
            }

        return result
    }

    private func mergeAppendingOlder(current: [FeaturedPost], incomingOlderPage: [FeaturedPost]) -> [FeaturedPost] {
        var seen = Set(current.map(\.id))
        var merged = current

        for post in incomingOlderPage where !seen.contains(post.id) && !post.isExpired && post.isVisible {
            merged.append(post)
            seen.insert(post.id)
        }

        return merged.sorted { lhs, rhs in
            if lhs.expiresAt != rhs.expiresAt { return lhs.expiresAt > rhs.expiresAt }
            return lhs.createdAt > rhs.createdAt
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/home/presentation/viewmodel/RemoteImageLoader.swift

```swift
//
//  RemoteImageLoader.swift
//  Altos del Murco
//
//  Created by José Ruiz on 14/4/26.
//

import Combine
import SwiftUI
import ImageIO

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var isLoading = false
    @Published private(set) var didFail = false

    private var currentURL: URL?
    private var task: Task<Void, Never>?

    private static let memoryCache = NSCache<NSURL, UIImage>()

    private static let cache: URLCache = {
        URLCache(
            memoryCapacity: 80 * 1024 * 1024,
            diskCapacity: 500 * 1024 * 1024,
            diskPath: "featured-posts-images"
        )
    }()

    private static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 120
        return URLSession(configuration: configuration)
    }()

    @MainActor
    func load(from url: URL?, targetPixelSize: CGSize? = nil) {
        let sameURL = currentURL == url

        if sameURL, image != nil {
            return
        }

        if sameURL, isLoading {
            return
        }

        if !sameURL {
            cancel()
            currentURL = url
            image = nil
            didFail = false
        } else {
            didFail = false
        }

        guard let url else {
            didFail = true
            return
        }

        let nsURL = url as NSURL

        if let cached = Self.memoryCache.object(forKey: nsURL) {
            image = cached
            return
        }

        let request = URLRequest(
            url: url,
            cachePolicy: .returnCacheDataElseLoad,
            timeoutInterval: 60
        )

        if let cachedResponse = Self.cache.cachedResponse(for: request),
           let decoded = Self.decodeImage(data: cachedResponse.data, targetPixelSize: targetPixelSize) {
            Self.memoryCache.setObject(decoded, forKey: nsURL)
            image = decoded
            return
        }

        isLoading = true
        didFail = false

        task = Task {
            do {
                let (data, response) = try await Self.session.data(for: request)

                if Task.isCancelled { return }

                guard let decoded = Self.decodeImage(data: data, targetPixelSize: targetPixelSize) else {
                    await MainActor.run {
                        guard self.currentURL == url else { return }
                        self.isLoading = false
                        self.didFail = true
                    }
                    return
                }

                let cachedResponse = CachedURLResponse(response: response, data: data)
                Self.cache.storeCachedResponse(cachedResponse, for: request)
                Self.memoryCache.setObject(decoded, forKey: nsURL)

                await MainActor.run {
                    guard self.currentURL == url else { return }
                    self.image = decoded
                    self.isLoading = false
                    self.didFail = false
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.currentURL == url else { return }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    guard self.currentURL == url else { return }
                    self.isLoading = false
                    self.didFail = true
                }
            }
        }
    }

    func retry(targetPixelSize: CGSize? = nil) {
        load(from: currentURL, targetPixelSize: targetPixelSize)
    }

    func cancel() {
        task?.cancel()
        task = nil
        isLoading = false
    }

    private static func decodeImage(data: Data, targetPixelSize: CGSize?) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return UIImage(data: data)
        }

        let maxDimension: CGFloat
        if let targetPixelSize {
            maxDimension = max(targetPixelSize.width, targetPixelSize.height) * UIScreen.main.scale
        } else {
            maxDimension = 2000
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return UIImage(data: data)
        }

        return UIImage(cgImage: cgImage)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/data/LoyaltyRewardsService.swift

```swift
//
//  LoyaltyRewardsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation
import FirebaseFirestore

protocol LoyaltyRewardsListenerToken {
    func remove()
}

final class FirestoreLoyaltyWalletListenerToken: LoyaltyRewardsListenerToken {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration?) {
        self.registration = registration
    }

    func remove() {
        registration?.remove()
        registration = nil
    }
}

private final class CompositeLoyaltyRewardsListenerToken: LoyaltyRewardsListenerToken {
    private var registrations: [ListenerRegistration]

    init(registrations: [ListenerRegistration]) {
        self.registrations = registrations
    }

    func remove() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
    }
}

@MainActor
private final class LoyaltyWalletObservationCoordinator {
    private let emit: () -> Void
    private let onFailure: (Error) -> Void

    private var hasWalletSnapshot = false
    private var hasTemplatesSnapshot = false
    private var hasOrdersSnapshot = false
    private var hasBookingsSnapshot = false

    init(
        emit: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.emit = emit
        self.onFailure = onFailure
    }

    func receiveWallet(error: Error?) {
        receive(error: error, mark: \.hasWalletSnapshot)
    }

    func receiveTemplates(error: Error?) {
        receive(error: error, mark: \.hasTemplatesSnapshot)
    }

    func receiveOrders(error: Error?) {
        receive(error: error, mark: \.hasOrdersSnapshot)
    }

    func receiveBookings(error: Error?) {
        receive(error: error, mark: \.hasBookingsSnapshot)
    }

    private func receive(
        error: Error?,
        mark keyPath: ReferenceWritableKeyPath<LoyaltyWalletObservationCoordinator, Bool>
    ) {
        if let error {
            onFailure(error)
            return
        }

        self[keyPath: keyPath] = true

        guard hasWalletSnapshot, hasTemplatesSnapshot, hasOrdersSnapshot, hasBookingsSnapshot else {
            return
        }

        emit()
    }
}

protocol LoyaltyRewardsServiceable {
    func loadWalletSnapshot(for nationalId: String) async throws -> RewardWalletSnapshot

    func observeWalletSnapshot(
        for nationalId: String,
        onChange: @escaping (Result<RewardWalletSnapshot, Error>) -> Void
    ) -> LoyaltyRewardsListenerToken

    func previewRestaurantRewards(
        for nationalId: String,
        items: [OrderItem]
    ) async throws -> RewardComputationResult

    func previewAdventureRewards(
        for nationalId: String,
        activityItems: [AdventureReservationItemDraft],
        foodItems: [ReservationFoodItemDraft],
        catalog: AdventureCatalogSnapshot
    ) async throws -> RewardComputationResult

    func reserveRewards(
        nationalId: String,
        referenceType: LoyaltyRewardReferenceType,
        referenceId: String,
        appliedRewards: [AppliedReward]
    ) async throws

    func consumeRewards(
        nationalId: String,
        referenceId: String
    ) async throws

    func releaseRewards(
        nationalId: String,
        referenceId: String
    ) async throws
}

final class LoyaltyRewardsService: LoyaltyRewardsServiceable {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func loadWalletSnapshot(for nationalId: String) async throws -> RewardWalletSnapshot {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else { return .empty(nationalId: "") }

        async let templatesTask = fetchTemplates()
        async let totalsTask = computeTotals(for: cleanNationalId)
        async let walletTask = fetchWalletDocument(for: cleanNationalId)

        let templates = try await templatesTask
        let totals = try await totalsTask
        let walletDocument = try await walletTask

        let currentLevel = LoyaltyLevel.from(totalSpent: totals.totalSpent)

        let eligibleTemplates = templates.filter { template in
            template.isActive &&
            !template.isExpired &&
            template.triggerMode == .automatic &&
            template.isEligible(for: currentLevel) &&
            usageCount(
                templateId: template.id,
                inside: walletDocument.events
            ) < max(1, template.maxUsesPerClient)
        }
        .sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let reserved = walletDocument.events.filter { $0.status == .reserved }
        let consumed = walletDocument.events.filter { $0.status == .consumed }
        let released = walletDocument.events.filter { $0.status == .released }

        return RewardWalletSnapshot(
            nationalId: cleanNationalId,
            currentLevel: currentLevel,
            totalSpent: totals.totalSpent,
            points: Int(totals.totalSpent.rounded(.down)),
            availableTemplates: eligibleTemplates,
            reservedEvents: reserved,
            consumedEvents: consumed,
            releasedEvents: released
        )
    }

    func observeWalletSnapshot(
        for nationalId: String,
        onChange: @escaping (Result<RewardWalletSnapshot, Error>) -> Void
    ) -> LoyaltyRewardsListenerToken {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            onChange(.success(.empty(nationalId: "")))
            return FirestoreLoyaltyWalletListenerToken(registration: nil)
        }

        let walletRef = db
            .collection(FirestoreConstants.client_loyalty_wallets)
            .document(cleanNationalId)

        let templatesRef = db.collection(FirestoreConstants.loyalty_reward_templates)

        let ordersQuery = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("nationalId", isEqualTo: cleanNationalId)

        let bookingsQuery = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("nationalId", isEqualTo: cleanNationalId)

        let coordinator = LoyaltyWalletObservationCoordinator(
            emit: { [weak self] in
                guard let self else { return }

                Task {
                    do {
                        let snapshot = try await self.loadWalletSnapshot(for: cleanNationalId)
                        await MainActor.run {
                            onChange(.success(snapshot))
                        }
                    } catch {
                        await MainActor.run {
                            onChange(.failure(error))
                        }
                    }
                }
            },
            onFailure: { error in
                onChange(.failure(error))
            }
        )

        let walletRegistration = walletRef.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveWallet(error: error)
            }
        }

        let templatesRegistration = templatesRef.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveTemplates(error: error)
            }
        }

        let ordersRegistration = ordersQuery.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveOrders(error: error)
            }
        }

        let bookingsRegistration = bookingsQuery.addSnapshotListener { _, error in
            Task { @MainActor in
                coordinator.receiveBookings(error: error)
            }
        }

        return CompositeLoyaltyRewardsListenerToken(
            registrations: [
                walletRegistration,
                templatesRegistration,
                ordersRegistration,
                bookingsRegistration
            ]
        )
    }

    func previewRestaurantRewards(
        for nationalId: String,
        items: [OrderItem]
    ) async throws -> RewardComputationResult {
        let wallet = try await loadWalletSnapshot(for: nationalId)

        let lines = items.map {
            RewardMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity
            )
        }

        return LoyaltyRewardEngine.evaluateRestaurant(
            templates: wallet.availableTemplates,
            wallet: wallet,
            menuLines: lines
        )
    }

    func previewAdventureRewards(
        for nationalId: String,
        activityItems: [AdventureReservationItemDraft],
        foodItems: [ReservationFoodItemDraft],
        catalog: AdventureCatalogSnapshot
    ) async throws -> RewardComputationResult {
        let wallet = try await loadWalletSnapshot(for: nationalId)

        let activityLines = activityItems.compactMap { item -> RewardActivityLine? in
            guard let activity = catalog.activity(for: item.activity) else { return nil }
            let linePrice = AdventurePricingEngine.subtotal(for: item, catalog: catalog)

            return RewardActivityLine(
                activityId: activity.id,
                title: activity.title,
                linePrice: linePrice
            )
        }

        let foodLines = foodItems.map {
            RewardMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity
            )
        }

        let result = LoyaltyRewardEngine.evaluateAdventure(
            templates: wallet.availableTemplates,
            wallet: wallet,
            activityLines: activityLines,
            foodLines: foodLines
        )
        
        return result
    }

    func reserveRewards(
        nationalId: String,
        referenceType: LoyaltyRewardReferenceType,
        referenceId: String,
        appliedRewards: [AppliedReward]
    ) async throws {
        guard !appliedRewards.isEmpty else { return }

        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else { return }

        let walletRef = db.collection(FirestoreConstants.client_loyalty_wallets).document(cleanNationalId)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let walletDocument = try Self.loadWalletDocument(
                    from: transaction,
                    walletRef: walletRef
                )

                var events = walletDocument.events

                for reward in appliedRewards {
                    let templateRef = self.db
                        .collection(FirestoreConstants.loyalty_reward_templates)
                        .document(reward.templateId)

                    let templateSnapshot = try transaction.getDocument(templateRef)
                    guard templateSnapshot.exists else {
                        throw NSError(
                            domain: "LoyaltyRewardsService",
                            code: 10,
                            userInfo: [NSLocalizedDescriptionKey: "Reward template \(reward.templateId) no longer exists."]
                        )
                    }

                    let templateDto = try templateSnapshot.data(as: LoyaltyRewardTemplateDto.self)
                    let template = templateDto.toDomain()

                    guard template.isActive, !template.isExpired else {
                        throw NSError(
                            domain: "LoyaltyRewardsService",
                            code: 11,
                            userInfo: [NSLocalizedDescriptionKey: "The reward \(template.title) is no longer available."]
                        )
                    }

                    let alreadyUsed = Self.usageCount(
                        templateId: reward.templateId,
                        inside: events
                    )

                    guard alreadyUsed < max(1, template.maxUsesPerClient) else {
                        throw NSError(
                            domain: "LoyaltyRewardsService",
                            code: 12,
                            userInfo: [NSLocalizedDescriptionKey: "The reward \(template.title) is no longer available."]
                        )
                    }

                    events.append(
                        LoyaltyWalletEvent(
                            id: reward.id,
                            templateId: reward.templateId,
                            templateTitle: reward.title,
                            referenceType: referenceType,
                            referenceId: referenceId,
                            status: .reserved,
                            amount: reward.amount,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                    )
                }

                let updated = LoyaltyWalletDocument(
                    nationalId: cleanNationalId,
                    updatedAt: Date(),
                    events: events
                )

                try transaction.setData(from: updated, forDocument: walletRef, merge: true)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    func consumeRewards(
        nationalId: String,
        referenceId: String
    ) async throws {
        try await mutateReferenceStatus(
            nationalId: nationalId,
            referenceId: referenceId,
            targetStatus: .consumed
        )
    }

    func releaseRewards(
        nationalId: String,
        referenceId: String
    ) async throws {
        try await mutateReferenceStatus(
            nationalId: nationalId,
            referenceId: referenceId,
            targetStatus: .released
        )
    }

    private func mutateReferenceStatus(
        nationalId: String,
        referenceId: String,
        targetStatus: LoyaltyWalletEventStatus
    ) async throws {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else { return }

        let walletRef = db.collection(FirestoreConstants.client_loyalty_wallets).document(cleanNationalId)

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                let wallet = try Self.loadWalletDocument(
                    from: transaction,
                    walletRef: walletRef
                )

                let updatedEvents = wallet.events.map { event in
                    guard event.referenceId == referenceId else { return event }
                    guard event.status == .reserved else { return event }

                    return LoyaltyWalletEvent(
                        id: event.id,
                        templateId: event.templateId,
                        templateTitle: event.templateTitle,
                        referenceType: event.referenceType,
                        referenceId: event.referenceId,
                        status: targetStatus,
                        amount: event.amount,
                        createdAt: event.createdAt,
                        updatedAt: Date()
                    )
                }

                let updated = LoyaltyWalletDocument(
                    nationalId: cleanNationalId,
                    updatedAt: Date(),
                    events: updatedEvents
                )

                try transaction.setData(from: updated, forDocument: walletRef, merge: true)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }
    }

    private func fetchTemplates() async throws -> [LoyaltyRewardTemplate] {
        let snapshot = try await db
            .collection(FirestoreConstants.loyalty_reward_templates)
            .getDocuments()

        return try snapshot.documents
            .map { try $0.data(as: LoyaltyRewardTemplateDto.self).toDomain() }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
                return lhs.title < rhs.title
            }
    }

    private func fetchWalletDocument(
        for nationalId: String
    ) async throws -> LoyaltyWalletDocument {
        let ref = db.collection(FirestoreConstants.client_loyalty_wallets).document(nationalId)
        let snapshot = try await ref.getDocument()

        guard snapshot.exists else {
            return LoyaltyWalletDocument(
                nationalId: nationalId,
                updatedAt: Date(),
                events: []
            )
        }

        return try snapshot.data(as: LoyaltyWalletDocument.self)
    }

    private func computeTotals(
        for nationalId: String
    ) async throws -> (restaurantSpent: Double, adventureSpent: Double, totalSpent: Double) {
        async let ordersTask = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("nationalId", isEqualTo: nationalId)
            .getDocuments()

        async let bookingsTask = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("nationalId", isEqualTo: nationalId)
            .getDocuments()

        let orderSnapshot = try await ordersTask
        let bookingSnapshot = try await bookingsTask

        let orders: [Order] = try orderSnapshot.documents.compactMap { document in
            let dto = try document.data(as: OrderDto.self)
            return dto.toDomain()
        }

        let bookings: [AdventureBooking] = try bookingSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureBookingDto.self)
            return dto.toDomain(documentId: document.documentID)
        }

        let completedOrders = orders.filter { $0.recalculatedStatus() == .completed }
        let completedBookings = bookings.filter { $0.status == .completed }

        let restaurantSpent = completedOrders.reduce(0) { $0 + $1.totalAmount }
        let adventureSpent = completedBookings.reduce(0) { $0 + $1.totalAmount }

        return (
            restaurantSpent: restaurantSpent,
            adventureSpent: adventureSpent,
            totalSpent: restaurantSpent + adventureSpent
        )
    }

    private func usageCount(
        templateId: String,
        inside events: [LoyaltyWalletEvent]
    ) -> Int {
        Self.usageCount(templateId: templateId, inside: events)
    }

    private static func usageCount(
        templateId: String,
        inside events: [LoyaltyWalletEvent]
    ) -> Int {
        events.filter {
            $0.templateId == templateId &&
            ($0.status == .reserved || $0.status == .consumed)
        }.count
    }

    private static func loadWalletDocument(
        from transaction: Transaction,
        walletRef: DocumentReference
    ) throws -> LoyaltyWalletDocument {
        let snapshot = try transaction.getDocument(walletRef)

        guard snapshot.exists else {
            return LoyaltyWalletDocument(
                nationalId: walletRef.documentID,
                updatedAt: Date(),
                events: []
            )
        }

        return try snapshot.data(as: LoyaltyWalletDocument.self)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/data/ProfileImageCache.swift

```swift
//
//  ProfileImageCache.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import UIKit

final class ProfileImageCache {
    static let shared = ProfileImageCache()

    private let fileManager = FileManager.default
    private let directoryURL: URL

    private init() {
        let root = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let directory = root.appendingPathComponent("ProfileImages", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        self.directoryURL = directory
    }

    private func fileURL(for userId: String) -> URL {
        directoryURL.appendingPathComponent("profile_\(userId).jpg")
    }

    func loadImage(for userId: String) -> UIImage? {
        guard let data = try? Data(contentsOf: fileURL(for: userId)) else { return nil }
        return UIImage(data: data)
    }

    @discardableResult
    func saveImageData(_ data: Data, for userId: String) throws -> UIImage? {
        let url = fileURL(for: userId)
        try data.write(to: url, options: .atomic)
        return UIImage(data: data)
    }

    func removeImage(for userId: String) {
        try? fileManager.removeItem(at: fileURL(for: userId))
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/data/ProfileImageStorageService.swift

```swift
//
//  ProfileImageStorageService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseStorage
import UIKit

struct UploadedProfileImage {
    let downloadURL: String
    let storagePath: String
}

final class ProfileImageStorageService {
    private let storage: Storage

    init(storage: Storage = Storage.storage()) {
        self.storage = storage
    }

    func uploadProfileImage(
        data: Data,
        userId: String,
        replacing existingPath: String?
    ) async throws -> UploadedProfileImage {
        if let existingPath, !existingPath.isEmpty {
            try? await deleteProfileImage(path: existingPath)
        }

        let jpegData = UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data
        let path = "clients/profile_images/\(userId)/avatar_\(Int(Date().timeIntervalSince1970)).jpg"
        let ref = storage.reference(withPath: path)

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.putData(jpegData, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

        let url = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "ProfileImageStorageService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Missing profile image download URL."]
                    ))
                }
            }
        }

        return UploadedProfileImage(
            downloadURL: url.absoluteString,
            storagePath: path
        )
    }

    func deleteProfileImage(path: String?) async throws {
        guard let path = path, !path.isEmpty else { return }

        let ref = storage.reference(withPath: path)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ref.delete { error in
                if let nsError = error as NSError?,
                   nsError.code == StorageErrorCode.objectNotFound.rawValue {
                    continuation.resume(returning: ())
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}


```

---

# Altos del Murco/root/feature/altos/profile/data/ProfileStatsService.swift

```swift
//
//  ProfileStatsService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation
import FirebaseFirestore

protocol ProfileStatsListenerToken {
    func remove()
}

private final class EmptyProfileStatsListenerToken: ProfileStatsListenerToken {
    func remove() { }
}

private final class CompositeProfileStatsListenerToken: ProfileStatsListenerToken {
    private var registrations: [ListenerRegistration]
    private var walletListenerToken: LoyaltyRewardsListenerToken?

    init(
        registrations: [ListenerRegistration],
        walletListenerToken: LoyaltyRewardsListenerToken?
    ) {
        self.registrations = registrations
        self.walletListenerToken = walletListenerToken
    }

    func remove() {
        registrations.forEach { $0.remove() }
        registrations.removeAll()
        walletListenerToken?.remove()
        walletListenerToken = nil
    }
}

final class ProfileStatsService {
    private let db: Firestore
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func loadStats(for nationalId: String) async throws -> ProfileStats {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else { return .empty }

        async let ordersTask = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .getDocuments()

        async let bookingsTask = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .getDocuments()

        async let walletTask = loyaltyRewardsService.loadWalletSnapshot(for: cleanNationalId)

        let ordersSnapshot = try await ordersTask
        let bookingsSnapshot = try await bookingsTask
        let wallet = try await walletTask

        let orders: [Order] = try ordersSnapshot.documents.compactMap { document in
            let dto = try document.data(as: OrderDto.self)
            return dto.toDomain()
        }

        let bookings: [AdventureBooking] = try bookingsSnapshot.documents.compactMap { document in
            let dto = try document.data(as: AdventureBookingDto.self)
            return dto.toDomain(documentId: document.documentID)
        }

        let completedOrders = orders.filter { $0.recalculatedStatus() == .completed }
        let completedBookings = bookings.filter { $0.status == .completed }

        let restaurantSpent = completedOrders.reduce(0) { $0 + $1.totalAmount }
        let adventureSpent = completedBookings.reduce(0) { $0 + $1.totalAmount }
        let totalSpent = restaurantSpent + adventureSpent

        return ProfileStats(
            points: wallet.points,
            completedOrders: completedOrders.count,
            completedBookings: completedBookings.count,
            restaurantSpent: restaurantSpent,
            adventureSpent: adventureSpent,
            totalSpent: totalSpent,
            level: wallet.currentLevel,
            wallet: wallet
        )
    }

    func observeStats(
        for nationalId: String,
        onChange: @escaping (Result<ProfileStats, Error>) -> Void
    ) -> ProfileStatsListenerToken {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            onChange(.success(.empty))
            return EmptyProfileStatsListenerToken()
        }

        let emit: @Sendable () -> Void = { [weak self] in
            guard let self else { return }

            Task {
                do {
                    let stats = try await self.loadStats(for: cleanNationalId)
                    await MainActor.run {
                        onChange(.success(stats))
                    }
                } catch {
                    await MainActor.run {
                        onChange(.failure(error))
                    }
                }
            }
        }

        let ordersRegistration = db
            .collection(FirestoreConstants.restaurant_orders)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .addSnapshotListener { _, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                emit()
            }

        let bookingsRegistration = db
            .collection(FirestoreConstants.adventure_bookings)
            .whereField("nationalId", isEqualTo: cleanNationalId)
            .addSnapshotListener { _, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                emit()
            }

        let walletListener = loyaltyRewardsService.observeWalletSnapshot(for: cleanNationalId) { result in
            switch result {
            case .success:
                emit()

            case .failure(let error):
                onChange(.failure(error))
            }
        }

        emit()

        return CompositeProfileStatsListenerToken(
            registrations: [ordersRegistration, bookingsRegistration],
            walletListenerToken: walletListener
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/ClientProfileDocument.swift

```swift
//
//  ClientProfileDocument.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

struct ClientProfileDocument: Codable {
    let id: String
    let email: String
    let appleUserIdentifier: String
    let fullName: String
    let nationalId: String
    let phoneNumber: String
    let birthday: Date
    let address: String
    let emergencyContactName: String
    let emergencyContactPhone: String
    let isProfileComplete: Bool
    let createdAt: Date
    let updatedAt: Date
    let profileCompletedAt: Date?
    let profileImageURL: String?
    let profileImagePath: String?

    init(profile: ClientProfile) {
        self.id = profile.id
        self.email = profile.email
        self.appleUserIdentifier = profile.appleUserIdentifier
        self.fullName = profile.fullName
        self.nationalId = profile.nationalId
        self.phoneNumber = profile.phoneNumber
        self.birthday = profile.birthday
        self.address = profile.address
        self.emergencyContactName = profile.emergencyContactName
        self.emergencyContactPhone = profile.emergencyContactPhone
        self.isProfileComplete = profile.isProfileComplete
        self.createdAt = profile.createdAt
        self.updatedAt = profile.updatedAt
        self.profileCompletedAt = profile.profileCompletedAt
        self.profileImageURL = profile.profileImageURL
        self.profileImagePath = profile.profileImagePath
    }

    func toDomain() -> ClientProfile {
        ClientProfile(
            id: id,
            email: email,
            appleUserIdentifier: appleUserIdentifier,
            fullName: fullName,
            nationalId: nationalId,
            phoneNumber: phoneNumber,
            birthday: birthday,
            address: address,
            emergencyContactName: emergencyContactName,
            emergencyContactPhone: emergencyContactPhone,
            isProfileComplete: isProfileComplete,
            createdAt: createdAt,
            updatedAt: updatedAt,
            profileCompletedAt: profileCompletedAt,
            profileImageURL: profileImageURL,
            profileImagePath: profileImagePath
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/LoyaltyLevel.swift

```swift
//
//  LoyaltyLevel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

enum LoyaltyLevel: String, Codable, CaseIterable, Hashable, Identifiable {
    case bronze
    case silver
    case gold
    case platinum
    case diamond

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bronze: return "Bronce"
        case .silver: return "Plata"
        case .gold: return "Oro"
        case .platinum: return "Platino"
        case .diamond: return "Diamante"
        }
    }

    var systemImage: String {
        switch self {
        case .bronze: return "sparkles"
        case .silver: return "seal.fill"
        case .gold: return "star.circle.fill"
        case .platinum: return "crown.fill"
        case .diamond: return "diamond.fill"
        }
    }

    var badgeSubtitle: String {
        switch self {
        case .bronze: return "Tus primeras visitas ya empiezan a premiarte"
        case .silver: return "Más beneficios cada vez que vuelves"
        case .gold: return "Descuentos más fuertes y regalos más frecuentes"
        case .platinum: return "Nivel preferente con premios premium"
        case .diamond: return "Nuestro máximo nivel para clientes top"
        }
    }

    var minimumSpent: Double {
        switch self {
        case .bronze: return 0
        case .silver: return 100
        case .gold: return 300
        case .platinum: return 800
        case .diamond: return 1500
        }
    }

    var spendRangeText: String {
        switch self {
        case .bronze: return "De $0 a $99"
        case .silver: return "De $100 a $299"
        case .gold: return "De $300 a $799"
        case .platinum: return "De $800 a $1499"
        case .diamond: return "Desde $1500"
        }
    }

    var nextLevel: LoyaltyLevel? {
        switch self {
        case .bronze: return .silver
        case .silver: return .gold
        case .gold: return .platinum
        case .platinum: return .diamond
        case .diamond: return nil
        }
    }

    func remainingSpend(from totalSpent: Double) -> Double {
        guard let nextLevel else { return 0 }
        return max(nextLevel.minimumSpent - totalSpent, 0)
    }

    static func from(totalSpent: Double) -> LoyaltyLevel {
        switch totalSpent {
        case 0..<100: return .bronze
        case 100..<300: return .silver
        case 300..<800: return .gold
        case 800..<1500: return .platinum
        default: return .diamond
        }
    }

    static func progress(for totalSpent: Double) -> Double {
        let current = from(totalSpent: totalSpent)
        guard let next = current.nextLevel else { return 1 }

        let start = current.minimumSpent
        let end = next.minimumSpent
        guard end > start else { return 1 }

        let raw = (totalSpent - start) / (end - start)
        return min(max(raw, 0), 1)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/LoyaltyRewardEngine.swift

```swift
//
//  LoyaltyRewardEngine.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation

enum LoyaltyRewardEngine {
    static func evaluateRestaurant(
        templates: [LoyaltyRewardTemplate],
        wallet: RewardWalletSnapshot,
        menuLines: [RewardMenuLine]
    ) -> RewardComputationResult {
        let eligible = templates.filter {
            $0.isActive &&
            $0.triggerMode == .automatic &&
            $0.scope.matchesRestaurant() &&
            $0.isEligible(for: wallet.currentLevel)
        }

        let stackableTemplates = eligible.filter(\.canStack).sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let exclusiveTemplates = eligible.filter { !$0.canStack }.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let stackableResult = applyRestaurantTemplates(stackableTemplates, menuLines: menuLines)
        let bestExclusive = exclusiveTemplates
            .map { applyRestaurantTemplates([$0], menuLines: menuLines) }
            .max { lhs, rhs in lhs.totalDiscount < rhs.totalDiscount }

        let winner = (bestExclusive?.totalDiscount ?? 0) > stackableResult.totalDiscount
            ? bestExclusive!
            : stackableResult

        return RewardComputationResult(
            appliedRewards: winner.appliedRewards,
            totalDiscount: winner.totalDiscount,
            walletSnapshot: wallet
        )
    }

    static func evaluateAdventure(
        templates: [LoyaltyRewardTemplate],
        wallet: RewardWalletSnapshot,
        activityLines: [RewardActivityLine],
        foodLines: [RewardMenuLine]
    ) -> RewardComputationResult {
        let eligible = templates.filter { template in
            template.isActive &&
            template.triggerMode == .automatic &&
            template.isEligible(for: wallet.currentLevel) &&
            templateAppliesInAdventureContext(template)
        }

        let stackableTemplates = eligible.filter(\.canStack).sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let exclusiveTemplates = eligible.filter { !$0.canStack }.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.title < rhs.title
        }

        let stackableResult = applyAdventureTemplates(
            stackableTemplates,
            activityLines: activityLines,
            foodLines: foodLines
        )

        let bestExclusive = exclusiveTemplates
            .map { applyAdventureTemplates([$0], activityLines: activityLines, foodLines: foodLines) }
            .max { lhs, rhs in lhs.totalDiscount < rhs.totalDiscount }

        let winner = (bestExclusive?.totalDiscount ?? 0) > stackableResult.totalDiscount
            ? bestExclusive!
            : stackableResult

        return RewardComputationResult(
            appliedRewards: winner.appliedRewards,
            totalDiscount: winner.totalDiscount,
            walletSnapshot: wallet
        )
    }

    private static func templateAppliesInAdventureContext(
        _ template: LoyaltyRewardTemplate
    ) -> Bool {
        switch template.rule.type {
        case .activityPercentage:
            return template.scope.matchesAdventure()

        case .mostExpensiveMenuItemPercentage,
             .specificMenuItemPercentage,
             .freeMenuItem,
             .buyXGetYFree:
            switch template.scope {
            case .restaurant, .adventure, .both:
                return true
            }
        }
    }

    private static func templateCanApplyToAdventureFood(
        _ template: LoyaltyRewardTemplate
    ) -> Bool {
        switch template.scope {
        case .restaurant, .adventure, .both:
            return true
        }
    }

    private struct InternalRewardResult {
        var appliedRewards: [AppliedReward]
        var totalDiscount: Double
    }

    private struct MutableMenuLine {
        let menuItemId: String
        let name: String
        let unitPrice: Double
        var remainingRewardableUnits: Int
    }

    private struct MutableActivityLine {
        let activityId: String
        let title: String
        var remainingRewardableAmount: Double
    }

    private static func applyRestaurantTemplates(
        _ templates: [LoyaltyRewardTemplate],
        menuLines: [RewardMenuLine]
    ) -> InternalRewardResult {
        var workingLines = menuLines.map {
            MutableMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                remainingRewardableUnits: max(0, $0.quantity)
            )
        }

        var appliedRewards: [AppliedReward] = []
        var totalDiscount = 0.0

        for template in templates {
            guard let reward = applyRestaurantTemplate(template, lines: &workingLines) else { continue }
            appliedRewards.append(reward)
            totalDiscount += reward.amount
        }

        return InternalRewardResult(
            appliedRewards: appliedRewards,
            totalDiscount: totalDiscount
        )
    }

    private static func applyAdventureTemplates(
        _ templates: [LoyaltyRewardTemplate],
        activityLines: [RewardActivityLine],
        foodLines: [RewardMenuLine]
    ) -> InternalRewardResult {
        var workingActivities = activityLines.map {
            MutableActivityLine(
                activityId: $0.activityId,
                title: $0.title,
                remainingRewardableAmount: max(0, $0.linePrice)
            )
        }

        var workingFood = foodLines.map {
            MutableMenuLine(
                menuItemId: $0.menuItemId,
                name: $0.name,
                unitPrice: $0.unitPrice,
                remainingRewardableUnits: max(0, $0.quantity)
            )
        }

        var appliedRewards: [AppliedReward] = []
        var totalDiscount = 0.0

        for template in templates {
            switch template.rule.type {
            case .activityPercentage:
                guard let reward = applyActivityTemplate(template, lines: &workingActivities) else { continue }
                appliedRewards.append(reward)
                totalDiscount += reward.amount

            default:
                guard let reward = applyRestaurantTemplate(template, lines: &workingFood) else { continue }
                appliedRewards.append(reward)
                totalDiscount += reward.amount
            }
        }

        return InternalRewardResult(
            appliedRewards: appliedRewards,
            totalDiscount: totalDiscount
        )
    }

    private static func applyRestaurantTemplate(
        _ template: LoyaltyRewardTemplate,
        lines: inout [MutableMenuLine]
    ) -> AppliedReward? {
        switch template.rule.type {
        case .mostExpensiveMenuItemPercentage:
            guard let percentage = template.rule.percentage else { return nil }
            guard let index = lines.indices
                .filter({ lines[$0].remainingRewardableUnits > 0 })
                .max(by: { lines[$0].unitPrice < lines[$1].unitPrice }) else { return nil }

            let line = lines[index]
            let amount = roundMoney(line.unitPrice * (percentage / 100))
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= 1

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "\(Int(percentage))% en \(line.name)",
                affectedMenuItemIds: [line.menuItemId],
                affectedActivityIds: []
            )

        case .specificMenuItemPercentage:
            let percentage = template.rule.percentage ?? 0
            let quantity = max(1, template.rule.quantity ?? 1)
            let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !targetId.isEmpty else { return nil }
            guard let index = lines.firstIndex(where: {
                $0.menuItemId == targetId && $0.remainingRewardableUnits > 0
            }) else { return nil }

            let applicableUnits = min(quantity, lines[index].remainingRewardableUnits)
            guard applicableUnits > 0 else { return nil }

            let amount = roundMoney(Double(applicableUnits) * lines[index].unitPrice * (percentage / 100))
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= applicableUnits

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "\(Int(percentage))% en \(lines[index].name)",
                affectedMenuItemIds: [targetId],
                affectedActivityIds: []
            )

        case .freeMenuItem:
            let quantity = max(1, template.rule.quantity ?? 1)
            let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !targetId.isEmpty else { return nil }
            guard let index = lines.firstIndex(where: {
                $0.menuItemId == targetId && $0.remainingRewardableUnits > 0
            }) else { return nil }

            let applicableUnits = min(quantity, lines[index].remainingRewardableUnits)
            guard applicableUnits > 0 else { return nil }

            let amount = roundMoney(Double(applicableUnits) * lines[index].unitPrice)
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= applicableUnits

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "\(applicableUnits)x \(lines[index].name) gratis",
                affectedMenuItemIds: [targetId],
                affectedActivityIds: []
            )

        case .buyXGetYFree:
            let targetId = template.rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let buyQuantity = max(1, template.rule.buyQuantity ?? 1)
            let freeQuantity = max(1, template.rule.freeQuantity ?? 1)
            let repeatable = template.rule.repeatable ?? true

            guard !targetId.isEmpty else { return nil }
            guard let index = lines.firstIndex(where: { $0.menuItemId == targetId }) else { return nil }

            let line = lines[index]
            let totalUnits = line.remainingRewardableUnits
            guard totalUnits >= buyQuantity else { return nil }

            let freeUnits: Int = {
                if repeatable {
                    return min(totalUnits, (totalUnits / buyQuantity) * freeQuantity)
                }
                return totalUnits >= buyQuantity ? min(totalUnits, freeQuantity) : 0
            }()

            guard freeUnits > 0 else { return nil }

            let amount = roundMoney(Double(freeUnits) * line.unitPrice)
            guard amount > 0 else { return nil }

            lines[index].remainingRewardableUnits -= freeUnits

            return AppliedReward(
                id: UUID().uuidString,
                templateId: template.id,
                title: template.title,
                amount: amount,
                note: "Compra \(buyQuantity) y recibe \(freeUnits) gratis en \(line.name)",
                affectedMenuItemIds: [targetId],
                affectedActivityIds: []
            )

        case .activityPercentage:
            return nil
        }
    }

    private static func applyActivityTemplate(
        _ template: LoyaltyRewardTemplate,
        lines: inout [MutableActivityLine]
    ) -> AppliedReward? {
        guard template.rule.type == .activityPercentage else { return nil }

        let percentage = template.rule.percentage ?? 0
        let targetId = template.rule.activityId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !targetId.isEmpty else { return nil }
        guard let index = lines.firstIndex(where: {
            $0.activityId == targetId && $0.remainingRewardableAmount > 0
        }) else { return nil }

        let amount = roundMoney(lines[index].remainingRewardableAmount * (percentage / 100))
        guard amount > 0 else { return nil }

        lines[index].remainingRewardableAmount = 0

        return AppliedReward(
            id: UUID().uuidString,
            templateId: template.id,
            title: template.title,
            amount: amount,
            note: "\(Int(percentage))% en \(lines[index].title)",
            affectedMenuItemIds: [],
            affectedActivityIds: [targetId]
        )
    }

    private static func roundMoney(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/LoyaltyRewardModels.swift

```swift
//
//  LoyaltyRewardModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation

enum LoyaltyRewardScope: String, Codable, CaseIterable, Identifiable, Hashable {
    case restaurant
    case adventure
    case both

    var id: String { rawValue }

    var title: String {
        switch self {
        case .restaurant: return "Restaurante"
        case .adventure: return "Aventura"
        case .both: return "Ambos"
        }
    }

    func matchesRestaurant() -> Bool {
        self == .restaurant || self == .both
    }

    func matchesAdventure() -> Bool {
        self == .adventure || self == .both
    }
}

enum LoyaltyRewardTriggerMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case automatic
    case manual

    var id: String { rawValue }
}

enum LoyaltyRewardRuleType: String, Codable, CaseIterable, Identifiable, Hashable {
    case mostExpensiveMenuItemPercentage
    case specificMenuItemPercentage
    case activityPercentage
    case freeMenuItem
    case buyXGetYFree

    var id: String { rawValue }
}

struct LoyaltyRewardRule: Codable, Hashable {
    var type: LoyaltyRewardRuleType
    var percentage: Double?
    var menuItemId: String?
    var activityId: String?
    var quantity: Int?
    var buyQuantity: Int?
    var freeQuantity: Int?
    var repeatable: Bool?

    static func mostExpensiveMenuItemDiscount(_ percentage: Double) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .mostExpensiveMenuItemPercentage,
            percentage: percentage,
            menuItemId: nil,
            activityId: nil,
            quantity: 1,
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func specificMenuItemDiscount(
        menuItemId: String,
        percentage: Double,
        quantity: Int = 1
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .specificMenuItemPercentage,
            percentage: percentage,
            menuItemId: menuItemId,
            activityId: nil,
            quantity: max(1, quantity),
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func activityDiscount(
        activityId: String,
        percentage: Double
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .activityPercentage,
            percentage: percentage,
            menuItemId: nil,
            activityId: activityId,
            quantity: 1,
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func freeMenuItem(
        menuItemId: String,
        quantity: Int = 1
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .freeMenuItem,
            percentage: nil,
            menuItemId: menuItemId,
            activityId: nil,
            quantity: max(1, quantity),
            buyQuantity: nil,
            freeQuantity: nil,
            repeatable: nil
        )
    }

    static func buyXGetYFree(
        menuItemId: String,
        buyQuantity: Int,
        freeQuantity: Int = 1,
        repeatable: Bool = true
    ) -> LoyaltyRewardRule {
        LoyaltyRewardRule(
            type: .buyXGetYFree,
            percentage: nil,
            menuItemId: menuItemId,
            activityId: nil,
            quantity: nil,
            buyQuantity: max(1, buyQuantity),
            freeQuantity: max(1, freeQuantity),
            repeatable: repeatable
        )
    }
}

struct LoyaltyRewardTemplate: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var subtitle: String
    var scope: LoyaltyRewardScope
    var minimumLevel: LoyaltyLevel
    var triggerMode: LoyaltyRewardTriggerMode
    var isActive: Bool
    var canStack: Bool
    var priority: Int
    var maxUsesPerClient: Int
    var expiresInDays: Int?
    var rule: LoyaltyRewardRule
    var createdAt: Date
    var updatedAt: Date

    var displaySummary: String {
        switch rule.type {
        case .mostExpensiveMenuItemPercentage:
            return "\(Int(rule.percentage ?? 0))% en el plato elegible más caro"
        case .specificMenuItemPercentage:
            return "\(Int(rule.percentage ?? 0))% en item específico"
        case .activityPercentage:
            return "\(Int(rule.percentage ?? 0))% en actividad específica"
        case .freeMenuItem:
            return "\(max(1, rule.quantity ?? 1)) item(s) gratis"
        case .buyXGetYFree:
            return "Compra \(max(1, rule.buyQuantity ?? 1)) y recibe \(max(1, rule.freeQuantity ?? 1)) gratis"
        }
    }

    func isEligible(for level: LoyaltyLevel) -> Bool {
        level.minimumSpent >= minimumLevel.minimumSpent
    }

    var expirationDate: Date? {
        guard let expiresInDays, expiresInDays > 0 else { return nil }
        return Calendar.current.date(byAdding: .day, value: expiresInDays, to: updatedAt)
    }

    var isExpired: Bool {
        guard let expirationDate else { return false }
        return Date() > expirationDate
    }

    var expirationText: String? {
        guard let expirationDate else { return nil }
        return "Vence \(expirationDate.formatted(date: .abbreviated, time: .omitted))"
    }

    var targetMenuItemId: String? {
        let value = rule.menuItemId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    var targetActivityId: String? {
        let value = rule.activityId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }
}

enum LoyaltyRewardReferenceType: String, Codable, Hashable {
    case order
    case booking
}

enum LoyaltyWalletEventStatus: String, Codable, CaseIterable, Hashable {
    case reserved
    case consumed
    case released
    case expired
}

struct LoyaltyWalletEvent: Identifiable, Codable, Hashable {
    let id: String
    let templateId: String
    let templateTitle: String
    let referenceType: LoyaltyRewardReferenceType
    let referenceId: String
    let status: LoyaltyWalletEventStatus
    let amount: Double
    let createdAt: Date
    let updatedAt: Date
}

struct AppliedReward: Identifiable, Codable, Hashable {
    let id: String
    let templateId: String
    let title: String
    let amount: Double
    let note: String
    let affectedMenuItemIds: [String]
    let affectedActivityIds: [String]
}

struct RewardWalletSnapshot: Hashable {
    let nationalId: String
    let currentLevel: LoyaltyLevel
    let totalSpent: Double
    let points: Int
    let availableTemplates: [LoyaltyRewardTemplate]
    let reservedEvents: [LoyaltyWalletEvent]
    let consumedEvents: [LoyaltyWalletEvent]
    let releasedEvents: [LoyaltyWalletEvent]

    static func empty(nationalId: String) -> RewardWalletSnapshot {
        RewardWalletSnapshot(
            nationalId: nationalId,
            currentLevel: .bronze,
            totalSpent: 0,
            points: 0,
            availableTemplates: [],
            reservedEvents: [],
            consumedEvents: [],
            releasedEvents: []
        )
    }
}

struct RewardComputationResult: Hashable {
    let appliedRewards: [AppliedReward]
    let totalDiscount: Double
    let walletSnapshot: RewardWalletSnapshot

    static func empty(wallet: RewardWalletSnapshot) -> RewardComputationResult {
        RewardComputationResult(
            appliedRewards: [],
            totalDiscount: 0,
            walletSnapshot: wallet
        )
    }
}

struct RewardMenuLine: Hashable {
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
}

struct RewardActivityLine: Hashable {
    let activityId: String
    let title: String
    let linePrice: Double
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/LoyaltyRewardTemplateDto.swift

```swift
//
//  LoyaltyRewardTemplateDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import FirebaseFirestore
import Foundation

struct LoyaltyRewardTemplateDto: Codable {
    let id: String
    let title: String
    let subtitle: String
    let scope: String
    let minimumLevel: String
    let triggerMode: String
    let isActive: Bool
    let canStack: Bool
    let priority: Int
    let maxUsesPerClient: Int
    let expiresInDays: Int?
    let rule: LoyaltyRewardRule
    let createdAt: Timestamp
    let updatedAt: Timestamp

    init(domain: LoyaltyRewardTemplate) {
        self.id = domain.id
        self.title = domain.title
        self.subtitle = domain.subtitle
        self.scope = domain.scope.rawValue
        self.minimumLevel = domain.minimumLevel.rawValue
        self.triggerMode = domain.triggerMode.rawValue
        self.isActive = domain.isActive
        self.canStack = domain.canStack
        self.priority = domain.priority
        self.maxUsesPerClient = max(1, domain.maxUsesPerClient)
        self.expiresInDays = domain.expiresInDays
        self.rule = domain.rule
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
    }

    func toDomain() -> LoyaltyRewardTemplate {
        LoyaltyRewardTemplate(
            id: id,
            title: title,
            subtitle: subtitle,
            scope: LoyaltyRewardScope(rawValue: scope) ?? .both,
            minimumLevel: LoyaltyLevel(rawValue: minimumLevel) ?? .bronze,
            triggerMode: LoyaltyRewardTriggerMode(rawValue: triggerMode) ?? .automatic,
            isActive: isActive,
            canStack: canStack,
            priority: priority,
            maxUsesPerClient: max(1, maxUsesPerClient),
            expiresInDays: expiresInDays,
            rule: rule,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}

struct LoyaltyWalletEventDto: Codable {
    let id: String
    let templateId: String
    let templateTitle: String
    let referenceType: String
    let referenceId: String
    let status: String
    let amount: Double
    let createdAt: Timestamp
    let updatedAt: Timestamp

    init(domain: LoyaltyWalletEvent) {
        self.id = domain.id
        self.templateId = domain.templateId
        self.templateTitle = domain.templateTitle
        self.referenceType = domain.referenceType.rawValue
        self.referenceId = domain.referenceId
        self.status = domain.status.rawValue
        self.amount = domain.amount
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
    }

    func toDomain() -> LoyaltyWalletEvent {
        LoyaltyWalletEvent(
            id: id,
            templateId: templateId,
            templateTitle: templateTitle,
            referenceType: LoyaltyRewardReferenceType(rawValue: referenceType) ?? .order,
            referenceId: referenceId,
            status: LoyaltyWalletEventStatus(rawValue: status) ?? .reserved,
            amount: amount,
            createdAt: createdAt.dateValue(),
            updatedAt: updatedAt.dateValue()
        )
    }
}

struct LoyaltyWalletDocument: Codable {
    let nationalId: String
    let updatedAt: Date
    let events: [LoyaltyWalletEvent]

    init(
        nationalId: String,
        updatedAt: Date,
        events: [LoyaltyWalletEvent]
    ) {
        self.nationalId = nationalId
        self.updatedAt = updatedAt
        self.events = events
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nationalId = try container.decode(String.self, forKey: .nationalId)
        let updatedAtTimestamp = try container.decode(Timestamp.self, forKey: .updatedAt)
        let eventDtos = try container.decodeIfPresent([LoyaltyWalletEventDto].self, forKey: .events) ?? []
        updatedAt = updatedAtTimestamp.dateValue()
        events = eventDtos.map { $0.toDomain() }
    }

    enum CodingKeys: String, CodingKey {
        case nationalId
        case updatedAt
        case events
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(nationalId, forKey: .nationalId)
        try container.encode(Timestamp(date: updatedAt), forKey: .updatedAt)
        try container.encode(events.map(LoyaltyWalletEventDto.init(domain:)), forKey: .events)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/ProfileStats.swift

```swift
//
//  ProfileStats.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Foundation

struct ProfileStats {
    let points: Int
    let completedOrders: Int
    let completedBookings: Int
    let restaurantSpent: Double
    let adventureSpent: Double
    let totalSpent: Double
    let level: LoyaltyLevel
    let wallet: RewardWalletSnapshot

    static let empty = ProfileStats(
        points: 0,
        completedOrders: 0,
        completedBookings: 0,
        restaurantSpent: 0,
        adventureSpent: 0,
        totalSpent: 0,
        level: .bronze,
        wallet: .empty(nationalId: "")
    )
}

```

---

# Altos del Murco/root/feature/altos/profile/domain/RewardPresentation.swift

```swift
//
//  RewardPresentationModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 21/4/26.
//

import Foundation

struct RewardPresentation: Identifiable, Hashable {
    let id: String
    let badge: String
    let title: String
    let message: String
    let amountText: String?

    init(
        id: String = UUID().uuidString,
        badge: String,
        title: String,
        message: String,
        amountText: String? = nil
    ) {
        self.id = id
        self.badge = badge
        self.title = title
        self.message = message
        self.amountText = amountText
    }

    static func from(appliedReward reward: AppliedReward) -> RewardPresentation {
        let lowered = reward.note.lowercased()
        let badge: String

        if lowered.contains("gratis") {
            badge = "Gratis"
        } else if lowered.contains("%") {
            badge = "Descuento"
        } else {
            badge = "Premio"
        }

        return RewardPresentation(
            id: reward.id,
            badge: badge,
            title: reward.title,
            message: reward.note,
            amountText: reward.amount.priceText
        )
    }
}

enum RewardPresentationFactory {
    static func menuPresentation(
        for item: MenuItem,
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        buildMenuPresentation(
            for: item,
            wallet: wallet,
            includeAdventureScopedTemplates: false
        )
    }

    static func adventureMenuPresentation(
        for item: MenuItem,
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        buildMenuPresentation(
            for: item,
            wallet: wallet,
            includeAdventureScopedTemplates: true
        )
    }

    static func activityPresentation(
        for activity: AdventureActivityCatalogItem,
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        for template in wallet.availableTemplates where template.scope.matchesAdventure() && !template.isExpired {
            switch template.rule.type {
            case .activityPercentage:
                guard template.targetActivityId == activity.id else { continue }

                let percentage = Int((template.rule.percentage ?? 0).rounded())
                guard percentage > 0 else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "\(percentage)% OFF",
                    title: template.title,
                    message: "\(activity.title) tiene \(percentage)% de descuento automático por tu nivel \(wallet.currentLevel.title)."
                )

            default:
                continue
            }
        }

        return nil
    }

    static func packagePresentation(
        for package: AdventureFeaturedPackage,
        catalog: AdventureCatalogSnapshot,
        menuItemsById: [String: MenuItem],
        wallet: RewardWalletSnapshot
    ) -> RewardPresentation? {
        for item in package.items {
            guard let activity = catalog.activity(for: item.activity) else { continue }
            if let presentation = activityPresentation(for: activity, wallet: wallet) {
                return presentation
            }
        }

        for item in package.foodItems {
            guard let menuItem = menuItemsById[item.menuItemId] else { continue }
            if let presentation = adventureMenuPresentation(for: menuItem, wallet: wallet) {
                return presentation
            }
        }

        return nil
    }

    private static func buildMenuPresentation(
        for item: MenuItem,
        wallet: RewardWalletSnapshot,
        includeAdventureScopedTemplates: Bool
    ) -> RewardPresentation? {
        for template in wallet.availableTemplates
        where templateMatchesMenuContext(
            template,
            includeAdventureScopedTemplates: includeAdventureScopedTemplates
        ) && !template.isExpired {
            switch template.rule.type {
            case .freeMenuItem:
                guard template.targetMenuItemId == item.id else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "Gratis",
                    title: template.title,
                    message: "\(item.name) puede salir gratis por tu nivel \(wallet.currentLevel.title)."
                )

            case .specificMenuItemPercentage:
                guard template.targetMenuItemId == item.id else { continue }

                let percentage = Int((template.rule.percentage ?? 0).rounded())
                guard percentage > 0 else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "\(percentage)% OFF",
                    title: template.title,
                    message: "\(item.name) tiene \(percentage)% de descuento automático por tu nivel \(wallet.currentLevel.title)."
                )

            case .buyXGetYFree:
                guard template.targetMenuItemId == item.id else { continue }

                let buyQuantity = max(1, template.rule.buyQuantity ?? 1)
                let freeQuantity = max(1, template.rule.freeQuantity ?? 1)

                return RewardPresentation(
                    id: template.id,
                    badge: "Promo",
                    title: template.title,
                    message: "Compra \(buyQuantity) y recibe \(freeQuantity) gratis."
                )

            case .mostExpensiveMenuItemPercentage:
                let percentage = Int((template.rule.percentage ?? 0).rounded())
                guard percentage > 0 else { continue }

                return RewardPresentation(
                    id: template.id,
                    badge: "\(percentage)% OFF",
                    title: template.title,
                    message: "Puede aplicar \(percentage)% si este plato termina siendo el elegible más caro de tu pedido."
                )

            case .activityPercentage:
                continue
            }
        }

        return nil
    }

    private static func templateMatchesMenuContext(
        _ template: LoyaltyRewardTemplate,
        includeAdventureScopedTemplates: Bool
    ) -> Bool {
        switch template.rule.type {
        case .activityPercentage:
            return false

        case .mostExpensiveMenuItemPercentage,
             .specificMenuItemPercentage,
             .freeMenuItem,
             .buyXGetYFree:
            if includeAdventureScopedTemplates {
                switch template.scope {
                case .restaurant, .adventure, .both:
                    return true
                }
            } else {
                return template.scope.matchesRestaurant()
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/AccountActionsView.swift

```swift
//
//  AccountActionsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import SwiftUI

struct AccountActionsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSignOutDialog = false
    @State private var showDeleteDialog = false

    private let theme: AppSectionTheme = .neutral

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                dangerRow(
                    title: "Cerrar sesión",
                    subtitle: "Cierra tu sesión actual en este dispositivo",
                    systemImage: "rectangle.portrait.and.arrow.right",
                    tint: .orange
                ) {
                    showSignOutDialog = true
                }

                dangerRow(
                    title: "Eliminar cuenta",
                    subtitle: "Elimina permanentemente tu cuenta y perfil",
                    systemImage: "trash.fill",
                    tint: .red
                ) {
                    showDeleteDialog = true
                }
            }
            .padding(16)
        }
        .navigationTitle("Acciones de la cuenta")
        .appScreenStyle(theme)
        .confirmationDialog(
            "¿Cerrar sesión?",
            isPresented: $showSignOutDialog,
            titleVisibility: .visible
        ) {
            Button("Cerrar sesión", role: .destructive) {
                viewModel.signOutTapped()
            }
            Button("Cancelar", role: .cancel) { }
        }
        .confirmationDialog(
            "¿Eliminar cuenta?",
            isPresented: $showDeleteDialog,
            titleVisibility: .visible
        ) {
            Button("Eliminar cuenta", role: .destructive) {
                viewModel.askForDeleteAccount()
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Estas acciones afectan tu cuenta y deben confirmarse primero.")
        }
    }

    private func dangerRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(colorScheme == .dark ? 0.20 : 0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(tint)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(tint.opacity(0.7))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/AppExternalLinks.swift

```swift
//
//  AppExternalLinks.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

enum AppExternalLinks {
    static let instagram = URL(string: "https://instagram.com/altosdelmurco")!
    static let tiktok = URL(string: "https://www.tiktok.com/@altosdelmurco")!
    static let facebook = URL(string: "https://www.facebook.com/altosdelmurco")!
    static let whatsapp = URL(string: "https://wa.me/593000000000")!
    static let maps = URL(string: "https://maps.google.com/?q=Altos+del+Murco")!

    static let supportEmail = URL(string: "mailto:soporte@altosdelmurco.com")!
    static let privacyPolicy = URL(string: "https://altosdelmurco.com/privacy")!
    static let terms = URL(string: "https://altosdelmurco.com/terms")!
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/AppPreferences.swift

```swift
//
//  AppPreferences.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "Sistema"
        case .light: return "Claro"
        case .dark: return "Oscuro"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Seguir la apariencia del dispositivo"
        case .light: return "Usar siempre el modo claro"
        case .dark: return "Usar siempre el modo oscuro"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class AppPreferences: ObservableObject {
    private enum Keys {
        static let appearance = "altos_del_murco_app_appearance"
    }

    @Published var appearance: AppAppearance {
        didSet {
            defaults.set(appearance.rawValue, forKey: Keys.appearance)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedValue = defaults.string(forKey: Keys.appearance)
        self.appearance = AppAppearance(rawValue: storedValue ?? "") ?? .system
    }

    var preferredColorScheme: ColorScheme? {
        appearance.colorScheme
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/AppearanceSettingsView.swift

```swift
//
//  AppearanceSettingsView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

import SwiftUI

struct AppearanceSettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let theme: AppSectionTheme = .neutral

    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apariencia")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)
                    
                    Text("Elige cómo se verá la app en toda la interfaz.")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                ForEach(AppAppearance.allCases) { appearance in
                    Button {
                        viewModel.updateAppearance(appearance)
                    } label: {
                        HStack(spacing: 14) {
                            BrandIconBubble(
                                theme: theme,
                                systemImage: icon(for: appearance),
                                size: 44
                            )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(appearance.title)
                                    .font(.headline)
                                    .foregroundStyle(palette.textPrimary)

                                Text(appearance.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            if viewModel.currentAppearance == appearance {
                                ZStack {
                                    Circle()
                                        .fill(palette.heroGradient)
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(palette.onPrimary)
                                }
                            } else {
                                Circle()
                                    .stroke(palette.stroke, lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Apariencia")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(theme)
    }
    
    private func icon(for appearance: AppAppearance) -> String {
        switch appearance {
        case .system:
            return "iphone"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/DeleteAccountConfirmationView.swift

```swift
//
//  DeleteAccountConfirmationView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI
import AuthenticationServices

struct DeleteAccountConfirmationView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .neutral, scheme: colorScheme)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BrandScreenBackground(theme: .neutral)
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        consequencesCard
                        actionSection
                        
                        if viewModel.isDeletingAccount {
                            ProgressView("Eliminando cuenta...")
                                .tint(palette.destructive)
                                .foregroundStyle(palette.textSecondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Confirmar eliminación")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .tint(palette.primary)
    }
    
    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(palette.destructive.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(palette.destructive.opacity(0.25), lineWidth: 1)
                    )
                
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(palette.destructive)
            }
            
            VStack(spacing: 10) {
                Text("Eliminar cuenta")
                    .font(.title2.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("Esta acción es permanente. Tu perfil será eliminado y perderás el acceso a tu cuenta.")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var consequencesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            warningRow(
                systemImage: "person.crop.circle.badge.xmark",
                text: "Tu perfil de cliente será eliminado"
            )
            
            warningRow(
                systemImage: "rectangle.portrait.and.arrow.right",
                text: "Se cerrará tu sesión inmediatamente"
            )
            
            warningRow(
                systemImage: "exclamationmark.triangle.fill",
                text: "Esta acción no se puede deshacer"
            )
        }
        .appCardStyle(.neutral, emphasized: true)
    }
    
    private var actionSection: some View {
        VStack(spacing: 14) {
            Text("Para continuar, confirma tu identidad con Apple.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            
            SignInWithAppleButton(
                onRequest: viewModel.onDeleteRequest,
                onCompletion: viewModel.onDeleteCompletion
            )
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(height: 56)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.08),
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }
    
    private func warningRow(systemImage: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.destructive.opacity(colorScheme == .dark ? 0.18 : 0.10))
                    .frame(width: 36, height: 36)
                
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.destructive)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(palette.textPrimary)
            
            Spacer()
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/EditProfileView.swift

```swift
//
//  EditProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: EditProfileViewModel
    
    private let theme: AppSectionTheme = .neutral

    init(viewModelFactory: @escaping () -> EditProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    ProfileFieldSection(theme: theme, title: "Cuenta") {
                        ReadOnlyFieldCard(
                            theme: theme,
                            title: "Correo electrónico",
                            value: viewModel.email.isEmpty ? "Oculto por Apple" : viewModel.email
                        )
                    }

                    ProfileFieldSection(theme: theme, title: "Información personal") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Nombre completo",
                            placeholder: "Ingresa tu nombre completo",
                            text: $viewModel.fullName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Número de cédula",
                            placeholder: "Ejemplo: 0501234567",
                            text: $viewModel.nationalId,
                            keyboardType: .numberPad
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Número de teléfono",
                            placeholder: "Ejemplo: 0987654321",
                            text: $viewModel.phoneNumber,
                            keyboardType: .phonePad
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Fecha de nacimiento", systemImage: "calendar")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            DatePicker(
                                "Fecha de nacimiento",
                                selection: $viewModel.birthday,
                                in: viewModel.validBirthdayRange,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .tint(palette.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .frame(minHeight: AppTheme.Metrics.fieldHeight)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                    .fill(palette.elevatedCard)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                    .stroke(palette.stroke, lineWidth: 1)
                            )
                        }
                    }

                    ProfileFieldSection(theme: theme, title: "Dirección") {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Dirección", systemImage: "house")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            TextField("Calle, referencia, sector...", text: $viewModel.address, axis: .vertical)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .foregroundStyle(palette.textPrimary)
                                .tint(palette.primary)
                                .padding(16)
                                .frame(minHeight: 110, alignment: .topLeading)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                        .fill(palette.elevatedCard)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                        .stroke(palette.stroke, lineWidth: 1)
                                )
                        }
                    }

                    ProfileFieldSection(theme: theme, title: "Contacto de emergencia") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Nombre del contacto de emergencia",
                            placeholder: "¿A quién debemos contactar si es necesario?",
                            text: $viewModel.emergencyContactName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Teléfono del contacto de emergencia",
                            placeholder: "Ejemplo: 0999999999",
                            text: $viewModel.emergencyContactPhone,
                            keyboardType: .phonePad
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(palette.destructive)
                            
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(palette.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .fill(palette.destructive.opacity(colorScheme == .dark ? 0.14 : 0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                                .stroke(palette.destructive.opacity(0.25), lineWidth: 1)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.saveChanges()
                    } label: {
                        if viewModel.isSaving {
                            ProgressView()
                                .tint(palette.primary)
                        } else {
                            Text("Guardar")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                }
            }
            .onChange(of: viewModel.isSaving) { _, isSaving in
                if !isSaving, viewModel.errorMessage == nil {
                    dismiss()
                }
            }
        }
        .appScreenStyle(theme)
    }
}

private struct ProfileFieldSection<Content: View>: View {
    let theme: AppSectionTheme
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(theme: theme, title: title)
            content
        }
        .appCardStyle(theme)
    }
}

private struct EditableFieldCard: View {
    let theme: AppSectionTheme
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(keyboardType == .default ? .words : .never)
                .autocorrectionDisabled()
                .appTextFieldStyle(theme)
        }
    }
}

private struct ReadOnlyFieldCard: View {
    let theme: AppSectionTheme
    let title: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.bold())

            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .frame(minHeight: AppTheme.Metrics.fieldHeight)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
                .foregroundStyle(palette.textSecondary)
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/LoyaltyProgramView.swift

```swift
//
//  LoyaltyProgramView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 20/4/26.
//

import SwiftUI

struct LoyaltyProgramView: View {
    @Environment(\.colorScheme) private var colorScheme

    private let theme: AppSectionTheme = .neutral

    let currentLevel: LoyaltyLevel
    let totalSpent: Double
    let points: Int
    let completedOrders: Int
    let completedBookings: Int
    var walletSnapshot: RewardWalletSnapshot = .empty(nationalId: "")

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var nextLevel: LoyaltyLevel? {
        currentLevel.nextLevel
    }

    private var progressToNextLevel: Double {
        LoyaltyLevel.progress(for: totalSpent)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroSection
                progressSection
                availableRewardsSection
                reservedRewardsSection
                usedRewardsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .navigationTitle("Murco Loyalty")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(theme)
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(palette.chipGradient)
                        .frame(width: 68, height: 68)

                    Image(systemName: currentLevel.systemImage)
                        .font(.title2.bold())
                        .foregroundStyle(palette.primary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Nivel \(currentLevel.title)")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(currentLevel.badgeSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text("Consumo acumulado: \(totalSpent.priceText)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primary)
                }

                Spacer()
            }

            HStack(spacing: 12) {
                statCard("Puntos", "\(points)")
                statCard("Pedidos", "\(completedOrders)")
                statCard("Reservas", "\(completedBookings)")
            }
        }
        .appCardStyle(theme)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: theme,
                title: "Tu progreso",
                subtitle: nextLevel == nil
                    ? "Ya estás en la cima del programa."
                    : "Sigue acumulando para desbloquear tu próximo premio fuerte."
            )

            if let nextLevel {
                HStack {
                    Text("Próximo nivel: \(nextLevel.title)")
                        .font(.headline)

                    Spacer()

                    Text(nextLevel.spendRangeText)
                        .font(.caption.bold())
                        .foregroundStyle(palette.primary)
                }

                ProgressView(value: progressToNextLevel)
                    .tint(palette.primary)

                Text("Te faltan \(currentLevel.remainingSpend(from: totalSpent).priceText) para subir.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(theme, emphasized: false)
    }

    private var availableRewardsSection: some View {
        rewardSection(
            title: "Premios disponibles",
            subtitle: "Estos se aplican automáticamente cuando el pedido o la reserva cumplen la regla.",
            emptyText: "Todavía no tienes premios automáticos disponibles para tu nivel."
        ) {
            walletSnapshot.availableTemplates.map { template in
                AnyView(
                    HStack(alignment: .top, spacing: 12) {
                        BrandIconBubble(theme: theme, systemImage: "gift.fill", size: 42)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.title).font(.headline)
                            Text(template.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(palette.textSecondary)
                            Text(template.displaySummary)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.primary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                )
            }
        }
    }

    private var reservedRewardsSection: some View {
        rewardSection(
            title: "Premios reservados",
            subtitle: "Ya están apartados en un pedido o reserva pendiente.",
            emptyText: "No tienes premios reservados ahora mismo."
        ) {
            walletSnapshot.reservedEvents.map { event in
                AnyView(
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.templateTitle).font(.headline)
                            Text(event.referenceType == .order ? "Pedido \(event.referenceId)" : "Reserva \(event.referenceId)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.amount.priceText)
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                )
            }
        }
    }

    private var usedRewardsSection: some View {
        rewardSection(
            title: "Historial de premios usados",
            subtitle: "Tus beneficios ya consumidos.",
            emptyText: "Todavía no has usado premios."
        ) {
            walletSnapshot.consumedEvents.map { event in
                AnyView(
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.templateTitle).font(.headline)
                            Text(event.referenceType == .order ? "Pedido \(event.referenceId)" : "Reserva \(event.referenceId)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(event.amount.priceText)
                            .font(.subheadline.bold())
                            .foregroundStyle(.green)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.elevatedCard)
                    )
                )
            }
        }
    }

    @ViewBuilder
    private func rewardSection(
        title: String,
        subtitle: String,
        emptyText: String,
        rows: () -> [AnyView]
    ) -> some View {
        let content = rows()

        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(theme: theme, title: title, subtitle: subtitle)

            if content.isEmpty {
                Text(emptyText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                ForEach(Array(content.enumerated()), id: \.offset) { _, row in
                    row
                }
            }
        }
        .appCardStyle(theme)
    }

    private func statCard(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileAccountHubView.swift

```swift
//
//  ProfileAccountHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct ProfileAccountHubView: View {
    @ObservedObject var viewModel: ProfileViewModel

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                actionRow(
                    title: "Información personal",
                    subtitle: "Edita tus datos de contacto y emergencia",
                    systemImage: "person.text.rectangle"
                ) {
                    viewModel.openEditProfile()
                }

                actionRow(
                    title: "Recompensas y puntos",
                    subtitle: "\(viewModel.stats.level.title) • \(viewModel.stats.points) puntos",
                    systemImage: "gift.fill"
                ) { }

                actionRow(
                    title: "Beneficios de cumpleaños",
                    subtitle: "Se usa para promociones y descuentos especiales",
                    systemImage: "birthday.cake.fill"
                ) { }

                NavigationLink {
                    AccountActionsView(viewModel: viewModel)
                } label: {
                    row(
                        title: "Acciones de la cuenta",
                        subtitle: "Cerrar sesión y otras acciones sensibles de la cuenta",
                        systemImage: "exclamationmark.shield.fill"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("Cuenta")
        .appScreenStyle(theme)
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            row(title: title, subtitle: subtitle, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func row(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: theme, systemImage: systemImage, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(theme)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileAlertItem.swift

```swift
//
//  ProfileAlertItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct ProfileAlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileContainerView.swift

```swift
//
//  ProfileContainerView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct ProfileContainerView: View {
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @EnvironmentObject private var appPreferences: AppPreferences

    var body: some View {
        Group {
            if let factory = sessionViewModel.makeProfileViewModelFactory(appPreferences: appPreferences) {
                ProfileView(viewModelFactory: factory)
                    .appScreenStyle(.neutral)
            } else {
                NavigationStack {
                    ZStack {
                        BrandScreenBackground(theme: .neutral)
                        
                        VStack(spacing: 18) {
                            ProgressView()
                                .scaleEffect(1.1)
                            
                            VStack(spacing: 6) {
                                Text("Cargando perfil...")
                                    .font(.headline)
                                
                                Text("Preparando tu cuenta y preferencias.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .appCardStyle(.neutral, emphasized: true)
                        .padding()
                    }
                    .navigationTitle("Perfil")
                    .appScreenStyle(.neutral)
                }
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfilePreferencesHubView.swift

```swift
//
//  ProfilePreferencesHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import SwiftUI

struct ProfilePreferencesHubView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.openURL) private var openURL

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                NavigationLink {
                    AppearanceSettingsView(viewModel: viewModel)
                } label: {
                    row(
                        title: "Apariencia",
                        subtitle: viewModel.appearanceTitle,
                        systemImage: "circle.lefthalf.filled"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(settingsURL)
                } label: {
                    row(
                        title: "Permisos de la app",
                        subtitle: "Notificaciones, ubicación y ajustes del dispositivo",
                        systemImage: "gearshape.2.fill"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("Preferencias")
        .appScreenStyle(theme)
    }

    private func row(
        title: String,
        subtitle: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: theme, systemImage: systemImage, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(theme)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileSupportHubView.swift

```swift
//
//  ProfileSupportHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import SwiftUI

struct ProfileSupportHubView: View {
    @Environment(\.openURL) private var openURL

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                supportRow(
                    title: "Ayuda y soporte",
                    subtitle: "Escribe a nuestro equipo de soporte",
                    systemImage: "questionmark.circle.fill",
                    tint: .teal,
                    url: AppExternalLinks.supportEmail
                )

                supportRow(
                    title: "Política de privacidad",
                    subtitle: "Lee cómo se usan tus datos",
                    systemImage: "hand.raised.fill",
                    tint: .indigo,
                    url: AppExternalLinks.privacyPolicy
                )

                supportRow(
                    title: "Términos y condiciones",
                    subtitle: "Términos de la app y del servicio",
                    systemImage: "doc.text.fill",
                    tint: .brown,
                    url: AppExternalLinks.terms
                )
            }
            .padding(16)
        }
        .navigationTitle("Ayuda y soporte")
        .appScreenStyle(theme)
    }

    private func supportRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        url: URL
    ) -> some View {
        Button {
            openURL(url)
        } label: {
            HStack(spacing: 14) {
                BrandIconBubble(theme: theme, systemImage: systemImage, size: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.tertiary)
            }
            .appCardStyle(theme)
        }
        .buttonStyle(.plain)
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileView.swift

```swift
//
//  ProfileView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import PhotosUI
import SwiftUI

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let theme: AppSectionTheme = .neutral

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    init(viewModelFactory: @escaping () -> ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModelFactory())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    statsSection
                    mainMenuSection
                    socialCompactSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Perfil")
            .appScreenStyle(theme)
            .sheet(isPresented: $viewModel.isShowingEditProfile) {
                EditProfileView(
                    viewModelFactory: { viewModel.makeEditProfileViewModel() }
                )
            }
            .sheet(isPresented: $viewModel.isShowingDeleteAccountSheet) {
                DeleteAccountConfirmationView(viewModel: viewModel)
            }
            .alert(item: $viewModel.alertItem) { item in
                Alert(
                    title: Text(item.title),
                    message: Text(item.message),
                    dismissButton: .default(Text("Aceptar"))
                )
            }
            .onAppear {
                viewModel.onAppear()
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }

                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            viewModel.uploadProfileImage(data: data)
                        }
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                avatarView

                /*
                HStack(spacing: 10) {
                    if viewModel.hasProfileImage {
                        Button {
                            viewModel.removeProfileImage()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(Circle().fill(.red))
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(palette.primary)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                    }
                }
                .offset(x: 4, y: 4)
                 */
            }

            VStack(spacing: 6) {
                Text(viewModel.displayName)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)

                Text(viewModel.emailText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)

                Label("Miembro desde \(viewModel.memberSinceText)", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }

            HStack(spacing: 10) {
                compactInfoCard(
                    title: "Teléfono",
                    value: viewModel.phoneText,
                    systemImage: "phone.fill"
                )

                compactInfoCard(
                    title: "Cumpleaños",
                    value: viewModel.birthdayText,
                    systemImage: "birthday.cake.fill"
                )
            }

            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: theme,
                    systemImage: "house.fill",
                    size: 38
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("Dirección")
                        .font(.caption.bold())
                        .foregroundStyle(palette.textSecondary)

                    Text(viewModel.addressText)
                        .font(.subheadline)
                        .foregroundStyle(palette.textPrimary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(palette.elevatedCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme, emphasized: false)
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(palette.heroGradient)
                .frame(width: 112, height: 112)
                .overlay(
                    Circle()
                        .stroke(
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.32),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.12),
                    radius: 16,
                    x: 0,
                    y: 10
                )

            if let avatarImage = viewModel.avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
            } else {
                Text(viewModel.displayName.initials)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onPrimary)
            }

            if viewModel.isUploadingProfileImage {
                Circle()
                    .fill(.black.opacity(0.35))
                    .frame(width: 112, height: 112)

                ProgressView()
                    .tint(.white)
            }
        }
    }

    private func compactInfoCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)

                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textSecondary)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var statsSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Resumen")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                Spacer()
            }

            levelCard

            HStack(spacing: 12) {
                profileStatCard(
                    title: "Puntos",
                    value: "\(viewModel.stats.points)",
                    systemImage: "star.fill"
                )

                profileStatCard(
                    title: "Pedidos",
                    value: "\(viewModel.stats.completedOrders)",
                    systemImage: "fork.knife"
                )

                profileStatCard(
                    title: "Reservas",
                    value: "\(viewModel.stats.completedBookings)",
                    systemImage: "calendar"
                )
            }

            HStack(spacing: 12) {
                profileStatCard(
                    title: "Restaurante",
                    value: viewModel.stats.restaurantSpent.priceText,
                    systemImage: "takeoutbag.and.cup.and.straw.fill"
                )

                profileStatCard(
                    title: "Aventura",
                    value: viewModel.stats.adventureSpent.priceText,
                    systemImage: "figure.hiking"
                )
            }
        }
    }

    private var levelCard: some View {
        NavigationLink {
            LoyaltyProgramView(
                currentLevel: viewModel.stats.level,
                totalSpent: viewModel.stats.totalSpent,
                points: viewModel.stats.points,
                completedOrders: viewModel.stats.completedOrders,
                completedBookings: viewModel.stats.completedBookings,
                walletSnapshot: viewModel.stats.wallet
            )
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(palette.chipGradient)
                            .frame(width: 60, height: 60)

                        Image(systemName: viewModel.stats.level.systemImage)
                            .font(.title3.bold())
                            .foregroundStyle(palette.primary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nivel \(viewModel.stats.level.title)")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(viewModel.stats.level.badgeSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)

                        Text("Consumo acumulado: \(viewModel.stats.totalSpent.priceText)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.primary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(palette.primary)
                }

                Text("Vuelve, acumula y desbloquea descuentos, regalos y premios gratis en platos, jugos, bebidas y postres.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textPrimary)

                if let nextLevel = viewModel.stats.level.nextLevel {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Progreso a \(nextLevel.title)")
                                .font(.caption.bold())
                                .foregroundStyle(palette.textSecondary)

                            Spacer()

                            Text("\(Int(LoyaltyLevel.progress(for: viewModel.stats.totalSpent) * 100))%")
                                .font(.caption.bold())
                                .foregroundStyle(palette.primary)
                        }

                        ProgressView(value: LoyaltyLevel.progress(for: viewModel.stats.totalSpent))
                            .tint(palette.primary)

                        Text("Te faltan \(viewModel.stats.level.remainingSpend(from: viewModel.stats.totalSpent).priceText) para subir.")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(palette.textSecondary)
                    }
                } else {
                    Label("Ya estás en el nivel más alto", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.primary)
                }

                HStack(spacing: 10) {
                    loyaltyMiniStat(
                        title: "Puntos",
                        value: "\(viewModel.stats.points)",
                        systemImage: "star.fill"
                    )

                    loyaltyMiniStat(
                        title: "Pedidos",
                        value: "\(viewModel.stats.completedOrders)",
                        systemImage: "fork.knife"
                    )

                    loyaltyMiniStat(
                        title: "Reservas",
                        value: "\(viewModel.stats.completedBookings)",
                        systemImage: "calendar"
                    )
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.14 : 0.06),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
    }

    private func loyaltyMiniStat(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(palette.primary)

            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func profileStatCard(
        title: String,
        value: String,
        systemImage: String
    ) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(palette.primary)
            }

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.14 : 0.06),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    private var mainMenuSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Configuración")

            NavigationLink {
                ProfileAccountHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Cuenta",
                    subtitle: "Información personal, recompensas y acciones de la cuenta",
                    systemImage: "person.crop.circle",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfilePreferencesHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Preferencias",
                    subtitle: "Apariencia y permisos de la app",
                    systemImage: "slider.horizontal.3",
                    tint: .purple
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfileSupportHubView()
            } label: {
                navigationRow(
                    title: "Ayuda y soporte",
                    subtitle: "Soporte, política de privacidad y términos",
                    systemImage: "questionmark.circle",
                    tint: .teal
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var socialCompactSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Redes y visítanos")

            HStack(spacing: 14) {
                socialIconButton(
                    systemImage: "camera.fill",
                    action: { openURL(AppExternalLinks.instagram) }
                )

                socialIconButton(
                    systemImage: "music.note.tv",
                    action: { openURL(AppExternalLinks.tiktok) }
                )

                socialIconButton(
                    systemImage: "f.cursive.circle.fill",
                    action: { openURL(AppExternalLinks.facebook) }
                )

                socialIconButton(
                    systemImage: "message.fill",
                    action: { openURL(AppExternalLinks.whatsapp) }
                )

                socialIconButton(
                    systemImage: "map.fill",
                    action: { openURL(AppExternalLinks.maps) }
                )
            }
            .frame(maxWidth: .infinity)
            .appCardStyle(theme)
        }
    }

    private func socialIconButton(
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 52, height: 52)

                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(palette.primary)
            }
            .overlay(
                Circle()
                    .stroke(palette.stroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            Text("Altos del Murco")
                .font(.footnote.bold())
                .foregroundStyle(palette.textPrimary)

            Text(Bundle.main.appVersionDescription)
                .font(.caption)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
            Spacer()
        }
    }

    private func navigationRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        baseRow(
            title: title,
            subtitle: subtitle,
            systemImage: systemImage,
            tint: tint
        )
    }

    private func baseRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.20 : 0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(palette.textTertiary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/viewmodel/CompleteProfileViewModel.swift

```swift
//
//  CompleteProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 19/4/26.
//

import Combine
import Foundation

@MainActor
final class CompleteProfileViewModel: ObservableObject {
    @Published var fullName: String
    @Published var nationalId: String
    @Published var phoneNumber: String
    @Published var birthday: Date
    @Published var address: String
    @Published var emergencyContactName: String
    @Published var emergencyContactPhone: String

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    let validBirthdayRange: ClosedRange<Date>

    private let authenticatedUser: AuthenticatedUser
    private let existingProfile: ClientProfile?
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let onCompleted: @MainActor (ClientProfile) -> Void

    init(
        authenticatedUser: AuthenticatedUser,
        existingProfile: ClientProfile?,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        onCompleted: @escaping @MainActor (ClientProfile) -> Void
    ) {
        self.authenticatedUser = authenticatedUser
        self.existingProfile = existingProfile
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.onCompleted = onCompleted

        let now = Date()
        let minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: now) ?? now
        self.validBirthdayRange = minimumDate...now

        self.fullName = existingProfile?.fullName ?? authenticatedUser.displayName
        self.nationalId = existingProfile?.nationalId ?? ""
        self.phoneNumber = existingProfile?.phoneNumber ?? ""
        self.birthday = existingProfile?.birthday ?? Calendar.current.date(byAdding: .year, value: -18, to: now) ?? now
        self.address = existingProfile?.address ?? ""
        self.emergencyContactName = existingProfile?.emergencyContactName ?? ""
        self.emergencyContactPhone = existingProfile?.emergencyContactPhone ?? ""
    }

    var canSubmit: Bool {
        !fullName.trimmed.isEmpty &&
        nationalId.digitsOnly.count >= 8 &&
        phoneNumber.digitsOnly.count >= 8 &&
        !address.trimmed.isEmpty &&
        !emergencyContactName.trimmed.isEmpty &&
        emergencyContactPhone.digitsOnly.count >= 8 &&
        birthday <= Date()
    }

    func saveProfile() {
        guard canSubmit else {
            errorMessage = "Please complete all required fields correctly."
            return
        }

        errorMessage = nil
        isSaving = true

        let now = Date()
        let profile = ClientProfile(
            id: authenticatedUser.uid,
            email: authenticatedUser.email,
            appleUserIdentifier: authenticatedUser.appleUserIdentifier,
            fullName: fullName.trimmed,
            nationalId: nationalId.digitsOnly,
            phoneNumber: phoneNumber.digitsOnly,
            birthday: birthday,
            address: address.trimmed,
            emergencyContactName: emergencyContactName.trimmed,
            emergencyContactPhone: emergencyContactPhone.digitsOnly,
            isProfileComplete: true,
            createdAt: existingProfile?.createdAt ?? now,
            updatedAt: now,
            profileCompletedAt: existingProfile?.profileCompletedAt ?? now,
            profileImageURL: existingProfile?.profileImageURL,
            profileImagePath: existingProfile?.profileImagePath
        )

        Task {
            do {
                try await completeClientProfileUseCase.execute(profile: profile)
                isSaving = false
                onCompleted(profile)
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/viewmodel/EditProfileViewModel.swift

```swift
//
//  EditProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import Foundation

@MainActor
final class EditProfileViewModel: ObservableObject {
    @Published var fullName: String
    @Published var nationalId: String
    @Published var phoneNumber: String
    @Published var birthday: Date
    @Published var address: String
    @Published var emergencyContactName: String
    @Published var emergencyContactPhone: String

    @Published private(set) var isSaving = false
    @Published var errorMessage: String?

    private let originalProfile: ClientProfile
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let onSaved: @MainActor (ClientProfile) -> Void

    let validBirthdayRange: ClosedRange<Date>

    init(
        profile: ClientProfile,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        onSaved: @escaping @MainActor (ClientProfile) -> Void
    ) {
        self.originalProfile = profile
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.onSaved = onSaved

        let now = Date()
        let minimumDate = Calendar.current.date(byAdding: .year, value: -100, to: now) ?? now
        self.validBirthdayRange = minimumDate...now

        self.fullName = profile.fullName
        self.nationalId = profile.nationalId
        self.phoneNumber = profile.phoneNumber
        self.birthday = profile.birthday
        self.address = profile.address
        self.emergencyContactName = profile.emergencyContactName
        self.emergencyContactPhone = profile.emergencyContactPhone
    }

    var email: String {
        originalProfile.email
    }

    var canSave: Bool {
        !fullName.trimmed.isEmpty &&
        nationalId.digitsOnly.count >= 8 &&
        phoneNumber.digitsOnly.count >= 8 &&
        !address.trimmed.isEmpty &&
        !emergencyContactName.trimmed.isEmpty &&
        emergencyContactPhone.digitsOnly.count >= 8
    }

    func saveChanges() {
        guard canSave else {
            errorMessage = "Please complete all required fields correctly."
            return
        }

        errorMessage = nil
        isSaving = true

        let updatedProfile = ClientProfile(
            id: originalProfile.id,
            email: originalProfile.email,
            appleUserIdentifier: originalProfile.appleUserIdentifier,
            fullName: fullName.trimmed,
            nationalId: nationalId.digitsOnly,
            phoneNumber: phoneNumber.digitsOnly,
            birthday: birthday,
            address: address.trimmed,
            emergencyContactName: emergencyContactName.trimmed,
            emergencyContactPhone: emergencyContactPhone.digitsOnly,
            isProfileComplete: true,
            createdAt: originalProfile.createdAt,
            updatedAt: Date(),
            profileCompletedAt: originalProfile.profileCompletedAt ?? Date(),
            profileImageURL: originalProfile.profileImageURL,
            profileImagePath: originalProfile.profileImagePath
        )

        Task {
            do {
                try await completeClientProfileUseCase.execute(profile: updatedProfile)
                isSaving = false
                onSaved(updatedProfile)
            } catch {
                isSaving = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/profile/presentation/viewmodel/ProfileViewModel.swift

```swift
//
//  ProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Combine
import AuthenticationServices
import Foundation
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: ClientProfile
    @Published private(set) var stats: ProfileStats = .empty
    @Published var avatarImage: UIImage?
    @Published private(set) var isLoadingStats = false
    @Published private(set) var isUploadingProfileImage = false

    @Published var isShowingEditProfile = false
    @Published var isShowingDeleteAccountSheet = false
    @Published var alertItem: ProfileAlertItem?
    @Published private(set) var isDeletingAccount = false

    private let appPreferences: AppPreferences
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let profileImageStorageService: ProfileImageStorageService
    private let profileStatsService: ProfileStatsService
    private let onProfileUpdated: @MainActor (ClientProfile) -> Void
    private let onSignOut: @MainActor () -> Void
    private let onAccountDeleted: @MainActor () -> Void

    private var deleteNonce: String?
    private var statsListenerToken: ProfileStatsListenerToken?

    init(
        initialProfile: ClientProfile,
        appPreferences: AppPreferences,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        profileImageStorageService: ProfileImageStorageService,
        profileStatsService: ProfileStatsService,
        onProfileUpdated: @escaping @MainActor (ClientProfile) -> Void,
        onSignOut: @escaping @MainActor () -> Void,
        onAccountDeleted: @escaping @MainActor () -> Void
    ) {
        self.profile = initialProfile
        self.appPreferences = appPreferences
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.profileImageStorageService = profileImageStorageService
        self.profileStatsService = profileStatsService
        self.onProfileUpdated = onProfileUpdated
        self.onSignOut = onSignOut
        self.onAccountDeleted = onAccountDeleted

        Task {
            await loadAvatar()
            startObservingStats()
        }
    }

    var displayName: String {
        profile.fullName.isEmpty ? "Guest User" : profile.fullName
    }

    var emailText: String {
        profile.email.isEmpty ? "Hidden by Apple" : profile.email
    }

    var phoneText: String {
        profile.phoneNumber.isEmpty ? "Not provided" : profile.phoneNumber
    }

    var birthdayText: String {
        profile.birthday.formatted(date: .long, time: .omitted)
    }

    var addressText: String {
        profile.address.isEmpty ? "Not provided" : profile.address
    }

    var memberSinceText: String {
        profile.createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    var appearanceTitle: String {
        appPreferences.appearance.title
    }

    var currentAppearance: AppAppearance {
        appPreferences.appearance
    }

    var hasProfileImage: Bool {
        profile.hasProfileImage || avatarImage != nil
    }

    func onAppear() {
        startObservingStats()
    }

    func updateAppearance(_ appearance: AppAppearance) {
        appPreferences.appearance = appearance
        objectWillChange.send()
    }

    func openEditProfile() {
        isShowingEditProfile = true
    }

    func signOutTapped() {
        onSignOut()
    }

    func askForDeleteAccount() {
        isShowingDeleteAccountSheet = true
    }

    func handleProfileSaved(_ updatedProfile: ClientProfile) {
        profile = updatedProfile
        onProfileUpdated(updatedProfile)

        Task {
            await loadAvatar()
            startObservingStats()
        }
    }

    func makeEditProfileViewModel() -> EditProfileViewModel {
        EditProfileViewModel(
            profile: profile,
            completeClientProfileUseCase: completeClientProfileUseCase,
            onSaved: { [weak self] updatedProfile in
                self?.handleProfileSaved(updatedProfile)
            }
        )
    }


    private func startObservingStats() {
        statsListenerToken?.remove()
        statsListenerToken = nil

        let nationalId = profile.nationalId.filter(\.isNumber)
        guard !nationalId.isEmpty else {
            stats = .empty
            isLoadingStats = false
            return
        }

        isLoadingStats = true

        statsListenerToken = profileStatsService.observeStats(for: nationalId) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let stats):
                self.stats = stats
                self.isLoadingStats = false

            case .failure(let error):
                self.isLoadingStats = false
                self.alertItem = ProfileAlertItem(
                    title: "Could not load profile stats",
                    message: error.localizedDescription
                )
            }
        }
    }

    func refreshStats() async {
        let nationalId = profile.nationalId.filter(\.isNumber)
        guard !nationalId.isEmpty else {
            stats = .empty
            return
        }

        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            stats = try await profileStatsService.loadStats(for: nationalId)
        } catch {
            alertItem = ProfileAlertItem(
                title: "Could not load profile stats",
                message: error.localizedDescription
            )
        }
    }

    func uploadProfileImage(data: Data) {
        isUploadingProfileImage = true
        alertItem = nil

        Task {
            do {
                let uploaded = try await profileImageStorageService.uploadProfileImage(
                    data: data,
                    userId: profile.id,
                    replacing: profile.profileImagePath
                )

                _ = try ProfileImageCache.shared.saveImageData(
                    UIImage(data: data)?.jpegData(compressionQuality: 0.82) ?? data,
                    for: profile.id
                )

                let updatedProfile = ClientProfile(
                    id: profile.id,
                    email: profile.email,
                    appleUserIdentifier: profile.appleUserIdentifier,
                    fullName: profile.fullName,
                    nationalId: profile.nationalId,
                    phoneNumber: profile.phoneNumber,
                    birthday: profile.birthday,
                    address: profile.address,
                    emergencyContactName: profile.emergencyContactName,
                    emergencyContactPhone: profile.emergencyContactPhone,
                    isProfileComplete: profile.isProfileComplete,
                    createdAt: profile.createdAt,
                    updatedAt: Date(),
                    profileCompletedAt: profile.profileCompletedAt,
                    profileImageURL: uploaded.downloadURL,
                    profileImagePath: uploaded.storagePath
                )

                try await completeClientProfileUseCase.execute(profile: updatedProfile)
                avatarImage = ProfileImageCache.shared.loadImage(for: profile.id)
                handleProfileSaved(updatedProfile)
            } catch {
                alertItem = ProfileAlertItem(
                    title: "Could not update profile photo",
                    message: error.localizedDescription
                )
            }

            isUploadingProfileImage = false
        }
    }

    func removeProfileImage() {
        isUploadingProfileImage = true
        alertItem = nil

        Task {
            do {
                try await profileImageStorageService.deleteProfileImage(path: profile.profileImagePath)
                ProfileImageCache.shared.removeImage(for: profile.id)

                let updatedProfile = ClientProfile(
                    id: profile.id,
                    email: profile.email,
                    appleUserIdentifier: profile.appleUserIdentifier,
                    fullName: profile.fullName,
                    nationalId: profile.nationalId,
                    phoneNumber: profile.phoneNumber,
                    birthday: profile.birthday,
                    address: profile.address,
                    emergencyContactName: profile.emergencyContactName,
                    emergencyContactPhone: profile.emergencyContactPhone,
                    isProfileComplete: profile.isProfileComplete,
                    createdAt: profile.createdAt,
                    updatedAt: Date(),
                    profileCompletedAt: profile.profileCompletedAt,
                    profileImageURL: nil,
                    profileImagePath: nil
                )

                try await completeClientProfileUseCase.execute(profile: updatedProfile)
                avatarImage = nil
                handleProfileSaved(updatedProfile)
            } catch {
                alertItem = ProfileAlertItem(
                    title: "Could not delete profile photo",
                    message: error.localizedDescription
                )
            }

            isUploadingProfileImage = false
        }
    }

    private func loadAvatar() async {
        if let cached = ProfileImageCache.shared.loadImage(for: profile.id) {
            avatarImage = cached
            return
        }

        guard let urlString = profile.profileImageURL,
              let url = URL(string: urlString) else {
            avatarImage = nil
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = try ProfileImageCache.shared.saveImageData(data, for: profile.id) {
                avatarImage = image
            }
        } catch {
            avatarImage = nil
        }
    }

    func onDeleteRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = []

        let nonce = AppleNonce.randomNonceString()
        deleteNonce = nonce
        request.nonce = AppleNonce.sha256(nonce)
    }

    func onDeleteCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                await handleDeleteAuthorization(authorization)
            }

        case .failure(let error):
            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                return
            }

            alertItem = ProfileAlertItem(
                title: "Deletion cancelled",
                message: error.localizedDescription
            )
        }
    }

    private func handleDeleteAuthorization(_ authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            alertItem = ProfileAlertItem(
                title: "Unable to continue",
                message: "Could not read your Apple credential."
            )
            return
        }

        guard let nonce = deleteNonce else {
            alertItem = ProfileAlertItem(
                title: "Invalid state",
                message: "Please try deleting the account again."
            )
            return
        }

        guard let identityToken = credential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            alertItem = ProfileAlertItem(
                title: "Unable to continue",
                message: "Could not read the Apple identity token."
            )
            return
        }

        isDeletingAccount = true

        do {
            try await profileImageStorageService.deleteProfileImage(path: profile.profileImagePath)
            ProfileImageCache.shared.removeImage(for: profile.id)

            try await deleteCurrentAccountUseCase.execute(
                currentUserId: profile.id,
                idToken: idToken,
                rawNonce: nonce
            )
            isDeletingAccount = false
            onAccountDeleted()
        } catch {
            isDeletingAccount = false
            alertItem = ProfileAlertItem(
                title: "Could not delete account",
                message: error.localizedDescription
            )
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/data/remote/dto/MenuItemDto.swift

```swift
//
//  MenuItemDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Foundation
import FirebaseFirestore

struct MenuItemDto: Codable {
    let id: String
    let categoryId: String
    let categoryTitle: String
    let name: String
    let description: String
    let notes: String?
    let ingredients: [String]
    let price: Double
    let offerPrice: Double?
    let imageURL: String?
    let isAvailable: Bool
    let remainingQuantity: Int
    let isFeatured: Bool
    let sortOrder: Int
    let createdAt: Timestamp?
    let updatedAt: Timestamp?

    func toDomain() -> MenuItem {
        MenuItem(
            id: id,
            categoryId: categoryId,
            categoryTitle: categoryTitle,
            name: name,
            description: description,
            notes: notes,
            ingredients: ingredients,
            price: price,
            offerPrice: offerPrice,
            imageURL: imageURL,
            isAvailable: isAvailable,
            remainingQuantity: max(0, remainingQuantity),
            isFeatured: isFeatured,
            sortOrder: sortOrder
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/data/remote/dto/OrderDto.swift

```swift
//
//  OrderDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import FirebaseFirestore

struct AppliedRewardDto: Codable {
    let id: String
    let templateId: String
    let title: String
    let amount: Double
    let note: String
    let affectedMenuItemIds: [String]
    let affectedActivityIds: [String]

    init(domain: AppliedReward) {
        self.id = domain.id
        self.templateId = domain.templateId
        self.title = domain.title
        self.amount = domain.amount
        self.note = domain.note
        self.affectedMenuItemIds = domain.affectedMenuItemIds
        self.affectedActivityIds = domain.affectedActivityIds
    }

    func toDomain() -> AppliedReward {
        AppliedReward(
            id: id,
            templateId: templateId,
            title: title,
            amount: amount,
            note: note,
            affectedMenuItemIds: affectedMenuItemIds,
            affectedActivityIds: affectedActivityIds
        )
    }
}

struct OrderDto: Codable {
    let id: String
    let nationalId: String?
    let clientName: String
    let tableNumber: String
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let items: [OrderItemDto]
    let subtotal: Double
    let loyaltyDiscountAmount: Double?
    let appliedRewards: [AppliedRewardDto]?
    let totalAmount: Double
    let status: String?
    let revision: Int?
    let lastConfirmedRevision: Int?

    init(from domain: Order) {
        self.id = domain.id
        self.nationalId = domain.nationalId
        self.clientName = domain.clientName
        self.tableNumber = domain.tableNumber
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
        self.items = domain.items.map(OrderItemDto.init(from:))
        self.subtotal = domain.subtotal
        self.loyaltyDiscountAmount = domain.loyaltyDiscountAmount
        self.appliedRewards = domain.appliedRewards.map(AppliedRewardDto.init(domain:))
        self.totalAmount = domain.totalAmount
        self.status = domain.status.rawValue
        self.revision = domain.revision
        self.lastConfirmedRevision = domain.lastConfirmedRevision
    }

    func toDomain() -> Order? {
        let domainItems = items.compactMap { $0.toDomain() }
        guard domainItems.count == items.count else { return nil }

        let safeStatus = OrderStatus(rawValue: status ?? OrderStatus.pending.rawValue) ?? .pending
        let safeCreatedAt = createdAt.dateValue()
        let safeUpdatedAt = updatedAt?.dateValue() ?? safeCreatedAt
        let safeRevision = revision ?? 1

        return Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: safeCreatedAt,
            updatedAt: safeUpdatedAt,
            items: domainItems,
            subtotal: subtotal,
            loyaltyDiscountAmount: max(0, loyaltyDiscountAmount ?? 0),
            appliedRewards: (appliedRewards ?? []).map { $0.toDomain() },
            totalAmount: totalAmount,
            status: safeStatus,
            revision: safeRevision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/data/remote/dto/OrderItemDto.swift

```swift
//
//  OrderitemDto.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderItemDto: Codable {
    let id: String
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let preparedQuantity: Int?
    let totalPrice: Double?
    let notes: String?
}

extension OrderItemDto {
    init(from domain: OrderItem) {
        self.id = domain.id.uuidString
        self.menuItemId = domain.menuItemId
        self.name = domain.name
        self.unitPrice = domain.unitPrice
        self.quantity = domain.quantity
        self.preparedQuantity = domain.preparedQuantity
        self.totalPrice = domain.totalPrice
        self.notes = domain.notes
    }
    
    func toDomain() -> OrderItem? {
        guard let uuid = UUID(uuidString: id) else { return nil }
        
        return OrderItem(
            id: uuid,
            menuItemId: menuItemId,
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            preparedQuantity: preparedQuantity ?? 0,
            notes: notes
        )
        
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/data/remote/service/CartPersistenceService.swift

```swift
//
//  CartPersistenceService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import SwiftData

@MainActor
final class CartPersistenceService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func loadDraft() -> OrderDraft {
        let descriptor = FetchDescriptor<CartDraftEntity>()

        do {
            let drafts = try context.fetch(descriptor)
            return drafts.first?.toDomain() ?? OrderDraft()
        } catch {
            print("Failed to load cart draft: \(error)")
            return OrderDraft()
        }
    }

    func save(draft: OrderDraft) {
        do {
            let existing = try context.fetch(FetchDescriptor<CartDraftEntity>())
            for entity in existing {
                context.delete(entity)
            }

            let newEntity = CartDraftEntity(from: draft)
            context.insert(newEntity)

            try context.save()
        } catch {
            print("Failed to save cart draft: \(error)")
        }
    }

    func clear() {
        do {
            let existing = try context.fetch(FetchDescriptor<CartDraftEntity>())
            for entity in existing {
                context.delete(entity)
            }
            try context.save()
        } catch {
            print("Failed to clear cart draft: \(error)")
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/data/remote/service/MenuService.swift

```swift
//
//  MenuService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Foundation
import FirebaseFirestore

final class MenuService: MenuServiceable {
    private let db: Firestore

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    func observeMenu(
        onChange: @escaping (Result<[MenuSection], Error>) -> Void
    ) -> MenuListenerTokenable {
        let registration = db
            .collection(FirestoreConstants.restaurant_menu_items)
            .order(by: "categoryTitle")
            .order(by: "sortOrder")
            .addSnapshotListener { snapshot, error in
                if let error {
                    onChange(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    onChange(.success([]))
                    return
                }

                do {
                    let items = try documents.map { document in
                        try document.data(as: MenuItemDto.self).toDomain()
                    }

                    let sections = Self.groupIntoSections(items: items)
                    onChange(.success(sections))
                } catch {
                    onChange(.failure(error))
                }
            }

        return MenuListenerToken(registration: registration)
    }

    private static func groupIntoSections(items: [MenuItem]) -> [MenuSection] {
        let grouped = Dictionary(grouping: items, by: \.categoryId)

        let sections = grouped.compactMap { categoryId, items -> MenuSection? in
            guard let first = items.first else { return nil }

            return MenuSection(
                id: categoryId,
                category: MenuCategory(
                    id: categoryId,
                    title: first.categoryTitle
                ),
                items: items.sorted { $0.sortOrder < $1.sortOrder }
            )
        }

        return sections.sorted { $0.category.title < $1.category.title }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/data/remote/service/OrdersService.swift

```swift
//
//  OrdersService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import FirebaseFirestore

final class OrdersService: OrdersServiceable {
    private let db: Firestore
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    init(
        db: Firestore = Firestore.firestore(),
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.db = db
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func submit(order: Order) async throws {
        let quantitiesByMenuItemId = Dictionary(
            grouping: order.items,
            by: \.menuItemId
        )
        .compactMapValues { items in
            let total = items.reduce(0) { $0 + $1.quantity }
            return total > 0 ? total : nil
        }

        let menuItemsToProcess: [(ref: DocumentReference, totalQuantity: Int)] =
        quantitiesByMenuItemId.map { menuItemId, totalQuantity in
            (
                ref: self.db
                    .collection(FirestoreConstants.restaurant_menu_items)
                    .document(menuItemId),
                totalQuantity: totalQuantity
            )
        }

        _ = try await db.runTransaction { transaction, errorPointer in
            do {
                var loadedItems: [(ref: DocumentReference, dto: MenuItemDto, totalQuantity: Int)] = []

                for item in menuItemsToProcess {
                    let snapshot = try transaction.getDocument(item.ref)
                    let dto = try snapshot.data(as: MenuItemDto.self)

                    loadedItems.append((
                        ref: item.ref,
                        dto: dto,
                        totalQuantity: item.totalQuantity
                    ))
                }

                for item in loadedItems {
                    guard item.dto.isAvailable else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "\(item.dto.name) no está disponible."]
                        )
                    }

                    guard item.dto.remainingQuantity >= item.totalQuantity else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Ya no hay suficiente stock de \(item.dto.name)."]
                        )
                    }

                    let newRemainingQuantity = item.dto.remainingQuantity - item.totalQuantity

                    transaction.updateData([
                        "remainingQuantity": newRemainingQuantity,
                        "isAvailable": newRemainingQuantity > 0,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: item.ref)
                }

                let dto = OrderDto(from: order)
                let orderData = try Firestore.Encoder().encode(dto)

                let orderRef = self.db
                    .collection(FirestoreConstants.restaurant_orders)
                    .document(order.id)

                transaction.setData(orderData, forDocument: orderRef)
                return nil
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
        }

        if let nationalId = order.nationalId?.trimmingCharacters(in: .whitespacesAndNewlines),
           !nationalId.isEmpty,
           !order.appliedRewards.isEmpty {
            try await loyaltyRewardsService.reserveRewards(
                nationalId: nationalId,
                referenceType: .order,
                referenceId: order.id,
                appliedRewards: order.appliedRewards
            )
        }
    }

    func observeOrders(for nationalId: String) -> AsyncThrowingStream<[Order], Error> {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        return AsyncThrowingStream { continuation in
            guard !cleanNationalId.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }

            let listener = db
                .collection(FirestoreConstants.restaurant_orders)
                .whereField("nationalId", isEqualTo: cleanNationalId)
                .order(by: "createdAt", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        continuation.finish(throwing: error)
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        continuation.yield([])
                        return
                    }

                    do {
                        let orders = try documents.compactMap { document in
                            try document.data(as: OrderDto.self).toDomain()
                        }
                        continuation.yield(orders)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/event/CheckoutEvent.swift

```swift
//
//  CheckoutEvent.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum CheckoutEvent {
    case confirmTapped
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/event/OrdersEvent.swift

```swift
//
//  OrderEvent.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum OrdersEvent {
    case onAppear
    case refresh
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/cart/CartItem.swift

```swift
//
//  CartItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct CartItem: Identifiable, Hashable {
    let id: UUID = UUID()
    let menuItem: MenuItem
    var quantity: Int
    var notes: String?
    
    var unitPrice: Double {
        menuItem.finalPrice
    }
    
    var totalPrice: Double {
        Double(quantity) * unitPrice
    }
    
    init(menuItem: MenuItem, quantity: Int, notes: String? = nil) {
        self.menuItem = menuItem
        self.quantity = quantity
        self.notes = notes
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/cart/CartPersistenceMappers.swift

```swift
//
//  CartPersistenceMappers.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

extension CartItemEntity {
    convenience init(from item: CartItem, draft: CartDraftEntity? = nil) {
        let ingredientsData = (try? JSONEncoder().encode(item.menuItem.ingredients)) ?? Data()

        self.init(
            id: item.id,
            menuItemId: item.menuItem.id,
            categoryId: item.menuItem.categoryId,
            name: item.menuItem.name,
            itemDescription: item.menuItem.description,
            quantity: item.quantity,
            notes: item.notes,
            ingredientsData: ingredientsData,
            price: item.menuItem.price,
            offerPrice: item.menuItem.offerPrice,
            imageURL: item.menuItem.imageURL,
            isAvailable: item.menuItem.isAvailable,
            isFeatured: item.menuItem.isFeatured,
            draft: draft
        )
    }

    func toDomain() -> CartItem {
        let ingredients = (try? JSONDecoder().decode([String].self, from: ingredientsData)) ?? []

        let menuItem = MenuItem(
            id: menuItemId,
            categoryId: categoryId,
            name: name,
            description: itemDescription,
            notes: nil,
            ingredients: ingredients,
            price: price,
            offerPrice: offerPrice,
            imageURL: imageURL,
            isAvailable: isAvailable,
            isFeatured: isFeatured
        )

        return CartItem(
            menuItem: menuItem,
            quantity: quantity,
            notes: notes
        )
    }
}

extension CartDraftEntity {
    convenience init(from draft: OrderDraft) {
        self.init(
            id: draft.id,
            nationalId: draft.nationalId,
            clientName: draft.clientName,
            tableNumber: draft.tableNumber,
            createdAt: draft.createdAt,
            updatedAt: draft.updatedAt,
            items: []
        )

        self.items = draft.items.map { CartItemEntity(from: $0, draft: self) }
    }

    func toDomain() -> OrderDraft {
        OrderDraft(
            id: id,
            clientId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: items.map { $0.toDomain() }
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/cart/CartPersistenceModels.swift

```swift
//
//  CartPersistenceModels.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation
import SwiftData

@Model
final class CartDraftEntity {
    @Attribute(.unique) var id: UUID
    var nationalId: String?
    var clientName: String
    var tableNumber: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CartItemEntity.draft)
    var items: [CartItemEntity]

    init(
        id: UUID = UUID(),
        nationalId: String? = nil,
        clientName: String = "",
        tableNumber: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [CartItemEntity] = []
    ) {
        self.id = id
        self.nationalId = nationalId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

@Model
final class CartItemEntity {
    var id: UUID
    var menuItemId: String
    var categoryId: String
    var name: String
    var itemDescription: String
    var quantity: Int
    var notes: String?
    var ingredientsData: Data
    var price: Double
    var offerPrice: Double?
    var imageURL: String?
    var isAvailable: Bool
    var isFeatured: Bool

    var draft: CartDraftEntity?

    init(
        id: UUID = UUID(),
        menuItemId: String,
        categoryId: String,
        name: String,
        itemDescription: String,
        quantity: Int,
        notes: String?,
        ingredientsData: Data,
        price: Double,
        offerPrice: Double?,
        imageURL: String?,
        isAvailable: Bool,
        isFeatured: Bool,
        draft: CartDraftEntity? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.categoryId = categoryId
        self.name = name
        self.itemDescription = itemDescription
        self.quantity = quantity
        self.notes = notes
        self.ingredientsData = ingredientsData
        self.price = price
        self.offerPrice = offerPrice
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.isFeatured = isFeatured
        self.draft = draft
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/menu/MenuCategory.swift

```swift
//
//  MenuCategory.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct MenuCategory: Identifiable, Hashable {
    let id: String
    let title: String
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/menu/MenuItem.swift

```swift
//
//  MenuItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct MenuItem: Identifiable, Hashable {
    let id: String
    let categoryId: String
    let categoryTitle: String
    let name: String
    let description: String
    var notes: String?
    let ingredients: [String]
    let price: Double
    let offerPrice: Double?
    let imageURL: String?
    let isAvailable: Bool
    let remainingQuantity: Int
    let isFeatured: Bool
    let sortOrder: Int

    init(
        id: String,
        categoryId: String,
        categoryTitle: String = "",
        name: String,
        description: String,
        notes: String? = nil,
        ingredients: [String],
        price: Double,
        offerPrice: Double? = nil,
        imageURL: String? = nil,
        isAvailable: Bool = true,
        remainingQuantity: Int = 20,
        isFeatured: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.categoryId = categoryId
        self.categoryTitle = categoryTitle
        self.name = name
        self.description = description
        self.notes = notes
        self.ingredients = ingredients
        self.price = price
        self.offerPrice = offerPrice
        self.imageURL = imageURL
        self.isAvailable = isAvailable
        self.remainingQuantity = max(0, remainingQuantity)
        self.isFeatured = isFeatured
        self.sortOrder = sortOrder
    }

    var hasOffer: Bool {
        guard let offerPrice else { return false }
        return offerPrice < price
    }

    var finalPrice: Double {
        offerPrice ?? price
    }

    var isSoldOut: Bool {
        remainingQuantity <= 0
    }

    var canBeOrdered: Bool {
        isAvailable && remainingQuantity > 0
    }

    var stockLabel: String {
        if !isAvailable { return "No disponible" }
        if remainingQuantity <= 0 { return "Agotado" }
        if remainingQuantity == 1 { return "Último plato" }
        if remainingQuantity <= 5 { return "Quedan \(remainingQuantity)" }
        return "\(remainingQuantity) disponibles"
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/menu/MenuSection.swift

```swift
//
//  MenuSection.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct MenuSection: Identifiable, Hashable {
    let id: String
    let category: MenuCategory
    let items: [MenuItem]
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/order/Order.swift

```swift
//
//  Order.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct Order: Identifiable, Hashable, Codable {
    let id: String
    let nationalId: String?
    let clientName: String
    let tableNumber: String
    let createdAt: Date
    let updatedAt: Date
    let items: [OrderItem]
    let subtotal: Double
    let loyaltyDiscountAmount: Double
    let appliedRewards: [AppliedReward]
    let totalAmount: Double
    var status: OrderStatus
    let revision: Int
    let lastConfirmedRevision: Int?

    init(
        id: String,
        nationalId: String?,
        clientName: String,
        tableNumber: String,
        createdAt: Date,
        updatedAt: Date,
        items: [OrderItem],
        subtotal: Double,
        loyaltyDiscountAmount: Double = 0,
        appliedRewards: [AppliedReward] = [],
        totalAmount: Double,
        status: OrderStatus,
        revision: Int,
        lastConfirmedRevision: Int?
    ) {
        self.id = id
        self.nationalId = nationalId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
        self.subtotal = subtotal
        self.loyaltyDiscountAmount = max(0, loyaltyDiscountAmount)
        self.appliedRewards = appliedRewards
        self.totalAmount = max(0, totalAmount)
        self.status = status
        self.revision = revision
        self.lastConfirmedRevision = lastConfirmedRevision
    }

    func withLoyalty(
        appliedRewards: [AppliedReward],
        discount: Double
    ) -> Order {
        Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: updatedAt,
            items: items,
            subtotal: subtotal,
            loyaltyDiscountAmount: max(0, discount),
            appliedRewards: appliedRewards,
            totalAmount: max(0, subtotal - max(0, discount)),
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    var preparedItemsCount: Int {
        items.reduce(0) { $0 + $1.preparedQuantity }
    }

    var allItemsCompleted: Bool {
        !items.isEmpty && items.allSatisfy(\.isCompleted)
    }

    var hasStartedPreparing: Bool {
        items.contains(where: \.isStarted)
    }

    var requiresReconfirmation: Bool {
        lastConfirmedRevision != revision
    }

    var wasEditedAfterConfirmation: Bool {
        guard let lastConfirmedRevision else { return false }
        return revision > lastConfirmedRevision
    }

    func recalculatedStatus() -> OrderStatus {
        if status == .canceled { return .canceled }
        if requiresReconfirmation { return .pending }
        if allItemsCompleted { return .completed }
        if hasStartedPreparing { return .preparing }
        if status == .confirmed { return .confirmed }
        return .pending
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/order/OrderItem.swift

```swift
//
//  OrderItem.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderItem: Identifiable, Hashable, Codable {
    let id: UUID
    let menuItemId: String
    let name: String
    let unitPrice: Double
    let quantity: Int
    let preparedQuantity: Int
    let totalPrice: Double
    let notes: String?

    init(
        id: UUID = UUID(),
        menuItemId: String,
        name: String,
        unitPrice: Double,
        quantity: Int,
        preparedQuantity: Int = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.menuItemId = menuItemId
        self.name = name
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.preparedQuantity = min(max(preparedQuantity, 0), quantity)
        self.totalPrice = Double(quantity) * unitPrice
        self.notes = notes
    }

    var remainingQuantity: Int {
        quantity - preparedQuantity
    }

    var isStarted: Bool {
        preparedQuantity > 0
    }

    var isCompleted: Bool {
        preparedQuantity == quantity
    }

    func updatingPreparedQuantity(_ newValue: Int) -> OrderItem {
        OrderItem(
            id: id,
            menuItemId: menuItemId,
            name: name,
            unitPrice: unitPrice,
            quantity: quantity,
            preparedQuantity: min(max(newValue, 0), quantity),
            notes: notes
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/model/order/OrderStatus.swift

```swift
//
//  OrderStatus.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum OrderStatus: String, Codable, Hashable, CaseIterable {
    case pending
    case confirmed
    case preparing
    case completed
    case canceled

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .confirmed: return "Confirmed"
        case .preparing: return "Preparing"
        case .completed: return "Completed"
        case .canceled: return "Canceled"
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/serviceable/MenuListenerToken.swift

```swift
//
//  MenuListenerToken.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import FirebaseFirestore

final class MenuListenerToken: MenuListenerTokenable {
    private var registration: ListenerRegistration?

    init(registration: ListenerRegistration) {
        self.registration = registration
    }

    func remove() {
        registration?.remove()
        registration = nil
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/serviceable/MenuServiceable.swift

```swift
//
//  MenuServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Foundation

protocol MenuServiceable {
    func observeMenu(
        onChange: @escaping (Result<[MenuSection], Error>) -> Void
    ) -> MenuListenerTokenable
}

protocol MenuListenerTokenable {
    func remove()
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/serviceable/OrdersServiceable.swift

```swift
//
//  OrdersServiceable.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

protocol OrdersServiceable {
    func submit(order: Order) async throws
    func observeOrders(for nationalId: String) -> AsyncThrowingStream<[Order], Error>
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/state/OrdersState.swift

```swift
//
//  OrderState.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrdersState {
    var nationalId: String = ""
    var isLoading = false
    var orders: [Order] = []
    var errorMessage: String?
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/usecase/ObserveOrdersUseCase.swift

```swift
//
//  ObserveOrdersUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct ObserveOrdersUseCase {
    let service: OrdersServiceable
    
    func execute(nationalId: String) -> AsyncThrowingStream<[Order], Error> {
        service.observeOrders(for: nationalId)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/domain/usecase/SubmitOrderUseCase.swift

```swift
//
//  SubmitOrderUseCase.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct SubmitOrderUseCase {
    let service: OrdersServiceable
    
    func execute(order: Order) async throws {
        try await service.submit(order: order)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/RestaurantRootView.swift

```swift
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
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/cart/CartItemRowView.swift

```swift
//
//  CartItemRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CartItemRowView: View {
    let cartItem: CartItem
    
    @EnvironmentObject private var cartManager: CartManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(cartItem.menuItem.name)
                        .font(.headline)
                    
                    Text(cartItem.menuItem.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !cartItem.menuItem.canBeOrdered {
                        Text("Agotado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    } else if cartItem.quantity >= cartItem.menuItem.remainingQuantity {
                        Text("Límite alcanzado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    
                    if let notes = cartItem.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        if cartItem.menuItem.hasOffer {
                            Text(cartItem.menuItem.price.priceText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .strikethrough()
                            
                            Text(cartItem.menuItem.finalPrice.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        } else {
                            Text(cartItem.menuItem.finalPrice.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Spacer()
            }
            
            HStack {
                HStack(spacing: 14) {
                    Button {
                        cartManager.decreaseQuantity(for: cartItem.menuItem.id)
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    
                    Text("\(cartItem.quantity)")
                        .font(.headline)
                        .frame(minWidth: 24)
                    
                    Button {
                        cartManager.increaseQuantity(for: cartItem.menuItem.id)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(!cartItem.menuItem.canBeOrdered || cartItem.quantity >= cartItem.menuItem.remainingQuantity)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(cartItem.totalPrice.priceText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
            
            
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/cart/CartManager.swift

```swift
//
//  CartManager.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class CartManager: ObservableObject {
    @Published private(set) var draft: OrderDraft

    private let persistence: CartPersistenceService

    init(persistence: CartPersistenceService) {
        self.persistence = persistence
        self.draft = persistence.loadDraft()
    }

    var items: [CartItem] { draft.items }

    var clientId: String? {
        get { draft.nationalId }
        set {
            draft.nationalId = newValue
            persist()
        }
    }

    var clientName: String {
        get { draft.clientName }
        set {
            draft.clientName = newValue
            persist()
        }
    }

    var tableNumber: String {
        get { draft.tableNumber }
        set {
            draft.tableNumber = newValue
            persist()
        }
    }

    var orderCreatedAt: Date { draft.createdAt }
    var totalItems: Int { draft.totalItems }
    var subtotal: Double { draft.subtotal }
    var totalAmount: Double { draft.totalAmount }
    var isEmpty: Bool { draft.isEmpty }

    func add(item: MenuItem, quantity: Int = 1, notes: String? = nil) {
        guard item.canBeOrdered else { return }
        guard quantity > 0 else { return }

        let cleanNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (cleanNotes?.isEmpty == true) ? nil : cleanNotes

        if draft.items.isEmpty {
            draft.createdAt = Date()
        }

        if let index = draft.items.firstIndex(where: { $0.menuItem.id == item.id && $0.notes == finalNotes }) {
            let current = draft.items[index].quantity
            let next = min(current + quantity, item.remainingQuantity)
            draft.items[index].quantity = next
        } else {
            let safeQuantity = min(quantity, item.remainingQuantity)
            guard safeQuantity > 0 else { return }
            draft.items.append(CartItem(menuItem: item, quantity: safeQuantity, notes: finalNotes))
        }

        draft.updatedAt = Date()
        persist()
    }

    func increaseQuantity(for itemId: String, by amount: Int = 1) {
        guard amount > 0 else { return }
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }

        let menuItem = draft.items[index].menuItem
        guard menuItem.canBeOrdered else { return }

        let current = draft.items[index].quantity
        let next = min(current + amount, menuItem.remainingQuantity)
        guard next > current else { return }

        draft.items[index].quantity = next
        draft.updatedAt = Date()
        persist()
    }

    func decreaseQuantity(for itemId: String, by amount: Int = 1) {
        guard amount > 0 else { return }
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }

        let newQuantity = draft.items[index].quantity - amount

        if newQuantity > 0 {
            draft.items[index].quantity = newQuantity
        } else {
            draft.items.remove(at: index)

            if draft.items.isEmpty {
                resetDraftMetadata()
            }
        }

        draft.updatedAt = Date()
        persist()
    }

    func updateQuantity(for itemId: String, quantity: Int) {
        guard let index = draft.items.firstIndex(where: { $0.menuItem.id == itemId }) else { return }

        if quantity <= 0 {
            draft.items.remove(at: index)

            if draft.items.isEmpty {
                resetDraftMetadata()
            }

            draft.updatedAt = Date()
            persist()
            return
        }

        guard draft.items[index].menuItem.isAvailable else { return }
        draft.items[index].quantity = quantity
        draft.updatedAt = Date()
        persist()
    }

    func remove(itemId: String) {
        draft.items.removeAll { $0.menuItem.id == itemId }

        if draft.items.isEmpty {
            resetDraftMetadata()
        }

        draft.updatedAt = Date()
        persist()
    }

    func updateClientId(_ id: String) {
        draft.nationalId = id
        persist()
    }

    func updateClientName(_ name: String) {
        draft.clientName = name
        persist()
    }

    func updateTableNumber(_ table: String) {
        draft.tableNumber = table
        persist()
    }

    func contains(itemId: String) -> Bool {
        draft.items.contains { $0.menuItem.id == itemId }
    }

    func quantity(for itemId: String) -> Int {
        draft.items.first(where: { $0.menuItem.id == itemId })?.quantity ?? 0
    }

    func cartItem(for itemId: String) -> CartItem? {
        draft.items.first(where: { $0.menuItem.id == itemId })
    }

    func clear() {
        draft = OrderDraft()
        persistence.clear()
    }

    func resetDraftMetadata() {
        draft.clientName = ""
        draft.tableNumber = ""
        draft.createdAt = Date()
    }

    func resetDraftKeepingIdentity() {
        draft = OrderDraft(id: draft.id)
        persist()
    }

    func replaceDraft(with newDraft: OrderDraft) {
        draft = newDraft
        persist()
    }

    func createOrder() -> Order? {
        guard draft.canSubmit else { return nil }
        return draft.toOrder()
    }

    func submitOrder() -> Order? {
        guard let order = createOrder() else { return nil }
        clear()
        return order
    }

    private func persist() {
        persistence.save(draft: draft)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/cart/CartView.swift

```swift
//
//  CartView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CartView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    let nationalId: String

    @EnvironmentObject private var cartManager: CartManager
    @State private var showClearCartAlert = false

    private var rowDiscounts: [UUID: Double] {
        viewModel.allocatedDiscountByCartItemId(for: cartManager.items)
    }

    private var effectiveTotal: Double {
        viewModel.effectiveTotal(for: cartManager.subtotal)
    }

    var body: some View {
        VStack(spacing: 0) {
            if cartManager.isEmpty {
                ContentUnavailableView(
                    "Tu carrito está vacío",
                    systemImage: "cart",
                    description: Text("Agrega algunos platos deliciosos del menú.")
                )
            } else {
                List {
                    Section("Productos") {
                        ForEach(cartManager.items) { cartItem in
                            RewardAwareCartItemRow(
                                cartItem: cartItem,
                                allocatedDiscount: rowDiscounts[cartItem.id, default: 0]
                            )
                        }
                        .onDelete(perform: deleteItems)
                    }

                    Section("Resumen") {
                        summaryRow("Subtotal", cartManager.subtotal.priceText, emphasized: true)
                        if viewModel.state.isLoadingRewards {
                            summaryRow("Murco Loyalty", "Calculando...", secondary: true)
                        } else if viewModel.state.rewardPreview.discountAmount > 0 {
                            summaryRow(
                                "Murco Loyalty",
                                "-\(viewModel.state.rewardPreview.discountAmount.priceText)",
                                accent: true
                            )
                        }
                        summaryRow("Productos", "\(cartManager.totalItems)", secondary: true)
                        summaryRow("Total", effectiveTotal.priceText, emphasized: true)
                    }

                    if !viewModel.state.rewardPreview.appliedRewards.isEmpty {
                        Section("Premios aplicados") {
                            ForEach(viewModel.state.rewardPreview.appliedRewards) { reward in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(reward.title)
                                        .font(.subheadline.bold())

                                    Text(reward.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)

                                    Text("-\(reward.amount.priceText)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Carrito")
        .appScreenStyle(.restaurant)
        .onAppear {
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: nationalId) { _, value in
            viewModel.onAppear(nationalId: value)
        }
        .toolbar {
            if !cartManager.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Vaciar") {
                        showClearCartAlert = true
                    }
                }
            }
        }
        .alert("¿Vaciar carrito?", isPresented: $showClearCartAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Vaciar", role: .destructive) {
                cartManager.clear()
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar todos los productos de tu carrito?")
        }
        .safeAreaInset(edge: .bottom) {
            if !cartManager.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if viewModel.state.isLoadingRewards {
                                Text("Calculando Murco Loyalty...")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            } else if viewModel.state.rewardPreview.discountAmount > 0 {
                                Text("Incluye Murco Loyalty")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.green)
                            }

                            Text(effectiveTotal.priceText)
                                .font(.title3)
                                .fontWeight(.bold)
                        }

                        Spacer()

                        NavigationLink(value: Route.checkout) {
                            Text("Finalizar compra")
                                .font(.headline)
                                .frame(minWidth: 140)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .background(Color.primary)
                                .foregroundStyle(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(.ultraThinMaterial)
                }
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let itemId = cartManager.items[index].menuItem.id
            cartManager.remove(itemId: itemId)
        }
    }

    private func summaryRow(
        _ title: String,
        _ value: String,
        emphasized: Bool = false,
        secondary: Bool = false,
        accent: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .headline : .body)
                .foregroundStyle(accent ? .green : (secondary ? .secondary : .primary))

            Spacer()

            Text(value)
                .font(emphasized ? .headline : .body)
                .fontWeight(emphasized ? .bold : .semibold)
                .foregroundStyle(accent ? .green : (secondary ? .secondary : .primary))
        }
    }
}

private struct RewardAwareCartItemRow: View {
    let cartItem: CartItem
    let allocatedDiscount: Double

    @EnvironmentObject private var cartManager: CartManager

    private var discountedTotal: Double {
        max(0, cartItem.totalPrice - allocatedDiscount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: 22))
                            .foregroundStyle(.gray)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(cartItem.menuItem.name)
                        .font(.headline)

                    Text(cartItem.menuItem.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    if !cartItem.menuItem.canBeOrdered {
                        Text("Agotado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    } else if cartItem.quantity >= cartItem.menuItem.remainingQuantity {
                        Text("Límite alcanzado")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }

                    if let notes = cartItem.notes,
                       !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(notes)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        if cartItem.menuItem.hasOffer {
                            Text(cartItem.menuItem.price.priceText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .strikethrough()

                            Text(cartItem.menuItem.finalPrice.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        } else {
                            Text(cartItem.menuItem.finalPrice.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        if allocatedDiscount > 0 {
                            Text("• Premio -\(allocatedDiscount.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }
                    }
                }

                Spacer()
            }

            HStack {
                HStack(spacing: 14) {
                    Button {
                        cartManager.decreaseQuantity(for: cartItem.menuItem.id)
                    } label: {
                        Image(systemName: "minus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)

                    Text("\(cartItem.quantity)")
                        .font(.headline)
                        .frame(minWidth: 24)

                    Button {
                        cartManager.increaseQuantity(for: cartItem.menuItem.id)
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                            .background(Color.gray.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(!cartItem.menuItem.canBeOrdered || cartItem.quantity >= cartItem.menuItem.remainingQuantity)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(allocatedDiscount > 0 ? "Total con premio" : "Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if allocatedDiscount > 0 {
                        Text(cartItem.totalPrice.priceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                    }

                    Text(discountedTotal.priceText)
                        .font(.headline)
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/cart/OrderDraft.swift

```swift
//
//  OrderDraft.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct OrderDraft: Identifiable, Hashable {
    let id: UUID
    var nationalId: String?
    var clientName: String
    var tableNumber: String
    var createdAt: Date
    var updatedAt: Date
    var items: [CartItem]
    var revision: Int?
    var lastConfirmedRevision: Int?
    
    init(
        id: UUID = UUID(),
        clientId: String? = nil,
        clientName: String = "",
        tableNumber: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [CartItem] = []
    ) {
        self.id = id
        self.nationalId = clientId
        self.clientName = clientName
        self.tableNumber = tableNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
    
    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var subtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }
    
    var totalAmount: Double {
        subtotal
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/menu/FeaturedMenuCard.swift

```swift
//
//  FeaturedMenuCard.swift
//  Altos del Murco
//
//  Created by José Ruiz on 15/4/26.
//

import SwiftUI

struct FeaturedMenuCard: View {
    let item: MenuItem
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.cardGradient)

            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .overlay {
                    if let imageURL = item.imageURL,
                       let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ZStack {
                                    palette.card
                                    ProgressView()
                                        .tint(palette.primary)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                
                            case .failure:
                                ZStack {
                                    palette.card
                                    
                                    VStack(spacing: 10) {
                                        Image(systemName: "fork.knife.circle.fill")
                                            .font(.system(size: 34))
                                            .foregroundStyle(palette.primary)
                                        
                                        Text(item.name)
                                            .font(.headline)
                                            .foregroundStyle(palette.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                                
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        )
                    }
                }

            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(colorScheme == .dark ? 0.35 : 0.15),
                    .black.opacity(0.72)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    BrandBadge(theme: .restaurant, title: "Destacados", selected: true)
                    Spacer()
                }
                
                Text(item.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(item.description)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(2)

                Text(String(format: "$%.2f", item.finalPrice))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
        .frame(height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .stroke(palette.stroke.opacity(0.6), lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.12),
            radius: 16,
            x: 0,
            y: 10
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/menu/MenuItemDetailView.swift

```swift
//
//  MenuItemView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuItemDetailView: View {
    var item: MenuItem
    let categoryTitle: String
    let rewardPresentationProvider: (MenuItem, Int) -> RewardPresentation?
    let displayedPriceProvider: (MenuItem, Int) -> Double
    let incrementalDiscountProvider: (MenuItem, Int) -> Double

    @EnvironmentObject private var cartManager: CartManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var quantity: Int = 1
    @State private var notesText: String = ""
    @State private var showAddedMessage = false

    private let theme: AppSectionTheme = .restaurant

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var rewardPresentation: RewardPresentation? {
        rewardPresentationProvider(item, quantity)
    }

    private var displayedPrice: Double {
        displayedPriceProvider(item, quantity)
    }

    private var incrementalDiscount: Double {
        incrementalDiscountProvider(item, quantity)
    }

    private var baseSubtotal: Double {
        item.finalPrice * Double(quantity)
    }

    init(
        item: MenuItem,
        categoryTitle: String,
        rewardPresentationProvider: @escaping (MenuItem, Int) -> RewardPresentation?,
        displayedPriceProvider: @escaping (MenuItem, Int) -> Double,
        incrementalDiscountProvider: @escaping (MenuItem, Int) -> Double
    ) {
        self.item = item
        self.categoryTitle = categoryTitle
        self.rewardPresentationProvider = rewardPresentationProvider
        self.displayedPriceProvider = displayedPriceProvider
        self.incrementalDiscountProvider = incrementalDiscountProvider
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                heroSection
                detailsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 120)
        }
        .navigationTitle("Plato")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.heroGradient)
                .frame(height: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                        .fill(.black.opacity(colorScheme == .dark ? 0.08 : 0.02))
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(palette.glow.opacity(colorScheme == .dark ? 0.30 : 0.18))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .offset(x: 24, y: -24)
                }

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    BrandIconBubble(theme: .restaurant, systemImage: "fork.knife", size: 60)

                    Spacer()

                    if item.isFeatured {
                        BrandBadge(theme: .restaurant, title: "Popular", selected: true)
                    }
                }

                Spacer()

                Text(item.name)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onPrimary)

                HStack(spacing: 10) {
                    Label(categoryTitle, systemImage: "tag.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.onPrimary.opacity(0.92))

                    Text(item.stockLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.canBeOrdered ? palette.onPrimary : palette.destructive)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            item.canBeOrdered
                                ? .white.opacity(0.18)
                                : .white.opacity(0.92)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(20)
        }
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.28 : 0.12),
            radius: 18,
            x: 0,
            y: 10
        )
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let rewardPresentation {
                rewardsCard(rewardPresentation)
            }

            descriptionCard
            ingredientsCard
            priceCard
            quantityCard
            notesCard
        }
    }

    private func rewardsCard(_ reward: RewardPresentation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Premio disponible",
                subtitle: "Este beneficio se refleja automáticamente en el valor mostrado."
            )

            HStack(alignment: .top, spacing: 12) {
                BrandBadge(theme: .restaurant, title: reward.badge, selected: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(reward.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(reward.message)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                if let amountText = reward.amountText {
                    Text("-\(amountText)")
                        .font(.caption.bold())
                        .foregroundStyle(palette.success)
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Descripción",
                subtitle: "Conoce más sobre este plato."
            )

            Text(item.description)
                .font(.body)
                .foregroundStyle(palette.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var ingredientsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Ingredientes",
                subtitle: "Componentes frescos y acompañamientos."
            )

            ForEach(item.ingredients, id: \.self) { ingredient in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 7, height: 7)
                        .padding(.top, 7)

                    Text(ingredient)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Precio",
                subtitle: item.hasOffer ? "Oferta especial disponible." : "Precio regular actual."
            )

            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if incrementalDiscount > 0 {
                    Text(baseSubtotal.priceText)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.textTertiary)
                        .strikethrough()

                    Text(displayedPrice.priceText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.success)
                } else if item.hasOffer, let offerPrice = item.offerPrice {
                    Text((item.price * Double(quantity)).priceText)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.textTertiary)
                        .strikethrough()

                    Text((offerPrice * Double(quantity)).priceText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                } else {
                    Text(baseSubtotal.priceText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var quantityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Cantidad",
                subtitle: "Elige cuántos quieres añadir."
            )

            QuantitySelectorView(
                quantity: $quantity,
                isEnabled: item.canBeOrdered,
                theme: .restaurant,
                minimum: 1,
                maximum: max(1, item.remainingQuantity)
            )
            .opacity(item.isAvailable ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Notas",
                subtitle: "Instrucciones especiales para la cocina."
            )

            TextField("Agrega alguna nota especial (opcional)", text: $notesText, axis: .vertical)
                .appTextFieldStyle(.restaurant)
                .lineLimit(3, reservesSpace: true)
                .disabled(!item.isAvailable)
                .opacity(item.isAvailable ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            if showAddedMessage {
                Text("El pedido ha sido agregado")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(palette.success)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(palette.textSecondary)

                        if incrementalDiscount > 0 {
                            Text("Incluye premio")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.success)
                        }

                        if incrementalDiscount > 0 {
                            Text(baseSubtotal.priceText)
                                .font(.caption)
                                .foregroundStyle(palette.textTertiary)
                                .strikethrough()
                        }

                        Text((incrementalDiscount > 0 ? displayedPrice : baseSubtotal).priceText)
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                    }

                    Spacer()
                }

                Button {
                    let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
                    let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

                    cartManager.add(
                        item: item,
                        quantity: quantity,
                        notes: finalNotes
                    )

                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAddedMessage = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAddedMessage = false
                        }
                        dismiss()
                    }
                } label: {
                    Label("Agregar al carrito", systemImage: "cart.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
                .disabled(!item.canBeOrdered)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/menu/MenuItemRowView.swift

```swift
//
//  MenuItemRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuItemRowView: View {
    let item: MenuItem
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }
    
    private var stockTextColor: Color {
        item.canBeOrdered ? palette.textSecondary : palette.destructive
    }
    
    private var stockBackground: Color {
        item.canBeOrdered
        ? palette.elevatedCard
        : palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.12)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            thumbnail
            
            VStack(alignment: .leading, spacing: 8) {
                headerSection
                descriptionSection
                footerSection
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.08),
            radius: 10,
            x: 0,
            y: 6
        )
        .opacity(item.canBeOrdered ? 1 : 0.58)
    }
    
    private var thumbnail: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(palette.elevatedCard)
            .frame(width: 88, height: 88)
            .overlay {
                if let imageURL = item.imageURL,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(palette.primary)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "fork.knife")
                                .font(.title2)
                                .foregroundStyle(palette.primary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(palette.primary)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(item.name)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            if item.isFeatured {
                statusBadge(
                    title: "Popular",
                    textColor: palette.primary,
                    background: palette.primary.opacity(0.12)
                )
            }
        }
    }
    
    private var descriptionSection: some View {
        Text(item.description)
            .font(.subheadline)
            .foregroundStyle(palette.textSecondary)
            .lineLimit(3)
            .multilineTextAlignment(.leading)
    }
    
    private var footerSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            if item.hasOffer, let offerPrice = item.offerPrice {
                Text(item.price.priceText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textTertiary)
                    .strikethrough()
                
                Text(offerPrice.priceText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.accent)
            } else {
                Text(item.price.priceText)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(palette.primary)
            }
            
            Spacer()
            
            statusBadge(
                title: item.stockLabel,
                textColor: stockTextColor,
                background: stockBackground
            )
        }
        .padding(.top, 2)
    }
    
    private func statusBadge(
        title: String,
        textColor: Color,
        background: Color
    ) -> some View {
        Text(title)
            .font(.caption2.weight(.bold))
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(background)
            )
            .overlay(
                Capsule()
                    .stroke(textColor.opacity(0.18), lineWidth: 1)
            )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/menu/MenuListView.swift

```swift
//
//  MenuListView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct MenuListView: View {
    let sections: [MenuSection]

    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @Binding var path: NavigationPath

    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedCategoryId: String?

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private let categoryDisplayOrder: [String] = [
        "Entradas",
        "Sopas",
        "Platos Fuertes",
        "Extras",
        "Postres",
        "Bebidas",
        "Bebidas Alcohólicas"
    ]

    private var authenticatedNationalId: String {
        sessionViewModel.authenticatedProfile?.nationalId ?? ""
    }

    private func categoryRank(for title: String) -> Int {
        categoryDisplayOrder.firstIndex(of: title) ?? Int.max
    }

    private var orderedSections: [MenuSection] {
        sections.sorted { lhs, rhs in
            let lhsRank = categoryRank(for: lhs.category.title)
            let rhsRank = categoryRank(for: rhs.category.title)

            if lhsRank != rhsRank { return lhsRank < rhsRank }
            return lhs.category.title < rhs.category.title
        }
    }

    private var categories: [MenuCategory] {
        orderedSections.map(\.category)
    }

    private var filteredSections: [MenuSection] {
        guard let selectedCategoryId else { return orderedSections }
        return orderedSections.filter { $0.category.id == selectedCategoryId }
    }

    private var featuredItems: [MenuItem] {
        orderedSections
            .flatMap(\.items)
            .filter(\.isFeatured)
    }

    private var appliedDiscountAmount: Double {
        checkoutViewModel.state.rewardPreview.discountAmount
    }

    private var effectiveCartTotal: Double {
        checkoutViewModel.effectiveTotal(for: cartManager.subtotal)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                if !featuredItems.isEmpty {
                    featuredCarousel
                }

                categorySelector

                ForEach(filteredSections) { section in
                    sectionContent(section)
                }
                rewardsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Sabor de Los Altos")
        .navigationBarTitleDisplayMode(.large)
        .appScreenStyle(.restaurant)
        .task {
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }

            syncIdentityAndRefreshRewards()
        }
        .onAppear {
            menuViewModel.onAppear()
            syncIdentityAndRefreshRewards()
        }
        .onChange(of: sessionViewModel.authenticatedProfile?.nationalId) { _, _ in
            syncIdentityAndRefreshRewards()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    OrdersView(viewModel: ordersViewModel)
                } label: {
                    ZStack {
                        Circle()
                            .fill(palette.chipGradient)
                            .frame(width: 34, height: 34)

                        Image(systemName: "list.bullet.clipboard.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(palette.primary)
                    }
                }

                NavigationLink(value: Route.cart) {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Circle()
                                .fill(palette.chipGradient)
                                .frame(width: 34, height: 34)

                            Image(systemName: "cart.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(palette.primary)
                        }

                        if cartManager.totalItems > 0 {
                            Text("\(cartManager.totalItems)")
                                .font(.system(size: 9, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .padding(.horizontal, cartManager.totalItems > 9 ? 4 : 0)
                                .background(palette.destructive)
                                .clipShape(Capsule())
                                .offset(x: 5, y: -4)
                        }
                    }
                }
            }
        }
        .navigationDestination(for: Route.self) { route in
            switch route {
            case let .menuDetail(item, categoryTitle):
                MenuItemDetailView(
                    item: item,
                    categoryTitle: categoryTitle,
                    rewardPresentationProvider: { menuItem, quantity in
                        menuViewModel.rewardPresentation(for: menuItem, quantity: quantity)
                    },
                    displayedPriceProvider: { menuItem, quantity in
                        menuViewModel.displayedPrice(for: menuItem, quantity: quantity)
                    },
                    incrementalDiscountProvider: { menuItem, quantity in
                        menuViewModel.incrementalDiscount(for: menuItem, quantity: quantity)
                    }
                )
            case .cart:
                CartView(
                    viewModel: checkoutViewModel,
                    nationalId: authenticatedNationalId
                )

            case .checkout:
                CheckoutView(viewModel: checkoutViewModel, path: $path)

            case .reservationBuilder:
                AdventureComboBuilderView(
                    adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                    menuViewModel: menuViewModel
                )
                .onAppear {
                    adventureComboBuilderViewModel.prepareFoodOnlyDraftIfNeeded()
                }

            case let .orderSuccess(order):
                OrderSuccessView(order: order, path: $path)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !cartManager.isEmpty {
                bottomCartBar
            }
        }
    }

    private func syncIdentityAndRefreshRewards() {
        let nationalId = authenticatedNationalId
        menuViewModel.setNationalId(nationalId)
        checkoutViewModel.onAppear(nationalId: nationalId)
    }

    @ViewBuilder
    private var rewardsSection: some View {
        let templates = menuViewModel.restaurantRewardTemplates

        if !templates.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Tus cupones y premios",
                    subtitle: "Aquí puedes ver qué premio tienes, cuándo vence y a qué plato o promo aplica."
                )

                if menuViewModel.state.isLoadingRewards {
                    ProgressView("Actualizando premios...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                }

                ForEach(templates) { template in
                    rewardCouponCard(template)
                }
            }
        }
    }

    private func rewardCouponCard(_ template: LoyaltyRewardTemplate) -> some View {
        let eligibleItems = menuViewModel.eligibleMenuItems(for: template)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                BrandBadge(
                    theme: .restaurant,
                    title: badgeText(for: template),
                    selected: true
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    Text(template.subtitle.isEmpty ? template.displaySummary : template.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()
            }

            if let expirationText = menuViewModel.expirationText(for: template) {
                Label(expirationText, systemImage: "calendar")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.warning)
            }

            if !eligibleItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elige un plato elegible")
                        .font(.caption.bold())
                        .foregroundStyle(palette.textPrimary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(eligibleItems) { item in
                                NavigationLink(value: Route.menuDetail(item, categoryTitle(for: item.categoryId))) {
                                    Text(item.name)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(palette.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(palette.chipGradient)
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(palette.stroke, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            } else if template.rule.type == .mostExpensiveMenuItemPercentage {
                Text("Agrega el plato elegible más caro que quieras y el descuento se calculará automáticamente sobre ese plato.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private func badgeText(for template: LoyaltyRewardTemplate) -> String {
        switch template.rule.type {
        case .freeMenuItem:
            return "Gratis"
        case .specificMenuItemPercentage, .mostExpensiveMenuItemPercentage:
            return "\(Int((template.rule.percentage ?? 0).rounded()))% OFF"
        case .buyXGetYFree:
            return "Promo"
        case .activityPercentage:
            return "Aventura"
        }
    }

    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Popular",
                subtitle: "Favoritos de los clientes y platos destacados"
            )

            TabView {
                ForEach(featuredItems) { item in
                    NavigationLink(value: Route.menuDetail(item, categoryTitle(for: item.categoryId))) {
                        FeaturedMenuCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 220)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Explorar por categoría"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategoryId = category.id
                            }
                        } label: {
                            BrandBadge(
                                theme: .restaurant,
                                title: category.title,
                                selected: selectedCategoryId == category.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    private func sectionContent(_ section: MenuSection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: section.category.title
            )

            LazyVStack(spacing: 12) {
                ForEach(section.items) { item in
                    NavigationLink(value: Route.menuDetail(item, section.category.title)) {
                        VStack(alignment: .leading, spacing: 10) {
                            MenuItemRowView(item: item)

                            if let appliedReward = checkoutViewModel.appliedRewardPresentation(forMenuItemId: item.id) {
                                appliedRewardCard(appliedReward)
                            } else if let availableReward = menuViewModel.rewardPresentation(for: item) {
                                availableRewardCard(availableReward)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? ""
    }

    private func availableRewardCard(_ reward: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .restaurant, title: reward.badge, selected: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(reward.message)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private func appliedRewardCard(_ reward: RewardPresentation) -> some View {
        HStack(alignment: .top, spacing: 10) {
            BrandBadge(theme: .restaurant, title: "Aplicado", selected: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(reward.title)
                    .font(.caption.bold())
                    .foregroundStyle(palette.textPrimary)

                Text(reward.message)
                    .font(.caption)
                    .foregroundStyle(palette.success)
            }

            Spacer()

            if let amountText = reward.amountText {
                Text("-\(amountText)")
                    .font(.caption.bold())
                    .foregroundStyle(palette.success)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.success.opacity(colorScheme == .dark ? 0.14 : 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.success.opacity(0.25), lineWidth: 1)
        )
    }

    private var bottomCartBar: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu pedido")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)

                    if appliedDiscountAmount > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Subtotal \(cartManager.subtotal.priceText)")
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)

                            Text("Murco Loyalty -\(appliedDiscountAmount.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.success)

                            Text(effectiveCartTotal.priceText)
                                .font(.title3.bold())
                                .foregroundStyle(palette.textPrimary)
                        }
                    } else {
                        Text(cartManager.subtotal.priceText)
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                    }
                }

                Spacer()

                NavigationLink(value: Route.cart) {
                    Text("Ver carrito")
                        .font(.headline)
                        .frame(minWidth: 140)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .background(palette.primary)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/menu/QuantitySelectorView.swift

```swift
//
//  QuantitySelectorView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct QuantitySelectorView: View {
    @Binding var quantity: Int
    
    let isEnabled: Bool
    let theme: AppSectionTheme
    
    var minimum: Int = 1
    var maximum: Int? = nil
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    private var canDecrease: Bool {
        isEnabled && quantity > minimum
    }
    
    private var canIncrease: Bool {
        guard isEnabled else { return false }
        guard let maximum else { return true }
        return quantity < maximum
    }
    
    var body: some View {
        HStack(spacing: 14) {
            controlButton(
                systemImage: "minus",
                enabled: canDecrease
            ) {
                quantity -= 1
            }
            
            Text("\(quantity)")
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(isEnabled ? palette.textPrimary : palette.textTertiary)
                .frame(minWidth: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    Capsule()
                        .stroke(palette.stroke, lineWidth: 1)
                )
            
            controlButton(
                systemImage: "plus",
                enabled: canIncrease
            ) {
                quantity += 1
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
            radius: 10,
            x: 0,
            y: 4
        )
        .opacity(isEnabled ? 1 : 0.65)
        .animation(.easeOut(duration: 0.18), value: quantity)
        .animation(.easeOut(duration: 0.18), value: isEnabled)
    }
    
    private func controlButton(
        systemImage: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? palette.onPrimary : palette.textTertiary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(
                            enabled
                            ? AnyShapeStyle(palette.heroGradient)
                            : AnyShapeStyle(palette.card)
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            enabled ? Color.white.opacity(0.12) : palette.stroke,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: enabled
                    ? palette.shadow.opacity(colorScheme == .dark ? 0.22 : 0.10)
                    : .clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .scaleEffect(enabled ? 1.0 : 0.96)
        .animation(.easeOut(duration: 0.18), value: enabled)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/CheckoutView.swift

```swift
//
//  CheckoutView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CheckoutView: View {
    @ObservedObject var viewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Binding var path: NavigationPath
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }

    private var effectiveTotal: Double {
        viewModel.effectiveTotal(for: cartManager.subtotal)
    }

    private var rowDiscounts: [UUID: Double] {
        viewModel.allocatedDiscountByCartItemId(for: cartManager.items)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                clientDetailsSection
                summarySection
                rewardsSection
                confirmSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle("Confirmación")
        .appScreenStyle(.restaurant)
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.state.errorMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.clearError()
                    }
                }
            ),
            actions: {
                Button("Aceptar") {
                    viewModel.clearError()
                }
            },
            message: {
                Text(viewModel.state.errorMessage ?? "")
            }
        )
        .onAppear {
            syncProfileFieldsFromSession()
            let nationalId = authenticatedProfile?.nationalId ?? cartManager.clientId ?? ""
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: authenticatedProfile?.nationalId) { _, _ in
            syncProfileFieldsFromSession()
            let nationalId = authenticatedProfile?.nationalId ?? cartManager.clientId ?? ""
            viewModel.onAppear(nationalId: nationalId)
        }
        .onChange(of: authenticatedProfile?.fullName) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: viewModel.state.createdOrder) { _, order in
            guard let order else { return }
            path.append(Route.orderSuccess(order))
        }
    }

    private var clientDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Datos del cliente",
                subtitle: "La información de tu perfil se utiliza automáticamente para este pedido."
            )

            VStack(spacing: 14) {
                themedField(
                    title: "Cédula",
                    text: Binding(
                        get: { authenticatedProfile?.nationalId ?? cartManager.clientId ?? "" },
                        set: { _ in }
                    )
                )
                .disabled(true)

                themedField(
                    title: "Nombre",
                    text: Binding(
                        get: { authenticatedProfile?.fullName ?? cartManager.clientName },
                        set: { _ in }
                    )
                )
                .disabled(true)

                themedField(
                    title: "Número de mesa",
                    text: Binding(
                        get: { cartManager.tableNumber },
                        set: { cartManager.updateTableNumber($0) }
                    )
                )
                .keyboardType(.numberPad)

                Text("¿Necesitas cambiar tu nombre o cédula? Hazlo desde Editar perfil.")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .appCardStyle(.restaurant)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Resumen",
                subtitle: "Revisa tu pedido antes de confirmarlo."
            )

            VStack(spacing: 12) {
                ForEach(cartManager.items) { cartItem in
                    let lineDiscount = rowDiscounts[cartItem.id, default: 0]
                    let discountedLine = max(0, cartItem.totalPrice - lineDiscount)

                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(cartItem.quantity)x \(cartItem.menuItem.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(palette.textPrimary)

                            if let reward = viewModel.appliedRewardPresentation(forMenuItemId: cartItem.menuItem.id) {
                                Text(reward.message)
                                    .font(.caption)
                                    .foregroundStyle(palette.success)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            if lineDiscount > 0 {
                                Text(cartItem.totalPrice.priceText)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                                    .strikethrough()

                                Text(discountedLine.priceText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.success)
                            } else {
                                Text(cartItem.totalPrice.priceText)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.textPrimary)
                            }
                        }
                    }

                    if cartItem.id != cartManager.items.last?.id {
                        Divider().overlay(palette.stroke)
                    }
                }
            }

            Divider().overlay(palette.stroke)

            detailLine(title: "Subtotal", value: cartManager.subtotal.priceText)

            if viewModel.state.isLoadingRewards {
                detailLine(title: "Murco Loyalty", value: "Calculando...", secondary: true)
            } else if viewModel.state.rewardPreview.discountAmount > 0 {
                detailLine(
                    title: "Murco Loyalty",
                    value: "-\(viewModel.state.rewardPreview.discountAmount.priceText)",
                    accent: true
                )
            }

            Divider().overlay(palette.stroke)

            detailLine(
                title: "Total",
                value: effectiveTotal.priceText,
                emphasized: true
            )
        }
        .appCardStyle(.restaurant)
    }

    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Premios aplicados",
                subtitle: viewModel.state.rewardPreview.appliedRewards.isEmpty
                    ? "No hay premios activos para este pedido."
                    : "Estos descuentos ya se reflejan en el total."
            )

            if viewModel.state.isLoadingRewards {
                ProgressView("Calculando premios...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if viewModel.state.rewardPreview.appliedRewards.isEmpty {
                Text("No se aplicó ningún cupón o premio automático a este pedido.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.state.rewardPreview.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: .restaurant, title: "Aplicado", selected: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reward.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.textPrimary)

                                Text(reward.note)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Text("-\(reward.amount.priceText)")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.success)
                        }
                    }
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var confirmSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total a pagar")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)

                    Text(effectiveTotal.priceText)
                        .font(.title2.bold())
                        .foregroundStyle(palette.textPrimary)
                }

                Spacer()
            }

            Button {
                viewModel.onEvent(.confirmTapped)
            } label: {
                if viewModel.state.isSubmitting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Confirmar pedido")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(cartManager.isEmpty || viewModel.state.isSubmitting)
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }

        if cartManager.clientId != profile.nationalId {
            cartManager.clientId = profile.nationalId
        }

        if cartManager.clientName != profile.fullName {
            cartManager.clientName = profile.fullName
        }
    }

    private func themedField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.textSecondary)

            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func detailLine(
        title: String,
        value: String,
        emphasized: Bool = false,
        secondary: Bool = false,
        accent: Bool = false
    ) -> some View {
        HStack {
            Text(title)
                .font(emphasized ? .headline : .subheadline)
                .foregroundStyle(
                    accent
                    ? palette.success
                    : (secondary ? palette.textSecondary : palette.textPrimary)
                )

            Spacer()

            Text(value)
                .font(emphasized ? .headline.bold() : .subheadline.weight(.semibold))
                .foregroundStyle(
                    accent
                    ? palette.success
                    : (secondary ? palette.textSecondary : palette.textPrimary)
                )
        }
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrderDetailItemRow.swift

```swift
//
//  OrderDetailItemRow.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderDetailItemRow: View {
    let item: OrderItem
    
    @Environment(\.colorScheme) private var colorScheme
    private let theme: AppSectionTheme = .restaurant
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var statusText: String {
        if item.isCompleted { return "Lista" }
        if item.isStarted { return "En proceso" }
        return "Esperando"
    }

    private var progressValue: Double {
        guard item.quantity > 0 else { return 0 }
        return Double(item.preparedQuantity) / Double(item.quantity)
    }
    
    private var progressColor: Color {
        if item.isCompleted { return palette.success }
        if item.isStarted { return palette.warning }
        return palette.textTertiary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: theme,
                    systemImage: "fork.knife",
                    size: 42
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Text("\(item.quantity) × \(item.unitPrice.priceText)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(item.totalPrice.priceText)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(palette.textPrimary)

                    ItemStatusBadge(
                        isCompleted: item.isCompleted,
                        isStarted: item.isStarted
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Prepared: \(item.preparedQuantity)/\(item.quantity)")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)

                    Spacer()

                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(progressColor)
                }

                ProgressView(value: progressValue)
                    .tint(progressColor)
            }

            if let notes = item.notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "note.text")
                        .font(.subheadline)
                        .foregroundStyle(palette.accent)
                        .padding(.top, 1)

                    Text(notes)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(palette.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
            }
        }
        .appCardStyle(.restaurant)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrderDetailView.swift

```swift
//
//  OrderDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderDetailView: View {
    let order: Order
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var effectiveStatus: OrderStatus {
        order.recalculatedStatus()
    }

    private var progressValue: Double {
        guard order.totalItems > 0 else { return 0 }
        return Double(order.preparedItemsCount) / Double(order.totalItems)
    }

    var body: some View {
        List {
            Section {
                headerCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }

            Section {
                ForEach(order.items) { item in
                    OrderDetailItemRow(item: item)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Productos",
                    subtitle: "Todo lo incluido en este pedido"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }

            if !order.appliedRewards.isEmpty {
                Section {
                    rewardsCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                } header: {
                    BrandSectionHeader(
                        theme: .restaurant,
                        title: "Premios aplicados",
                        subtitle: "Beneficios usados automáticamente en este pedido."
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .textCase(nil)
                }
            }

            Section {
                amountsCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Montos"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Detalle del pedido")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.clientName.isEmpty ? "Cliente sin reserva" : order.clientName)
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text("Pedido #\(order.id.prefix(8))")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                OrderStatusBadge(status: effectiveStatus)
            }

            HStack(spacing: 12) {
                DetailMetricView(
                    title: "Mesa",
                    value: order.tableNumber,
                    systemImage: "tablecells"
                )

                DetailMetricView(
                    title: "Productos",
                    value: "\(order.totalItems)",
                    systemImage: "fork.knife"
                )
            }

            HStack(spacing: 12) {
                DetailMetricView(
                    title: "Creado",
                    value: order.createdAt.shortDateTimeString,
                    systemImage: "calendar"
                )

                DetailMetricView(
                    title: "Actualizado",
                    value: order.updatedAt.shortDateTimeString,
                    systemImage: "clock.arrow.circlepath"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Progreso de preparación")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    Text("\(order.preparedItemsCount)/\(order.totalItems)")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                }

                ProgressView(value: progressValue)
                    .tint(palette.accent)
            }

            if order.requiresReconfirmation {
                Label("Este pedido necesita reconfirmación antes de que cocina continúe.", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(palette.warning)
                    .padding(.top, 2)
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(order.appliedRewards) { reward in
                HStack(alignment: .top, spacing: 12) {
                    BrandBadge(theme: .restaurant, title: "Premio", selected: true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reward.title)
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text(reward.note)
                            .font(.caption)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Text("-\(reward.amount.priceText)")
                        .font(.subheadline.bold())
                        .foregroundStyle(palette.success)
                }
            }
        }
        .appCardStyle(.restaurant)
    }

    private var amountsCard: some View {
        VStack(spacing: 0) {
            detailLine(title: "Subtotal", value: order.subtotal.priceText)

            if order.loyaltyDiscountAmount > 0 {
                Divider().overlay(palette.stroke)
                detailLine(
                    title: "Murco Loyalty",
                    value: "-\(order.loyaltyDiscountAmount.priceText)"
                )
            }

            Divider().overlay(palette.stroke)
            detailLine(title: "Total", value: order.totalAmount.priceText, emphasized: true)
        }
        .appCardStyle(.restaurant)
    }

    private func detailLine(title: String, value: String, emphasized: Bool = false) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)

            Spacer()

            Text(value)
                .font(emphasized ? .headline : .subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? palette.primary : palette.textPrimary)
        }
        .padding(.vertical, 14)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrderRowView.swift

```swift
//
//  OrderRowView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var progressColor: Color {
        switch effectiveStatus {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.secondary
        case .preparing:
            return palette.accent
        case .completed:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }

    let order: Order

    private var effectiveStatus: OrderStatus {
        order.recalculatedStatus()
    }

    private var progressText: String {
        "\(order.preparedItemsCount)/\(order.totalItems) productos"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName.isEmpty ? "Cliente sin reserva" : order.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    HStack(spacing: 8) {
                        Label("Mesa \(order.tableNumber)", systemImage: "tablecells")
                        Label(order.createdAt.relativeTimeString, systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                OrderStatusBadge(status: effectiveStatus)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(progressText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(palette.textPrimary)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        if order.loyaltyDiscountAmount > 0 {
                            Text(order.subtotal.priceText)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                                .strikethrough()

                            Text(order.totalAmount.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(palette.success)
                        } else {
                            Text(order.totalAmount.priceText)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(palette.primary)
                        }
                    }
                }

                ProgressView(value: progressValue)
                    .tint(progressColor)
            }

            if order.loyaltyDiscountAmount > 0 || !order.appliedRewards.isEmpty {
                Divider().overlay(palette.stroke)

                HStack(alignment: .top, spacing: 8) {
                    BrandBadge(theme: .restaurant, title: "Murco", selected: true)

                    VStack(alignment: .leading, spacing: 4) {
                        if order.loyaltyDiscountAmount > 0 {
                            Text("Descuento aplicado: -\(order.loyaltyDiscountAmount.priceText)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(palette.success)
                        }

                        if let reward = order.appliedRewards.first {
                            Text(reward.note)
                                .font(.caption)
                                .foregroundStyle(palette.textSecondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()
                }
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }

    private var progressValue: Double {
        guard order.totalItems > 0 else { return 0 }
        return Double(order.preparedItemsCount) / Double(order.totalItems)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrderStatusBadge.swift

```swift
//
//  OrderStatusBadge.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrderStatusBadge: View {
    let status: OrderStatus
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            
            Text(status.title)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(statusColor.opacity(colorScheme == .dark ? 0.18 : 0.12))
        )
        .overlay(
            Capsule()
                .stroke(statusColor.opacity(colorScheme == .dark ? 0.35 : 0.20), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch status {
        case .pending:
            return palette.warning
        case .confirmed:
            return palette.secondary
        case .preparing:
            return Color.adaptive(
                light: UIColor(hex: 0x7C3AED),
                dark: UIColor(hex: 0xB794F4)
            )
        case .completed:
            return palette.success
        case .canceled:
            return palette.destructive
        }
    }
}

struct ItemStatusBadge: View {
    let isCompleted: Bool
    let isStarted: Bool
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            
            Text(title)
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(colorScheme == .dark ? 0.18 : 0.12))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(colorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
        )
    }

    private var title: String {
        if isCompleted { return "Ready" }
        if isStarted { return "In progress" }
        return "Waiting"
    }

    private var color: Color {
        if isCompleted { return palette.success }
        if isStarted { return palette.warning }
        return palette.textSecondary
    }
}

struct InfoChip: View {
    let text: String
    let systemImage: String
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .foregroundStyle(palette.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(palette.chipGradient)
            )
            .overlay(
                Capsule()
                    .stroke(palette.stroke, lineWidth: 1)
            )
    }
}

struct DetailMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    var theme: AppSectionTheme = .restaurant
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(palette.chipGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(palette.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.cardGradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
        .shadow(
            color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
            radius: 10,
            x: 0,
            y: 5
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrderSuccessView.swift

```swift
//
//  OrderSuccessView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct OrderSuccessView: View {
    let order: Order

    @Binding var path: NavigationPath
    @Environment(\.colorScheme) private var colorScheme

    private let theme: AppSectionTheme = .restaurant

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                successHeader
                orderDetailsCard
                rewardsCard

                Button {
                    path = NavigationPath()
                } label: {
                    Text("Listo")
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Éxito")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .appScreenStyle(theme)
    }

    private var successHeader: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(palette.chipGradient)
                    .frame(width: 108, height: 108)
                    .overlay(
                        Circle()
                            .stroke(palette.stroke, lineWidth: 1)
                    )
                    .shadow(
                        color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                        radius: 18,
                        x: 0,
                        y: 10
                    )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(palette.success)
            }

            VStack(spacing: 8) {
                Text("Pedido enviado")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                Text("Tu pedido fue creado correctamente.")
                    .font(.body)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var orderDetailsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            BrandSectionHeader(
                theme: theme,
                title: "Resumen del pedido",
                subtitle: "Tu pedido del restaurante ha sido registrado correctamente."
            )

            VStack(spacing: 14) {
                InfoRow(title: "ID del pedido", value: String(order.id.prefix(7)), theme: theme)
                InfoRow(title: "Cliente", value: order.clientName, theme: theme)
                InfoRow(title: "Mesa", value: order.tableNumber, theme: theme)
                InfoRow(title: "Estado", value: order.status.title, theme: theme)
                InfoRow(
                    title: "Hora",
                    value: order.createdAt.formatted(date: .omitted, time: .shortened),
                    theme: theme
                )
                InfoRow(title: "Subtotal", value: order.subtotal.priceText, theme: theme)
                if order.loyaltyDiscountAmount > 0 {
                    InfoRow(
                        title: "Murco Loyalty",
                        value: "-\(order.loyaltyDiscountAmount.priceText)",
                        theme: theme
                    )
                }
                InfoRow(title: "Total", value: order.totalAmount.priceText, theme: theme, emphasized: true)
            }
        }
        .appCardStyle(theme, emphasized: false)
    }

    @ViewBuilder
    private var rewardsCard: some View {
        if !order.appliedRewards.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: theme,
                    title: "Premios aplicados",
                    subtitle: "Estos premios quedaron guardados con tu pedido."
                )

                VStack(spacing: 12) {
                    ForEach(order.appliedRewards) { reward in
                        HStack(alignment: .top, spacing: 10) {
                            BrandBadge(theme: theme, title: "Aplicado", selected: true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(reward.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(palette.textPrimary)

                                Text(reward.note)
                                    .font(.caption)
                                    .foregroundStyle(palette.textSecondary)
                            }

                            Spacer()

                            Text("-\(reward.amount.priceText)")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.success)
                        }
                    }
                }
            }
            .appCardStyle(theme)
        }
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let theme: AppSectionTheme
    var emphasized: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
            
            Spacer(minLength: 16)
            
            Text(value)
                .font(emphasized ? .headline : .subheadline.weight(.semibold))
                .foregroundStyle(emphasized ? palette.primary : palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrdersSummaryView.swift

```swift
//
//  OrdersSummaryView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrdersSummaryView: View {
    let orders: [Order]
    var theme: AppSectionTheme = .restaurant

    private var pendingCount: Int {
        orders.filter { $0.recalculatedStatus() == .pending }.count
    }

    private var preparingCount: Int {
        orders.filter { $0.recalculatedStatus() == .preparing }.count
    }

    private var completedCount: Int {
        orders.filter { $0.recalculatedStatus() == .completed }.count
    }

    private var totalRevenue: Double {
        orders
            .filter { $0.recalculatedStatus() != .canceled }
            .reduce(0) { $0 + $1.totalAmount }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            SummaryMetricCard(
                theme: theme,
                title: "Pendientes",
                value: "\(pendingCount)",
                systemImage: "clock",
                tone: .warning
            )

            SummaryMetricCard(
                theme: theme,
                title: "En preparación",
                value: "\(preparingCount)",
                systemImage: "flame.fill",
                tone: .accent
            )

            SummaryMetricCard(
                theme: theme,
                title: "Completados",
                value: "\(completedCount)",
                systemImage: "checkmark.circle.fill",
                tone: .success
            )

            SummaryMetricCard(
                theme: theme,
                title: "Ingresos",
                value: totalRevenue.priceText,
                systemImage: "dollarsign.circle.fill",
                tone: .primary,
                emphasized: true
            )
        }
    }
}

enum SummaryMetricTone {
    case primary
    case accent
    case success
    case warning
}

struct SummaryMetricCard: View {
    let theme: AppSectionTheme
    let title: String
    let value: String
    let systemImage: String
    let tone: SummaryMetricTone
    var emphasized: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }

    private var valueColor: Color {
        switch tone {
        case .primary:
            return palette.primary
        case .accent:
            return palette.accent
        case .success:
            return palette.success
        case .warning:
            return palette.warning
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(palette.textSecondary)

                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(valueColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .appCardStyle(theme, emphasized: emphasized)
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(palette.chipGradient)
                .frame(width: 46, height: 46)

            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(valueColor)
        }
        .overlay(
            Circle()
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/view/order/OrdersView.swift

```swift
//
//  OrdersView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

private enum OrdersGroupingOption: String, CaseIterable, Identifiable {
    case byDate = "Fecha"
    case byStatus = "Estado"
    var id: String { rawValue }
}

private enum OrdersSortOption: String, CaseIterable, Identifiable {
    case newestFirst = "Más recientes"
    case oldestFirst = "Más antiguos"
    case highestTotal = "Mayor total"
    var id: String { rawValue }
}

private enum OrdersStatusFilter: String, CaseIterable, Identifiable {
    case all = "Todos"
    case pending = "Pendiente"
    case confirmed = "Confirmado"
    case preparing = "Preparando"
    case completed = "Completado"
    case canceled = "Cancelado"

    var id: String { rawValue }

    var status: OrderStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .confirmed: return .confirmed
        case .preparing: return .preparing
        case .completed: return .completed
        case .canceled: return .canceled
        }
    }
}

private struct OrdersGroup: Identifiable {
    let id: String
    let title: String
    let orders: [Order]
}

struct OrdersView: View {
    @ObservedObject var viewModel: OrdersViewModel
    @EnvironmentObject private var sessionViewModel: AppSessionViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedOrder: Order?
    @State private var grouping: OrdersGroupingOption = .byDate
    @State private var sortOption: OrdersSortOption = .newestFirst
    @State private var statusFilter: OrdersStatusFilter = .all

    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var filteredOrders: [Order] {
        viewModel.state.orders.filter { order in
            guard let filterStatus = statusFilter.status else { return true }
            return order.recalculatedStatus() == filterStatus
        }
    }

    private var sortedOrders: [Order] {
        switch sortOption {
        case .newestFirst:
            return filteredOrders.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return filteredOrders.sorted { $0.createdAt < $1.createdAt }
        case .highestTotal:
            return filteredOrders.sorted { $0.totalAmount > $1.totalAmount }
        }
    }

    private var groupedOrders: [OrdersGroup] {
        switch grouping {
        case .byStatus:
            let orderedStatuses: [OrderStatus] = [.pending, .confirmed, .preparing, .completed, .canceled]

            let buckets = Dictionary(grouping: sortedOrders) { $0.recalculatedStatus() }
            return orderedStatuses.compactMap { status in
                guard let orders = buckets[status], !orders.isEmpty else { return nil }
                return OrdersGroup(
                    id: status.rawValue,
                    title: status.title,
                    orders: orders
                )
            }

        case .byDate:
            let calendar = Calendar.current
            let buckets = Dictionary(grouping: sortedOrders) { calendar.startOfDay(for: $0.createdAt) }

            return buckets
                .map { day, orders in
                    OrdersGroup(
                        id: ISO8601DateFormatter().string(from: day),
                        title: dateTitle(for: day),
                        orders: sortInsideGroup(orders)
                    )
                }
                .sorted { lhs, rhs in
                    guard let lhsDate = lhs.orders.first?.createdAt,
                          let rhsDate = rhs.orders.first?.createdAt else {
                        return lhs.title > rhs.title
                    }

                    switch sortOption {
                    case .oldestFirst:
                        return lhsDate < rhsDate
                    case .newestFirst, .highestTotal:
                        return lhsDate > rhsDate
                    }
                }
        }
    }

    var body: some View {
        ZStack {
            BrandScreenBackground(theme: .restaurant)
            content
        }
        .navigationTitle("Pedidos")
        .navigationBarTitleDisplayMode(.large)
        .tint(palette.primary)
        .onAppear {
            if let nationalId = sessionViewModel.authenticatedProfile?.nationalId {
                viewModel.setNationalId(nationalId)
            }
            viewModel.onEvent(.onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.orders.isEmpty {
            loadingView
        } else if let error = viewModel.state.errorMessage, viewModel.state.orders.isEmpty {
            stateCard(
                title: "Algo salió mal",
                systemImage: "exclamationmark.triangle",
                description: error
            )
        } else if viewModel.state.orders.isEmpty {
            stateCard(
                title: "Aún no hay pedidos",
                systemImage: "tray",
                description: "Los pedidos aparecerán aquí una vez que los clientes los realicen."
            )
        } else {
            ordersList
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView("Cargando pedidos...")
                .tint(palette.primary)
                .foregroundStyle(palette.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func stateCard(
        title: String,
        systemImage: String,
        description: String
    ) -> some View {
        VStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(description)
            )
            .foregroundStyle(palette.textSecondary)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .appCardStyle(.restaurant, emphasized: true)
        .padding()
    }

    private var ordersList: some View {
        List {
            summarySection
            controlsSection

            ForEach(groupedOrders) { group in
                Section {
                    ForEach(group.orders) { order in
                        Button {
                            selectedOrder = order
                        } label: {
                            OrderRowView(order: order)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appListRowStyle(.restaurant)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    sectionHeader(title: group.title, count: group.orders.count)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable {
            viewModel.onEvent(.refresh)
        }
        .navigationDestination(item: $selectedOrder) { order in
            OrderDetailView(order: order)
        }
    }

    private var summarySection: some View {
        Section {
            OrdersSummaryView(orders: filteredOrders)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle(.restaurant, emphasized: false)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 10, trailing: 8))
                .listRowBackground(Color.clear)
        } header: {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Resumen",
                subtitle: "Haz seguimiento de tus pedidos con agrupación por fecha, filtros y ordenamiento."
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
            .textCase(nil)
        }
    }

    private var controlsSection: some View {
        Section {
            VStack(spacing: 14) {
                Picker("Agrupar", selection: $grouping) {
                    ForEach(OrdersGroupingOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Estado", selection: $statusFilter) {
                    ForEach(OrdersStatusFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Picker("Ordenar", selection: $sortOption) {
                    ForEach(OrdersSortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
            }
            .padding(.vertical, 4)
            .appCardStyle(.restaurant, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 10, trailing: 8))
            .listRowBackground(Color.clear)
        } header: {
            Text("Herramientas de pedidos")
                .font(.headline)
                .foregroundStyle(palette.textSecondary)
                .textCase(nil)
        }
    }

    private func sectionHeader(title: String, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()

            BrandBadge(
                theme: .restaurant,
                title: "\(count)",
                selected: true
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .textCase(nil)
    }

    private func sortInsideGroup(_ orders: [Order]) -> [Order] {
        switch sortOption {
        case .newestFirst:
            return orders.sorted { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            return orders.sorted { $0.createdAt < $1.createdAt }
        case .highestTotal:
            return orders.sorted { $0.totalAmount > $1.totalAmount }
        }
    }

    private func dateTitle(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Hoy" }
        if calendar.isDateInYesterday(day) { return "Ayer" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/viewmodel/CheckoutViewModel.swift

```swift
//
//  CheckoutViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import Foundation

struct CheckoutRewardPreview: Hashable {
    let appliedRewards: [AppliedReward]
    let discountAmount: Double
    let walletSnapshot: RewardWalletSnapshot

    static func empty(nationalId: String) -> CheckoutRewardPreview {
        CheckoutRewardPreview(
            appliedRewards: [],
            discountAmount: 0,
            walletSnapshot: .empty(nationalId: nationalId)
        )
    }
}

struct CheckoutState {
    var isSubmitting = false
    var isLoadingRewards = false
    var createdOrder: Order?
    var rewardPreview: CheckoutRewardPreview = .empty(nationalId: "")
    var errorMessage: String?
}

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published private(set) var state = CheckoutState()

    private let submitOrderUseCase: SubmitOrderUseCase
    private let cartManager: CartManager
    private let loyaltyRewardsService: LoyaltyRewardsServiceable

    private var cancellables = Set<AnyCancellable>()
    private var currentNationalId: String = ""
    private var walletListenerToken: LoyaltyRewardsListenerToken?

    init(
        submitOrderUseCase: SubmitOrderUseCase,
        cartManager: CartManager,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.submitOrderUseCase = submitOrderUseCase
        self.cartManager = cartManager
        self.loyaltyRewardsService = loyaltyRewardsService

        cartManager.$draft
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    await self.refreshRewardPreviewIfPossible()
                }
            }
            .store(in: &cancellables)
    }

    func onAppear(nationalId: String) {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldRestartObservation =
            cleanNationalId != currentNationalId || walletListenerToken == nil

        currentNationalId = cleanNationalId

        if shouldRestartObservation {
            startWalletObservation()
        }
    }

    func refreshRewardPreviewIfPossible() async {
        await refreshRewardPreview(nationalId: currentNationalId)
    }

    func refreshRewardPreview(nationalId: String) async {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        currentNationalId = cleanNationalId
        state.errorMessage = nil

        do {
            state.isLoadingRewards = true
            let preview = try await buildRewardPreview(for: cleanNationalId)
            state.rewardPreview = preview
            state.isLoadingRewards = false
        } catch {
            state.isLoadingRewards = false
            state.errorMessage = error.localizedDescription
            state.rewardPreview = .empty(nationalId: cleanNationalId)
        }
    }

    func onEvent(_ event: CheckoutEvent) {
        switch event {
        case .confirmTapped:
            submitOrder()
        }
    }

    func effectiveTotal(for subtotal: Double) -> Double {
        max(0, subtotal - state.rewardPreview.discountAmount)
    }

    func appliedRewardPresentation(forMenuItemId menuItemId: String) -> RewardPresentation? {
        guard let reward = state.rewardPreview.appliedRewards.first(where: {
            $0.affectedMenuItemIds.contains(menuItemId)
        }) else {
            return nil
        }

        return RewardPresentation.from(appliedReward: reward)
    }

    func allocatedDiscountByMenuItemId() -> [String: Double] {
        state.rewardPreview.appliedRewards.reduce(into: [:]) { partial, reward in
            for menuItemId in reward.affectedMenuItemIds {
                partial[menuItemId, default: 0] += reward.amount
            }
        }
    }

    func allocatedDiscountByCartItemId(for cartItems: [CartItem]) -> [UUID: Double] {
        let menuDiscounts = allocatedDiscountByMenuItemId()
        guard !menuDiscounts.isEmpty, !cartItems.isEmpty else { return [:] }

        let grouped = Dictionary(grouping: Array(cartItems.enumerated()), by: { $0.element.menuItem.id })
        var result: [UUID: Double] = [:]

        for (menuItemId, entries) in grouped {
            let totalDiscount = roundMoney(menuDiscounts[menuItemId, default: 0])
            guard totalDiscount > 0 else { continue }

            let subtotal = entries.reduce(0) { $0 + $1.element.totalPrice }
            guard subtotal > 0 else { continue }

            var remainingDiscount = totalDiscount

            for offset in entries.indices {
                let cartItem = entries[offset].element
                let allocation: Double

                if offset == entries.count - 1 {
                    allocation = min(cartItem.totalPrice, max(0, roundMoney(remainingDiscount)))
                } else {
                    let share = cartItem.totalPrice / subtotal
                    allocation = min(
                        cartItem.totalPrice,
                        max(0, roundMoney(totalDiscount * share))
                    )
                    remainingDiscount = roundMoney(remainingDiscount - allocation)
                }

                result[cartItem.id] = allocation
            }
        }

        return result
    }

    func allocatedDiscount(for cartItem: CartItem, in cartItems: [CartItem]) -> Double {
        allocatedDiscountByCartItemId(for: cartItems)[cartItem.id, default: 0]
    }

    func clearError() {
        state.errorMessage = nil
    }

    private func startWalletObservation() {
        walletListenerToken?.remove()
        walletListenerToken = nil

        let cleanNationalId = currentNationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            state.isLoadingRewards = false
            state.rewardPreview = .empty(nationalId: "")
            return
        }

        state.isLoadingRewards = true

        walletListenerToken = loyaltyRewardsService.observeWalletSnapshot(
            for: cleanNationalId
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success:
                    await self.refreshRewardPreview(nationalId: cleanNationalId)

                case .failure(let error):
                    self.state.isLoadingRewards = false
                    self.state.errorMessage = error.localizedDescription
                    self.state.rewardPreview = .empty(nationalId: cleanNationalId)
                }
            }
        }
    }

    private func submitOrder() {
        Task { @MainActor in
            guard let baseOrder = cartManager.createOrder() else {
                state.errorMessage = "Please complete client name, table number, and cart items."
                return
            }

            state.isSubmitting = true
            state.errorMessage = nil

            do {
                let previewNationalId = (
                    baseOrder.nationalId?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? baseOrder.nationalId!
                    : currentNationalId
                )

                let latestPreview = try await buildRewardPreview(for: previewNationalId)
                state.rewardPreview = latestPreview

                let finalOrder = baseOrder.withLoyalty(
                    appliedRewards: latestPreview.appliedRewards,
                    discount: latestPreview.discountAmount
                )

                try await submitOrderUseCase.execute(order: finalOrder)

                cartManager.clear()
                state.createdOrder = finalOrder
                state.rewardPreview = .empty(nationalId: previewNationalId)
                state.isSubmitting = false
            } catch {
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func buildRewardPreview(for nationalId: String) async throws -> CheckoutRewardPreview {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            return .empty(nationalId: "")
        }

        let previewItems = cartManager.items.map {
            OrderItem(
                menuItemId: $0.menuItem.id,
                name: $0.menuItem.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity,
                notes: $0.notes
            )
        }

        guard !previewItems.isEmpty else {
            return .empty(nationalId: cleanNationalId)
        }

        let result = try await loyaltyRewardsService.previewRestaurantRewards(
            for: cleanNationalId,
            items: previewItems
        )

        return CheckoutRewardPreview(
            appliedRewards: result.appliedRewards,
            discountAmount: result.totalDiscount,
            walletSnapshot: result.walletSnapshot
        )
    }

    private func roundMoney(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/viewmodel/MenuViewModel.swift

```swift
//
//  MenuViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import Combine
import Foundation

struct RestaurantMenuState {
    var sections: [MenuSection] = []
    var isLoading = false
    var isLoadingRewards = false
    var currentNationalId: String = ""
    var rewardWalletSnapshot: RewardWalletSnapshot = .empty(nationalId: "")
    var errorMessage: String?
}

@MainActor
final class MenuViewModel: ObservableObject {
    @Published private(set) var state = RestaurantMenuState()

    private let service: MenuServiceable
    private let loyaltyRewardsService: LoyaltyRewardsServiceable
    private var listenerToken: MenuListenerTokenable?
    private var walletListenerToken: LoyaltyRewardsListenerToken?

    init(
        service: MenuServiceable,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.service = service
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func onAppear() {
        guard listenerToken == nil else { return }

        state.isLoading = true
        state.errorMessage = nil

        listenerToken = service.observeMenu { [weak self] result in
            Task { @MainActor in
                guard let self else { return }

                switch result {
                case .success(let sections):
                    self.state.sections = sections
                    self.state.isLoading = false

                case .failure(let error):
                    self.state.sections = []
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
    }

    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
        walletListenerToken?.remove()
        walletListenerToken = nil
    }

    func setNationalId(_ nationalId: String) {
        let cleanNationalId = nationalId.filter(\.isNumber)
        guard state.currentNationalId != cleanNationalId else { return }

        state.currentNationalId = cleanNationalId
        startWalletObservation()
    }

    private func startWalletObservation() {
        walletListenerToken?.remove()
        walletListenerToken = nil

        let cleanNationalId = state.currentNationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanNationalId.isEmpty else {
            state.rewardWalletSnapshot = .empty(nationalId: "")
            state.isLoadingRewards = false
            return
        }

        state.isLoadingRewards = true

        walletListenerToken = loyaltyRewardsService.observeWalletSnapshot(
            for: cleanNationalId
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.state.isLoadingRewards = false

                switch result {
                case .success(let snapshot):
                    self.state.rewardWalletSnapshot = snapshot

                case .failure(let error):
                    self.state.rewardWalletSnapshot = .empty(nationalId: cleanNationalId)
                    self.state.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func rewardPresentation(for item: MenuItem, quantity: Int = 1) -> RewardPresentation? {
        let projected = projectedRewardResult(for: item, quantity: quantity)

        if let appliedReward = projected.appliedRewards.first(where: {
            $0.affectedMenuItemIds.contains(item.id)
        }) {
            return RewardPresentation.from(appliedReward: appliedReward)
        }

        return RewardPresentationFactory.menuPresentation(
            for: item,
            wallet: state.rewardWalletSnapshot
        )
    }

    func incrementalDiscount(for item: MenuItem, quantity: Int = 1) -> Double {
        let projected = projectedRewardResult(for: item, quantity: quantity)
        return max(0, roundMoney(projected.totalDiscount))
    }

    func displayedPrice(for item: MenuItem, quantity: Int = 1) -> Double {
        let subtotal = roundMoney(item.finalPrice * Double(max(1, quantity)))
        return max(0, subtotal - incrementalDiscount(for: item, quantity: quantity))
    }

    private func projectedRewardResult(
        for item: MenuItem,
        quantity: Int
    ) -> RewardComputationResult {
        let safeQuantity = max(1, quantity)
        let wallet = state.rewardWalletSnapshot

        guard !wallet.availableTemplates.isEmpty else {
            return .empty(wallet: wallet)
        }

        return LoyaltyRewardEngine.evaluateRestaurant(
            templates: wallet.availableTemplates,
            wallet: wallet,
            menuLines: [
                RewardMenuLine(
                    menuItemId: item.id,
                    name: item.name,
                    unitPrice: item.finalPrice,
                    quantity: safeQuantity
                )
            ]
        )
    }

    private func roundMoney(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    var restaurantRewardTemplates: [LoyaltyRewardTemplate] {
        state.rewardWalletSnapshot.availableTemplates
            .filter { $0.scope.matchesRestaurant() && !$0.isExpired }
            .sorted {
                if $0.priority != $1.priority { return $0.priority < $1.priority }
                return $0.title < $1.title
            }
    }

    func rewardPresentation(for item: MenuItem) -> RewardPresentation? {
        RewardPresentationFactory.menuPresentation(
            for: item,
            wallet: state.rewardWalletSnapshot
        )
    }

    func eligibleMenuItems(for template: LoyaltyRewardTemplate) -> [MenuItem] {
        let allItems = state.sections.flatMap(\.items)

        switch template.rule.type {
        case .freeMenuItem, .specificMenuItemPercentage, .buyXGetYFree:
            guard let targetId = template.targetMenuItemId else { return [] }
            return allItems.filter { $0.id == targetId }

        case .mostExpensiveMenuItemPercentage:
            return Array(
                allItems
                    .filter(\.canBeOrdered)
                    .sorted { lhs, rhs in
                        if lhs.finalPrice != rhs.finalPrice { return lhs.finalPrice > rhs.finalPrice }
                        return lhs.name < rhs.name
                    }
                    .prefix(8)
            )

        case .activityPercentage:
            return []
        }
    }

    func expirationText(for template: LoyaltyRewardTemplate) -> String? {
        template.expirationText
    }
}

```

---

# Altos del Murco/root/feature/altos/restaurant/presentation/viewmodel/OrdersViewModel.swift

```swift
//
//  OrdersViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import Foundation

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var state = OrdersState()

    private let observeOrdersUseCase: ObserveOrdersUseCase
    private var observeTask: Task<Void, Never>?

    init(observeOrdersUseCase: ObserveOrdersUseCase) {
        self.observeOrdersUseCase = observeOrdersUseCase
    }

    func setNationalId(_ nationalId: String) {
        let clean = nationalId.filter(\.isNumber)
        guard state.nationalId != clean else { return }
        state.nationalId = clean
    }

    func onEvent(_ event: OrdersEvent) {
        switch event {
        case .onAppear:
            if state.orders.isEmpty && !state.isLoading {
                startObservingOrders()
            }
        case .refresh:
            startObservingOrders()
        }
    }

    private func startObservingOrders() {
        observeTask?.cancel()

        let nationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !nationalId.isEmpty else {
            state.orders = []
            state.errorMessage = nil
            state.isLoading = false
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        observeTask = Task {
            do {
                for try await orders in observeOrdersUseCase.execute(nationalId: nationalId) {
                    guard !Task.isCancelled else { return }
                    state.orders = orders
                    state.isLoading = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                state.isLoading = false
                state.errorMessage = error.localizedDescription
            }
        }
    }

    deinit {
        observeTask?.cancel()
    }
}

```

---

# Altos del Murco/root/navigation/AppRouter.swift

```swift
//
//  Common.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Combine
import SwiftUI

final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    
    func goToRoot() {
        path = NavigationPath()
    }
}

```

---

# Altos del Murco/root/navigation/MainTabView.swift

```swift
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
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label(MainTab.home.title, systemImage: MainTab.home.systemImage)
                }
                .tag(MainTab.home)

            RestaurantRootView(
                ordersViewModel: ordersViewModel,
                checkoutViewModel: checkoutViewModel,
                adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                menuViewModel: menuViewModel
            )
            .tabItem {
                Label(MainTab.restaurant.title, systemImage: MainTab.restaurant.systemImage)
            }
            .tag(MainTab.restaurant)

            ExperiencesView(
                adventureComboBuilderViewModel: adventureComboBuilderViewModel,
                menuViewModel: menuViewModel
            )
            .tabItem {
                Label(MainTab.experiences.title, systemImage: MainTab.experiences.systemImage)
            }
            .tag(MainTab.experiences)

            BookingsView(
                ordersViewModel: ordersViewModel,
                adventureModuleFactory: adventureModuleFactory
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
        case .experiences: return "Aventura"
        case .bookings: return "Reservas"
        case .profile: return "Perfil"
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

```

---

# Altos del Murco/root/navigation/RootView.swift

```swift
//
//  RootView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import SwiftUI

struct RootView<Home: View>: View {
    @ObservedObject var viewModel: AppSessionViewModel
    let home: () -> Home

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                SessionLoadingView()
                    .transition(.opacity)

            case .signedOut:
                AuthenticationView(viewModel: viewModel)
                    .transition(.opacity)

            case .needsProfile(let user, let existingProfile):
                CompleteProfileView {
                    viewModel.makeCompleteProfileViewModel(
                        user: user,
                        existingProfile: existingProfile
                    )
                }
                .transition(.opacity)

            case .authenticated:
                home()
                    .transition(.opacity)

            case .error(let message):
                SessionErrorView(
                    message: message,
                    retryAction: {
                        Task { await viewModel.bootstrap() }
                    },
                    signOutAction: {
                        viewModel.signOut()
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.screenKey)
    }
}

private struct SessionLoadingView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: .restaurant, scheme: colorScheme)
        
        ZStack {
            BrandScreenBackground(theme: .restaurant)

            VStack(spacing: 24) {
                VStack(spacing: 18) {
                    BrandIconBubble(
                        theme: .restaurant,
                        systemImage: "flame.fill",
                        size: 72
                    )
                    
                    VStack(spacing: 8) {
                        Text("Altos del Murco")
                            .font(.title.bold())
                            .foregroundStyle(palette.textPrimary)
                        
                        Text("Loading your experience...")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
                
                VStack(spacing: 14) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(palette.primary)
                    
                    Text("Please wait a moment")
                        .font(.footnote)
                        .foregroundStyle(palette.textTertiary)
                }
            }
            .frame(maxWidth: 360)
            .appCardStyle(.restaurant, emphasized: false)
            .padding(24)
        }
    }
}

private struct SessionErrorView: View {
    let message: String
    let retryAction: () -> Void
    let signOutAction: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = AppTheme.palette(for: .neutral, scheme: colorScheme)
        
        ZStack {
            BrandScreenBackground(theme: .neutral)

            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .fill(palette.destructive.opacity(colorScheme == .dark ? 0.22 : 0.12))
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(palette.destructive)
                }

                VStack(spacing: 10) {
                    Text("Something went wrong")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text(message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(palette.textSecondary)
                }

                VStack(spacing: 12) {
                    Button(action: retryAction) {
                        Text("Try again")
                    }
                    .buttonStyle(BrandPrimaryButtonStyle(theme: .neutral))

                    Button(action: signOutAction) {
                        Text("Sign out")
                    }
                    .buttonStyle(BrandSecondaryButtonStyle(theme: .neutral))
                }
            }
            .frame(maxWidth: 420)
            .appCardStyle(.neutral, emphasized: true)
            .padding(24)
        }
    }
}

```

---

# Altos del Murco/root/navigation/Route.swift

```swift
//
//  Route.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum Route: Hashable {
    case menuDetail(MenuItem, String)
    case cart
    case checkout
    case reservationBuilder
    case orderSuccess(Order)
}

```

---

# Altos del Murco/root/ui/theme/AltosColours.swift

```swift
//
//  AltosColours.swift
//  Altos del Murco
//
//  Created by José Ruiz on 5/4/26.
//

import Foundation
import SwiftUI

// MARK: - Theme Namespace

enum AppSectionTheme: String, Hashable, CaseIterable {
    case neutral
    case adventure
    case restaurant
    
    /// Optional watermark asset names.
    /// Add your uploaded illustrations to Assets using these names if you want them as subtle background marks.
    var watermarkAssetName: String? {
        switch self {
        case .neutral:
            return nil
        case .adventure:
            return "theme_adventure_mark"
        case .restaurant:
            return "theme_restaurant_mark"
        }
    }
}

struct ThemePalette {
    let primary: Color
    let secondary: Color
    let accent: Color
    let onPrimary: Color
    
    let background: Color
    let surface: Color
    let card: Color
    let elevatedCard: Color
    let stroke: Color
    
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    
    let success: Color
    let warning: Color
    let destructive: Color
    
    let shadow: Color
    let glow: Color
    
    let heroGradient: LinearGradient
    let softGradient: LinearGradient
    let cardGradient: LinearGradient
    let chipGradient: LinearGradient
}

enum AppTheme {
    
    enum Radius {
        static let small: CGFloat = 14
        static let medium: CGFloat = 18
        static let large: CGFloat = 22
        static let xLarge: CGFloat = 28
    }
    
    enum Metrics {
        static let fieldHeight: CGFloat = 54
        static let buttonHeight: CGFloat = 54
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let shadowRadius: CGFloat = 18
        static let shadowY: CGFloat = 10
    }
    
    static func palette(for theme: AppSectionTheme, scheme: ColorScheme) -> ThemePalette {
        switch theme {
        case .neutral:
            let primary = Color.adaptive(
                light: UIColor(hex: 0x2F3E4F),
                dark: UIColor(hex: 0xB5C2D0)
            )
            let secondary = Color.adaptive(
                light: UIColor(hex: 0x5F738A),
                dark: UIColor(hex: 0x8FA7BF)
            )
            let accent = Color.adaptive(
                light: UIColor(hex: 0x6F8FB0),
                dark: UIColor(hex: 0x9DB6D4)
            )
            let onPrimary = Color.white
            
            let background = Color.adaptive(
                light: UIColor(hex: 0xF4F7FA),
                dark: UIColor(hex: 0x0C1014)
            )
            let surface = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x12171D)
            )
            let card = Color.adaptive(
                light: UIColor(hex: 0xFBFCFD),
                dark: UIColor(hex: 0x151B22)
            )
            let elevatedCard = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x19212A)
            )
            let stroke = Color.adaptive(
                light: UIColor(hex: 0xDDE5EC),
                dark: UIColor(hex: 0x2A3542)
            )
            
            let textPrimary = Color.adaptive(
                light: UIColor(hex: 0x15202B),
                dark: UIColor(hex: 0xF1F5F9)
            )
            let textSecondary = Color.adaptive(
                light: UIColor(hex: 0x5C6B7A),
                dark: UIColor(hex: 0xA7B4C2)
            )
            let textTertiary = Color.adaptive(
                light: UIColor(hex: 0x8A97A5),
                dark: UIColor(hex: 0x728191)
            )
            
            let success = Color.adaptive(
                light: UIColor(hex: 0x2F855A),
                dark: UIColor(hex: 0x68D391)
            )
            let warning = Color.adaptive(
                light: UIColor(hex: 0xB7791F),
                dark: UIColor(hex: 0xF6AD55)
            )
            let destructive = Color.adaptive(
                light: UIColor(hex: 0xC53030),
                dark: UIColor(hex: 0xFC8181)
            )
            
            let shadow = Color.black
            let glow = Color.adaptive(
                light: UIColor(hex: 0x9DB6D4),
                dark: UIColor(hex: 0x5D7996)
            )
            
            return ThemePalette(
                primary: primary,
                secondary: secondary,
                accent: accent,
                onPrimary: onPrimary,
                background: background,
                surface: surface,
                card: card,
                elevatedCard: elevatedCard,
                stroke: stroke,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                success: success,
                warning: warning,
                destructive: destructive,
                shadow: shadow,
                glow: glow,
                heroGradient: LinearGradient(
                    colors: [primary, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                softGradient: LinearGradient(
                    colors: [
                        background,
                        accent.opacity(scheme == .dark ? 0.10 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [
                        elevatedCard,
                        card
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                chipGradient: LinearGradient(
                    colors: [
                        primary.opacity(scheme == .dark ? 0.24 : 0.14),
                        accent.opacity(scheme == .dark ? 0.16 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .adventure:
            let primary = Color.adaptive(
                light: UIColor(hex: 0x2F6B3C),
                dark: UIColor(hex: 0x7BCB69)
            )
            let secondary = Color.adaptive(
                light: UIColor(hex: 0x4D8A47),
                dark: UIColor(hex: 0x9BE07C)
            )
            let accent = Color.adaptive(
                light: UIColor(hex: 0xA6C95A),
                dark: UIColor(hex: 0xD5F08D)
            )
            let onPrimary = Color.white
            
            let background = Color.adaptive(
                light: UIColor(hex: 0xF2F7F0),
                dark: UIColor(hex: 0x0B140D)
            )
            let surface = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x111B13)
            )
            let card = Color.adaptive(
                light: UIColor(hex: 0xF8FCF6),
                dark: UIColor(hex: 0x152017)
            )
            let elevatedCard = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x19261B)
            )
            let stroke = Color.adaptive(
                light: UIColor(hex: 0xD8E7D4),
                dark: UIColor(hex: 0x2A3C2D)
            )
            
            let textPrimary = Color.adaptive(
                light: UIColor(hex: 0x142117),
                dark: UIColor(hex: 0xEEF8EE)
            )
            let textSecondary = Color.adaptive(
                light: UIColor(hex: 0x5D7260),
                dark: UIColor(hex: 0xA8BDAA)
            )
            let textTertiary = Color.adaptive(
                light: UIColor(hex: 0x839485),
                dark: UIColor(hex: 0x708172)
            )
            
            let success = Color.adaptive(
                light: UIColor(hex: 0x2F855A),
                dark: UIColor(hex: 0x68D391)
            )
            let warning = Color.adaptive(
                light: UIColor(hex: 0xB7791F),
                dark: UIColor(hex: 0xF6C15A)
            )
            let destructive = Color.adaptive(
                light: UIColor(hex: 0xC53030),
                dark: UIColor(hex: 0xFC8181)
            )
            
            let shadow = Color.black
            let glow = Color.adaptive(
                light: UIColor(hex: 0x9FD96A),
                dark: UIColor(hex: 0x59B84B)
            )
            
            return ThemePalette(
                primary: primary,
                secondary: secondary,
                accent: accent,
                onPrimary: onPrimary,
                background: background,
                surface: surface,
                card: card,
                elevatedCard: elevatedCard,
                stroke: stroke,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                success: success,
                warning: warning,
                destructive: destructive,
                shadow: shadow,
                glow: glow,
                heroGradient: LinearGradient(
                    colors: [primary, secondary, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                softGradient: LinearGradient(
                    colors: [
                        background,
                        primary.opacity(scheme == .dark ? 0.18 : 0.07),
                        accent.opacity(scheme == .dark ? 0.10 : 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [
                        elevatedCard,
                        card,
                        accent.opacity(scheme == .dark ? 0.04 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                chipGradient: LinearGradient(
                    colors: [
                        primary.opacity(scheme == .dark ? 0.30 : 0.14),
                        accent.opacity(scheme == .dark ? 0.18 : 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .restaurant:
            let primary = Color.adaptive(
                light: UIColor(hex: 0x3E4347),   // charcoal
                dark: UIColor(hex: 0xC2C8CE)     // soft silver
            )
            let secondary = Color.adaptive(
                light: UIColor(hex: 0x5A6066),   // graphite
                dark: UIColor(hex: 0x9BA3AB)     // muted steel
            )
            let accent = Color.adaptive(
                light: UIColor(hex: 0x8B7D67),   // aged brass / vintage taupe
                dark: UIColor(hex: 0xC5B79E)     // soft antique metal
            )
            let onPrimary = Color.white
            
            let background = Color.adaptive(
                light: UIColor(hex: 0xF3F2F0),   // warm stone
                dark: UIColor(hex: 0x0D0F11)     // deep charcoal black
            )
            let surface = Color.adaptive(
                light: UIColor(hex: 0xFCFBFA),   // soft neutral
                dark: UIColor(hex: 0x14171A)     // dark graphite
            )
            let card = Color.adaptive(
                light: UIColor(hex: 0xF7F5F3),   // vintage paper-stone
                dark: UIColor(hex: 0x1A1E22)     // lifted dark card
            )
            let elevatedCard = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x20252A)
            )
            let stroke = Color.adaptive(
                light: UIColor(hex: 0xD8D4CE),   // soft border
                dark: UIColor(hex: 0x333940)     // subtle dark divider
            )
            
            let textPrimary = Color.adaptive(
                light: UIColor(hex: 0x1C1F22),
                dark: UIColor(hex: 0xF3F5F7)
            )
            let textSecondary = Color.adaptive(
                light: UIColor(hex: 0x666D74),
                dark: UIColor(hex: 0xB1B8BF)
            )
            let textTertiary = Color.adaptive(
                light: UIColor(hex: 0x8A9096),
                dark: UIColor(hex: 0x7A838C)
            )
            
            let success = Color.adaptive(
                light: UIColor(hex: 0x2F855A),
                dark: UIColor(hex: 0x68D391)
            )
            let warning = Color.adaptive(
                light: UIColor(hex: 0x9C7B3D),   // muted vintage gold
                dark: UIColor(hex: 0xD6B56E)
            )
            let destructive = Color.adaptive(
                light: UIColor(hex: 0xC94C4C),
                dark: UIColor(hex: 0xFC8181)
            )
            
            let shadow = Color.black
            let glow = Color.adaptive(
                light: UIColor(hex: 0xA79A84),   // subtle warm smoke
                dark: UIColor(hex: 0x7B7468)
            )
            
            return ThemePalette(
                primary: primary,
                secondary: secondary,
                accent: accent,
                onPrimary: onPrimary,
                background: background,
                surface: surface,
                card: card,
                elevatedCard: elevatedCard,
                stroke: stroke,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                success: success,
                warning: warning,
                destructive: destructive,
                shadow: shadow,
                glow: glow,
                heroGradient: LinearGradient(
                    colors: [primary, secondary, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                softGradient: LinearGradient(
                    colors: [
                        background,
                        primary.opacity(scheme == .dark ? 0.16 : 0.05),
                        accent.opacity(scheme == .dark ? 0.10 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [
                        elevatedCard,
                        card,
                        accent.opacity(scheme == .dark ? 0.035 : 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                chipGradient: LinearGradient(
                    colors: [
                        primary.opacity(scheme == .dark ? 0.28 : 0.12),
                        accent.opacity(scheme == .dark ? 0.14 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Background System

struct BrandScreenBackground: View {
    let theme: AppSectionTheme
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        ZStack {
            palette.background
                .ignoresSafeArea()
            
            palette.softGradient
                .ignoresSafeArea()
            
            switch theme {
            case .neutral:
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.14 : 0.10))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: -120, y: -220)
                
            case .adventure:
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.22 : 0.16))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(x: -140, y: -240)
                
                Circle()
                    .fill(palette.secondary.opacity(colorScheme == .dark ? 0.16 : 0.10))
                    .frame(width: 240, height: 240)
                    .blur(radius: 80)
                    .offset(x: 150, y: 260)
                
            case .restaurant:
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.22 : 0.16))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: 120, y: -220)
                
                Circle()
                    .fill(palette.primary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 90)
                    .offset(x: -150, y: 280)
            }
            
            BrandWatermark(theme: theme)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 70)
                .padding(.trailing, 20)
                .opacity(colorScheme == .dark ? 0.05 : 0.08)
        }
    }
}

struct BrandWatermark: View {
    let theme: AppSectionTheme
    
    var body: some View {
        Group {
            if let assetName = theme.watermarkAssetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Reusable Components

struct BrandSectionHeader: View {
    let theme: AppSectionTheme
    let title: String
    let subtitle: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(theme: AppSectionTheme, title: String, subtitle: String? = nil) {
        self.theme = theme
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Capsule()
                    .fill(palette.heroGradient)
                    .frame(width: 28, height: 8)
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
            }
            
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BrandIconBubble: View {
    let theme: AppSectionTheme
    let systemImage: String
    var size: CGFloat = 48
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        ZStack {
            Circle()
                .fill(palette.chipGradient)
                .overlay(
                    Circle()
                        .stroke(palette.stroke, lineWidth: 1)
                )
            
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(palette.primary)
        }
        .frame(width: size, height: size)
    }
}

struct BrandBadge: View {
    let theme: AppSectionTheme
    let title: String
    var selected: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? palette.onPrimary : palette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selected ? AnyShapeStyle(palette.heroGradient) : AnyShapeStyle(palette.chipGradient))
            )
            .overlay(
                Capsule()
                    .stroke(selected ? palette.primary.opacity(0.0) : palette.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Button Styles

struct BrandPrimaryButtonStyle: ButtonStyle {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        let pressed = configuration.isPressed
        
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(palette.onPrimary.opacity(isEnabled ? 1 : 0.75))
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(palette.heroGradient) : AnyShapeStyle(palette.stroke))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18), lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.32 : 0.14),
                radius: pressed ? 10 : AppTheme.Metrics.shadowRadius,
                x: 0,
                y: pressed ? 4 : AppTheme.Metrics.shadowY
            )
            .scaleEffect(pressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.18), value: pressed)
    }
}

struct BrandSecondaryButtonStyle: ButtonStyle {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        let pressed = configuration.isPressed
        
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(isEnabled ? palette.textPrimary : palette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.08),
                radius: pressed ? 8 : 14,
                x: 0,
                y: pressed ? 3 : 8
            )
            .scaleEffect(pressed ? 0.988 : 1.0)
            .animation(.easeOut(duration: 0.18), value: pressed)
    }
}

// MARK: - View Modifiers

struct BrandScreenModifier: ViewModifier {
    let theme: AppSectionTheme
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .tint(palette.primary)
            .foregroundStyle(palette.textPrimary)
            .background(BrandScreenBackground(theme: theme))
    }
}

struct BrandCardModifier: ViewModifier {
    let theme: AppSectionTheme
    var emphasized: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .padding(AppTheme.Metrics.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if emphasized {
                    Capsule()
                        .fill(palette.heroGradient)
                        .frame(width: 62, height: 6)
                        .padding(16)
                }
            }
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                radius: AppTheme.Metrics.shadowRadius,
                x: 0,
                y: AppTheme.Metrics.shadowY
            )
    }
}

struct BrandTextFieldModifier: ViewModifier {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .foregroundStyle(palette.textPrimary)
            .tint(palette.primary)
            .padding(.horizontal, 16)
            .frame(minHeight: AppTheme.Metrics.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(palette.elevatedCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.12 : 0.04),
                radius: 8,
                x: 0,
                y: 3
            )
    }
}

struct BrandListRowModifier: ViewModifier {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
                radius: 10,
                x: 0,
                y: 5
            )
    }
}

// MARK: - View Convenience API

extension View {
    func appScreenStyle(_ theme: AppSectionTheme) -> some View {
        modifier(BrandScreenModifier(theme: theme))
    }
    
    func appCardStyle(_ theme: AppSectionTheme, emphasized: Bool = false) -> some View {
        modifier(BrandCardModifier(theme: theme, emphasized: emphasized))
    }
    
    func appTextFieldStyle(_ theme: AppSectionTheme) -> some View {
        modifier(BrandTextFieldModifier(theme: theme))
    }
    
    func appListRowStyle(_ theme: AppSectionTheme) -> some View {
        modifier(BrandListRowModifier(theme: theme))
    }
}

// MARK: - UINavigationBar / UITabBar Appearance

@MainActor
enum ThemeAppearance {
    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }
    
    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.label
    }
    
    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.82)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.10)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Helpers

extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

```

---

# Altos del Murco/root/util/Logs.swift

```swift
//
//  Logs.swift
//  Altos del Murco
//
//  Created by José Ruiz on 22/4/26.
//

import Foundation
import OSLog

//enum RewardDebugLog {
//    static let isEnabled = true
//
//    private static let logger = Logger(
//        subsystem: Bundle.main.bundleIdentifier ?? "AltosDelMurco",
//        category: "RewardsAdventure"
//    )
//
//    static func info(_ message: String) {
//        guard isEnabled else { return }
//        logger.info("\(message, privacy: .public)")
//    }
//
//    static func error(_ message: String) {
//        guard isEnabled else { return }
//        logger.error("\(message, privacy: .public)")
//    }
//
//    static func dumpAppliedRewards(_ rewards: [AppliedReward], prefix: String) {
//        guard isEnabled else { return }
//
//        if rewards.isEmpty {
//            info("\(prefix) appliedRewards=[]")
//            return
//        }
//
//        for reward in rewards {
//            info(
//                "\(prefix) reward id=\(reward.id) templateId=\(reward.templateId) title=\(reward.title) amount=\(formatMoney(reward.amount)) menuItemIds=\(reward.affectedMenuItemIds.joined(separator: ",")) activityIds=\(reward.affectedActivityIds.joined(separator: ",")) note=\(reward.note)"
//            )
//        }
//    }
//
//    static func formatMoney(_ value: Double) -> String {
//        String(format: "%.2f", value)
//    }
//}

```

---

# Altos del Murco/root/util/constant/FirestoreConstants.swift

```swift
//
//  FirestoreConstants.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

enum FirestoreConstants {
    static let restaurant_orders = "restaurant_orders"
    static let adventure_bookings = "adventure_bookings"
    static let loyalty_transactions = "loyalty_transactions"
    static let posts = "posts"
    static let restaurant_menu_items = "restaurant_menu_items"
    static let client_loyalty_wallets = "client_loyalty_wallets"
    static let loyalty_reward_templates = "loyalty_reward_templates"
}

```

---

# Altos del Murco/root/util/extension/Date+Elapsed.swift

```swift
//
//  Date+Elapsed.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

extension Date {
    func elapsedTimeText(relativeTo now: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: now)
    }
    
    func elapsedMinutes(relativeTo now: Date = Date()) -> Int {
        max(0, Int(now.timeIntervalSince(self) / 60))
    }
    
    var shortDateTimeString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}


```

---

# Altos del Murco/root/util/extension/Double.swift

```swift
//
//  Double.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

extension Double {
    
    var priceText: String {
        "\(String(format: "%.2f", self))"
    }
}

```

---

# Altos del Murco/root/util/extension/OrderDraftExtension.swift

```swift
//
//  OrderDraft.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

extension OrderDraft {
    func toOrder(orderId: String = UUID().uuidString, status: OrderStatus = .pending) -> Order {
        let orderItems = items.map {
            OrderItem(
                menuItemId: $0.menuItem.id,
                name: $0.menuItem.name,
                unitPrice: $0.unitPrice,
                quantity: $0.quantity,
                notes: $0.notes
            )
        }
        
        return Order(
            id: orderId,
            nationalId: nationalId,
            clientName: clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            tableNumber: tableNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: Date(),
            updatedAt: Date(),
            items: orderItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: status,
            revision: revision ?? 0,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }
    
    var hasValidClientName: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasValidTableNumber: Bool {
        !tableNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var canSubmit: Bool {
        !isEmpty && hasValidClientName && hasValidTableNumber
    }
}


```

---

# Altos del Murco/root/util/extension/OrderStatusExtension.swift

```swift
//
//  OrderStatusExtension.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

extension OrderStatus {
    var badgeColor: Color {
        switch self {
        case .pending: return .orange
        case .confirmed: return .blue
        case .preparing: return .purple
        case .completed: return .gray
        case .canceled: return .red
        }
    }
}

```

---

