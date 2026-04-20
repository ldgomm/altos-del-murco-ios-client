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
    var errorMessage: String?
    var successMessage: String?
}

@MainActor
final class AdventureComboBuilderViewModel: ObservableObject {
    @Published private(set) var state: AdventureComboBuilderState

    private let getAvailabilityUseCase: GetAdventureAvailabilityUseCase
    private let createBookingUseCase: CreateAdventureBookingUseCase
    private let fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase
    private var hasLoadedCatalog = false

    init(
        prefilledItems: [AdventureReservationItemDraft],
        initialPackageDiscountAmount: Double,
        getAvailabilityUseCase: GetAdventureAvailabilityUseCase,
        createBookingUseCase: CreateAdventureBookingUseCase,
        fetchAdventureCatalogUseCase: FetchAdventureCatalogUseCase
    ) {
        self.state = AdventureComboBuilderState(
            items: prefilledItems.isEmpty ? [AdventureActivityType.defaultDraft(for: .offRoad)] : prefilledItems,
            packageDiscountAmount: max(0, initialPackageDiscountAmount)
        )
        self.getAvailabilityUseCase = getAvailabilityUseCase
        self.createBookingUseCase = createBookingUseCase
        self.fetchAdventureCatalogUseCase = fetchAdventureCatalogUseCase

        keepCampingAtEnd()
    }

    func onAppear() {
        Task {
            await loadCatalogIfNeeded()
            await loadAvailability()
        }
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
            return
        }

        state.items.append(
            AdventureActivityType.defaultDraft(for: activity, catalog: state.catalog)
        )
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
        notes: String? = nil,
        for selectedDate: Date
    ) {
        let isTodayReservation = AdventureDateHelper.calendar.isDateInToday(selectedDate)

        guard !(isTodayReservation && !menuItem.canBeOrdered) else {
            state.errorMessage = "For today this item is out of stock and cannot be ordered."
            state.successMessage = nil
            return
        }

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
    
    func updateFoodItem(_ item: ReservationFoodItemDraft) {
        guard let index = state.foodItems.firstIndex(where: { $0.id == item.id }) else { return }

        let trimmedNotes = item.notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNotes = (trimmedNotes?.isEmpty == false) ? trimmedNotes : nil

        state.foodItems[index] = ReservationFoodItemDraft(
            id: item.id,
            menuItemId: item.menuItemId,
            name: item.name,
            unitPrice: item.unitPrice,
            quantity: max(1, item.quantity),
            notes: finalNotes
        )

        state.selectedSlot = nil
        Task { await loadAvailability() }
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

    func presentError(_ message: String) {
        state.errorMessage = message
        state.successMessage = nil
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
        max(0, estimatedAdventureSubtotal - state.packageDiscountAmount) + estimatedFoodSubtotal
    }

    func reset() {
        state = AdventureComboBuilderState(
            items: [AdventureActivityType.defaultDraft(for: .offRoad, catalog: state.catalog)],
            packageDiscountAmount: 0,
            catalog: state.catalog
        )
        keepCampingAtEnd()
        Task { await loadAvailability() }
    }

    func resetForFoodOnly() {
        state = AdventureComboBuilderState(
            items: [],
            packageDiscountAmount: 0,
            catalog: state.catalog
        )
        Task { await loadAvailability() }
    }

    func replaceItems(with items: [AdventureReservationItemDraft], packageDiscountAmount: Double = 0) {
        let uniqueItems = items.reduce(into: [AdventureReservationItemDraft]()) { result, item in
            guard !result.contains(where: { $0.activity == item.activity }) else { return }
            result.append(item)
        }

        state.items = uniqueItems.isEmpty ? [] : uniqueItems
        state.packageDiscountAmount = max(0, packageDiscountAmount)
        keepCampingAtEnd()
        state.selectedSlot = nil
        state.errorMessage = nil
        state.successMessage = nil
        Task { await loadAvailability() }
    }

    private func loadCatalogIfNeeded() async {
        guard !hasLoadedCatalog else { return }
        hasLoadedCatalog = true

        state.isLoadingCatalog = true
        do {
            let catalog = try await fetchAdventureCatalogUseCase.execute()
            state.catalog = catalog

            state.items = state.items.map { current in
                if let config = catalog.activity(for: current.activity) {
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
                return current
            }

            keepCampingAtEnd()
        } catch {
            state.errorMessage = error.localizedDescription
        }
        state.isLoadingCatalog = false
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
            packageDiscountAmount: state.packageDiscountAmount,
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
