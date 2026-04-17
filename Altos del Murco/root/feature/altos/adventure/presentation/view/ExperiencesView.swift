//
//  ExperiencesView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ExperiencesView: View {
    @ObservedObject var adventureComboBuilderViewModel: AdventureComboBuilderViewModel
    @ObservedObject var menuViewModel: MenuViewModel
    
    var body: some View {
        AdventureCatalogView(adventureComboBuilderViewModel: adventureComboBuilderViewModel, menuViewModel: menuViewModel)
    }
}
