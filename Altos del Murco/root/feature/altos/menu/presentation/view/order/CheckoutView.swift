//
//  CheckoutView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import SwiftUI

struct CheckoutView: View {
    @StateObject private var viewModel: CheckoutViewModel
    @EnvironmentObject private var cartManager: CartManager
    @EnvironmentObject private var router: AppRouter
    
    init(viewModel: CheckoutViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            Section("Client Details") {
                TextField("Client id", text: Binding(
                    get: { cartManager.clientId ?? "" },
                    set: { cartManager.updateClientId($0) }
                ))
                
                TextField("Client name", text: Binding(
                    get: { cartManager.clientName },
                    set: { cartManager.updateClientName($0) }
                ))
                
                TextField("Table number", text: Binding(
                    get: { cartManager.tableNumber },
                    set: { cartManager.updateTableNumber($0) }
                ))
                .keyboardType(.numberPad)
                
                HStack {
                    Text("Order time")
                    Spacer()
                    Text(cartManager.orderCreatedAt.formatted(date: .omitted, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Summary") {
                HStack {
                    Text("Items")
                    Spacer()
                    Text("\(cartManager.totalItems)")
                }
                
                HStack {
                    Text("Total")
                    Spacer()
                    Text(cartManager.totalAmount.priceText)
                        .fontWeight(.bold)
                }
            }
            
            Section {
                Button {
                    viewModel.onEvent(.confirmTapped)
                } label: {
                    if viewModel.state.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Confirm Order")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.state.isSubmitting)
            }
        }
        .navigationTitle("Checkout")
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
        .onChange(of: viewModel.state.createdOrder) { _, order in
            guard let order else { return }
            router.path.append(Route.orderSuccess(order))
        }
    }
}
