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
    
    var body: some View {
        HStack(spacing: 16) {
            Button {
                if isEnabled && quantity > 1 {
                    quantity -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Circle())
            }
            .disabled(!isEnabled || quantity <= 1)
            
            Text("\(quantity)")
                .font(.title3)
                .fontWeight(.semibold)
                .frame(minWidth: 28)
                .foregroundStyle(isEnabled ? .primary : .secondary)
            
            Button {
                if isEnabled {
                    quantity += 1
                }
            } label: {
                Image(systemName: "plus")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(Color.gray.opacity(0.12))
                    .clipShape(Circle())
            }
            .disabled(!isEnabled)
        }
        .opacity(isEnabled ? 1.0 : 0.5)
    }
}
