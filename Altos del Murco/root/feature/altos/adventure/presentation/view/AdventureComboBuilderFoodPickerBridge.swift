//
//  AdventureComboBuilderFoodPickerBridge.swift
//  Altos del Murco
//
//  Created by José Ruiz on 6/5/26.
//

import SwiftUI

struct AdventureComboBuilderFoodPickerBridge: View {
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    var body: some View {
        AdventureFoodPickerSheet(
            menuSections: menuViewModel.state.sections,
            selectedDate: adventureComboBuilderViewModel.state.selectedDate,
            rewardPresentationProvider: { item, quantity in
                adventureComboBuilderViewModel.foodPickerRewardPresentation(for: item, quantity: quantity)
            },
            displayedPriceProvider: { item, quantity in
                adventureComboBuilderViewModel.foodPickerDisplayedPrice(for: item, quantity: quantity)
            },
            incrementalDiscountProvider: { item, quantity in
                adventureComboBuilderViewModel.foodPickerIncrementalDiscount(for: item, quantity: quantity)
            },
            onAdd: { item, quantity, notes in
                adventureComboBuilderViewModel.addFoodItem(
                    item,
                    quantity: quantity,
                    notes: notes,
                    for: adventureComboBuilderViewModel.state.selectedDate
                )
            }
        )
    }
}
