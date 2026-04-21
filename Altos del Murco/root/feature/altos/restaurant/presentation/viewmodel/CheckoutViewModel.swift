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
        currentNationalId = cleanNationalId
        Task { await refreshRewardPreview(nationalId: cleanNationalId) }
    }

    func refreshRewardPreviewIfPossible() async {
        await refreshRewardPreview(nationalId: currentNationalId)
    }

    func refreshRewardPreview(nationalId: String) async {
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        currentNationalId = cleanNationalId

        guard !cleanNationalId.isEmpty else {
            state.rewardPreview = .empty(nationalId: "")
            return
        }

        guard let draftOrder = cartManager.createOrder() else {
            state.rewardPreview = .empty(nationalId: cleanNationalId)
            return
        }

        state.isLoadingRewards = true
        defer { state.isLoadingRewards = false }

        do {
            let result = try await loyaltyRewardsService.previewRestaurantRewards(
                for: cleanNationalId,
                items: draftOrder.items
            )

            state.rewardPreview = CheckoutRewardPreview(
                appliedRewards: result.appliedRewards,
                discountAmount: result.totalDiscount,
                walletSnapshot: result.walletSnapshot
            )
        } catch {
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

    private func submitOrder() {
        guard let baseOrder = cartManager.createOrder() else {
            state.errorMessage = "Please complete client name, table number, and cart items."
            return
        }

        let finalOrder = baseOrder.withLoyalty(
            appliedRewards: state.rewardPreview.appliedRewards,
            discount: state.rewardPreview.discountAmount
        )

        state.isSubmitting = true
        state.errorMessage = nil

        Task {
            do {
                try await submitOrderUseCase.execute(order: finalOrder)
                cartManager.clear()
                state.createdOrder = finalOrder
                state.rewardPreview = .empty(nationalId: currentNationalId)
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
