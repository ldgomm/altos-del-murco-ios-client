//
//  LoyaltyWalletViewModel.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import Combine
import SwiftUI

@MainActor
final class LoyaltyWalletViewModel: ObservableObject {
    @Published private(set) var state = LoyaltyWalletState()
    
    private let observeWalletUseCase: ObserveLoyaltyWalletUseCase
    private let fetchRewardsUseCase: FetchRewardsUseCase
    private let fetchTransactionsUseCase: FetchLoyaltyTransactionsUseCase
    private let previewRewardUseCase: PreviewRewardRedemptionUseCase
    private let redeemRewardUseCase: RedeemRewardUseCase
    
    private var walletObserverTask: Task<Void, Never>?
    
    init(
        observeWalletUseCase: ObserveLoyaltyWalletUseCase,
        fetchRewardsUseCase: FetchRewardsUseCase,
        fetchTransactionsUseCase: FetchLoyaltyTransactionsUseCase,
        previewRewardUseCase: PreviewRewardRedemptionUseCase,
        redeemRewardUseCase: RedeemRewardUseCase
    ) {
        self.observeWalletUseCase = observeWalletUseCase
        self.fetchRewardsUseCase = fetchRewardsUseCase
        self.fetchTransactionsUseCase = fetchTransactionsUseCase
        self.previewRewardUseCase = previewRewardUseCase
        self.redeemRewardUseCase = redeemRewardUseCase
    }
    
    deinit {
        walletObserverTask?.cancel()
    }
    
    func onEvent(_ event: LoyaltyWalletEvent) {
        switch event {
        case .onAppear(let clientId):
            handleOnAppear(clientId: clientId)
            
        case .didTapReward(let reward):
            Task { await loadPreview(for: reward) }
            
        case .confirmRedeem:
            Task { await redeemSelectedReward() }
            
        case .dismissPreview:
            state.selectedReward = nil
            state.preview = nil
            state.isLoadingPreview = false
            
        case .clearMessage:
            state.errorMessage = nil
            state.successMessage = nil
            
        case .retry:
            guard let clientId = state.clientId else { return }
            handleOnAppear(clientId: clientId)
        }
    }
    
    private func handleOnAppear(clientId: String) {
        if state.clientId != clientId {
            state.clientId = clientId
            startWalletObservation(clientId: clientId)
        }
        
        Task {
            await loadStaticData(clientId: clientId)
        }
    }
    
    private func startWalletObservation(clientId: String) {
        walletObserverTask?.cancel()
        
        walletObserverTask = Task {
            do {
                for try await wallet in observeWalletUseCase.execute(clientId: clientId) {
                    state.wallet = wallet
                }
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func loadStaticData(clientId: String) async {
        state.isLoading = true
        state.errorMessage = nil
        
        do {
            async let rewards = fetchRewardsUseCase.execute()
            async let transactions = fetchTransactionsUseCase.execute(clientId: clientId)
            
            state.rewards = try await rewards
            state.transactions = try await transactions
        } catch {
            state.errorMessage = error.localizedDescription
        }
        
        state.isLoading = false
    }
    
    private func loadPreview(for reward: Reward) async {
        guard let clientId = state.clientId else { return }
        
        state.selectedReward = reward
        state.preview = nil
        state.isLoadingPreview = true
        state.errorMessage = nil
        
        do {
            state.preview = try await previewRewardUseCase.execute(
                clientId: clientId,
                rewardId: reward.id
            )
        } catch {
            state.errorMessage = error.localizedDescription
        }
        
        state.isLoadingPreview = false
    }
    
    private func redeemSelectedReward() async {
        guard let clientId = state.clientId,
              let reward = state.selectedReward,
              let preview = state.preview,
              preview.canRedeem
        else { return }
        
        state.isRedeeming = true
        state.errorMessage = nil
        
        do {
            let result = try await redeemRewardUseCase.execute(
                clientId: clientId,
                rewardId: reward.id
            )
            
            state.successMessage = "\(result.rewardTitle) redeemed successfully."
            state.selectedReward = nil
            state.preview = nil
            state.transactions = try await fetchTransactionsUseCase.execute(clientId: clientId)
        } catch {
            state.errorMessage = error.localizedDescription
        }
        
        state.isRedeeming = false
    }
}
