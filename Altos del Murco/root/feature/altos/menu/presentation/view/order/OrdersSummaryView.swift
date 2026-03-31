//
//  OrdersSummaryView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct OrdersSummaryView: View {
    let orders: [Order]

    private var pendingCount: Int {
        orders.filter { $0.recalculatedStatus() == .pending }.count
    }

    private var preparingCount: Int {
        orders.filter { $0.recalculatedStatus() == .preparing }.count
    }

    private var completedCount: Int {
        orders.filter { $0.recalculatedStatus() == .completed }.count
    }

    private var totalRevenue: Double {
        orders
            .filter { $0.recalculatedStatus() != .canceled }
            .reduce(0) { $0 + $1.totalAmount }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryMetricCard(title: "Pending", value: "\(pendingCount)", systemImage: "clock")
                SummaryMetricCard(title: "Preparing", value: "\(preparingCount)", systemImage: "flame")
            }

            HStack(spacing: 12) {
                SummaryMetricCard(title: "Completed", value: "\(completedCount)", systemImage: "checkmark.circle")
                SummaryMetricCard(title: "Revenue", value: totalRevenue.priceText, systemImage: "dollarsign.circle")
            }
        }
    }
}

struct SummaryMetricCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
