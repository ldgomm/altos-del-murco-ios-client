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
    @StateObject private var menuViewModel: MenuViewModel
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

            let adventureService = AdventureBookingsService()
            self.adventureModuleFactory = AdventureModuleFactory(service: adventureService)

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

            let sessionVM = AppSessionViewModel(
                signInWithAppleUseCase: signInWithAppleUseCase,
                resolveSessionUseCase: resolveSessionUseCase,
                completeClientProfileUseCase: completeClientProfileUseCase,
                deleteCurrentAccountUseCase: deleteCurrentAccountUseCase,
                signOutUseCase: signOutUseCase
            )

            _sessionViewModel = StateObject(wrappedValue: sessionVM)
            
            let menuService = MenuService()
            let menuViewModel = MenuViewModel(service: menuService)
            _menuViewModel = StateObject(wrappedValue: menuViewModel)

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

struct AdventureReservationItemDraftDTO: Codable {
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

struct ReservationFoodItemDraftDTO: Codable {
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

struct ReservationFoodDraftDTO: Codable {
    let items: [ReservationFoodItemDraftDTO]
    let servingMoment: String
    let servingTime: Timestamp?
    let notes: String?
    
    init(from food: ReservationFoodDraft) {
        self.items = food.items.map(ReservationFoodItemDraftDTO.init(from:))
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

struct AdventureBookingBlockDTO: Codable {
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

@MainActor
struct AdventureBookingDTO: Codable {
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
    let items: [AdventureReservationItemDraftDTO]
    let foodReservation: ReservationFoodDraftDTO?
    let blocks: [AdventureBookingBlockDTO]
    let adventureSubtotal: Double?
    let foodSubtotal: Double?
    let subtotal: Double
    let discountAmount: Double
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
        createdAt: Date
    ) -> AdventureBookingDTO {
        AdventureBookingDTO(
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
            items: request.items.map(AdventureReservationItemDraftDTO.init(from:)),
            foodReservation: request.foodReservation.map(ReservationFoodDraftDTO.init(from:)),
            blocks: plan.blocks.map(AdventureBookingBlockDTO.init(from:)),
            adventureSubtotal: plan.adventureSubtotal,
            foodSubtotal: plan.foodSubtotal,
            subtotal: plan.subtotal,
            discountAmount: plan.discountAmount,
            nightPremium: plan.nightPremium,
            totalAmount: plan.totalAmount,
            status: AdventureBookingStatus.confirmed.rawValue,
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

final class AdventureBookingsService: AdventureBookingsServiceable {
    private let db: Firestore
    private let bookingsCollection = "adventure_bookings"
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func observeBookings(
        for day: Date,
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        let dayKey = AdventureDateHelper.dayKey(from: day)
        let nationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let registration = db.collection(bookingsCollection)
            .whereField("nationalId", isEqualTo: nationalId)
            .whereField("startDayKey", isEqualTo: dayKey)
            .order(by: "startAt")
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
                        let dto = try document.data(as: AdventureBookingDTO.self)
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
        foodReservation: ReservationFoodDraft?
    ) async throws -> [AdventureAvailabilitySlot] {
        AdventurePlanner.buildAvailability(
            day: date,
            items: items,
            foodReservation: foodReservation
        )
    }
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking {
        guard let plan = AdventurePlanner.buildPlan(
            day: request.date,
            startAt: request.selectedStartAt,
            items: request.items,
            foodReservation: request.foodReservation
        ) else {
            throw makeError("Invalid reservation configuration.")
        }
        
        let createdAt = Date()
        let bookingRef = db.collection(bookingsCollection).document()
        let dto = AdventureBookingDTO.from(
            bookingId: bookingRef.documentID,
            request: request,
            plan: plan,
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
        
        return dto.toDomain(documentId: bookingRef.documentID)
    }
    
    func cancelBooking(id: String, nationalId: String) async throws {
        let bookingRef = db.collection(bookingsCollection).document(id)
        let snapshot = try await bookingRef.getDocument()
        
        guard snapshot.exists else {
            throw makeError("Booking not found.")
        }
        
        let dto = try snapshot.data(as: AdventureBookingDTO.self)
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

extension AdventureService {
    static let mockServices: [AdventureService] = [
        AdventureService(
            activityType: .offRoad,
            title: "Off-road 4x4",
            systemImage: "car.fill",
            shortDescription: "Reserva 1, 2 o 3 horas por vehículo.",
            fullDescription: "Un vehículo off-road admite 1 o 2 personas. El precio es por vehículo por hora.",
            priceText: "$20 / hora / vehículo",
            durationText: "1 - 3 horas",
            includes: ["Vehículo", "Guía", "Charla de seguridad"]
        ),
        AdventureService(
            activityType: .paintball,
            title: "Paintball",
            systemImage: "shield.lefthalf.filled",
            shortDescription: "Sesiones flexibles para grupos.",
            fullDescription: "Reserva paintball en bloques de 30 minutos para tantas personas como desees.",
            priceText: "$5 / 30 min / persona",
            durationText: "30 - 120 min",
            includes: ["Marcadora", "Máscara", "Munición básica"]
        ),
        AdventureService(
            activityType: .goKarts,
            title: "Go karts",
            systemImage: "flag.checkered",
            shortDescription: "Vueltas rápidas con duración flexible.",
            fullDescription: "Reserva go karts en bloques de 30 minutos para grupos pequeños o grandes.",
            priceText: "$5 / 30 min / persona",
            durationText: "30 - 120 min",
            includes: ["Kart", "Casco", "Acceso a la pista"]
        ),
        AdventureService(
            activityType: .shootingRange,
            title: "Campo de tiro",
            systemImage: "target",
            shortDescription: "Sesiones de precisión por tiempo y número de personas.",
            fullDescription: "Reserva el campo de tiro de forma individual o dentro de un combo.",
            priceText: "$5 / 30 min / persona",
            durationText: "30 - 120 min",
            includes: ["Equipo", "Charla de seguridad"]
        ),
        AdventureService(
            activityType: .camping,
            title: "Camping",
            systemImage: "tent.fill",
            shortDescription: "Estadía nocturna con comida y experiencia off-road incluida.",
            fullDescription: "El camping se reserva por persona por noche y funciona como complemento nocturno.",
            priceText: "$30 / persona / noche",
            durationText: "1+ noches",
            includes: ["Comida", "Área para dormir", "Experiencia off-road incluida"]
        ),
        AdventureService(
            activityType: .extremeSlide,
            title: "Resvaladera extrema",
            systemImage: "figure.fall",
            shortDescription: "Experiencia en la resbaladera extrema con transporte off-road incluido.",
            fullDescription: "Una sesión fija que incluye el transporte y la resbaladera extrema.",
            priceText: "$15 / persona",
            durationText: "30 min + transporte",
            includes: ["Sesión en la resbaladera", "Transporte off-road incluido"]
        )
    ]
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
        for day: Date,
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken
    
    func fetchAvailability(
        for date: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?
    ) async throws -> [AdventureAvailabilitySlot]
    
    func createBooking(_ request: AdventureBookingRequest) async throws -> AdventureBooking
    
    func cancelBooking(id: String, nationalId: String) async throws
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
    
    var title: String {
        switch self {
        case .offRoad: return "Off-road 4x4"
        case .paintball: return "Paintball"
        case .goKarts: return "Go karts"
        case .shootingRange: return "Campo de tiro"
        case .camping: return "Camping"
        case .extremeSlide: return "Resbaladera extrema"
        }
    }
    
    var systemImage: String {
        switch self {
        case .offRoad: return "car.fill"
        case .paintball: return "shield.lefthalf.filled"
        case .goKarts: return "flag.checkered"
        case .shootingRange: return "target"
        case .camping: return "tent.fill"
        case .extremeSlide: return "figure.fall"
        }
    }
    
    var durationOptions: [Int] {
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
}

enum AdventureResourceType: String, Codable, Hashable {
    case offRoadVehicles
    case paintballPeople
    case goKartPeople
    case shootingPeople
    case campingPeople
    case extremeSlidePeople
}

enum AdventureBookingStatus: String, Codable, CaseIterable, Hashable {
    case pending
    case confirmed
    case canceled
    
    var title: String {
        switch self {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
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
    
    var title: String { activity.title }
    
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
    let notes: String?
    
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

struct AdventureTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String?
    let items: [AdventureReservationItemDraft]
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

    static func subtotal(for item: AdventureReservationItemDraft) -> Double {
        switch item.activity {
        case .offRoad:
            let hours = Double(item.durationMinutes) / 60
            return 20 * hours * Double(item.vehicleCount)
        case .paintball:
            return 5 * Double(item.durationMinutes / 30) * Double(item.peopleCount)
        case .goKarts:
            return 5 * Double(item.durationMinutes / 30) * Double(item.peopleCount)
        case .shootingRange:
            return 5 * Double(item.durationMinutes / 30) * Double(item.peopleCount)
        case .camping:
            return 30 * Double(item.peopleCount) * Double(item.nights)
        case .extremeSlide:
            return 15 * Double(item.peopleCount)
        }
    }

    static func estimatedSubtotal(items: [AdventureReservationItemDraft]) -> Double {
        items.reduce(0) { $0 + subtotal(for: $1) }
    }

    static func discount(for subtotal: Double) -> Double {
        let completeTenDollarSteps = Int(subtotal / 10)
        return Double(completeTenDollarSteps) * 0.5
    }

    static func foodSubtotal(for foodReservation: ReservationFoodDraft?) -> Double {
        foodReservation?.subtotal ?? 0
    }
    
    static func discountedSubtotal(for subtotal: Double) -> Double {
        max(0, subtotal - discount(for: subtotal))
    }

    static func estimatedDiscountedSubtotal(items: [AdventureReservationItemDraft]) -> Double {
        discountedSubtotal(for: estimatedSubtotal(items: items))
    }

    static func estimatedNightPremium(items: [AdventureReservationItemDraft]) -> Double {
        let hasCamping = items.contains { $0.activity == .camping }
        guard hasCamping else { return 0 }

        let discounted = estimatedDiscountedSubtotal(items: items)
        return discounted * nightPremiumRate
    }
}

enum AdventurePlanner {
    static func buildPlan(
        day: Date,
        startAt: Date,
        items: [AdventureReservationItemDraft],
        foodReservation: ReservationFoodDraft?
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
            let end = AdventureDateHelper.addMinutes(AdventureSchedule.foodOnlyDefaultDurationMinutes, to: startAt)
            guard end <= dayEnd else { return nil }
            
            return AdventureBuildPlan(
                startAt: startAt,
                endAt: end,
                blocks: [],
                adventureSubtotal: 0,
                foodSubtotal: foodSubtotal,
                subtotal: foodSubtotal,
                discountAmount: 0,
                nightPremium: 0,
                totalAmount: foodSubtotal,
                hasNightPremium: false
            )
        }
        
        var cursor = startAt
        var blocks: [AdventureBookingBlock] = []
        var adventureSubtotal = 0.0
        
        for (index, item) in items.enumerated() {
            switch item.activity {
            case .offRoad:
                guard item.vehicleCount > 0 else { return nil }
                guard item.offRoadRiderCount > 0 else { return nil }
                guard item.offRoadRiderCount <= item.vehicleCount * AdventureSchedule.offRoadPeoplePerVehicle else { return nil }
                
                let end = AdventureDateHelper.addMinutes(item.durationMinutes, to: cursor)
                guard end <= dayEnd else { return nil }
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                adventureSubtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Off-Road 4x4",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                adventureSubtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Paintball",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                adventureSubtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Go Karts",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                adventureSubtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Campo de tiro",
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
                
                let lineSubtotal = AdventurePricingEngine.subtotal(for: item)
                adventureSubtotal += lineSubtotal
                
                blocks.append(
                    AdventureBookingBlock(
                        id: UUID().uuidString,
                        title: "Extreme Slide",
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
                
                for night in 0..<max(1, item.nights) {
                    let start = AdventureDateHelper.addDays(night, to: campingStart)
                    let end = AdventureDateHelper.addMinutes(12 * 60, to: start)
                    let nightSubtotal = 30 * Double(item.peopleCount)
                    adventureSubtotal += nightSubtotal
                    
                    blocks.append(
                        AdventureBookingBlock(
                            id: UUID().uuidString,
                            title: "Camping Night \(night + 1)",
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
        
        //Later off-road
//        let hasMisalignedOffRoadBlock = blocks.contains {
//            $0.activity == .offRoad &&
//            AdventureDateHelper.calendar.component(.minute, from: $0.startAt) != 0
//        }
        
//        guard !hasMisalignedOffRoadBlock else { return nil }
        guard let last = blocks.last else { return nil }
        
        let hasNightPremium =
            items.contains(where: { $0.activity == .camping }) ||
            blocks.contains { AdventureDateHelper.isNightPremiumTime($0.startAt, $0.endAt) }
        
        let discountAmount = AdventurePricingEngine.discount(for: adventureSubtotal)
        let discountedAdventureSubtotal = AdventurePricingEngine.discountedSubtotal(for: adventureSubtotal)
        
        //Later premium
//        let premium = hasNightPremium ? discountedAdventureSubtotal * AdventurePricingEngine.nightPremiumRate : 0
        
        let totalSubtotal = adventureSubtotal + foodSubtotal
        let totalAmount = discountedAdventureSubtotal + foodSubtotal// + premium
        
        return AdventureBuildPlan(
            startAt: startAt,
            endAt: last.endAt,
            blocks: blocks,
            adventureSubtotal: adventureSubtotal,
            foodSubtotal: foodSubtotal,
            subtotal: totalSubtotal,
            discountAmount: discountAmount,
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
        foodReservation: ReservationFoodDraft?
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
                    foodReservation: foodReservation
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

enum AdventureCatalogTemplates {
    static let featured: [AdventureTemplate] = [
        AdventureTemplate(
            id: "off-road-duo",
            title: "Off-road dúo",
            subtitle: "1 hora de off-road para 2 personas",
            badge: "Popular",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 60,
                    peopleCount: 0,
                    vehicleCount: 1,
                    offRoadRiderCount: 2,
                    nights: 0
                )
            ]
        ),
        AdventureTemplate(
            id: "adrenaline-mix",
            title: "Mix de adrenalina",
            subtitle: "1 hora de off-road + 30 min de karts + 30 min de paintball",
            badge: "Destacado",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 60,
                    peopleCount: 0,
                    vehicleCount: 2,
                    offRoadRiderCount: 4,
                    nights: 0
                ),
                AdventureActivityType.defaultDraft(for: .goKarts),
                AdventureActivityType.defaultDraft(for: .paintball)
            ]
        ),
        AdventureTemplate(
            id: "full-adventure",
            title: "Aventura completa",
            subtitle: "2h off-road + 1h karts + 30m paintball + 30m tiro",
            badge: "Más vendido",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 120,
                    peopleCount: 0,
                    vehicleCount: 2,
                    offRoadRiderCount: 4,
                    nights: 0
                ),
                AdventureReservationItemDraft(
                    activity: .goKarts,
                    durationMinutes: 60,
                    peopleCount: 4,
                    vehicleCount: 0,
                    offRoadRiderCount: 0,
                    nights: 0
                ),
                AdventureActivityType.defaultDraft(for: .paintball),
                AdventureActivityType.defaultDraft(for: .shootingRange)
            ]
        ),
        AdventureTemplate(
            id: "camp-night",
            title: "Noche de camping",
            subtitle: "Actividades del día + noche de camping",
            badge: "Diversión nocturna",
            items: [
                AdventureReservationItemDraft(
                    activity: .offRoad,
                    durationMinutes: 60,
                    peopleCount: 0,
                    vehicleCount: 1,
                    offRoadRiderCount: 2,
                    nights: 0
                ),
                AdventureActivityType.defaultDraft(for: .camping)
            ]
        )
    ]
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
    private let service: AdventureBookingsServiceable
    
    init(service: AdventureBookingsServiceable = AdventureBookingsService()) {
        self.service = service
    }
    
    func makeBuilderViewModel(
        prefilledItems: [AdventureReservationItemDraft] = []
    ) -> AdventureComboBuilderViewModel {
        AdventureComboBuilderViewModel(
            prefilledItems: prefilledItems,
            getAvailabilityUseCase: GetAdventureAvailabilityUseCase(service: service),
            createBookingUseCase: CreateAdventureBookingUseCase(service: service)
        )
    }
    
    func makeBookingsViewModel() -> AdventureBookingsViewModel {
        AdventureBookingsViewModel(
            observeBookingsUseCase: ObserveAdventureBookingsUseCase(service: service),
            cancelBookingUseCase: CancelAdventureBookingUseCase(service: service)
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
        foodReservation: ReservationFoodDraft?
    ) async throws -> [AdventureAvailabilitySlot] {
        try await service.fetchAvailability(
            for: date,
            items: items,
            foodReservation: foodReservation
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
        day: Date,
        nationalId: String,
        onChange: @escaping (Result<[AdventureBooking], Error>) -> Void
    ) -> AdventureListenerToken {
        service.observeBookings(for: day, nationalId: nationalId, onChange: onChange)
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
    @Environment(\.colorScheme) private var colorScheme
    
    private let singles = AdventureActivityType.allCases.map(AdventureActivityType.defaultDraft(for:))
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 24) {
                    heroSection
                    featuredSection
                    singlesSection
                    customComboSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("Aventura en Los Altos")
            .navigationBarTitleDisplayMode(.large)
        }
        .appScreenStyle(.adventure)
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
            
            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.18))
                .frame(width: 160, height: 160)
                .blur(radius: 10)
                .offset(x: 40, y: -30)
            
            Circle()
                .fill(palette.accent.opacity(colorScheme == .dark ? 0.26 : 0.20))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
                .offset(x: 10, y: 55)
            
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
                    
                    Text("Mezcla off-road, paintball, go karts, campo de tiro, camping y columpio extremo con una experiencia con identidad propia.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.92))
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        heroChip("Off-road")
                        heroChip("Paintball")
                        heroChip("Go karts")
                        heroChip("Camping")
                    }
                }
                
                NavigationLink {
                    AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                        .onAppear {
                            adventureComboBuilderViewModel.reset()
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
                subtitle: "Combos sugeridos para reservar más rápido."
            )
            
            ForEach(AdventureCatalogTemplates.featured) { template in
                NavigationLink {
                    AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                        .onAppear {
                            adventureComboBuilderViewModel.replaceItems(with: template.items)
                        }
                } label: {
                    TemplateCard(template: template)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var singlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .adventure,
                title: "Actividades individuales",
                subtitle: "Reserva una sola experiencia de forma directa."
            )
            
            ForEach(singles, id: \.id) { item in
                NavigationLink {
                    AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                        .onAppear {
                            adventureComboBuilderViewModel.replaceItems(with: [item])
                        }
                } label: {
                    SingleActivityCard(item: item)
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
                Text("Puedes arrastrar para reordenar las actividades y establecer diferentes duraciones y número de personas por actividad.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                
                NavigationLink {
                    AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                        .onAppear {
                            adventureComboBuilderViewModel.reset()
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
    
    private func heroChip(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(colorScheme == .dark ? 0.12 : 0.16))
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private struct TemplateCard: View {
    let template: AdventureTemplate
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    private var priceText: String {
        String(format: "%.2f", AdventurePricingEngine.estimatedDiscountedSubtotal(items: template.items))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(
                    theme: .adventure,
                    systemImage: "figure.hiking",
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    
                    Text(template.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if let badge = template.badge {
                    BrandBadge(theme: .adventure, title: badge)
                }
            }
            
            HStack {
                Label("Desde $\(priceText)", systemImage: "dollarsign.circle.fill")
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
}

private struct SingleActivityCard: View {
    let item: AdventureReservationItemDraft
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .adventure, scheme: colorScheme)
    }
    
    private var basePrice: Double {
        AdventurePricingEngine.subtotal(for: item)
    }
    
    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(
                theme: .adventure,
                systemImage: item.activity.systemImage,
                size: 56
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.activity.title)
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                
                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .lineLimit(2)
                
                Text("Desde $\(basePrice, specifier: "%.2f")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.primary)
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
    
    private var authenticatedProfile: ClientProfile? {
        sessionViewModel.authenticatedProfile
    }
    
    @Environment(\.colorScheme) private var colorScheme
    private let theme: AppSectionTheme = .restaurant
    private var palette: ThemePalette {
        AppTheme.palette(for: theme, scheme: colorScheme)
    }
    
    @State private var showAddedMessage: Bool = false
    
    var body: some View {
        List {
            comboSection
            foodSection
            eventSection
            schedulingSection
            contactSection
            availabilitySection
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
        .onChange(of: authenticatedProfile?.id) { _, _ in
            syncProfileFieldsFromSession()
        }
        .onChange(of: authenticatedProfile?.updatedAt) { _, _ in
            syncProfileFieldsFromSession()
        }
        .sheet(item: $editingItem) { item in
            AdventureItemEditorView(item: item) { updated in
                adventureComboBuilderViewModel.updateItem(updated)
            }
        }
        .alert(
            "Mensaje",
            isPresented: Binding(
                get: { adventureComboBuilderViewModel.state.errorMessage != nil || adventureComboBuilderViewModel.state.successMessage != nil },
                set: { if !$0 { adventureComboBuilderViewModel.dismissMessage() } }
            )
        ) {
            Button("OK") { adventureComboBuilderViewModel.dismissMessage() }
        } message: {
            Text(adventureComboBuilderViewModel.state.errorMessage ?? adventureComboBuilderViewModel.state.successMessage ?? "")
        }
    }
    
    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }
        
        adventureComboBuilderViewModel.setClientName(profile.fullName)
        adventureComboBuilderViewModel.setWhatsapp(profile.phoneNumber)
        adventureComboBuilderViewModel.setNationalId(profile.nationalId)
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
                    ComboItemCard(item: item)
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
                        Button(activity.title) {
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
                
                if adventureComboBuilderViewModel.state.foodItems.isEmpty {
                    Text("No hay platos agregados todavía.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ForEach(adventureComboBuilderViewModel.state.foodItems) { item in
                            ReservationFoodRow(
                                item: item,
                                onIncrease: { adventureComboBuilderViewModel.increaseFoodQuantity(item.id) },
                                onDecrease: { adventureComboBuilderViewModel.decreaseFoodQuantity(item.id) },
                                onRemove: { adventureComboBuilderViewModel.removeFoodItem(item.id) }
                            )
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
                    AdventureFoodPickerSheet(menuSections: menuViewModel.state.sections) { item, quantity, notes in
                        adventureComboBuilderViewModel.addFoodItem(item, quantity: quantity, notes: notes)
                    }
                }
                
                if !adventureComboBuilderViewModel.state.foodItems.isEmpty {
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
            }
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private struct AdventureFoodPickerSheet: View {
        @Environment(\.dismiss) private var dismiss

        let menuSections: [MenuSection]
        let onAdd: (MenuItem, Int, String?) -> Void

        @State private var selectedCategoryId: String? = nil
        @State private var searchText = ""

        private var categories: [MenuCategory] {
            menuSections.map(\.category)
        }

        private var filteredSections: [MenuSection] {
            let categoryFiltered = menuSections.filter { section in
                selectedCategoryId == nil || section.category.id == selectedCategoryId
            }

            guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return categoryFiltered
            }

            let query = searchText.lowercased()

            return categoryFiltered.compactMap { section in
                let items = section.items.filter { item in
                    item.isAvailable &&
                    (
                        item.name.lowercased().contains(query) ||
                        item.description.lowercased().contains(query) ||
                        item.ingredients.contains(where: { $0.lowercased().contains(query) })
                    )
                }

                guard !items.isEmpty else { return nil }

                return MenuSection(
                    id: section.id,
                    category: section.category,
                    items: items
                )
            }
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

                                    ForEach(section.items.filter(\.isAvailable)) { item in
                                        NavigationLink {
                                            AdventureFoodDetailView(item: item) { quantity, notes in
                                                onAdd(item, quantity, notes)
                                                dismiss()
                                            }
                                        } label: {
                                            AdventureFoodMenuRow(item: item)
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
    }

    private struct AdventureFoodMenuRow: View {
        let item: MenuItem

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

                    Text(item.finalPrice.priceText)
                        .font(.subheadline.bold())
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
        }
    }

    private struct AdventureFoodDetailView: View {
        @Environment(\.dismiss) private var dismiss

        let item: MenuItem
        let onAdd: (Int, String?) -> Void

        @State private var quantity = 1
        @State private var notes = ""

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerCard
                    descriptionCard
                    ingredientsCard
                    priceCard
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

                    Text(item.finalPrice.priceText)
                        .font(.headline)
                        .foregroundStyle(.secondary)
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
                    if item.hasOffer, let offerPrice = item.offerPrice {
                        Text(item.price.priceText)
                            .foregroundStyle(.secondary)
                            .strikethrough()

                        Text(offerPrice.priceText)
                            .font(.title2.bold())
                    } else {
                        Text(item.price.priceText)
                            .font(.title2.bold())
                    }
                }
            }
            .appCardStyle(.adventure)
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
                    isEnabled: item.isAvailable,
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
    
    private var contactSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Contacto",
                    subtitle: "Your profile information is used automatically for this reservation."
                )
                
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
                        Text("Need to update your information?")
                            .font(.subheadline.weight(.semibold))
                        
                        Text("Please change your personal details from the Edit Profile page.")
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
            .appCardStyle(.adventure)
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
                                        isSelected: adventureComboBuilderViewModel.state.selectedSlot?.id == slot.id
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
    
    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                BrandSectionHeader(
                    theme: .adventure,
                    title: "Resumen",
                    subtitle: "Revisa el total antes de confirmar."
                )
                
                //Later
                if let slot = adventureComboBuilderViewModel.state.selectedSlot {
                    summaryRow("Aventura", "$\(slot.adventureSubtotal.priceText)")
                    summaryRow("Comida", "$\(slot.foodSubtotal.priceText)")
                    summaryRow("Subtotal", "$\(slot.subtotal.priceText)")
                    summaryRow("Descuento aventura", "-$\(slot.discountAmount.priceText)")
//                    summaryRow("Recargo nocturno", "$\(slot.nightPremium.priceText)")
                    Divider()
                    summaryRow("Total", "$\(slot.totalAmount.priceText)", bold: true)
                } else {
                    let estimatedSubtotal = AdventurePricingEngine.estimatedSubtotal(items: adventureComboBuilderViewModel.state.items)
                    let estimatedDiscount = AdventurePricingEngine.discount(for: estimatedSubtotal)
//                    let estimatedNightPremium = AdventurePricingEngine.estimatedNightPremium(items: viewModel.state.items)
                    let estimatedTotal =
                        AdventurePricingEngine.discountedSubtotal(for: estimatedSubtotal) //+ estimatedNightPremium

                    summaryRow("Subtotal estimado", "$\(estimatedSubtotal.priceText)")
                    summaryRow("Descuento estimado", "-$\(estimatedDiscount.priceText)")
//                    summaryRow("Recargo nocturno estimado", "$\(estimatedNightPremium.priceText)")
                    Divider()
                    summaryRow("Total estimado", "$\(estimatedTotal.priceText)", bold: true)
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
                    Text("Order has been added")
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
                    
                    dismiss()
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
                .disabled(adventureComboBuilderViewModel.state.isSubmitting || adventureComboBuilderViewModel.state.selectedSlot == nil)
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

private struct ComboItemCard: View {
    let item: AdventureReservationItemDraft
    
    var body: some View {
        HStack(spacing: 14) {
            BrandIconBubble(theme: .adventure, systemImage: item.activity.systemImage, size: 52)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("$\(AdventurePricingEngine.subtotal(for: item), specifier: "%.2f")")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)
        }
        .appCardStyle(.adventure)
    }
}

private struct ReservationFoodRow: View {
    let item: ReservationFoodItemDraft
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
                Text("Subtotal: \(item.subtotal.priceText)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
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
                
                Button("Quitar", role: .destructive, action: onRemove)
                    .font(.caption.bold())
            }
        }
        .appCardStyle(.adventure)
    }
}

private struct AdventureSlotCard: View {
    let slot: AdventureAvailabilitySlot
    let isSelected: Bool
    
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
            
            Text("$\(slot.totalAmount, specifier: "%.2f")")
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
            color: palette.shadow.opacity(isSelected ? (colorScheme == .dark ? 0.28 : 0.14) : (colorScheme == .dark ? 0.14 : 0.06)),
            radius: isSelected ? 14 : 8,
            x: 0,
            y: isSelected ? 8 : 4
        )
    }
}

private struct AdventureItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var item: AdventureReservationItemDraft
    let onSave: (AdventureReservationItemDraft) -> Void
    
    init(item: AdventureReservationItemDraft, onSave: @escaping (AdventureReservationItemDraft) -> Void) {
        _item = State(initialValue: item)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Actividad") {
                    Text(item.activity.title)
                }
                
                switch item.activity {
                case .offRoad:
                    Section("Off-road") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(item.activity.durationOptions, id: \.self) { minutes in
                                Text("\(minutes / 60) hora(s)").tag(minutes)
                            }
                        }
                        
                        Stepper("Vehículos: \(item.vehicleCount)", value: $item.vehicleCount, in: 1...10)
                        Stepper("Personas: \(item.offRoadRiderCount)", value: $item.offRoadRiderCount, in: 1...20)
                        
                        Text("Cada vehículo admite 1 o 2 personas. Ejemplo: 6 personas pueden usar 4 vehículos.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                case .paintball, .goKarts, .shootingRange:
                    Section("Configuración") {
                        Picker("Duración", selection: $item.durationMinutes) {
                            ForEach(item.activity.durationOptions, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                    }
                    
                case .camping:
                    Section("Camping") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Stepper("Noches: \(item.nights)", value: $item.nights, in: 1...7)
                        Text("El camping se programa de 7:00 PM a 7:00 AM y debe mantenerse al final del combo.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                case .extremeSlide:
                    Section("Resbaladera extrema") {
                        Stepper("Personas: \(item.peopleCount)", value: $item.peopleCount, in: 1...20)
                        Text("Incluye 30 minutos de transporte off-road más la sesión de la resbaladera.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Precio") {
                    Text("$\(AdventurePricingEngine.subtotal(for: item), specifier: "%.2f")")
                        .font(.headline)
                }
            }
            .scrollContentBackground(.hidden)
            .appScreenStyle(.adventure)
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
            if viewModel.state.isLoading && viewModel.state.bookings.isEmpty {
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
            } else {
                List {
                    headerSection
                    dateSection
                    contentSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .appScreenStyle(.adventure)
            }
        }
        .navigationTitle("Reservas y eventos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onAppear {
            syncNationalIdFromSession()
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        
    }
    private func syncNationalIdFromSession() {
        guard let nationalId = authenticatedProfile?.nationalId else { return }
        viewModel.setNationalId(nationalId)
    }
    
    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .adventure, systemImage: "calendar.badge.clock", size: 52)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gestiona tus reservas")
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                        
                        Text("Consulta reservas de aventura, comida, cumpleaños y otros eventos.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                }
            }
            .appCardStyle(.adventure, emphasized: false)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    private var dateSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Fecha")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)
                
                DatePicker(
                    "Fecha seleccionada",
                    selection: Binding(
                        get: { viewModel.state.selectedDate },
                        set: { viewModel.setDate($0) }
                    ),
                    in: Date()...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(palette.primary)
            }
            .padding(.vertical, 4)
            .appCardStyle(.adventure)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if viewModel.state.bookings.isEmpty {
            Section {
                ContentUnavailableView(
                    "Sin reservas",
                    systemImage: "calendar",
                    description: Text("Las reservas para la fecha seleccionada aparecerán aquí.")
                )
                .foregroundStyle(palette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .appCardStyle(.adventure)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } else {
            Section {
                ForEach(viewModel.state.bookings) { booking in
                    AdventureReservationRow(booking: booking)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            if booking.status != .canceled {
                                Button(role: .destructive) {
                                    viewModel.cancelBooking(booking.id)
                                } label: {
                                    Label("Cancelar", systemImage: "xmark")
                                }
                            }
                        }
                }
            } header: {
                Text("Reservas")
                    .font(.headline)
                    .foregroundStyle(palette.textSecondary)
                    .textCase(nil)
                    .padding(.horizontal, 20)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                BrandIconBubble(theme: .adventure, systemImage: "figure.hiking", size: 46)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)
                    
                    Text("\(AdventureDateHelper.timeText(booking.startAt)) • \(booking.whatsappNumber)")
                        .font(.subheadline)
                        .foregroundStyle(palette.textSecondary)
                    
                    Text("Cédula \(booking.nationalId)")
                        .font(.caption)
                        .foregroundStyle(palette.textTertiary)
                }
                
                Spacer()
                
                statusBadge
            }
            
            HStack(spacing: 8) {
                BrandBadge(theme: .adventure, title: booking.visitTypeTitle)
                BrandBadge(theme: .adventure, title: booking.eventDisplayTitle, selected: booking.eventType != .regularVisit)
            }
            
            Text("Invitados: \(booking.guestCount)")
                .font(.subheadline)
                .foregroundStyle(palette.textSecondary)
            
            if booking.hasActivities {
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
            
            if let food = booking.foodReservation, !food.items.isEmpty {
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
                }
            }
            
            Divider()
                .overlay(palette.stroke)
            
            VStack(spacing: 8) {
                amountRow("Aventura", booking.adventureSubtotal)
                amountRow("Comida", booking.foodSubtotal)
                amountRow("Descuento", -booking.discountAmount)
//                amountRow("Recargo nocturno", booking.nightPremium)
                amountRow("Total", booking.totalAmount, isPrimary: true)
            }
        }
        .appCardStyle(.adventure)
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
            .navigationTitle("Reservas")
        }
        .appScreenStyle(.neutral)
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
import SwiftUI

struct AdventureBookingsState {
    var selectedDate: Date = Date()
    var nationalId: String = ""
    var bookings: [AdventureBooking] = []
    var isLoading = false
    var errorMessage: String?
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
    
    func setNationalId(_ nationalId: String) {
        let cleanNationalId = nationalId.filter(\.isNumber)
        guard state.nationalId != cleanNationalId else { return }
        
        state.nationalId = cleanNationalId
        
        if listenerToken != nil {
            startListening()
        }
    }
    
    func onAppear() {
        startListening()
    }
    
    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
    }
    
    func setDate(_ date: Date) {
        state.selectedDate = date
        startListening()
    }
    
    func cancelBooking(_ id: String) {
        let nationalId = state.nationalId
        
        guard !nationalId.isEmpty else {
            state.errorMessage = "No se encontró una cédula asociada a esta cuenta."
            return
        }
        
        Task {
            do {
                try await cancelBookingUseCase.execute(id: id, nationalId: nationalId)
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func startListening() {
        let nationalId = state.nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !nationalId.isEmpty else {
            listenerToken?.remove()
            listenerToken = nil
            state.bookings = []
            state.isLoading = false
            state.errorMessage = nil
            return
        }
        
        state.isLoading = true
        state.errorMessage = nil
        
        listenerToken?.remove()
        listenerToken = observeBookingsUseCase.execute(
            day: state.selectedDate,
            nationalId: nationalId
        ) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                
                switch result {
                case let .success(bookings):
                    self.state.bookings = bookings
                    self.state.isLoading = false
                    
                case let .failure(error):
                    self.state.bookings = []
                    self.state.errorMessage = error.localizedDescription
                    self.state.isLoading = false
                }
            }
        }
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
    
    var availableSlots: [AdventureAvailabilitySlot] = []
    var selectedSlot: AdventureAvailabilitySlot?
    
    var isLoadingAvailability = false
    var isSubmitting = false
    var errorMessage: String?
    var successMessage: String?
}

@MainActor
final class AdventureComboBuilderViewModel: ObservableObject {
    @Published private(set) var state: AdventureComboBuilderState
    
    private let getAvailabilityUseCase: GetAdventureAvailabilityUseCase
    private let createBookingUseCase: CreateAdventureBookingUseCase
    
    var estimatedNightPremium: Double {
        AdventurePricingEngine.estimatedNightPremium(items: state.items)
    }
    
    init(
        prefilledItems: [AdventureReservationItemDraft],
        getAvailabilityUseCase: GetAdventureAvailabilityUseCase,
        createBookingUseCase: CreateAdventureBookingUseCase
    ) {
        self.state = AdventureComboBuilderState(
            items: prefilledItems.isEmpty ? [AdventureActivityType.defaultDraft(for: .offRoad)] : prefilledItems
        )
        self.getAvailabilityUseCase = getAvailabilityUseCase
        self.createBookingUseCase = createBookingUseCase
        
        keepCampingAtEnd()
    }
    
    func onAppear() {
        Task { await loadAvailability() }
    }
    
    func canAddItem(_ activity: AdventureActivityType) -> Bool {
        !state.items.contains(where: { $0.activity == activity })
    }
    
    var availableActivitiesToAdd: [AdventureActivityType] {
        AdventureActivityType.allCases.filter { activity in
            canAddItem(activity)
        }
    }
    
    func addItem(_ activity: AdventureActivityType) {
        guard canAddItem(activity) else {
            state.errorMessage = "\(activity.title) ya fue agregada a esta reserva."
            return
        }
        
        state.items.append(AdventureActivityType.defaultDraft(for: activity))
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func updateItem(_ item: AdventureReservationItemDraft) {
        guard let index = state.items.firstIndex(where: { $0.id == item.id }) else { return }
        state.items[index] = item
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func removeItem(at offsets: IndexSet) {
        state.items.remove(atOffsets: offsets)
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func moveItems(from source: IndexSet, to destination: Int) {
        state.items.move(fromOffsets: source, toOffset: destination)
        keepCampingAtEnd()
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func addFoodItem(
        _ menuItem: MenuItem,
        quantity: Int = 1,
        notes: String? = nil
    ) {
        guard menuItem.isAvailable else { return }

        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil
        let safeQuantity = max(1, quantity)

        if let index = state.foodItems.firstIndex(where: {
            $0.menuItemId == menuItem.id && $0.notes == finalNotes
        }) {
            state.foodItems[index].quantity += safeQuantity
        } else {
            state.foodItems.append(
                ReservationFoodItemDraft(
                    from: menuItem,
                    quantity: safeQuantity,
                    notes: finalNotes
                )
            )
        }

        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func increaseFoodQuantity(_ id: String) {
        guard let index = state.foodItems.firstIndex(where: { $0.id == id }) else { return }
        state.foodItems[index].quantity += 1
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func decreaseFoodQuantity(_ id: String) {
        guard let index = state.foodItems.firstIndex(where: { $0.id == id }) else { return }
        
        let nextValue = state.foodItems[index].quantity - 1
        if nextValue <= 0 {
            state.foodItems.remove(at: index)
        } else {
            state.foodItems[index].quantity = nextValue
        }
        
        state.selectedSlot = nil
        Task { await loadAvailability() }
    }
    
    func removeFoodItem(_ id: String) {
        state.foodItems.removeAll { $0.id == id }
        state.selectedSlot = nil
        Task { await loadAvailability() }
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
    
    func setCustomEventTitle(_ value: String) { state.customEventTitle = value }
    func setEventNotes(_ value: String) { state.eventNotes = value }
    
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
    
    func setFoodNotes(_ value: String) { state.foodNotes = value }
    func setClientName(_ value: String) { state.clientName = value }
    func setWhatsapp(_ value: String) { state.whatsappNumber = value }
    func setNationalId(_ value: String) { state.nationalId = value }
    func setNotes(_ value: String) { state.notes = value }
    
    func selectSlot(_ slot: AdventureAvailabilitySlot) {
        state.selectedSlot = slot
    }
    
    func dismissMessage() {
        state.errorMessage = nil
        state.successMessage = nil
    }
    
    func submit(clientId: String?) {
        Task { await submitReservation(clientId: clientId) }
    }
    
    var estimatedAdventureSubtotal: Double {
        AdventurePricingEngine.estimatedSubtotal(items: state.items)
    }
    
    var estimatedFoodSubtotal: Double {
        state.foodItems.reduce(0) { $0 + $1.subtotal }
    }
    
    func reset() {
        state = AdventureComboBuilderState(
            items: [AdventureActivityType.defaultDraft(for: .offRoad)]
        )
        keepCampingAtEnd()
        Task { await loadAvailability() }
    }
    
    func resetForFoodOnly() {
        state = AdventureComboBuilderState(items: [])
        Task { await loadAvailability() }
    }
    
    func replaceItems(with items: [AdventureReservationItemDraft]) {
        let uniqueItems = items.reduce(into: [AdventureReservationItemDraft]()) { result, item in
            guard !result.contains(where: { $0.activity == item.activity }) else { return }
            result.append(item)
        }
        
        state.items = uniqueItems.isEmpty ? [] : uniqueItems
        keepCampingAtEnd()
        state.selectedSlot = nil
        state.errorMessage = nil
        state.successMessage = nil
        Task { await loadAvailability() }
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
                foodReservation: foodDraft
            )
            state.availableSlots = slots
            if let selected = state.selectedSlot {
                state.selectedSlot = slots.first(where: { $0.startAt == selected.startAt && $0.endAt == selected.endAt })
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
    
    private func submitReservation(clientId: String?) async {
        let foodDraft = buildFoodDraft()
        let hasFood = !(foodDraft?.isEmpty ?? true)
        let hasActivities = !state.items.isEmpty
        
        guard hasActivities || hasFood else {
            state.errorMessage = "Add at least one activity or one food item."
            return
        }
        
        guard !state.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.errorMessage = "Please enter the client name."
            return
        }
        
        let whatsappDigits = state.whatsappNumber.filter(\.isNumber)
        guard whatsappDigits.count >= 7 else {
            state.errorMessage = "Please enter a valid WhatsApp number."
            return
        }
        
        let nationalIdDigits = state.nationalId.filter(\.isNumber)
        guard nationalIdDigits.count >= 8 else {
            state.errorMessage = "Please enter a valid national ID."
            return
        }
        
        guard state.guestCount > 0 else {
            state.errorMessage = "Please enter at least one guest."
            return
        }
        
        if state.eventType == .custom,
           state.customEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            state.errorMessage = "Please enter the custom event title."
            return
        }
        
        guard let slot = state.selectedSlot else {
            state.errorMessage = "Please choose an available start time."
            return
        }
        
        state.isSubmitting = true
        state.errorMessage = nil
        
        let cleanNotes = state.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEventNotes = state.eventNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCustomEventTitle = state.customEventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let request = AdventureBookingRequest(
            clientId: clientId,
            clientName: state.clientName.trimmingCharacters(in: .whitespacesAndNewlines),
            whatsappNumber: whatsappDigits,
            nationalId: nationalIdDigits,
            date: state.selectedDate,
            selectedStartAt: slot.startAt,
            guestCount: state.guestCount,
            eventType: state.eventType,
            customEventTitle: state.eventType == .custom && !cleanCustomEventTitle.isEmpty ? cleanCustomEventTitle : nil,
            eventNotes: cleanEventNotes.isEmpty ? nil : cleanEventNotes,
            items: state.items,
            foodReservation: foodDraft,
            notes: cleanNotes.isEmpty ? nil : cleanNotes
        )
        
        do {
            let booking = try await createBookingUseCase.execute(request)
            state.successMessage = "Reservation confirmed for \(booking.clientName) at \(AdventureDateHelper.timeText(booking.startAt))."
            await loadAvailability()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        
        state.isSubmitting = false
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

    var isComplete: Bool {
        isProfileComplete &&
        !fullName.trimmed.isEmpty &&
        !nationalId.trimmed.isEmpty &&
        !phoneNumber.trimmed.isEmpty &&
        !address.trimmed.isEmpty &&
        !emergencyContactName.trimmed.isEmpty &&
        !emergencyContactPhone.trimmed.isEmpty
    }
}

```

---

# Altos del Murco/root/feature/altos/authentication/domain/ClientProfileDocument.swift

```swift
//
//  ClientProfileDocument.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
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
            profileCompletedAt: profileCompletedAt
        )
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
                
                Text("Restaurant, adventure and rewards in one account.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
            }
            
            HStack(spacing: 10) {
                BrandBadge(theme: .restaurant, title: "Restaurant")
                BrandBadge(theme: .adventure, title: "Adventure")
                BrandBadge(theme: .neutral, title: "Rewards")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            BrandSectionHeader(
                theme: .neutral,
                title: "Everything in one place",
                subtitle: "Your account connects food, bookings, rewards and personalized offers."
            )
            
            VStack(spacing: 14) {
                FeatureRow(
                    theme: .restaurant,
                    icon: "fork.knife",
                    text: "Restaurant orders and loyalty"
                )
                
                FeatureRow(
                    theme: .neutral,
                    icon: "birthday.cake.fill",
                    text: "Birthday discounts and special promos"
                )
                
                FeatureRow(
                    theme: .adventure,
                    icon: "figure.outdoor.cycle",
                    text: "Adventure bookings in one place"
                )
                
                FeatureRow(
                    theme: .neutral,
                    icon: "lock.shield.fill",
                    text: "Private and secure Apple sign in"
                )
            }
        }
        .appCardStyle(.neutral, emphasized: true)
    }
    
    private var signInCard: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("Sign in to continue")
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("Your profile helps us personalize reservations, discounts and contact details.")
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
            
            Text("By continuing, your account will be linked to your Apple sign in.")
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

    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let resolveSessionUseCase: ResolveSessionUseCase
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let signOutUseCase: SignOutUseCase

    private var currentNonce: String?

    init(
        signInWithAppleUseCase: SignInWithAppleUseCase,
        resolveSessionUseCase: ResolveSessionUseCase,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        signOutUseCase: SignOutUseCase
    ) {
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.resolveSessionUseCase = resolveSessionUseCase
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.signOutUseCase = signOutUseCase

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

        return { [weak self] in
            ProfileViewModel(
                initialProfile: profile,
                appPreferences: appPreferences,
                completeClientProfileUseCase: saveUseCase,
                deleteCurrentAccountUseCase: deleteUseCase,
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

# Altos del Murco/root/feature/altos/authentication/presentation/viewmodel/CompleteProfileViewModel.swift

```swift
//
//  CompleteProfileViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
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
            profileCompletedAt: existingProfile?.profileCompletedAt ?? now
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
                        try document.data(as: FeaturedPostDTO.self).toDomain()
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
            try document.data(as: FeaturedPostDTO.self).toDomain()
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

struct FeaturedPostMediaDTO: Codable, Hashable, Identifiable {
    let id: String
    let downloadURL: String
    let storagePath: String
    let width: CGFloat
    let height: CGFloat
    let position: Int
}

struct FeaturedPostDTO: Codable {
    @DocumentID var id: String?
    let category: String
    let description: String?
    let media: [FeaturedPostMediaDTO]
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

extension FeaturedPostDTO {
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
    func toDTO() -> FeaturedPostDTO {
        FeaturedPostDTO(
            id: id,
            category: category.rawValue,
            description: description,
            media: orderedMedia.map {
                FeaturedPostMediaDTO(
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
                    quickAccessSection
                    featuredSection
                }
                .padding()
            }
            .navigationTitle("Altos del Murco")
            .navigationBarTitleDisplayMode(.large)
        }
        .appScreenStyle(.neutral)
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
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var subtitle: String {
        switch self {
        case .system: return "Follow the device appearance"
        case .light: return "Always use light mode"
        case .dark: return "Always use dark mode"
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
                    Text("Appearance")
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)
                    
                    Text("Choose how the app looks across the interface.")
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
        .navigationTitle("Appearance")
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
                            ProgressView("Deleting account...")
                                .tint(palette.destructive)
                                .foregroundStyle(palette.textSecondary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Confirm Deletion")
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
                Text("Delete account")
                    .font(.title2.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("This action is permanent. Your profile will be removed and you will lose access to your account.")
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
                text: "Your client profile will be deleted"
            )
            
            warningRow(
                systemImage: "rectangle.portrait.and.arrow.right",
                text: "You will be signed out immediately"
            )
            
            warningRow(
                systemImage: "exclamationmark.triangle.fill",
                text: "This action cannot be undone"
            )
        }
        .appCardStyle(.neutral, emphasized: true)
    }
    
    private var actionSection: some View {
        VStack(spacing: 14) {
            Text("To continue, confirm your identity with Apple.")
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
                    ProfileFieldSection(theme: theme, title: "Account") {
                        ReadOnlyFieldCard(
                            theme: theme,
                            title: "Email",
                            value: viewModel.email.isEmpty ? "Hidden by Apple" : viewModel.email
                        )
                    }

                    ProfileFieldSection(theme: theme, title: "Personal information") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Full name",
                            placeholder: "Enter your full name",
                            text: $viewModel.fullName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "National unique number",
                            placeholder: "Example: 0501234567",
                            text: $viewModel.nationalId,
                            keyboardType: .numberPad
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Phone number",
                            placeholder: "Example: 0987654321",
                            text: $viewModel.phoneNumber,
                            keyboardType: .phonePad
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Birthday", systemImage: "calendar")
                                .font(.subheadline.bold())
                                .foregroundStyle(palette.textPrimary)

                            DatePicker(
                                "Birthday",
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

                    ProfileFieldSection(theme: theme, title: "Address") {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Address", systemImage: "house")
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

                    ProfileFieldSection(theme: theme, title: "Emergency contact") {
                        EditableFieldCard(
                            theme: theme,
                            title: "Emergency contact name",
                            placeholder: "Who should we contact if needed?",
                            text: $viewModel.emergencyContactName,
                            keyboardType: .default
                        )

                        EditableFieldCard(
                            theme: theme,
                            title: "Emergency contact phone",
                            placeholder: "Example: 0999999999",
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
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
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
                            Text("Save")
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

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileAccountHubView.swift

```swift
//
//  ProfileAccountHubView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 16/4/26.
//

import SwiftUI

struct ProfileAccountHubView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    private let theme: AppSectionTheme = .neutral

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                actionRow(
                    title: "Personal Information",
                    subtitle: "Edit your contact and emergency details",
                    systemImage: "person.text.rectangle",
                    tint: .blue
                ) {
                    viewModel.openEditProfile()
                }

                actionRow(
                    title: "Rewards & Points",
                    subtitle: "Your loyalty history and benefits",
                    systemImage: "gift.fill",
                    tint: .orange
                ) { }

                actionRow(
                    title: "Birthday Benefits",
                    subtitle: "Used for special promos and discounts",
                    systemImage: "birthday.cake.fill",
                    tint: .pink
                ) { }
            }
            .padding(16)
        }
        .navigationTitle("Account")
        .appScreenStyle(theme)
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
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
        .buttonStyle(.plain)
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
                                Text("Loading profile...")
                                    .font(.headline)
                                
                                Text("Preparing your account and preferences.")
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
                    .navigationTitle("Profile")
                }
                .appScreenStyle(.neutral)
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
                        title: "Appearance",
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
                        title: "App Permissions",
                        subtitle: "Notifications, location and device settings",
                        systemImage: "gearshape.2.fill"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .navigationTitle("Preferences")
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

# Altos del Murco/root/feature/altos/profile/presentation/view/ProfileStats.swift

```swift
//
//  ProfileStats.swift
//  Altos del Murco
//
//  Created by José Ruiz on 3/4/26.
//

import Foundation

struct ProfileStats {
    let points: Int
    let orders: Int
    let bookings: Int

    static let empty = ProfileStats(
        points: 0,
        orders: 0,
        bookings: 0
    )
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
                    title: "Help & Support",
                    subtitle: "Email our support team",
                    systemImage: "questionmark.circle.fill",
                    tint: .teal,
                    url: AppExternalLinks.supportEmail
                )

                supportRow(
                    title: "Privacy Policy",
                    subtitle: "Read how your data is used",
                    systemImage: "hand.raised.fill",
                    tint: .indigo,
                    url: AppExternalLinks.privacyPolicy
                )

                supportRow(
                    title: "Terms & Conditions",
                    subtitle: "App and service terms",
                    systemImage: "doc.text.fill",
                    tint: .brown,
                    url: AppExternalLinks.terms
                )
            }
            .padding(16)
        }
        .navigationTitle("Help & Support")
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

import SwiftUI

struct ProfileView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: ProfileViewModel

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
                    dangerSection
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .navigationTitle("Profile")
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
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .appScreenStyle(theme)
    }

    private var headerSection: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(palette.heroGradient)
                    .frame(width: 104, height: 104)
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

                Text(viewModel.displayName.initials)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.onPrimary)

                Button {
                    viewModel.openEditProfile()
                } label: {
                    Image(systemName: "pencil")
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
                .offset(x: 4, y: 4)
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

                Label("Member since \(viewModel.memberSinceText)", systemImage: "calendar")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(palette.textSecondary)
            }

            HStack(spacing: 10) {
                compactInfoCard(
                    title: "Phone",
                    value: viewModel.phoneText,
                    systemImage: "phone.fill"
                )

                compactInfoCard(
                    title: "Birthday",
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
                    Text("Address")
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

    private func infoPill(title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(palette.textSecondary)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundStyle(palette.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }

    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overview")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Spacer()
            }

            HStack(spacing: 12) {
                profileStatCard(
                    title: "Points",
                    value: "\(viewModel.stats.points)",
                    systemImage: "star.fill"
                )

                profileStatCard(
                    title: "Orders",
                    value: "\(viewModel.stats.orders)",
                    systemImage: "fork.knife"
                )

                profileStatCard(
                    title: "Bookings",
                    value: "\(viewModel.stats.bookings)",
                    systemImage: "calendar"
                )
            }
        }
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

    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(palette.textPrimary)

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .appCardStyle(theme)
    }
    
    private var mainMenuSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Settings")

            NavigationLink {
                ProfileAccountHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Account",
                    subtitle: "Personal information, rewards and birthday benefits",
                    systemImage: "person.crop.circle",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfilePreferencesHubView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Preferences",
                    subtitle: "Appearance and app permissions",
                    systemImage: "slider.horizontal.3",
                    tint: .purple
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ProfileSupportHubView()
            } label: {
                navigationRow(
                    title: "Help & Support",
                    subtitle: "Support, privacy policy and terms",
                    systemImage: "questionmark.circle",
                    tint: .teal
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    private var socialCompactSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Social & Visit Us")

            HStack(spacing: 14) {
                socialIconButton(
                    systemImage: "camera.fill",
                    tint: .pink,
                    action: { openURL(AppExternalLinks.instagram) }
                )

                socialIconButton(
                    systemImage: "music.note.tv",
                    tint: .black,
                    action: { openURL(AppExternalLinks.tiktok) }
                )

                socialIconButton(
                    systemImage: "f.cursive.circle.fill",
                    tint: .blue,
                    action: { openURL(AppExternalLinks.facebook) }
                )

                socialIconButton(
                    systemImage: "message.fill",
                    tint: .green,
                    action: { openURL(AppExternalLinks.whatsapp) }
                )

                socialIconButton(
                    systemImage: "map.fill",
                    tint: .red,
                    action: { openURL(AppExternalLinks.maps) }
                )
            }
            .frame(maxWidth: .infinity)
            .appCardStyle(theme)
        }
    }

    private func socialIconButton(
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.14))
                    .frame(width: 54, height: 54)

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(.plain)
    }

    private var accountSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Account")

            actionRow(
                title: "Personal Information",
                subtitle: "Edit your contact and emergency details",
                systemImage: "person.text.rectangle",
                tint: .blue
            ) {
                viewModel.openEditProfile()
            }

            actionRow(
                title: "Rewards & Points",
                subtitle: "Your loyalty history and benefits",
                systemImage: "gift.fill",
                tint: .orange
            ) { }

            actionRow(
                title: "Birthday Benefits",
                subtitle: "Used for special promos and discounts",
                systemImage: "birthday.cake.fill",
                tint: .pink
            ) { }
        }
    }

    private var preferencesSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Preferences")

            NavigationLink {
                AppearanceSettingsView(viewModel: viewModel)
            } label: {
                navigationRow(
                    title: "Appearance",
                    subtitle: viewModel.appearanceTitle,
                    systemImage: "circle.lefthalf.filled",
                    tint: .purple
                )
            }
            .buttonStyle(.plain)

            actionRow(
                title: "App Permissions",
                subtitle: "Notifications, location and device settings",
                systemImage: "gearshape.2.fill",
                tint: .gray
            ) {
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                openURL(settingsURL)
            }
        }
    }

    private var socialSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Social & Visit Us")

            actionRow(
                title: "Instagram",
                subtitle: "@altosdelmurco",
                systemImage: "camera.fill",
                tint: .pink
            ) {
                openURL(AppExternalLinks.instagram)
            }

            actionRow(
                title: "TikTok",
                subtitle: "@altosdelmurco",
                systemImage: "music.note.tv",
                tint: .black
            ) {
                openURL(AppExternalLinks.tiktok)
            }

            actionRow(
                title: "Facebook",
                subtitle: "Follow our updates and promos",
                systemImage: "f.cursive.circle.fill",
                tint: .blue
            ) {
                openURL(AppExternalLinks.facebook)
            }

            actionRow(
                title: "WhatsApp",
                subtitle: "Contact us directly",
                systemImage: "message.fill",
                tint: .green
            ) {
                openURL(AppExternalLinks.whatsapp)
            }

            actionRow(
                title: "Open in Maps",
                subtitle: "Navigate to Altos del Murco",
                systemImage: "map.fill",
                tint: .red
            ) {
                openURL(AppExternalLinks.maps)
            }
        }
    }

    private var supportSection: some View {
        VStack(spacing: 12) {
            sectionHeader("Support & Legal")

            actionRow(
                title: "Help & Support",
                subtitle: "Email our support team",
                systemImage: "questionmark.circle.fill",
                tint: .teal
            ) {
                openURL(AppExternalLinks.supportEmail)
            }

            actionRow(
                title: "Privacy Policy",
                subtitle: "Read how your data is used",
                systemImage: "hand.raised.fill",
                tint: .indigo
            ) {
                openURL(AppExternalLinks.privacyPolicy)
            }

            actionRow(
                title: "Terms & Conditions",
                subtitle: "App and service terms",
                systemImage: "doc.text.fill",
                tint: .brown
            ) {
                openURL(AppExternalLinks.terms)
            }
        }
    }

    private var dangerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Account Actions")
                    .font(.headline)
                    .foregroundStyle(palette.textPrimary)

                Spacer()
            }

            Button {
                viewModel.signOutTapped()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(colorScheme == .dark ? 0.20 : 0.12))
                            .frame(width: 44, height: 44)

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sign Out")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)

                        Text("Close your current session")
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
            .buttonStyle(.plain)

            Button {
                viewModel.askForDeleteAccount()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.16))
                            .frame(width: 44, height: 44)

                        Image(systemName: "trash.fill")
                            .font(.headline)
                            .foregroundStyle(.red)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete Account")
                            .font(.headline)
                            .foregroundStyle(.red)

                        Text("Permanently remove your account")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.red.opacity(0.7))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.10 : 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.red.opacity(0.22), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
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
        BrandSectionHeader(theme: theme, title: title)
    }

    private func actionRow(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            baseRow(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: tint
            )
        }
        .buttonStyle(.plain)
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
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .overlay(
                Circle()
                    .stroke(palette.stroke, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(palette.textPrimary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.textTertiary)
        }
        .appListRowStyle(theme)
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
            profileCompletedAt: originalProfile.profileCompletedAt ?? Date()
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

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: ClientProfile
    @Published private(set) var stats: ProfileStats = .empty

    @Published var isShowingEditProfile = false
    @Published var isShowingDeleteAccountSheet = false
    @Published var alertItem: ProfileAlertItem?
    @Published private(set) var isDeletingAccount = false

    private let appPreferences: AppPreferences
    private let completeClientProfileUseCase: CompleteClientProfileUseCase
    private let deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase
    private let onProfileUpdated: @MainActor (ClientProfile) -> Void
    private let onSignOut: @MainActor () -> Void
    private let onAccountDeleted: @MainActor () -> Void

    private var deleteNonce: String?

    init(
        initialProfile: ClientProfile,
        appPreferences: AppPreferences,
        completeClientProfileUseCase: CompleteClientProfileUseCase,
        deleteCurrentAccountUseCase: DeleteCurrentAccountUseCase,
        onProfileUpdated: @escaping @MainActor (ClientProfile) -> Void,
        onSignOut: @escaping @MainActor () -> Void,
        onAccountDeleted: @escaping @MainActor () -> Void
    ) {
        self.profile = initialProfile
        self.appPreferences = appPreferences
        self.completeClientProfileUseCase = completeClientProfileUseCase
        self.deleteCurrentAccountUseCase = deleteCurrentAccountUseCase
        self.onProfileUpdated = onProfileUpdated
        self.onSignOut = onSignOut
        self.onAccountDeleted = onAccountDeleted
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

struct OrderDto: Codable {
    let id: String
    let nationalId: String?
    let clientName: String
    let tableNumber: String
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let items: [OrderItemDto]
    let subtotal: Double
    let totalAmount: Double
    let status: String?
    let revision: Int?
    let lastConfirmedRevision: Int?
}

@MainActor
extension OrderDto {
    init(from domain: Order) {
        self.id = domain.id
        self.nationalId = domain.nationalId
        self.clientName = domain.clientName
        self.tableNumber = domain.tableNumber
        self.createdAt = Timestamp(date: domain.createdAt)
        self.updatedAt = Timestamp(date: domain.updatedAt)
        self.items = domain.items.map(OrderItemDto.init(from: ))
        self.subtotal = domain.subtotal
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
        printDebugging()
        
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
    
    func printDebugging() {
        print("OrderItemDto: \(String(describing: notes))")
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

import Foundation
import FirebaseFirestore

final class FirebaseOrdersService: OrdersServiceable {
    private lazy var db = Firestore.firestore()
    
    func submit(order: Order) async throws {
        let _ = try await db.runTransaction { transaction, errorPointer in
            do {
                for item in order.items {
                    let ref = self.db
                        .collection(FirestoreConstants.restaurant_menu_items)
                        .document(item.menuItemId)
                    
                    let snapshot = try transaction.getDocument(ref)
                    let dto = try snapshot.data(as: MenuItemDto.self)
                    
                    guard dto.isAvailable else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "\(dto.name) no está disponible."]
                        )
                    }
                    
                    guard dto.remainingQuantity >= item.quantity else {
                        throw NSError(
                            domain: "OrdersService",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Ya no hay suficiente stock de \(dto.name)."]
                        )
                    }
                    
                    transaction.updateData([
                        "remainingQuantity": dto.remainingQuantity - item.quantity,
                        "updatedAt": Timestamp(date: Date())
                    ], forDocument: ref)
                }
                
                let dto = OrderDto(from: order)
                let orderData = try Firestore.Encoder().encode(dto)
                
                let orderRef = self.db
                    .collection(FirestoreConstants.restaurant_orders)
                    .document(order.id)
                
                transaction.setData(orderData, forDocument: orderRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            return nil
        }
    }
    
    func observeOrders(for nationalId: String) -> AsyncThrowingStream<[Order], Error> {
        let nationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return AsyncThrowingStream { continuation in
            guard !nationalId.isEmpty else {
                continuation.yield([])
                continuation.finish()
                return
            }
            
            let listener = db
                .collection(FirestoreConstants.restaurant_orders)
                .whereField("nationalId", isEqualTo: nationalId)
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
                    
                    let orders: [Order] = documents.compactMap { document in
                        do {
                            let dto = try document.data(as: OrderDto.self)
                            return dto.toDomain()
                        } catch {
                            return nil
                        }
                    }
                    
                    continuation.yield(orders)
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
    let totalAmount: Double
    var status: OrderStatus
    let revision: Int
    let lastConfirmedRevision: Int?

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
        if status == .canceled {
            return .canceled
        }

        if requiresReconfirmation {
            return .pending
        }

        if allItemsCompleted {
            return .completed
        }

        if hasStartedPreparing {
            return .preparing
        }

        if status == .confirmed {
            return .confirmed
        }

        return .pending
    }

    func confirming(now: Date = Date()) -> Order {
        var updated = Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: items,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: .confirmed,
            revision: revision,
            lastConfirmedRevision: revision
        )
        updated.status = updated.recalculatedStatus()
        return updated
    }

    func canceling(now: Date = Date()) -> Order {
        Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: items,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: .canceled,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
    }

    func updatingItems(
        _ newItems: [OrderItem],
        subtotal: Double,
        totalAmount: Double,
        now: Date = Date()
    ) -> Order {
        var updated = Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: newItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: .pending,
            revision: revision + 1,
            lastConfirmedRevision: lastConfirmedRevision
        )
        updated.status = updated.recalculatedStatus()
        return updated
    }

    func updatingPreparation(
        items newItems: [OrderItem],
        now: Date = Date()
    ) -> Order {
        var updated = Order(
            id: id,
            nationalId: nationalId,
            clientName: clientName,
            tableNumber: tableNumber,
            createdAt: createdAt,
            updatedAt: now,
            items: newItems,
            subtotal: subtotal,
            totalAmount: totalAmount,
            status: status,
            revision: revision,
            lastConfirmedRevision: lastConfirmedRevision
        )
        updated.status = updated.recalculatedStatus()
        return updated
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
        
        printDebugging()
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
    
    func printDebugging() {
        print("OrderItem: \(String(describing: notes))")
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

# Altos del Murco/root/feature/altos/restaurant/domain/state/CheckoutState.swift

```swift
//
//  CheckoutState.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct CheckoutState {
    var isSubmitting = false
    var createdOrder: Order?
    var errorMessage: String?
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
            .onAppear { menuViewModel.onAppear() }
            .onDisappear { menuViewModel.onDisappear() }
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
    @EnvironmentObject private var cartManager: CartManager
    @State private var showClearCartAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            if cartManager.isEmpty {
                ContentUnavailableView(
                    "Your cart is empty",
                    systemImage: "cart",
                    description: Text("Add some delicious dishes from the menu.")
                )
            } else {
                List {
                    Section("Items") {
                        ForEach(cartManager.items) { cartItem in
                            CartItemRowView(cartItem: cartItem)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    
                    Section("Summary") {
                        HStack {
                            Text("Subtotal")
                                .font(.headline)
                            Spacer()
                            Text(cartManager.subtotal.priceText)
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        HStack {
                            Text("Items")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(cartManager.totalItems)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Cart")
        .toolbar {
            if !cartManager.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear") {
                        showClearCartAlert = true
                    }
                }
            }
        }
        .alert("Clear cart?", isPresented: $showClearCartAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                cartManager.clear()
            }
        } message: {
            Text("Are you sure you want to remove all items from your cart?")
        }
        .safeAreaInset(edge: .bottom) {
            if !cartManager.isEmpty {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(cartManager.totalAmount.priceText)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        NavigationLink(value: Route.checkout) {
                            Text("Checkout")
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
                    BrandBadge(theme: .restaurant, title: "Featured", selected: true)
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
        .navigationTitle("Dish")
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
            descriptionCard
            ingredientsCard
            priceCard
            quantityCard
            notesCard
        }
    }
    
    private var descriptionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Description",
                subtitle: "A closer look at this dish."
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
                title: "Ingredients",
                subtitle: "Fresh components and accompaniments."
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
                title: "Price",
                subtitle: item.hasOffer ? "Special offer available." : "Current regular price."
            )
            
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                if item.hasOffer, let offerPrice = item.offerPrice {
                    Text(item.price.priceText)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(palette.textTertiary)
                        .strikethrough()
                    
                    Text(offerPrice.priceText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.textPrimary)
                } else {
                    Text(item.price.priceText)
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
                title: "Quantity",
                subtitle: "Choose how many you want to add."
            )
            
            QuantitySelectorView(
                quantity: $quantity,
                isEnabled: item.canBeOrdered,
                theme: .restaurant,
                minimum: 1,
                maximum: item.remainingQuantity
            )
            .opacity(item.isAvailable ? 1 : 0.55)
        }
        .appCardStyle(.restaurant)
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Notes",
                subtitle: "Special instructions for the kitchen."
            )
            
            TextField("Add any special notes (optional)", text: $notesText, axis: .vertical)
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
                Text("Order has been added")
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
                        
                        Text((Double(quantity) * item.finalPrice).priceText)
                            .font(.title3.bold())
                            .foregroundStyle(palette.textPrimary)
                    }
                    
                    Spacer()
                }
                
                if !item.canBeOrdered {
                    Text("No quedan platos disponibles por ahora.")
                        .font(.footnote)
                        .foregroundStyle(palette.destructive)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button {
                    cartManager.add(item: item, quantity: quantity, notes: notesText)
                    
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
                    Text(item.canBeOrdered ? "Añadir a la orden" : "Agotado")
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
                .disabled(!item.canBeOrdered)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(palette.elevatedCard.opacity(colorScheme == .dark ? 0.96 : 0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(
            Rectangle()
                .fill(palette.background.opacity(colorScheme == .dark ? 0.92 : 0.85))
                .ignoresSafeArea()
        )
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
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedCategoryId: String?
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var categories: [MenuCategory] {
        sections.map(\.category)
    }

    private var featuredItems: [MenuItem] {
        sections
            .flatMap(\.items)
            .filter(\.isFeatured)
    }

    private var filteredSections: [MenuSection] {
        guard let selectedCategoryId else { return sections }
        return sections.filter { $0.category.id == selectedCategoryId }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                headerSection
                
                if !featuredItems.isEmpty {
                    featuredCarousel
                }

                categorySelector

                ForEach(filteredSections) { section in
                    sectionContent(section)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .navigationTitle("Restaurant")
        .navigationBarTitleDisplayMode(.large)
        .appScreenStyle(.restaurant)
        .task {
            if selectedCategoryId == nil {
                selectedCategoryId = categories.first?.id
            }
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
                MenuItemDetailView(item: item, categoryTitle: categoryTitle)
            case .cart:
                CartView()
            case .checkout:
                CheckoutView(viewModel: checkoutViewModel, path: $path)
            case .reservationBuilder:
                AdventureComboBuilderView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
                    .onAppear {
                        adventureComboBuilderViewModel.resetForFoodOnly()
                    }
            case let .orderSuccess(order):
                OrderSuccessView(order: order, path: $path)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Flavors from Altos del Murco")
                    .font(.title2.bold())
                    .foregroundStyle(palette.textPrimary)
                
                Text("Explore our charcoal-grilled dishes, house specials, drinks, and more.")
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
            
            NavigationLink(value: Route.reservationBuilder) {
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .restaurant, systemImage: "calendar.badge.plus")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reservar comida o evento")
                            .font(.headline)
                            .foregroundStyle(palette.textPrimary)
                        Text("Cumpleaños, reuniones y comida para una visita futura.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundStyle(palette.textTertiary)
                }
                .appCardStyle(.restaurant)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(.restaurant, emphasized: false)
    }
    
    private var featuredCarousel: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Popular",
                subtitle: "Customer favorites and featured dishes"
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
                title: "Browse by category"
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
                        MenuItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func categoryTitle(for categoryId: String) -> String {
        categories.first(where: { $0.id == categoryId })?.title ?? ""
    }
    
    private func stockBadge(for item: MenuItem) -> some View {
        Text(item.stockLabel)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(item.canBeOrdered ? palette.textSecondary : palette.destructive)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        item.canBeOrdered
                        ? palette.elevatedCard
                        : palette.destructive.opacity(0.12)
                    )
            )
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                clientDetailsSection
                summarySection
                confirmSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .navigationTitle("Checkout")
        .appScreenStyle(.restaurant)
        .alert(
            "Error",
            isPresented: .constant(viewModel.state.errorMessage != nil),
            actions: {
                Button("OK") {
                    viewModel.clearError()
                }
            },
            message: {
                Text(viewModel.state.errorMessage ?? "")
            }
        )
        .onAppear {
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
                title: "Client Details",
                subtitle: "Your profile information is used automatically for this order."
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
                    title: "Table number",
                    text: Binding(
                        get: { cartManager.tableNumber },
                        set: { cartManager.updateTableNumber($0) }
                    )
                )
                .keyboardType(.numberPad)
                
                HStack(alignment: .top, spacing: 12) {
                    BrandIconBubble(theme: .restaurant, systemImage: "person.crop.circle.badge.checkmark", size: 38)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Need to update your information?")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        
                        Text("Please change your name or cédula from the Edit Profile page.")
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .fill(palette.elevatedCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                        .stroke(palette.stroke, lineWidth: 1)
                )
                
                HStack(spacing: 12) {
                    BrandIconBubble(theme: .restaurant, systemImage: "clock.fill", size: 38)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Order time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.textPrimary)
                        
                        Text(cartManager.orderCreatedAt.formatted(date: .omitted, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(palette.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(14)
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
        .appCardStyle(.restaurant, emphasized: false)
    }
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Summary",
                subtitle: "Quick review of the order before confirming."
            )
            
            VStack(spacing: 14) {
                summaryRow(
                    title: "Items",
                    value: "\(cartManager.totalItems)",
                    systemImage: "fork.knife"
                )
                
                summaryRow(
                    title: "Total",
                    value: cartManager.totalAmount.priceText,
                    systemImage: "dollarsign.circle.fill",
                    isHighlighted: true
                )
            }
        }
        .appCardStyle(.restaurant)
    }
    
    private var confirmSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.onEvent(.confirmTapped)
            } label: {
                Group {
                    if viewModel.state.isSubmitting {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Confirm Order")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(BrandPrimaryButtonStyle(theme: .restaurant))
            .disabled(viewModel.state.isSubmitting)
            
            Text("Review the data carefully before creating the order.")
                .font(.footnote)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .appCardStyle(.restaurant)
    }
    
    private func themedField(
        title: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            
            TextField(title, text: text)
                .appTextFieldStyle(.restaurant)
        }
    }
    
    private func summaryRow(
        title: String,
        value: String,
        systemImage: String,
        isHighlighted: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            BrandIconBubble(theme: .restaurant, systemImage: systemImage, size: 40)
            
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(isHighlighted ? .headline.bold() : .headline)
                .foregroundStyle(isHighlighted ? palette.primary : palette.textPrimary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .fill(palette.elevatedCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                .stroke(palette.stroke, lineWidth: 1)
        )
    }
    
    private func syncProfileFieldsFromSession() {
        guard let profile = authenticatedProfile else { return }
        
        if cartManager.clientId != profile.nationalId {
            cartManager.updateClientId(profile.nationalId)
        }
        
        if cartManager.clientName != profile.fullName {
            cartManager.updateClientName(profile.fullName)
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
        if item.isCompleted { return "Ready" }
        if item.isStarted { return "In progress" }
        return "Waiting"
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
                    title: "Items",
                    subtitle: "Everything included in this order"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }

            Section {
                amountsCard
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            } header: {
                BrandSectionHeader(
                    theme: .restaurant,
                    title: "Amounts"
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .textCase(nil)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationTitle("Order Detail")
        .navigationBarTitleDisplayMode(.inline)
        .appScreenStyle(.restaurant)
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(order.clientName.isEmpty ? "Walk-in customer" : order.clientName)
                        .font(.title3.bold())
                        .foregroundStyle(palette.textPrimary)

                    Text("Order #\(order.id.prefix(8))")
                        .font(.caption)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer()

                OrderStatusBadge(status: effectiveStatus)
            }

            HStack(spacing: 12) {
                DetailMetricView(
                    title: "Table",
                    value: order.tableNumber,
                    systemImage: "tablecells"
                )

                DetailMetricView(
                    title: "Items",
                    value: "\(order.totalItems)",
                    systemImage: "fork.knife"
                )
            }

            HStack(spacing: 12) {
                DetailMetricView(
                    title: "Created",
                    value: order.createdAt.shortDateTimeString,
                    systemImage: "calendar"
                )

                DetailMetricView(
                    title: "Updated",
                    value: order.updatedAt.shortDateTimeString,
                    systemImage: "clock.arrow.circlepath"
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Preparation progress")
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
                Label("This order needs reconfirmation before kitchen proceeds.", systemImage: "exclamationmark.triangle.fill")
                    .font(.subheadline)
                    .foregroundStyle(palette.warning)
                    .padding(.top, 2)
            }
        }
        .appCardStyle(.restaurant, emphasized: false)
    }
    
    private var amountsCard: some View {
        VStack(spacing: 0) {
            detailLine(title: "Subtotal", value: order.subtotal.priceText)
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
        "\(order.preparedItemsCount)/\(order.totalItems) items"
    }

    private var progressValue: Double {
        guard order.totalItems > 0 else { return 0 }
        return Double(order.preparedItemsCount) / Double(order.totalItems)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.clientName.isEmpty ? "Walk-in customer" : order.clientName)
                        .font(.headline)
                        .foregroundStyle(palette.textPrimary)

                    HStack(spacing: 8) {
                        Label("Table \(order.tableNumber)", systemImage: "tablecells")
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

                    Text(order.totalAmount.priceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(palette.primary)
                }

                ProgressView(value: progressValue)
                    .tint(progressColor)
            }

            if order.requiresReconfirmation {
                Label("Edited after confirmation", systemImage: "exclamationmark.arrow.trianglehead.2.clockwise")
                    .font(.caption)
                    .foregroundStyle(palette.warning)
            } else if order.wasEditedAfterConfirmation {
                Label("Updated order", systemImage: "pencil.circle")
                    .font(.caption)
                    .foregroundStyle(palette.textSecondary)
            }
        }
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
                
                Button {
                    path = NavigationPath()
                } label: {
                    Text("Done")
                }
                .buttonStyle(BrandPrimaryButtonStyle(theme: theme))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .scrollIndicators(.hidden)
        .navigationTitle("Success")
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
                Text("Order Sent")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.textPrimary)
                
                Text("Your order was created successfully.")
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
                title: "Order summary",
                subtitle: "Your restaurant order has been registered correctly."
            )
            
            VStack(spacing: 14) {
                InfoRow(title: "Order ID", value: String(order.id.prefix(7)), theme: theme)
                InfoRow(title: "Client", value: order.clientName, theme: theme)
                InfoRow(title: "Table", value: order.tableNumber, theme: theme)
                InfoRow(title: "Status", value: order.status.title, theme: theme)
                InfoRow(
                    title: "Time",
                    value: order.createdAt.formatted(date: .omitted, time: .shortened),
                    theme: theme
                )
                InfoRow(title: "Total", value: order.totalAmount.priceText, theme: theme, emphasized: true)
            }
        }
        .appCardStyle(theme, emphasized: true)
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
                title: "Pending",
                value: "\(pendingCount)",
                systemImage: "clock",
                tone: .warning
            )

            SummaryMetricCard(
                theme: theme,
                title: "Preparing",
                value: "\(preparingCount)",
                systemImage: "flame.fill",
                tone: .accent
            )

            SummaryMetricCard(
                theme: theme,
                title: "Completed",
                value: "\(completedCount)",
                systemImage: "checkmark.circle.fill",
                tone: .success
            )

            SummaryMetricCard(
                theme: theme,
                title: "Revenue",
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

struct OrdersView: View {
    @ObservedObject var viewModel: OrdersViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var palette: ThemePalette {
        AppTheme.palette(for: .restaurant, scheme: colorScheme)
    }

    private var groupedOrders: [(status: OrderStatus, orders: [Order])] {
        let grouped = Dictionary(grouping: viewModel.state.orders) { $0.recalculatedStatus() }

        let orderedStatuses: [OrderStatus] = [
            .pending,
            .confirmed,
            .preparing,
            .completed,
            .canceled
        ]

        return orderedStatuses.compactMap { status in
            guard let orders = grouped[status], !orders.isEmpty else { return nil }
            return (status, orders.sorted { $0.createdAt > $1.createdAt })
        }
    }

    var body: some View {
        ZStack {
            BrandScreenBackground(theme: .restaurant)
            content
        }
        .navigationTitle("Orders")
        .navigationBarTitleDisplayMode(.large)
        .tint(palette.primary)
        .onAppear {
            viewModel.onEvent(.onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.state.isLoading && viewModel.state.orders.isEmpty {
            loadingView
        } else if let error = viewModel.state.errorMessage, viewModel.state.orders.isEmpty {
            stateCard(
                title: "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: error
            )
        } else if viewModel.state.orders.isEmpty {
            stateCard(
                title: "No orders yet",
                systemImage: "tray",
                description: "Orders will appear here once customers place them."
            )
        } else {
            ordersList
        }
    }

    private var loadingView: some View {
        VStack {
            ProgressView("Loading orders...")
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

            ForEach(groupedOrders, id: \.status) { group in
                Section {
                    ForEach(group.orders) { order in
                        NavigationLink {
                            OrderDetailView(order: order)
                        } label: {
                            OrderRowView(order: order)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .appListRowStyle(.restaurant)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    sectionHeader(for: group.status, count: group.orders.count)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .refreshable {
            viewModel.onEvent(.refresh)
        }
    }

    private var summarySection: some View {
        Section {
            OrdersSummaryView(orders: viewModel.state.orders)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appCardStyle(.restaurant, emphasized: false)
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 10, trailing: 8))
                .listRowBackground(Color.clear)
        } header: {
            BrandSectionHeader(
                theme: .restaurant,
                title: "Overview",
                subtitle: "Track today’s and recent restaurant orders."
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
            .textCase(nil)
        }
    }

    private func sectionHeader(for status: OrderStatus, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(status.title)
                .font(.headline)
                .foregroundStyle(palette.textPrimary)

            Spacer()

            BrandBadge(
                theme: .restaurant,
                title: "\(count)",
                selected: status == .pending || status == .preparing
            )
        }
        .padding(.horizontal, 4)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .textCase(nil)
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

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published private(set) var state = CheckoutState()
    
    private let submitOrderUseCase: SubmitOrderUseCase
    private let cartManager: CartManager
    
    init(
        submitOrderUseCase: SubmitOrderUseCase,
        cartManager: CartManager
    ) {
        self.submitOrderUseCase = submitOrderUseCase
        self.cartManager = cartManager
    }
    
    func onEvent(_ event: CheckoutEvent) {
        switch event {
        case .confirmTapped:
            submitOrder()
        }
    }
    
    private func submitOrder() {
        guard let order = cartManager.createOrder() else {
            state.errorMessage = "Please complete client name, table number, and cart items."
            return
        }
        
        state.isSubmitting = true
        state.errorMessage = nil
        
        Task {
            do {
                try await submitOrderUseCase.execute(order: order)
                cartManager.clear()
                state.createdOrder = order
                state.isSubmitting = false
            } catch {
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
            }
        }
    }
    
    func clearError() {
        state.errorMessage = nil
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
    var errorMessage: String?
}

@MainActor
final class MenuViewModel: ObservableObject {
    @Published private(set) var state = RestaurantMenuState()

    private let service: MenuServiceable
    private var listenerToken: MenuListenerTokenable?

    init(service: MenuServiceable) {
        self.service = service
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
import FirebaseAuth

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var state = OrdersState()

    private let observeOrdersUseCase: ObserveOrdersUseCase
    private var observeTask: Task<Void, Never>?

    init(observeOrdersUseCase: ObserveOrdersUseCase) {
        self.observeOrdersUseCase = observeOrdersUseCase
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

        state.isLoading = true
        state.errorMessage = nil

        observeTask = Task {
            do {
                for try await orders in observeOrdersUseCase.execute(nationalId: "0503638371") {
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

import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: MainTab = .home
    
    @ObservedObject var ordersViewModel: OrdersViewModel
    @ObservedObject var checkoutViewModel: CheckoutViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    private let adventureModuleFactory: AdventureModuleFactory
    @StateObject private var adventureComboBuilderViewModel: AdventureComboBuilderViewModel

    init(
        ordersViewModel: OrdersViewModel,
        checkoutViewModel: CheckoutViewModel,
        menuViewModel: MenuViewModel,
        adventureModuleFactory: AdventureModuleFactory
    ) {
        self.ordersViewModel = ordersViewModel
        self.checkoutViewModel = checkoutViewModel
        self.menuViewModel = menuViewModel
        self.adventureModuleFactory = adventureModuleFactory
        
        _adventureComboBuilderViewModel = StateObject(
            wrappedValue: adventureModuleFactory.makeBuilderViewModel()
        )
    }
    
    
    private var selectedPalette: ThemePalette {
        AppTheme.palette(for: selectedTab.theme, scheme: colorScheme)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
            )
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
                adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel
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

