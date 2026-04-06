//
//  ExperiencesView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ExperiencesView: View {
    @ObservedObject var comboBuilderViewModel: AdventureComboBuilderViewModel
    
    var body: some View {
        AdventureCatalogView(comboBuilderViewModel: comboBuilderViewModel)
    }
}
