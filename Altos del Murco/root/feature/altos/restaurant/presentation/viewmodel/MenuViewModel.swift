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
        if walletListenerToken == nil {
            startWalletObservation()
        }

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
        let cleanNationalId = nationalId.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldRestart = state.currentNationalId != cleanNationalId || walletListenerToken == nil
        state.currentNationalId = cleanNationalId

        if shouldRestart {
            startWalletObservation()
        }
    }

    private func startWalletObservation() {
        walletListenerToken?.remove()
        walletListenerToken = nil

        walletListenerToken = loyaltyRewardsService.observeWalletSnapshot() { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.state.isLoadingRewards = false

                switch result {
                case .success(let snapshot):
                    self.state.rewardWalletSnapshot = snapshot

                case .failure(let error):
                    self.state.rewardWalletSnapshot = .empty()
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
