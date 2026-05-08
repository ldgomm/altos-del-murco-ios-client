//
//  AltosSeasonalTheme.swift
//  Altos del Murco
//
//  Created by José Ruiz on 7/5/26.
//

import SwiftUI

// MARK: - Seasonal Theme Model

enum AltosSeasonalTheme: String, CaseIterable, Identifiable, Hashable {
    case newYear
    case diablada
    case reyes
    case carnival
    case valentinesDay
    case flowersFruits
    case pawkarRaymi
    case easterWeek
    case kasama
    case chirimoya
    case mothersDay
    case pichincha
    case corpusChristi
    case fathersDay
    case intiRaymi
    case sanPedro
    case chagrasMachachi
    case guayaquilJuly
    case augustIndependence
    case virgenDelCisne
    case yamor
    case guayaquilOctober
    case rodeoMontuvio
    case halloween
    case difuntos
    case cuencaIndependence
    case mamaNegra
    case quito
    case christmas
    case newYearsEve
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .newYear: return "Año Nuevo"
        case .diablada: return "Diablada de Píllaro"
        case .reyes: return "Día de Reyes"
        case .carnival: return "Carnaval"
        case .valentinesDay: return "San Valentín"
        case .flowersFruits: return "Flores y Frutas"
        case .pawkarRaymi: return "Pawkar Raymi"
        case .easterWeek: return "Semana Santa"
        case .kasama: return "Kasama Tsáchila"
        case .chirimoya: return "Festival de la Chirimoya"
        case .mothersDay: return "Día de Mamá"
        case .pichincha: return "24 de Mayo"
        case .corpusChristi: return "Corpus Christi"
        case .fathersDay: return "Día de Papá"
        case .intiRaymi: return "Inti Raymi"
        case .sanPedro: return "San Pedro"
        case .chagrasMachachi: return "Chagras de Machachi"
        case .guayaquilJuly: return "Fiestas Julianas"
        case .augustIndependence: return "10 de Agosto"
        case .virgenDelCisne: return "Virgen del Cisne"
        case .yamor: return "Fiesta del Yamor"
        case .guayaquilOctober: return "Guayaquil"
        case .rodeoMontuvio: return "Rodeo Montuvio"
        case .halloween: return "Halloween"
        case .difuntos: return "Difuntos"
        case .cuencaIndependence: return "Independencia de Cuenca"
        case .mamaNegra: return "Mama Negra"
        case .quito: return "Fiestas de Quito"
        case .christmas: return "Navidad"
        case .newYearsEve: return "Año Viejo"
        }
    }
    
    var badgeSystemImage: String {
        switch self {
        case .newYear: return "sparkles"
        case .diablada: return "theatermasks.fill"
        case .reyes: return "crown.fill"
        case .carnival: return "party.popper.fill"
        case .valentinesDay: return "heart.circle.fill"
        case .flowersFruits: return "camera.macro"
        case .pawkarRaymi: return "leaf.fill"
        case .easterWeek: return "fork.knife.circle.fill"
        case .kasama: return "figure.wave"
        case .chirimoya: return "leaf.circle.fill"
        case .mothersDay: return "heart.fill"
        case .pichincha: return "flag.fill"
        case .corpusChristi: return "seal.fill"
        case .fathersDay: return "person.2.fill"
        case .intiRaymi: return "sun.max.fill"
        case .sanPedro: return "music.note.list"
        case .chagrasMachachi: return "figure.equestrian.sports"
        case .guayaquilJuly: return "sailboat.fill"
        case .augustIndependence: return "flag.circle.fill"
        case .virgenDelCisne: return "bird.fill"
        case .yamor: return "drop.fill"
        case .guayaquilOctober: return "flag.2.crossed.fill"
        case .rodeoMontuvio: return "figure.equestrian.sports"
        case .halloween: return "moon.stars.fill"
        case .difuntos: return "cup.and.saucer.fill"
        case .cuencaIndependence: return "building.2.fill"
        case .mamaNegra: return "theatermasks.circle.fill"
        case .quito: return "building.columns.fill"
        case .christmas: return "gift.fill"
        case .newYearsEve: return "sparkles.rectangle.stack.fill"
        }
    }
    
    var particleSymbols: [String] {
        switch self {
        case .newYear:
            return ["sparkles", "star.fill", "party.popper.fill"]
            
        case .diablada:
            return ["theatermasks.fill", "flame.fill", "sparkles"]
            
        case .reyes:
            return ["crown.fill", "star.fill", "gift.fill"]
            
        case .carnival:
            return ["party.popper.fill", "paintpalette.fill", "sparkles"]
            
        case .valentinesDay:
            return ["heart.fill", "camera.macro", "gift.fill"]
            
        case .flowersFruits:
            return ["camera.macro", "leaf.fill", "sun.max.fill"]
            
        case .pawkarRaymi:
            return ["leaf.fill", "camera.macro", "sun.max.fill"]
            
        case .easterWeek:
            return ["fork.knife.circle.fill", "leaf.fill", "sun.haze.fill"]
            
        case .kasama:
            return ["figure.wave", "leaf.fill", "flame.fill"]
            
        case .chirimoya:
            return ["leaf.circle.fill", "leaf.fill", "sun.max.fill"]
            
        case .mothersDay:
            return ["heart.fill", "camera.macro", "gift.fill"]
            
        case .pichincha:
            return ["flag.fill", "mountain.2.fill", "star.fill"]
            
        case .corpusChristi:
            return ["seal.fill", "sparkles", "sun.max.fill"]
            
        case .fathersDay:
            return ["person.2.fill", "heart.fill", "star.fill"]
            
        case .intiRaymi:
            return ["sun.max.fill", "leaf.fill", "flame.fill"]
            
        case .sanPedro:
            return ["music.note.list", "sun.max.fill", "figure.walk.motion"]
            
        case .chagrasMachachi:
            return ["figure.equestrian.sports", "mountain.2.fill", "flame.fill"]
            
        case .guayaquilJuly:
            return ["sailboat.fill", "flag.fill", "sun.max.fill"]
            
        case .augustIndependence:
            return ["flag.circle.fill", "star.fill", "mountain.2.fill"]
            
        case .virgenDelCisne:
            return ["bird.fill", "star.fill", "leaf.fill"]
            
        case .yamor:
            return ["leaf.fill", "drop.fill", "sun.max.fill"]
            
        case .guayaquilOctober:
            return ["flag.2.crossed.fill", "star.fill", "sun.max.fill"]
            
        case .rodeoMontuvio:
            return ["figure.equestrian.sports", "flame.fill", "star.fill"]
            
        case .halloween:
            return ["moon.stars.fill", "eye.fill", "sparkles"]
            
        case .difuntos:
            return ["cup.and.saucer.fill", "leaf.fill", "flame.fill"]
            
        case .cuencaIndependence:
            return ["building.2.fill", "flag.fill", "star.fill"]
            
        case .mamaNegra:
            return ["theatermasks.circle.fill", "flame.fill", "sparkles"]
            
        case .quito:
            return ["building.columns.fill", "car.fill", "star.fill"]
            
        case .christmas:
            return ["gift.fill", "bell.fill", "star.fill"]
            
        case .newYearsEve:
            return ["sparkles", "flame.fill", "party.popper.fill"]
        }
    }
    
    var particleCount: Int {
        switch self {
        case .newYear: return 8
        case .diablada: return 7
        case .reyes: return 6
        case .carnival: return 10
        case .valentinesDay: return 10
        case .flowersFruits: return 10
        case .pawkarRaymi: return 7
        case .easterWeek: return 6
        case .kasama: return 7
        case .chirimoya: return 6
        case .mothersDay: return 9
        case .pichincha: return 6
        case .corpusChristi: return 6
        case .fathersDay: return 7
        case .intiRaymi: return 8
        case .sanPedro: return 7
        case .chagrasMachachi: return 7
        case .guayaquilJuly: return 7
        case .augustIndependence: return 7
        case .virgenDelCisne: return 6
        case .yamor: return 7
        case .guayaquilOctober: return 7
        case .rodeoMontuvio: return 7
        case .halloween: return 7
        case .difuntos: return 6
        case .cuencaIndependence: return 6
        case .mamaNegra: return 8
        case .quito: return 7
        case .christmas: return 9
        case .newYearsEve: return 10
        }
    }
    
    var motionStyle: SeasonalMotionStyle {
        switch self {
        case .newYear: return .burst
        case .diablada: return .fall
        case .reyes: return .orbit
        case .carnival: return .burst
        case .valentinesDay: return .bloom
        case .flowersFruits: return .bloom
        case .pawkarRaymi: return .orbit
        case .easterWeek: return .fall
        case .kasama: return .wind
        case .chirimoya: return .orbit
        case .mothersDay: return .bloom
        case .pichincha: return .fall
        case .corpusChristi: return .orbit
        case .fathersDay: return .fall
        case .intiRaymi: return .orbit
        case .sanPedro: return .wind
        case .chagrasMachachi: return .wind
        case .guayaquilJuly: return .wind
        case .augustIndependence: return .burst
        case .virgenDelCisne: return .fall
        case .yamor: return .orbit
        case .guayaquilOctober: return .wind
        case .rodeoMontuvio: return .wind
        case .halloween: return .fall
        case .difuntos: return .fall
        case .cuencaIndependence: return .burst
        case .mamaNegra: return .burst
        case .quito: return .wind
        case .christmas: return .fall
        case .newYearsEve: return .burst
        }
    }
    
    func colors(for scheme: ColorScheme) -> [Color] {
        let darkBoost: Double = scheme == .dark ? 1.0 : 0.86
        
        func c(_ hex: UInt, alpha: Double = 1.0) -> Color {
            Color(UIColor(hex: hex)).opacity(alpha * darkBoost)
        }
        
        switch self {
        case .newYear:
            return [c(0xF7D774), c(0xFFFFFF, alpha: 0.86), c(0x74C0FC), c(0xB197FC)]
        case .diablada:
            return [c(0xE03131), c(0xF59F00), c(0x212529, alpha: 0.75), c(0xFFFFFF, alpha: 0.82)]
        case .reyes:
            return [c(0xFFD43B), c(0xFFFFFF, alpha: 0.84), c(0xB197FC), c(0x4DABF7)]
        case .carnival:
            return [c(0xF783AC), c(0x4DABF7), c(0x69DB7C), c(0xFFD43B), c(0xB197FC)]
        case .valentinesDay:
            return [c(0xFF4D8D), c(0xFFB3C7), c(0xF783AC), c(0xE64980), c(0xFFF0F6), c(0xC2255C)]
        case .flowersFruits:
            return [c(0xF783AC), c(0xFFDEEB), c(0xFF922B), c(0x82C91E), c(0xFFD43B)]
        case .pawkarRaymi:
            return [c(0x69DB7C), c(0xFFD43B), c(0xFF922B), c(0x38D9A9)]
        case .easterWeek:
            return [c(0x9775FA), c(0xFFD43B), c(0x8CE99A), c(0xFFFFFF, alpha: 0.75), c(0xA16207, alpha: 0.70)]
        case .kasama:
            return [c(0x2F9E44), c(0xFFD43B), c(0x7950F2), c(0xFF922B)]
        case .chirimoya:
            return [c(0x82C91E), c(0xFFFFFF, alpha: 0.82), c(0xFFD43B), c(0x38D9A9)]
        case .mothersDay:
            return [c(0xF06595), c(0xFCC2D7), c(0xFF8787), c(0xB197FC)]
        case .pichincha:
            return [c(0xFFD43B), c(0x4DABF7), c(0xFF6B6B), c(0xFFFFFF, alpha: 0.8)]
        case .corpusChristi:
            return [c(0x7950F2), c(0xFFD43B), c(0xFFFFFF, alpha: 0.82), c(0xFF922B)]
        case .fathersDay:
            return [c(0x4DABF7), c(0x74C0FC), c(0xFFD43B), c(0xADB5BD)]
        case .intiRaymi:
            return [c(0xFFD43B), c(0xFF922B), c(0xF76707), c(0x69DB7C)]
        case .sanPedro:
            return [c(0xFFD43B), c(0xE67700), c(0x7950F2), c(0x2F9E44)]
        case .chagrasMachachi:
            return [c(0xA16207), c(0xD9480F), c(0x2B8A3E), c(0xFFFFFF, alpha: 0.76)]
        case .guayaquilJuly:
            return [c(0x4DABF7), c(0xFFFFFF, alpha: 0.88), c(0xFFD43B), c(0x228BE6)]
        case .augustIndependence:
            return [c(0xFFD43B), c(0x228BE6), c(0xFA5252), c(0xFFFFFF, alpha: 0.78)]
        case .virgenDelCisne:
            return [c(0x74C0FC), c(0xFFFFFF, alpha: 0.86), c(0xFFD43B), c(0xB197FC)]
        case .yamor:
            return [c(0xFFD43B), c(0x82C91E), c(0xFF922B), c(0x7950F2)]
        case .guayaquilOctober:
            return [c(0x228BE6), c(0xFFFFFF, alpha: 0.88), c(0xFFD43B), c(0x4DABF7)]
        case .rodeoMontuvio:
            return [c(0xD9480F), c(0xF59F00), c(0xA16207), c(0xFFFFFF, alpha: 0.72)]
        case .halloween:
            return [c(0xF76707), c(0x845EF7), c(0x212529), c(0xFFD43B)]
        case .difuntos:
            return [c(0x862E9C), c(0xF783AC), c(0xFF922B), c(0x8CE99A)]
        case .cuencaIndependence:
            return [c(0xC92A2A), c(0xFFD43B), c(0x228BE6), c(0xFFFFFF, alpha: 0.82)]
        case .mamaNegra:
            return [c(0xE03131), c(0xF59F00), c(0x7950F2), c(0x212529, alpha: 0.85)]
        case .quito:
            return [c(0xC92A2A), c(0x228BE6), c(0xFFD43B), c(0xFFFFFF, alpha: 0.82)]
        case .christmas:
            return [c(0xE03131), c(0x2F9E44), c(0xFFFFFF, alpha: 0.84), c(0x74C0FC), c(0xFFD43B)]
        case .newYearsEve:
            return [c(0xFFD43B), c(0xFF922B), c(0xE03131), c(0xFFFFFF, alpha: 0.8)]
        }
    }
}

enum SeasonalMotionStyle {
    case fall
    case wind
    case orbit
    case burst
    case bloom
}

// MARK: - Ecuador Date Resolver

enum EcuadorSeasonalCalendar {
    static let ecuadorTimeZone = TimeZone(identifier: "America/Guayaquil") ?? .current
    
    static func activeTheme(for date: Date = Date()) -> AltosSeasonalTheme? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "es_EC")
        calendar.timeZone = ecuadorTimeZone
        
        let localDate = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: localDate)
        
        func range(_ startMonth: Int, _ startDay: Int, _ endMonth: Int, _ endDay: Int) -> Bool {
            guard let start = makeDate(year: year, month: startMonth, day: startDay, calendar: calendar),
                  let end = makeDate(year: year, month: endMonth, day: endDay, calendar: calendar) else {
                return false
            }
            return localDate >= start && localDate <= end
        }
        
        func rangeAround(_ center: Date, before: Int = 7, after: Int = 1) -> Bool {
            guard let start = calendar.date(byAdding: .day, value: -before, to: center),
                  let end = calendar.date(byAdding: .day, value: after, to: center) else {
                return false
            }
            return localDate >= calendar.startOfDay(for: start) && localDate <= calendar.startOfDay(for: end)
        }
        
        func fixedCenter(month: Int, day: Int) -> Date? {
            makeDate(year: year, month: month, day: day, calendar: calendar)
        }
        
        let easter = easterSunday(year: year, calendar: calendar)
        let carnivalTuesday = calendar.date(byAdding: .day, value: -47, to: easter) ?? easter
        let corpusChristi = calendar.date(byAdding: .day, value: 60, to: easter) ?? easter
        
        // Highest-priority campaigns first. Close Ecuadorian dates intentionally use shorter windows.
        if range(12, 27, 12, 31) { return .newYearsEve }
        if let christmas = fixedCenter(month: 12, day: 25), rangeAround(christmas, before: 7, after: 1) { return .christmas }
        if let quito = fixedCenter(month: 12, day: 6), rangeAround(quito, before: 7, after: 1) { return .quito }
        if let mamaNegra = fixedCenter(month: 11, day: 11), rangeAround(mamaNegra, before: 6, after: 1) { return .mamaNegra }
        if range(11, 3, 11, 4) { return .cuencaIndependence }
        if range(11, 1, 11, 3) { return .difuntos }
        if range(10, 27, 10, 31) { return .halloween }
        if let rodeo = fixedCenter(month: 10, day: 12), rangeAround(rodeo, before: 1, after: 1) { return .rodeoMontuvio }
        if let guayaquilOctober = fixedCenter(month: 10, day: 9), rangeAround(guayaquilOctober, before: 7, after: 1) { return .guayaquilOctober }
        if let yamor = fixedCenter(month: 9, day: 8), rangeAround(yamor, before: 7, after: 1) { return .yamor }
        if let virgenDelCisne = fixedCenter(month: 8, day: 15), rangeAround(virgenDelCisne, before: 3, after: 1) { return .virgenDelCisne }
        if let augustIndependence = fixedCenter(month: 8, day: 10), rangeAround(augustIndependence, before: 7, after: 1) { return .augustIndependence }
        if let chagras = nthWeekday(year: year, month: 7, weekday: 7, nth: 3, calendar: calendar), rangeAround(chagras, before: 7, after: 1) { return .chagrasMachachi }
        if let guayaquilJuly = fixedCenter(month: 7, day: 25), rangeAround(guayaquilJuly, before: 4, after: 1) { return .guayaquilJuly }
        if let sanPedro = fixedCenter(month: 6, day: 29), rangeAround(sanPedro, before: 6, after: 1) { return .sanPedro }
        if let intiRaymi = fixedCenter(month: 6, day: 21), rangeAround(intiRaymi, before: 7, after: 1) { return .intiRaymi }
        if let fathersDay = nthWeekday(year: year, month: 6, weekday: 1, nth: 3, calendar: calendar), rangeAround(fathersDay, before: 3, after: 1) { return .fathersDay }
        if rangeAround(corpusChristi, before: 7, after: 1) { return .corpusChristi }
        if let pichincha = fixedCenter(month: 5, day: 24), rangeAround(pichincha, before: 7, after: 1) { return .pichincha }
        if let mothersDay = nthWeekday(year: year, month: 5, weekday: 1, nth: 2, calendar: calendar), rangeAround(mothersDay, before: 7, after: 1) { return .mothersDay }
        if let chirimoya = fixedCenter(month: 5, day: 3), rangeAround(chirimoya, before: 7, after: 1) { return .chirimoya }
        if let kasama = fixedCenter(month: 4, day: 14), rangeAround(kasama, before: 7, after: 1) { return .kasama }
        if rangeAround(easter, before: 7, after: 1) { return .easterWeek }
        if let pawkar = fixedCenter(month: 3, day: 21), rangeAround(pawkar, before: 7, after: 1) { return .pawkarRaymi }
        if rangeAround(carnivalTuesday, before: 4, after: 1) { return .flowersFruits }
        if rangeAround(carnivalTuesday, before: 7, after: -5) { return .carnival }
        if let valentines = fixedCenter(month: 2, day: 14), rangeAround(valentines, before: 7, after: 1) { return .valentinesDay }
        if let reyes = fixedCenter(month: 1, day: 6), rangeAround(reyes, before: 0, after: 1) { return .reyes }
        if range(1, 3, 1, 5) { return .diablada }
        if range(1, 1, 1, 2) { return .newYear }
        
        return nil
    }
    
    private static func makeDate(
        year: Int,
        month: Int,
        day: Int,
        calendar: Calendar
    ) -> Date? {
        calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: year, month: month, day: day))
    }
    
    private static func nthWeekday(
        year: Int,
        month: Int,
        weekday: Int,
        nth: Int,
        calendar: Calendar
    ) -> Date? {
        guard let firstOfMonth = makeDate(year: year, month: month, day: 1, calendar: calendar) else {
            return nil
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let offset = (weekday - firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: offset + ((nth - 1) * 7), to: firstOfMonth)
    }
    
    // Gregorian computus. Good for the app's recurring campaign windows.
    private static func easterSunday(year: Int, calendar: Calendar) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let rawMonth = (h + l - 7 * m + 114) / 31
        let rawDay = ((h + l - 7 * m + 114) % 31) + 1
        
        return makeDate(year: year, month: rawMonth, day: rawDay, calendar: calendar) ?? Date()
    }
}

// MARK: - Animated Background

struct SeasonalAnimatedCardBackdrop: View {
    let seasonalTheme: AltosSeasonalTheme?
    let cornerRadius: CGFloat
    var intensity: Double = 1
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        GeometryReader { proxy in
            if let seasonalTheme {
                ZStack {
                    seasonalWash(theme: seasonalTheme)
                    
                    if reduceMotion {
                        staticWatermark(theme: seasonalTheme, in: proxy.size)
                    } else {
                        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                            animatedParticles(
                                theme: seasonalTheme,
                                time: timeline.date.timeIntervalSinceReferenceDate,
                                size: proxy.size
                            )
                        }
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
    
    private func seasonalWash(theme: AltosSeasonalTheme) -> some View {
        let colors = theme.colors(for: colorScheme)
        return ZStack {
            LinearGradient(
                colors: [
                    colors[safe: 0]?.opacity(0.13 * intensity) ?? .clear,
                    colors[safe: 1]?.opacity(0.10 * intensity) ?? .clear,
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            RadialGradient(
                colors: [
                    colors[safe: 2]?.opacity(0.18 * intensity) ?? .clear,
                    .clear
                ],
                center: .topTrailing,
                startRadius: 8,
                endRadius: 280
            )
        }
    }
    
    private func staticWatermark(theme: AltosSeasonalTheme, in size: CGSize) -> some View {
        let colors = theme.colors(for: colorScheme)
        return ZStack {
            Image(systemName: theme.badgeSystemImage)
                .font(.system(size: max(80, min(size.width, size.height) * 0.72), weight: .black, design: .rounded))
                .foregroundStyle((colors.first ?? .white).opacity(0.08))
                .rotationEffect(.degrees(-10))
                .position(x: size.width * 0.82, y: size.height * 0.20)
        }
    }
    
    private func animatedParticles(
        theme: AltosSeasonalTheme,
        time: TimeInterval,
        size: CGSize
    ) -> some View {
        ZStack {
            staticWatermark(theme: theme, in: size)
            
            ForEach(0..<theme.particleCount, id: \.self) { index in
                let particle = SeasonalParticle(index: index, theme: theme)
                let progress = particle.progress(at: time)
                let position = particle.position(progress: progress, in: size, style: theme.motionStyle)
                let colors = theme.colors(for: colorScheme)
                let symbol = theme.particleSymbols[index % theme.particleSymbols.count]
                let color = colors[index % colors.count]
                
                Image(systemName: symbol)
                    .font(.system(size: particle.size, weight: .bold, design: .rounded))
                    .foregroundStyle(color.opacity(particle.opacity))
                    .shadow(color: color.opacity(0.18), radius: 10, x: 0, y: 0)
                    .rotationEffect(.degrees(particle.rotation(progress: progress, style: theme.motionStyle)))
                    .scaleEffect(particle.scale(progress: progress, style: theme.motionStyle))
                    .position(position)
                    .blendMode(colorScheme == .dark ? .screen : .plusLighter)
            }
        }
    }
}

private struct SeasonalParticle {
    let index: Int
    let baseX: Double
    let baseY: Double
    let offset: Double
    let duration: Double
    let drift: Double
    let phase: Double
    let size: CGFloat
    let opacity: Double
    
    init(index: Int, theme: AltosSeasonalTheme) {
        self.index = index
        self.baseX = Self.random(index * 31 + 1, min: 0.04, max: 0.96)
        self.baseY = Self.random(index * 37 + 3, min: 0.08, max: 0.92)
        self.offset = Self.random(index * 41 + 5, min: 0.0, max: 1.0)
        self.duration = Self.random(index * 43 + 7, min: theme.motionStyle == .burst ? 5.2 : 8.0, max: theme.motionStyle == .burst ? 9.0 : 15.0)
        self.drift = Self.random(index * 47 + 11, min: 16.0, max: 88.0)
        self.phase = Self.random(index * 53 + 13, min: 0.0, max: .pi * 2)
        self.size = CGFloat(Self.random(index * 59 + 17, min: 10.0, max: theme.motionStyle == .burst || theme.motionStyle == .bloom ? 30.0 : 24.0))
        self.opacity = Self.random(index * 61 + 19, min: 0.20, max: 0.52)
    }
    
    func progress(at time: TimeInterval) -> Double {
        let value = (time / duration + offset).truncatingRemainder(dividingBy: 1)
        return value < 0 ? value + 1 : value
    }
    
    func position(progress: Double, in size: CGSize, style: SeasonalMotionStyle) -> CGPoint {
        let width = max(1, size.width)
        let height = max(1, size.height)
        
        switch style {
        case .fall:
            let x = width * baseX + sin(progress * .pi * 2 + phase) * drift
            let y = -36 + (height + 72) * progress
            return CGPoint(x: x, y: y)
            
        case .wind:
            let x = -40 + (width + 80) * progress
            let y = height * baseY + sin(progress * .pi * 2 + phase) * drift * 0.42
            return CGPoint(x: x, y: y)
            
        case .orbit:
            let centerX = width * baseX
            let centerY = height * baseY
            let radius = drift * 0.55
            let angle = progress * .pi * 2 + phase
            return CGPoint(x: centerX + cos(angle) * radius, y: centerY + sin(angle) * radius)
            
        case .burst:
            let originX = width * 0.50
            let originY = height * 0.45
            let angle = baseX * .pi * 2
            let distance = (0.16 + progress) * min(width, height) * 0.92
            return CGPoint(
                x: originX + cos(angle + phase * 0.15) * distance,
                y: originY + sin(angle + phase * 0.15) * distance
            )
            
        case .bloom:
            let centerX = width * (0.18 + baseX * 0.64)
            let centerY = height * (0.18 + baseY * 0.64)
            let petalRadius = drift * (0.18 + progress * 0.58)
            let angle = progress * .pi * 2 + phase
            let floatY = sin(progress * .pi + phase) * 14 - progress * 18
            return CGPoint(
                x: centerX + cos(angle) * petalRadius + sin(progress * .pi * 4 + phase) * 8,
                y: centerY + sin(angle) * petalRadius + floatY
            )
        }
    }
    
    func rotation(progress: Double, style: SeasonalMotionStyle) -> Double {
        switch style {
        case .orbit: return progress * 120 + phase * 12
        case .burst: return progress * 280
        case .wind: return sin(progress * .pi * 2 + phase) * 24
        case .fall: return progress * 160 + phase * 8
        case .bloom: return sin(progress * .pi * 2 + phase) * 32 + progress * 90
        }
    }
    
    func scale(progress: Double, style: SeasonalMotionStyle) -> Double {
        switch style {
        case .burst:
            return 0.72 + sin(progress * .pi) * 0.42
        case .bloom:
            return 0.74 + sin(progress * .pi) * 0.36
        case .fall:
            return 0.86 + sin(progress * .pi * 2 + phase) * 0.14
        case .wind:
            return 0.86 + sin(progress * .pi * 2 + phase) * 0.14
        case .orbit:
            return 0.86 + sin(progress * .pi * 2 + phase) * 0.14
        }
    }
    
    private static func random(_ seed: Int, min: Double, max: Double) -> Double {
        let raw = sin(Double(seed) * 12.9898) * 43758.5453
        let normalized = raw - floor(raw)
        return min + normalized * (max - min)
    }
}

// MARK: - Seasonal Copy

extension AltosSeasonalTheme {
    var shortPromise: String {
        switch self {
        case .newYear: return "Año nuevo, aire libre y nuevos planes"
        case .diablada: return "Máscaras, fuego y tradición popular"
        case .reyes: return "Rosca, familia y últimos brillos navideños"
        case .carnival: return "Carnaval, color y antojos serranos"
        case .valentinesDay: return "Flores, corazones y planes para dos"
        case .flowersFruits: return "Ambato florece con frutas, flores y pan"
        case .pawkarRaymi: return "Florecimiento, agua y nuevos ciclos"
        case .easterWeek: return "Fanesca, calma y tradición familiar"
        case .kasama: return "Año nuevo Tsáchila, danza y raíces"
        case .chirimoya: return "Sabores de fruta, campo y feria"
        case .mothersDay: return "Un detalle bonito para mamá"
        case .pichincha: return "Historia, bandera y orgullo nacional"
        case .corpusChristi: return "Dulces, fe y fiesta patrimonial"
        case .fathersDay: return "Un plan para celebrar a papá"
        case .intiRaymi: return "Sol, cosecha y montaña"
        case .sanPedro: return "Zapateo, plaza y música andina"
        case .chagrasMachachi: return "Caballos, ponchos y montaña chagra"
        case .guayaquilJuly: return "Puerto, río y orgullo guayaquileño"
        case .augustIndependence: return "Primer grito, patria y memoria"
        case .virgenDelCisne: return "Camino, devoción y encuentro familiar"
        case .yamor: return "Maíz, música y fiesta otavaleña"
        case .guayaquilOctober: return "Independencia, Malecón y tradición"
        case .rodeoMontuvio: return "Campo, destreza y cultura montuvia"
        case .halloween: return "Noche divertida, misterio y antojos"
        case .difuntos: return "Tradición, colada morada y memoria"
        case .cuencaIndependence: return "Arte, historia y orgullo cuencano"
        case .mamaNegra: return "Comparsas, música y color latacungueño"
        case .quito: return "Fiestas, canelazo y quiteñidad"
        case .christmas: return "Navidad con sabor de casa"
        case .newYearsEve: return "Despedimos el año en familia"
        }
    }
    
    func homeHeroTitle(firstName: String?) -> String {
        let greeting = firstName.map { "Hola, \($0)" } ?? "Bienvenido"
        switch self {
        case .newYear: return "\(greeting)\nEmpieza el año en Los Altos"
        case .diablada: return "\(greeting)\nTradición y montaña con carácter"
        case .reyes: return "\(greeting)\nUn último plan de temporada"
        case .carnival: return "\(greeting)\nCarnaval con sabor y aventura"
        case .valentinesDay: return "\(greeting)\nCelebra con amor en Los Altos"
        case .flowersFruits: return "\(greeting)\nFlores, frutas y sabores de fiesta"
        case .pawkarRaymi: return "\(greeting)\nFlorece una nueva salida"
        case .easterWeek: return "\(greeting)\nSemana Santa con sabor a fanesca"
        case .kasama: return "\(greeting)\nCelebra raíces y nuevos comienzos"
        case .chirimoya: return "\(greeting)\nUn plan fresco y dulce"
        case .mothersDay: return "\(greeting)\nMamá merece Los Altos"
        case .pichincha: return "\(greeting)\nCelebra Ecuador desde la montaña"
        case .corpusChristi: return "\(greeting)\nDulces, tradición y mesa familiar"
        case .fathersDay: return "\(greeting)\nPapá merece una aventura"
        case .intiRaymi: return "\(greeting)\nCelebra el sol y la montaña"
        case .sanPedro: return "\(greeting)\nSan Pedro suena a fiesta andina"
        case .chagrasMachachi: return "\(greeting)\nRuta chagra cerca de la montaña"
        case .guayaquilJuly: return "\(greeting)\nGuayaquil también se celebra aquí"
        case .augustIndependence: return "\(greeting)\nUn plan con orgullo patrio"
        case .virgenDelCisne: return "\(greeting)\nDevoción, camino y sabores de casa"
        case .yamor: return "\(greeting)\nYamor, maíz y alegría andina"
        case .guayaquilOctober: return "\(greeting)\nCelebra independencia con sabor"
        case .rodeoMontuvio: return "\(greeting)\nCampo, tradición y platos fuertes"
        case .halloween: return "\(greeting)\nUna escapada con misterio"
        case .difuntos: return "\(greeting)\nTradición que abraza"
        case .cuencaIndependence: return "\(greeting)\nCuenca celebra y Los Altos acompaña"
        case .mamaNegra: return "\(greeting)\nColor, comparsa y tradición"
        case .quito: return "\(greeting)\nFiestas, montaña y experiencias"
        case .christmas: return "\(greeting)\nNavidad sabe mejor en familia"
        case .newYearsEve: return "\(greeting)\nCierra el año en Los Altos"
        }
    }
    
    func adventureHeroTitle(firstName: String?) -> String {
        let greeting = firstName.map { "Hola, \($0)" } ?? "Bienvenido"
        switch self {
        case .newYear: return "\(greeting)\nEmpieza el año con una ruta"
        case .diablada: return "\(greeting)\nAventura con espíritu de fiesta"
        case .reyes: return "\(greeting)\nCierra la temporada con montaña"
        case .carnival: return "\(greeting)\nCarnaval con adrenalina y sabor"
        case .valentinesDay: return "\(greeting)\nUna aventura para compartir"
        case .flowersFruits: return "\(greeting)\nFlorece una aventura distinta"
        case .pawkarRaymi: return "\(greeting)\nFlorece una nueva aventura"
        case .easterWeek: return "\(greeting)\nEscápate con calma a la montaña"
        case .kasama: return "\(greeting)\nNuevo ciclo, aire libre y tradición"
        case .chirimoya: return "\(greeting)\nUn paseo dulce por la montaña"
        case .mothersDay: return "\(greeting)\nMamá también merece aventura"
        case .pichincha: return "\(greeting)\nHistoria y paisaje en una salida"
        case .corpusChristi: return "\(greeting)\nTradición, dulces y montaña"
        case .fathersDay: return "\(greeting)\nPapá merece ruta y parrilla"
        case .intiRaymi: return "\(greeting)\nCelebra el sol en la montaña"
        case .sanPedro: return "\(greeting)\nFiesta andina con ruta y sabor"
        case .chagrasMachachi: return "\(greeting)\nVive una salida con alma chagra"
        case .guayaquilJuly: return "\(greeting)\nUn plan brillante como el puerto"
        case .augustIndependence: return "\(greeting)\nAventura con orgullo de Ecuador"
        case .virgenDelCisne: return "\(greeting)\nCamino, calma y experiencia familiar"
        case .yamor: return "\(greeting)\nCelebra el maíz y la montaña"
        case .guayaquilOctober: return "\(greeting)\nIndependencia con aire libre"
        case .rodeoMontuvio: return "\(greeting)\nCampo, fuerza y experiencia premium"
        case .halloween: return "\(greeting)\nUna aventura con misterio"
        case .difuntos: return "\(greeting)\nTradición, paisaje y familia"
        case .cuencaIndependence: return "\(greeting)\nHistoria, arte y una escapada"
        case .mamaNegra: return "\(greeting)\nColor, cultura y montaña"
        case .quito: return "\(greeting)\nFiestas, montaña y experiencias"
        case .christmas: return "\(greeting)\nNavidad con aventura familiar"
        case .newYearsEve: return "\(greeting)\nCierra el año con una gran ruta"
        }
    }
    
    var homeHeroSubtitle: String {
        switch self {
        case .newYear:
            return "Arranca el año con comida rica, aire de montaña y una reserva fácil para volver con buena energía."
        case .diablada:
            return "Una temporada de máscaras, música y tradición popular para inspirar planes con carácter."
        case .reyes:
            return "Últimos días de ambiente navideño: comparte algo rico y reserva una escapada familiar."
        case .carnival:
            return "Color, música, comida serrana y experiencias para venir con amigos o familia."
        case .valentinesDay:
            return "Arma un plan con comida, flores visuales, corazones y experiencias para compartir sin complicarte."
        case .flowersFruits:
            return "Inspirado en Ambato: flores, frutas, pan, desfile y una mesa lista para celebrar con sabor."
        case .pawkarRaymi:
            return "La época del florecimiento pide aire libre, comida de casa y una visita para renovar energía."
        case .easterWeek:
            return "Fanesca, tradición y calma: reserva comida o una experiencia familiar para Semana Santa."
        case .kasama:
            return "Un guiño al nuevo año Tsáchila: raíces, color, danza y planes para salir de la rutina."
        case .chirimoya:
            return "Celebra sabores de fruta y campo con una visita fresca, tranquila y bien servida."
        case .mothersDay:
            return "Sorprende a mamá con comida rica, paisajes y un plan familiar completo."
        case .pichincha:
            return "Historia, bandera y orgullo ecuatoriano con comida, paisaje y actividades para compartir."
        case .corpusChristi:
            return "Dulces tradicionales, fe popular y un ambiente familiar para sentarse a compartir."
        case .fathersDay:
            return "Comida fuerte, aventura y un día distinto para celebrar a papá."
        case .intiRaymi:
            return "Sol, cosecha, montaña y experiencias para reconectar con lo nuestro."
        case .sanPedro:
            return "Música, zapateo y tradición andina para inspirar una salida con comida y paisaje."
        case .chagrasMachachi:
            return "Cerca de Machachi, la cultura chagra se siente mejor con montaña, ruta y parrilla."
        case .guayaquilJuly:
            return "Fiestas del puerto con energía alegre: celebra con comida, familia y una experiencia distinta."
        case .augustIndependence:
            return "Primer Grito de Independencia, orgullo nacional y planes para disfrutar Ecuador."
        case .virgenDelCisne:
            return "Una temporada de camino y devoción que invita a compartir con calma y buena mesa."
        case .yamor:
            return "Maíz, música y tradición otavaleña para un plan andino con sabor auténtico."
        case .guayaquilOctober:
            return "Independencia, alegría y orgullo guayaquileño con una mesa lista para celebrar."
        case .rodeoMontuvio:
            return "Campo, destreza y cultura montuvia para una experiencia con platos bien servidos."
        case .halloween:
            return "Una temporada divertida para venir por antojos, fotos y una escapada diferente."
        case .difuntos:
            return "Sabores tradicionales, familia y un momento tranquilo para recordar y compartir."
        case .cuencaIndependence:
            return "Arte, historia y celebración cuencana con sabores de casa y planes familiares."
        case .mamaNegra:
            return "Comparsas, color y tradición popular para encender la temporada con alegría."
        case .quito:
            return "Fiestas, canelazo simbólico, música y montaña para celebrar cerca de casa."
        case .christmas:
            return "Reserva comida, experiencias y combos para compartir con esa sensación de casa que no se improvisa."
        case .newYearsEve:
            return "Comida, aventura y últimos recuerdos del año con descuentos y reservas desde una sola cuenta."
        }
    }
    
    var adventureHeroSubtitle: String {
        switch self {
        case .newYear:
            return "Empieza con una ruta, fotos, comida y una reserva clara para que el primer plan salga redondo."
        case .diablada:
            return "Una experiencia con energía intensa: montaña, adrenalina y comida para cerrar la salida."
        case .reyes:
            return "Aprovecha los últimos días de temporada para una salida familiar sin complicarte."
        case .carnival:
            return "Combina cuadrones, paintball, go karts o camping con comida para venir con amigos y disfrutar sin improvisar."
        case .valentinesDay:
            return "Elige una ruta, añade comida y arma un plan para dos con corazones, flores y montaña sin complicarte."
        case .flowersFruits:
            return "Flores, frutas y pan inspiran una escapada colorida con fotos, comida y montaña."
        case .pawkarRaymi:
            return "Aprovecha la temporada del florecimiento: aire libre, comida serrana y experiencias para reconectar."
        case .easterWeek:
            return "Reserva una escapada tranquila, con horarios claros, fanesca de temporada y experiencias familiares."
        case .kasama:
            return "Dale la bienvenida a un ciclo nuevo con naturaleza, ruta y una comida compartida."
        case .chirimoya:
            return "Un plan suave, fresco y familiar para disfrutar aire libre antes de sentarse a comer."
        case .mothersDay:
            return "Prepara un día completo para mamá: paisaje, comida rica, fotos y una experiencia que se recuerde."
        case .pichincha:
            return "Celebra historia ecuatoriana con una ruta, paisaje de sierra y comida para compartir."
        case .corpusChristi:
            return "Una salida familiar con tradición, dulces, calma y experiencias al aire libre."
        case .fathersDay:
            return "Arma una salida con ruta, adrenalina y una buena comida para celebrar a papá como se merece."
        case .intiRaymi:
            return "Sol, cosecha y montaña: actividades al aire libre con el sabor de Los Altos al final del camino."
        case .sanPedro:
            return "Una temporada andina para salir, zapatear simbólicamente y cerrar con parrilla."
        case .chagrasMachachi:
            return "Caballos, ponchos y montaña inspiran una experiencia de campo premium cerca de Los Altos."
        case .guayaquilJuly:
            return "Trae el ánimo del puerto a la sierra: aventura, fotos y comida para celebrar."
        case .augustIndependence:
            return "Un feriado con orgullo ecuatoriano: reserva experiencia, comida y momentos al aire libre."
        case .virgenDelCisne:
            return "Una salida tranquila para compartir camino, paisaje y sabores familiares."
        case .yamor:
            return "Maíz, cosecha y montaña: experiencias al aire libre con sabor andino."
        case .guayaquilOctober:
            return "Independencia guayaquileña con ruta, comida y un plan para hacer algo distinto."
        case .rodeoMontuvio:
            return "Campo y destreza inspiran una visita con actividades fuertes y comida bien servida."
        case .halloween:
            return "Reserva una salida divertida, con misterio visual, fotos y antojos de temporada."
        case .difuntos:
            return "Una salida tranquila para compartir, recordar y disfrutar sabores tradicionales cerca de la montaña."
        case .cuencaIndependence:
            return "Arte, historia y aire libre para convertir el feriado en una experiencia memorable."
        case .mamaNegra:
            return "Color, comparsa y energía popular para una aventura familiar con sabor serrano."
        case .quito:
            return "Celebra las fiestas con montaña, comida y experiencias que se sienten cerca de casa."
        case .christmas:
            return "Trae a la familia, reserva una experiencia y acompáñala con comida de casa en ambiente navideño."
        case .newYearsEve:
            return "Cierra el año con una ruta, fotos, comida y una reserva lista antes de los abrazos de medianoche."
        }
    }
    
    var restaurantHeroTitle: String {
        switch self {
        case .newYear: return "Primer antojo del año"
        case .diablada: return "Sabores con carácter"
        case .reyes: return "Última mesa de temporada"
        case .carnival: return "Antojos de Carnaval"
        case .valentinesDay: return "Sabores para enamorar"
        case .flowersFruits: return "Mesa entre flores y frutas"
        case .pawkarRaymi: return "Sabores que florecen"
        case .easterWeek: return "Fanesca y tradición"
        case .kasama: return "Sabores de nuevo ciclo"
        case .chirimoya: return "Dulce temporada de fruta"
        case .mothersDay: return "Mamá elige primero"
        case .pichincha: return "Mesa con orgullo nacional"
        case .corpusChristi: return "Dulces y tradición"
        case .fathersDay: return "Para papá, bien servido"
        case .intiRaymi: return "Mesa del sol y la cosecha"
        case .sanPedro: return "Sabores para zapatear"
        case .chagrasMachachi: return "Mesa chagra de montaña"
        case .guayaquilJuly: return "Sabor a fiesta juliana"
        case .augustIndependence: return "Mesa del Primer Grito"
        case .virgenDelCisne: return "Sabores para compartir camino"
        case .yamor: return "Maíz, bebida y mesa andina"
        case .guayaquilOctober: return "Mesa guayaquileña de fiesta"
        case .rodeoMontuvio: return "Platos fuertes de campo"
        case .halloween: return "Antojos de misterio"
        case .difuntos: return "Tradición en la mesa"
        case .cuencaIndependence: return "Sabores de feriado cuencano"
        case .mamaNegra: return "Mesa de comparsa"
        case .quito: return "Antojos de fiestas quiteñas"
        case .christmas: return "Mesa navideña en Los Altos"
        case .newYearsEve: return "Último antojo del año"
        }
    }
    
    var restaurantHeroSubtitle: String {
        switch self {
        case .newYear:
            return "Empieza con algo bien servido: platos fuertes, bebidas y reservas sin complicarte."
        case .diablada:
            return "Una temporada intensa pide sabores con fuerza, parrilla y algo caliente para compartir."
        case .reyes:
            return "Cierra la temporada navideña con una mesa familiar y un último gusto antes de volver a la rutina."
        case .carnival:
            return "Platos serranos, bebidas y energía de feriado para venir con familia o amigos."
        case .valentinesDay:
            return "Platos para compartir, detalles románticos y un ambiente cálido para venir en pareja o familia."
        case .flowersFruits:
            return "Inspirado en Ambato: colores, fruta, pan y platos familiares para celebrar bonito."
        case .pawkarRaymi:
            return "Una temporada de florecimiento con sabores frescos, comida de casa y una mesa tranquila."
        case .easterWeek:
            return "Fanesca, sabores tradicionales y una mesa familiar para vivir Semana Santa con calma."
        case .kasama:
            return "Celebra nuevos comienzos con platos para compartir y un ambiente lleno de raíz ecuatoriana."
        case .chirimoya:
            return "Un guiño dulce y fresco para acompañar platos familiares, postres y bebidas."
        case .mothersDay:
            return "Platos para consentir a mamá, compartir en familia y evitar que ella cocine ese día."
        case .pichincha:
            return "Sabores ecuatorianos para celebrar historia, bandera y orgullo en la mesa."
        case .corpusChristi:
            return "Dulces, tradición popular y comida de casa para una salida familiar."
        case .fathersDay:
            return "Platos fuertes, porciones generosas y una mesa pensada para celebrar a papá."
        case .intiRaymi:
            return "Sol, cosecha y sabores andinos para compartir después de una buena salida."
        case .sanPedro:
            return "Música andina, tradición y platos con energía de fiesta para compartir."
        case .chagrasMachachi:
            return "Sabores de campo, parrilla y montaña para una visita con alma chagra."
        case .guayaquilJuly:
            return "Celebra las fiestas del puerto con comida familiar, bebidas y buen ambiente."
        case .augustIndependence:
            return "Una fecha patria con platos ecuatorianos y una mesa lista para el feriado."
        case .virgenDelCisne:
            return "Un momento de encuentro familiar con comida cálida y atención tranquila."
        case .yamor:
            return "Maíz, tradición y sabores andinos para una mesa de temporada."
        case .guayaquilOctober:
            return "Independencia, alegría y platos para compartir como feriado de costa en la sierra."
        case .rodeoMontuvio:
            return "Platos fuertes, sabor de campo y energía montuvia en una mesa familiar."
        case .halloween:
            return "Antojos, bebidas y una presentación divertida para una visita diferente."
        case .difuntos:
            return "Una fecha para sabores tradicionales, calma y conversación en familia."
        case .cuencaIndependence:
            return "Feriado, arte y sabores de casa para celebrar con una buena mesa."
        case .mamaNegra:
            return "Color, comparsa y platos serranos para una temporada alegre y familiar."
        case .quito:
            return "Fiestas quiteñas con platos calientes, parrilla y ambiente de celebración."
        case .christmas:
            return "Sabores de casa, parrilladas, bebidas y platos para compartir sin correr en cocina."
        case .newYearsEve:
            return "Cierra el año con algo rico antes de los monigotes, cábalas y abrazos."
        }
    }
}

// MARK: - Seasonal Card Modifier

struct SeasonalBrandCardModifier: ViewModifier {
    let theme: AppSectionTheme
    var emphasized: Bool = false
    var seasonalTheme: AltosSeasonalTheme? = EcuadorSeasonalCalendar.activeTheme()
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        let radius = AppTheme.Radius.xLarge
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        
        content
            .padding(AppTheme.Metrics.cardPadding)
            .background {
                ZStack {
                    shape.fill(palette.cardGradient)
                    
                    SeasonalAnimatedCardBackdrop(
                        seasonalTheme: seasonalTheme,
                        cornerRadius: radius,
                        intensity: theme == .neutral ? 0.72 : 1.0
                    )
                }
            }
            .overlay {
                shape.stroke(palette.stroke.opacity(seasonalTheme == nil ? 1 : 0.72), lineWidth: 1)
            }
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.26 : 0.12),
                radius: AppTheme.Metrics.shadowRadius,
                x: 0,
                y: AppTheme.Metrics.shadowY
            )
    }
}

struct SeasonalTinyBadge: View {
    let theme: AltosSeasonalTheme
    let palette: ThemePalette
    
    var body: some View {
        Label(theme.title, systemImage: theme.badgeSystemImage)
            .font(.caption2.weight(.black))
            .foregroundStyle(palette.onPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(palette.heroGradient, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: palette.glow.opacity(0.35), radius: 10, x: 0, y: 3)
    }
}

extension View {
    /// Use this for special image cards or custom cards that do not go through `.appCardStyle`.
    func seasonalCardOverlay(cornerRadius: CGFloat = AppTheme.Radius.xLarge) -> some View {
        overlay {
            SeasonalAnimatedCardBackdrop(
                seasonalTheme: EcuadorSeasonalCalendar.activeTheme(),
                cornerRadius: cornerRadius,
                intensity: 0.85
            )
        }
    }
    
    /// Safe manual version when you do not want to replace the existing `BrandCardModifier` yet.
    func appSeasonalCardStyle(_ theme: AppSectionTheme, emphasized: Bool = false) -> some View {
        modifier(SeasonalBrandCardModifier(theme: theme, emphasized: emphasized))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
