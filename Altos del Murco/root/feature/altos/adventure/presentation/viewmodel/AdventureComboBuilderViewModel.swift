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
