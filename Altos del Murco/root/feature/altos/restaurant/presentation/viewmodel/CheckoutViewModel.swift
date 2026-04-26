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
        cartManager.refreshDefaultScheduleIfNeeded()

        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldRestartObservation = cleanNationalId != currentNationalId || walletListenerToken == nil
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
        case .scheduledAtChanged(let date):
            cartManager.updateScheduledAt(date)
        case .scheduleNowTapped:
            cartManager.scheduleForNow()
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
                    allocation = min(cartItem.totalPrice, max(0, roundMoney(totalDiscount * share)))
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
                state.errorMessage = cartManager.isScheduledForLater
                    ? "Agrega productos y confirma que tu perfil tenga nombre y cédula. La mesa puede quedar por asignar para reservas."
                    : "Completa la mesa y asegúrate de tener productos en el carrito."
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
