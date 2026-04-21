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

    init(
        service: MenuServiceable,
        loyaltyRewardsService: LoyaltyRewardsServiceable
    ) {
        self.service = service
        self.loyaltyRewardsService = loyaltyRewardsService
    }

    func onAppear() {
        if listenerToken == nil {
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

        Task {
            await refreshRewardWallet()
        }
    }

    func setNationalId(_ nationalId: String) {
        let cleanNationalId = nationalId.filter(\.isNumber)
        guard state.currentNationalId != cleanNationalId else { return }

        state.currentNationalId = cleanNationalId

        Task {
            await refreshRewardWallet()
        }
    }

    func rewardPresentation(for item: MenuItem) -> RewardPresentation? {
        RewardPresentationFactory.menuPresentation(
            for: item,
            wallet: state.rewardWalletSnapshot
        )
    }

    func onDisappear() {
        listenerToken?.remove()
        listenerToken = nil
    }

    private func refreshRewardWallet() async {
        let cleanNationalId = state.currentNationalId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanNationalId.isEmpty else {
            state.rewardWalletSnapshot = .empty(nationalId: "")
            state.isLoadingRewards = false
            return
        }

        state.isLoadingRewards = true
        defer { state.isLoadingRewards = false }

        do {
            state.rewardWalletSnapshot = try await loyaltyRewardsService.loadWalletSnapshot(for: cleanNationalId)
        } catch {
            state.rewardWalletSnapshot = .empty(nationalId: cleanNationalId)
            state.errorMessage = error.localizedDescription
        }
    }
}
