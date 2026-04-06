//
//  AdventureService.swift
//  Altos del Murco
//
//  Created by José Ruiz on 31/3/26.
//

import Foundation

struct AdventureService: Identifiable, Hashable {
    let id: String
    let activityType: AdventureActivityType
    let title: String
    let systemImage: String
    let shortDescription: String
    let fullDescription: String
    let priceText: String
    let durationText: String
    let includes: [String]
    
    init(
        id: String = UUID().uuidString,
        activityType: AdventureActivityType,
        title: String,
        systemImage: String,
        shortDescription: String,
        fullDescription: String,
        priceText: String,
        durationText: String,
        includes: [String]
    ) {
        self.id = id
        self.activityType = activityType
        self.title = title
        self.systemImage = systemImage
        self.shortDescription = shortDescription
        self.fullDescription = fullDescription
        self.priceText = priceText
        self.durationText = durationText
        self.includes = includes
    }
    
    var defaultDraft: AdventureReservationItemDraft {
        AdventureActivityType.defaultDraft(for: activityType)
    }
}

extension AdventureService {
    static let mockServices: [AdventureService] = [
        AdventureService(
            activityType: .offRoad,
            title: "Off-road 4x4",
            systemImage: "car.fill",
            shortDescription: "Reserva 1, 2 o 3 horas por vehículo.",
            fullDescription: "Un vehículo off-road admite 1 o 2 personas. El precio es por vehículo por hora.",
            priceText: "$20 / hora / vehículo",
            durationText: "1 - 3 horas",
            includes: ["Vehículo", "Guía", "Charla de seguridad"]
        ),
        AdventureService(
            activityType: .paintball,
            title: "Paintball",
            systemImage: "shield.lefthalf.filled",
            shortDescription: "Sesiones flexibles para grupos.",
            fullDescription: "Reserva paintball en bloques de 30 minutos para tantas personas como desees.",
            priceText: "$5 / 30 min / persona",
            durationText: "30 - 120 min",
            includes: ["Marcadora", "Máscara", "Munición básica"]
        ),
        AdventureService(
            activityType: .goKarts,
            title: "Go karts",
            systemImage: "flag.checkered",
            shortDescription: "Vueltas rápidas con duración flexible.",
            fullDescription: "Reserva go karts en bloques de 30 minutos para grupos pequeños o grandes.",
            priceText: "$5 / 30 min / persona",
            durationText: "30 - 120 min",
            includes: ["Kart", "Casco", "Acceso a la pista"]
        ),
        AdventureService(
            activityType: .shootingRange,
            title: "Campo de tiro",
            systemImage: "target",
            shortDescription: "Sesiones de precisión por tiempo y número de personas.",
            fullDescription: "Reserva el campo de tiro de forma individual o dentro de un combo.",
            priceText: "$5 / 30 min / persona",
            durationText: "30 - 120 min",
            includes: ["Equipo", "Charla de seguridad"]
        ),
        AdventureService(
            activityType: .camping,
            title: "Camping",
            systemImage: "tent.fill",
            shortDescription: "Estadía nocturna con comida y experiencia off-road incluida.",
            fullDescription: "El camping se reserva por persona por noche y funciona como complemento nocturno.",
            priceText: "$30 / persona / noche",
            durationText: "1+ noches",
            includes: ["Comida", "Área para dormir", "Experiencia off-road incluida"]
        ),
        AdventureService(
            activityType: .extremeSlide,
            title: "Columpio extremo",
            systemImage: "figure.fall",
            shortDescription: "Experiencia en el columpio con transporte off-road incluido.",
            fullDescription: "Una sesión fija que incluye el transporte y el columpio.",
            priceText: "$15 / persona",
            durationText: "30 min + transporte",
            includes: ["Sesión en el columpio", "Transporte off-road incluido"]
        )
    ]
}
