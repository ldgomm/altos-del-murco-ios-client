//
//  LoyaltyWalletView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 13/3/26.
//

import SwiftUI

struct LoyaltyWalletView: View {
    @StateObject var viewModel: LoyaltyWalletViewModel
    let clientId: String
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.state.isLoading && viewModel.state.wallet == nil {
                    ProgressView("Loading wallet...")
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            walletHeader
                            providerBalancesSection
                            rewardsSection
                            transactionsSection
                        }
                        .padding()
                    }
                    .refreshable {
                        viewModel.onEvent(.retry)
                    }
                }
            }
            .navigationTitle("My Points")
            .onAppear {
                viewModel.onEvent(.onAppear(clientId: clientId))
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.state.errorMessage != nil },
                    set: { _ in viewModel.onEvent(.clearMessage) }
                ),
                actions: {
                    Button("OK", role: .cancel) {
                        viewModel.onEvent(.clearMessage)
                    }
                },
                message: {
                    Text(viewModel.state.errorMessage ?? "")
                }
            )
            .alert(
                "Done",
                isPresented: Binding(
                    get: { viewModel.state.successMessage != nil },
                    set: { _ in viewModel.onEvent(.clearMessage) }
                ),
                actions: {
                    Button("OK", role: .cancel) {
                        viewModel.onEvent(.clearMessage)
                    }
                },
                message: {
                    Text(viewModel.state.successMessage ?? "")
                }
            )
            .sheet(
                isPresented: Binding(
                    get: { viewModel.state.selectedReward != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.onEvent(.dismissPreview)
                        }
                    }
                )
            ) {
                redemptionPreviewSheet
            }
        }
    }
    
    private var walletHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available Points")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("\(viewModel.state.wallet?.totalAvailablePoints ?? 0)")
                .font(.system(size: 42, weight: .bold, design: .rounded))
            
            if let updatedAt = viewModel.state.wallet?.updatedAt {
                Text("Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var providerBalancesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Points by Provider")
                .font(.title3.bold())
            
            if let balances = viewModel.state.wallet?.providerBalances, !balances.isEmpty {
                ForEach(balances) { balance in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(balance.providerName)
                                .font(.headline)
                            
                            Text(balance.serviceIds.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(balance.availablePoints) pts")
                            .font(.subheadline.bold())
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            } else {
                Text("No points yet.")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var rewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.title3.bold())
            
            ForEach(viewModel.state.rewards) { reward in
                Button {
                    viewModel.onEvent(.didTapReward(reward))
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(reward.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("\(reward.pointsRequired) pts")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        if !reward.subtitle.isEmpty {
                            Text(reward.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(reward.settlementAmount, format: .currency(code: "USD"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.title3.bold())
            
            if viewModel.state.transactions.isEmpty {
                Text("No activity yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.state.transactions) { transaction in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.serviceName)
                                .font(.headline)
                            
                            Text(transaction.providerName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if let note = transaction.note, !note.isEmpty {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(transaction.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(pointsText(for: transaction))
                            .font(.headline)
                            .foregroundStyle(transaction.points >= 0 ? .green : .red)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
    
    private var redemptionPreviewSheet: some View {
        NavigationStack {
            Group {
                if viewModel.state.isLoadingPreview {
                    ProgressView("Calculating reward...")
                } else if let preview = viewModel.state.preview {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(preview.rewardTitle)
                                    .font(.title2.bold())
                                
                                Text("Required: \(preview.pointsRequired) points")
                                    .font(.headline)
                                
                                Text("Available: \(preview.currentAvailablePoints) points")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(preview.settlementAmount, format: .currency(code: "USD"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Funding Breakdown")
                                    .font(.headline)
                                
                                ForEach(preview.providerShares) { share in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(share.providerName)
                                                .font(.subheadline.bold())
                                            Text(share.serviceName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("\(share.pointsUsed) pts")
                                                .font(.subheadline.bold())
                                            Text(share.amount, format: .currency(code: "USD"))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                            
                            if preview.canRedeem {
                                Button {
                                    viewModel.onEvent(.confirmRedeem)
                                } label: {
                                    HStack {
                                        if viewModel.state.isRedeeming {
                                            ProgressView()
                                                .tint(.white)
                                        }
                                        Text(viewModel.state.isRedeeming ? "Redeeming..." : "Confirm Redemption")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .disabled(viewModel.state.isRedeeming)
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Not enough points")
                                        .font(.headline)
                                    Text("You need \(preview.missingPoints) more points to redeem this reward.")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Preview unavailable",
                        systemImage: "gift",
                        description: Text("Please try again.")
                    )
                }
            }
            .navigationTitle("Reward Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        viewModel.onEvent(.dismissPreview)
                    }
                }
            }
        }
    }
    
    private func pointsText(for transaction: LoyaltyTransaction) -> String {
        transaction.points >= 0 ? "+\(transaction.points)" : "\(transaction.points)"
    }
}

extension LoyaltyWalletView {
    static func build(clientId: String) -> LoyaltyWalletView {
        let service = FirebaseLoyaltyService()
        
        let viewModel = LoyaltyWalletViewModel(
            observeWalletUseCase: ObserveLoyaltyWalletUseCase(service: service),
            fetchRewardsUseCase: FetchRewardsUseCase(service: service),
            fetchTransactionsUseCase: FetchLoyaltyTransactionsUseCase(service: service),
            previewRewardUseCase: PreviewRewardRedemptionUseCase(service: service),
            redeemRewardUseCase: RedeemRewardUseCase(service: service)
        )
        
        return LoyaltyWalletView(
            viewModel: viewModel,
            clientId: clientId
        )
    }
}
