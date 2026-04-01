//
//  MenuMockData.swift
//  Altos del Murco
//
//  Created by José Ruiz on 12/3/26.
//

import Foundation

struct MenuMockData {
    static let entradasCategory = MenuCategory(id: "entradas", title: "Entradas")
    static let sopasCategory = MenuCategory(id: "sopas", title: "Sopas")
    static let platosFuertesCategory = MenuCategory(id: "platos-fuertes", title: "Platos Fuertes")
    static let extrasCategory = MenuCategory(id: "extras", title: "Extras")
    static let postresCategory = MenuCategory(id: "postres", title: "Postres")
    static let bebidasCategory = MenuCategory(id: "bebidas", title: "Bebidas")
    static let bebidasAlcoholicasCategory = MenuCategory(id: "bebidas-alcoholicas", title: "Bebidas Alcohólicas")

    static let sections: [MenuSection] = [
        MenuSection(
            id: entradasCategory.id,
            category: entradasCategory,
            items: [
                MenuItem(
                    id: "choclo-con-queso",
                    categoryId: entradasCategory.id,
                    name: "Choclo con queso",
                    description: "Entrada tradicional serrana, ideal para abrir el apetito.",
                    notes: nil,
                    ingredients: [
                        "Choclo",
                        "Queso"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "habas-con-queso",
                    categoryId: entradasCategory.id,
                    name: "Habas con queso",
                    description: "Clásica combinación serrana, fresca y deliciosa.",
                    notes: nil,
                    ingredients: [
                        "Habas",
                        "Queso"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "maduro-con-queso",
                    categoryId: entradasCategory.id,
                    name: "Maduro con queso",
                    description: "Maduro suave y dulce con el contraste perfecto del queso.",
                    notes: nil,
                    ingredients: [
                        "Maduro",
                        "Queso"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "bandeja-mixta",
                    categoryId: entradasCategory.id,
                    name: "Bandeja mixta",
                    description: "Mix de entradas con auténtico sabor serrano.",
                    notes: nil,
                    ingredients: [
                        "Choclo",
                        "Habas",
                        "Maduro",
                        "Queso"
                    ],
                    price: 6.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                )
            ]
        ),

        MenuSection(
            id: sopasCategory.id,
            category: sopasCategory,
            items: [
                MenuItem(
                    id: "caldo-de-gallina",
                    categoryId: sopasCategory.id,
                    name: "Caldo de gallina",
                    description: "Delicioso caldo de gallina de campo con papas y verduras.",
                    notes: nil,
                    ingredients: [
                        "Gallina",
                        "Papa",
                        "Verduras",
                        "Caldo"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "yahuarlocro",
                    categoryId: sopasCategory.id,
                    name: "Yahuarlocro",
                    description: "Locro de papas con entrañas de borrego, aguacate, tomate, sangre de borrego y cebolla.",
                    notes: nil,
                    ingredients: [
                        "Papa",
                        "Entrañas de borrego",
                        "Aguacate",
                        "Tomate",
                        "Sangre de borrego",
                        "Cebolla"
                    ],
                    price: 5.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                )
            ]
        ),

        MenuSection(
            id: platosFuertesCategory.id,
            category: platosFuertesCategory,
            items: [
                MenuItem(
                    id: "cuy-asado-medio",
                    categoryId: platosFuertesCategory.id,
                    name: "Cuy asado - Medio",
                    description: "Crujiente y jugoso cuy asado con papas cocidas, encurtido, aguacate, tostado y salsa de maní.",
                    notes: nil,
                    ingredients: [
                        "Medio cuy asado",
                        "Papas cocidas",
                        "Encurtido de cebolla y tomate",
                        "Aguacate",
                        "Tostado",
                        "Salsa de maní"
                    ],
                    price: 12.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "cuy-asado-entero",
                    categoryId: platosFuertesCategory.id,
                    name: "Cuy asado - Entero",
                    description: "Crujiente y jugoso cuy asado con papas cocidas, encurtido, aguacate, tostado y salsa de maní.",
                    notes: nil,
                    ingredients: [
                        "Cuy asado",
                        "Papas cocidas",
                        "Encurtido de cebolla y tomate",
                        "Aguacate",
                        "Tostado",
                        "Salsa de maní"
                    ],
                    price: 24.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "parrillada-andina-individual",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Andina - Individual",
                    description: "Pollo, chuleta de lomo o chuleta de cerdo con chorizo parrillero, morcilla, choclo, habas y papa chaucha.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Choclo",
                        "Habas",
                        "Papa chaucha"
                    ],
                    price: 8.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "parrillada-andina-completa",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Andina - Completa",
                    description: "Chorizo parrillero, morcilla, pollo, chuleta de lomo y chuleta de cerdo con choclo, habas y papa chaucha.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Choclo",
                        "Habas",
                        "Papa chaucha"
                    ],
                    price: 12.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "parrillada-andina-para-dos",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Andina - Para dos",
                    description: "Chorizo parrillero, morcilla, pollo, chuleta de lomo y chuleta de cerdo con choclo, habas y papa chaucha.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Choclo",
                        "Habas",
                        "Papa chaucha"
                    ],
                    price: 23.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "parrillada-andina-familiar",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Andina - Familiar",
                    description: "Chorizo parrillero, morcilla, pollo, chuleta de lomo y chuleta de cerdo con choclo, habas y papa chaucha.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Choclo",
                        "Habas",
                        "Papa chaucha"
                    ],
                    price: 34.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "parrillada-altos-individual",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Altos - Individual",
                    description: "Pollo, chuleta de lomo o chuleta de cerdo con chorizo parrillero, morcilla, asados al carbón y papas fritas.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Papas fritas"
                    ],
                    price: 8.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "parrillada-altos-completa",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Altos - Completa",
                    description: "Chorizo parrillero, morcilla, pollo, chuleta de lomo y chuleta de cerdo asados al carbón con papas fritas.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Papas fritas"
                    ],
                    price: 12.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "parrillada-altos-para-dos",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Altos - Para dos",
                    description: "Chorizo parrillero, morcilla, pollo, chuleta de lomo y chuleta de cerdo asados al carbón con papas fritas.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Papas fritas"
                    ],
                    price: 23.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "parrillada-altos-familiar",
                    categoryId: platosFuertesCategory.id,
                    name: "Parrillada Altos - Familiar",
                    description: "Chorizo parrillero, morcilla, pollo, chuleta de lomo y chuleta de cerdo asados al carbón con papas fritas.",
                    notes: nil,
                    ingredients: [
                        "Chorizo parrillero",
                        "Morcilla",
                        "Pollo",
                        "Chuleta de lomo",
                        "Chuleta de cerdo",
                        "Papas fritas"
                    ],
                    price: 34.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "borrego-asado",
                    categoryId: platosFuertesCategory.id,
                    name: "Borrego asado",
                    description: "Filete de borrego tierno y sabroso con choclo, habas, queso, papa chaucha y melloco.",
                    notes: nil,
                    ingredients: [
                        "Filete de borrego",
                        "Choclo",
                        "Habas",
                        "Queso",
                        "Papa chaucha",
                        "Melloco"
                    ],
                    price: 10.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "costilla-bbq-jack-daniels",
                    categoryId: platosFuertesCategory.id,
                    name: "Costilla BBQ Jack Daniel’s",
                    description: "Costilla de cerdo suave y jugosa bañada en salsa BBQ Jack Daniel’s, con papas fritas y arroz blanco.",
                    notes: nil,
                    ingredients: [
                        "Costilla de cerdo",
                        "Salsa BBQ Jack Daniel’s",
                        "Papas fritas",
                        "Arroz blanco"
                    ],
                    price: 10.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                )
            ]
        ),

        MenuSection(
            id: extrasCategory.id,
            category: extrasCategory,
            items: [
                MenuItem(
                    id: "arroz",
                    categoryId: extrasCategory.id,
                    name: "Arroz",
                    description: "Porción adicional de arroz blanco.",
                    notes: nil,
                    ingredients: [
                        "Arroz"
                    ],
                    price: 1.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "salsa-bbq",
                    categoryId: extrasCategory.id,
                    name: "Salsa BBQ",
                    description: "Porción extra de salsa BBQ.",
                    notes: nil,
                    ingredients: [
                        "Salsa BBQ"
                    ],
                    price: 1.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "papas-fritas",
                    categoryId: extrasCategory.id,
                    name: "Papas fritas",
                    description: "Porción extra de papas fritas.",
                    notes: nil,
                    ingredients: [
                        "Papas fritas"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                )
            ]
        ),

        MenuSection(
            id: postresCategory.id,
            category: postresCategory,
            items: [
                MenuItem(
                    id: "fresas-con-crema",
                    categoryId: postresCategory.id,
                    name: "Fresas con crema",
                    description: "Postre fresco y cremoso.",
                    notes: nil,
                    ingredients: [
                        "Fresas",
                        "Crema"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "helados-de-crema",
                    categoryId: postresCategory.id,
                    name: "Helados de crema",
                    description: "Postre clásico y refrescante.",
                    notes: nil,
                    ingredients: [
                        "Helado de crema"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cheesecake-limon",
                    categoryId: postresCategory.id,
                    name: "Cheesecake de limón",
                    description: "Cheesecake cremoso sabor limón.",
                    notes: nil,
                    ingredients: [
                        "Queso crema",
                        "Limón",
                        "Base de galleta"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cheesecake-maracuya",
                    categoryId: postresCategory.id,
                    name: "Cheesecake de maracuyá",
                    description: "Cheesecake cremoso sabor maracuyá.",
                    notes: nil,
                    ingredients: [
                        "Queso crema",
                        "Maracuyá",
                        "Base de galleta"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cheesecake-arandano",
                    categoryId: postresCategory.id,
                    name: "Cheesecake de arándano",
                    description: "Cheesecake cremoso sabor arándano.",
                    notes: nil,
                    ingredients: [
                        "Queso crema",
                        "Arándano",
                        "Base de galleta"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                )
            ]
        ),

        MenuSection(
            id: bebidasCategory.id,
            category: bebidasCategory,
            items: [
                MenuItem(
                    id: "jugo-natural-personal",
                    categoryId: bebidasCategory.id,
                    name: "Jugo natural - Personal",
                    description: "Jugo refrescante preparado al momento.",
                    notes: nil,
                    ingredients: [
                        "Fruta natural",
                        "Agua",
                        "Azúcar"
                    ],
                    price: 1.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "jugo-natural-jarra",
                    categoryId: bebidasCategory.id,
                    name: "Jugo natural - Jarra",
                    description: "Jugo natural ideal para compartir.",
                    notes: nil,
                    ingredients: [
                        "Fruta natural",
                        "Agua",
                        "Azúcar"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                ),
                MenuItem(
                    id: "jarra-de-chicha",
                    categoryId: bebidasCategory.id,
                    name: "Jarra de chicha",
                    description: "Bebida de jora, panela y hierbas.",
                    notes: nil,
                    ingredients: [
                        "Jora",
                        "Panela",
                        "Hierbas"
                    ],
                    price: 3.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cola-500ml",
                    categoryId: bebidasCategory.id,
                    name: "Cola personal",
                    description: "Bebida gaseosa personal.",
                    notes: nil,
                    ingredients: [
                        "Cola"
                    ],
                    price: 0.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cola-125l",
                    categoryId: bebidasCategory.id,
                    name: "Cola 1.25 L",
                    description: "Bebida gaseosa para compartir.",
                    notes: nil,
                    ingredients: [
                        "Cola"
                    ],
                    price: 1.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "agua",
                    categoryId: bebidasCategory.id,
                    name: "Agua",
                    description: "Agua embotellada sin gas.",
                    notes: nil,
                    ingredients: [
                        "Agua"
                    ],
                    price: 1.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "agua-mineral",
                    categoryId: bebidasCategory.id,
                    name: "Agua mineral",
                    description: "Agua mineral refrescante.",
                    notes: nil,
                    ingredients: [
                        "Agua mineral"
                    ],
                    price: 1.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cafe-sweet-and-coffee",
                    categoryId: bebidasCategory.id,
                    name: "Café Sweet And Coffee",
                    description: "Café caliente para acompañar postres o una buena conversación.",
                    notes: nil,
                    ingredients: [
                        "Café"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "te-twinings",
                    categoryId: bebidasCategory.id,
                    name: "Té Twinings",
                    description: "Té caliente y aromático.",
                    notes: nil,
                    ingredients: [
                        "Té Twinings"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                )
            ]
        ),

        MenuSection(
            id: bebidasAlcoholicasCategory.id,
            category: bebidasAlcoholicasCategory,
            items: [
                MenuItem(
                    id: "cerveza-club-pequena",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Cerveza Club pequeña",
                    description: "Cerveza Club pequeña bien fría.",
                    notes: nil,
                    ingredients: [
                        "Cerveza Club"
                    ],
                    price: 1.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cerveza-club-mediana",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Cerveza Club mediana",
                    description: "Cerveza Club mediana bien fría.",
                    notes: nil,
                    ingredients: [
                        "Cerveza Club"
                    ],
                    price: 2.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cerveza-club-grande",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Cerveza Club grande",
                    description: "Cerveza Club grande bien fría.",
                    notes: nil,
                    ingredients: [
                        "Cerveza Club"
                    ],
                    price: 3.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cerveza-coronita",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Cerveza Coronita",
                    description: "Cerveza Coronita bien fría.",
                    notes: nil,
                    ingredients: [
                        "Cerveza Coronita"
                    ],
                    price: 2.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cerveza-corona",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Cerveza Corona",
                    description: "Cerveza Corona bien fría.",
                    notes: nil,
                    ingredients: [
                        "Cerveza Corona"
                    ],
                    price: 3.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "cerveza-modelo",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Cerveza Modelo",
                    description: "Cerveza Modelo bien fría.",
                    notes: nil,
                    ingredients: [
                        "Cerveza Modelo"
                    ],
                    price: 3.50,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: false
                ),
                MenuItem(
                    id: "vino-artesanal",
                    categoryId: bebidasAlcoholicasCategory.id,
                    name: "Vino artesanal",
                    description: "Vino artesanal de mortiño, mora y uva.",
                    notes: nil,
                    ingredients: [
                        "Mortiño",
                        "Mora",
                        "Uva"
                    ],
                    price: 20.00,
                    offerPrice: nil,
                    imageURL: nil,
                    isAvailable: true,
                    isFeatured: true
                )
            ]
        )
    ]
}

