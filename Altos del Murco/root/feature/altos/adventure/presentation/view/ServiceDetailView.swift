//
//  ServiceDetailView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ServiceDetailView: View {
    let service: AdventureService
    let adventureModuleFactory: AdventureModuleFactory
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                descriptionSection
                infoSection
                includesSection
                actionSection
            }
            .padding()
        }
        .navigationTitle(service.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemGray6))
                    .frame(height: 180)
                
                Image(systemName: service.systemImage)
                    .font(.system(size: 52))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(service.title)
                    .font(.largeTitle.bold())
                
                Text(service.shortDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.title3.bold())
            Text(service.fullDescription)
                .foregroundStyle(.secondary)
        }
    }
    
    private var infoSection: some View {
        HStack(spacing: 16) {
            infoCard(title: "Price", value: service.priceText, systemImage: "dollarsign.circle")
            infoCard(title: "Duration", value: service.durationText, systemImage: "clock")
        }
    }
    
    private func infoCard(title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray6))
        )
    }
    
    private var includesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Includes")
                .font(.title3.bold())
            
            ForEach(service.includes, id: \.self) { item in
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(item)
                }
            }
        }
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                AdventureReservationView(
                    viewModel: adventureModuleFactory.makeReservationViewModel(
                        initialPackage: service.defaultPackage
                    )
                )
            } label: {
                Text("Book Now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            NavigationLink {
                AdventureReservationView(
                    viewModel: adventureModuleFactory.makeReservationViewModel(
                        initialPackage: .fullAdventure
                    )
                )
            } label: {
                Text("Book Complete Adventure")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}
