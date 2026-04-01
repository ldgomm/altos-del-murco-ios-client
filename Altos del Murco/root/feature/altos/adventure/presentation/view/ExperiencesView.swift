//
//  ExperiencesView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

import SwiftUI

struct ExperiencesView: View {
    let services: [AdventureService] = AdventureService.mockServices
    let adventureModuleFactory: AdventureModuleFactory
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(services) { service in
                        NavigationLink {
                            ServiceDetailView(
                                service: service,
                                adventureModuleFactory: adventureModuleFactory
                            )
                        } label: {
                            ServiceCardView(service: service)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Experiences")
        }
    }
}
