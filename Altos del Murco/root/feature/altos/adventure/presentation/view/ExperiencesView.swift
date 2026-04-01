//
//  ExperiencesView.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import SwiftUI

struct ExperiencesView: View {
    let adventureModuleFactory: AdventureModuleFactory
    
    var body: some View {
        AdventureCatalogView(adventureModuleFactory: adventureModuleFactory)
    }
}
