//
//  AdventureCatalogView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 1/4/26.
//

import SwiftUI

@MainActor
struct AdventureCatalogView: View {
    let adventureModuleFactory: AdventureModuleFactory
    
    private let singles = AdventureActivityType.allCases.map(AdventureActivityType.defaultDraft(for:))
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    featuredSection
                    singlesSection
                    customComboSection
                }
                .padding()
            }
            .navigationTitle("Aventura en Los Altos")
        }
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Construye tu combo perfecto")
                .font(.largeTitle.bold())
            
            Text("Mezcla off-road, paintball, go karts, campo de tiro, camping y columpio extremo con duraciones y número de personas personalizados.")
                .foregroundStyle(.secondary)
            
            NavigationLink {
                AdventureComboBuilderView(
                    viewModel: adventureModuleFactory.makeBuilderViewModel()
                )
            } label: {
                Text("Iniciar combo personalizado")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .foregroundStyle(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemGray6))
        )
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Paquetes destacados")
                .font(.title3.bold())
            
            ForEach(AdventureCatalogTemplates.featured) { template in
                NavigationLink {
                    AdventureComboBuilderView(
                        viewModel: adventureModuleFactory.makeBuilderViewModel(
                            prefilledItems: template.items
                        )
                    )
                } label: {
                    TemplateCard(template: template)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var singlesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividades individuales")
                .font(.title3.bold())
            
            ForEach(singles, id: \.id) { item in
                NavigationLink {
                    AdventureComboBuilderView(
                        viewModel: adventureModuleFactory.makeBuilderViewModel(
                            prefilledItems: [item]
                        )
                    )
                } label: {
                    SingleActivityCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var customComboSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("¿Necesitas algo diferente?")
                .font(.title3.bold())

            Text("Puedes arrastrar para reordenar las actividades y establecer diferentes duraciones y número de personas por actividad.")
                .foregroundStyle(.secondary)
            
            NavigationLink {
                AdventureComboBuilderView(
                    viewModel: adventureModuleFactory.makeBuilderViewModel()
                )
            } label: {
                Text("Abrir creador de combos")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
}

private struct TemplateCard: View {
    let template: AdventureTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(template.title)
                    .font(.headline)
                Spacer()
                if let badge = template.badge {
                    Text(badge)
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Text(template.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("From $\(AdventurePricingEngine.estimatedDiscountedSubtotal(items: template.items), default: "%.2f")")                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

private struct SingleActivityCard: View {
    let item: AdventureReservationItemDraft
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(width: 56, height: 56)
                
                Image(systemName: item.activity.systemImage)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.activity.title)
                    .font(.headline)
                Text(item.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                let base = AdventurePricingEngine.subtotal(for: item)
                Text("Desde $\(AdventurePricingEngine.discountedSubtotal(for: base), specifier: "%.2f")")                    .font(.caption.weight(.semibold))
            }
            
            Spacer()
            
            Text("Reservar ahora")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
}

