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
    case carnival
    case valentinesDay
    case pawkarRaymi
    case holyWeek
    case mothersDay
    case pichincha
    case fathersDay
    case intiRaymi
    case guayaquilJuly
    case augustIndependence
    case yamor
    case guayaquilOctober
    case rodeoMontuvio
    case halloween
    case difuntos
    case mamaNegra
    case quito
    case christmas
    case newYearsEve

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newYear: return "Año Nuevo"
        case .diablada: return "Diablada"
        case .carnival: return "Carnaval"
        case .valentinesDay: return "San Valentín"
        case .pawkarRaymi: return "Pawkar Raymi"
        case .holyWeek: return "Semana Santa"
        case .mothersDay: return "Día de Mamá"
        case .pichincha: return "24 de Mayo"
        case .fathersDay: return "Día de Papá"
        case .intiRaymi: return "Inti Raymi"
        case .guayaquilJuly: return "Fiestas Julianas"
        case .augustIndependence: return "10 de Agosto"
        case .yamor: return "Yamor"
        case .guayaquilOctober: return "Guayaquil"
        case .rodeoMontuvio: return "Rodeo Montuvio"
        case .halloween: return "Halloween"
        case .difuntos: return "Difuntos"
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
        case .carnival: return "party.popper.fill"
        case .valentinesDay: return "heart.circle.fill"
        case .pawkarRaymi: return "leaf.fill"
        case .holyWeek: return "flame.fill"
        case .mothersDay: return "heart.fill"
        case .pichincha: return "flag.fill"
        case .fathersDay: return "person.2.fill"
        case .intiRaymi: return "sun.max.fill"
        case .guayaquilJuly: return "sailboat.fill"
        case .augustIndependence: return "flag.circle.fill"
        case .yamor: return "leaf.circle.fill"
        case .guayaquilOctober: return "flag.2.crossed.fill"
        case .rodeoMontuvio: return "figure.equestrian.sports"
        case .halloween: return "moon.stars.fill"
        case .difuntos: return "cup.and.saucer.fill"
        case .mamaNegra: return "theatermasks.circle.fill"
        case .quito: return "building.columns.fill"
        case .christmas: return "gift.fill"
        case .newYearsEve: return "sparkles.rectangle.stack.fill"
        }
    }

    var particleSymbols: [String] {
        switch self {
        case .newYear:
            return ["sparkles", "star.fill", "party.popper.fill", "circle.fill"]
        case .diablada:
            return ["theatermasks.fill", "flame.fill", "sparkles", "circle.fill"]
        case .carnival:
            return ["party.popper.fill", "sparkles", "circle.fill", "star.fill", "paintpalette.fill"]
        case .valentinesDay:
            return ["heart.fill", "heart.circle.fill", "camera.macro", "gift.fill", "sparkles", "circle.fill", "seal.fill"]
        case .pawkarRaymi:
            return ["leaf.fill", "camera.macro", "sun.max.fill", "sparkles"]
        case .holyWeek:
            return ["flame.fill", "leaf.fill", "sun.haze.fill", "sparkles"]
        case .mothersDay:
            return ["heart.fill", "camera.macro", "gift.fill", "sparkles"]
        case .pichincha:
            return ["flag.fill", "mountain.2.fill", "star.fill", "sparkles"]
        case .fathersDay:
            return ["person.2.fill", "heart.fill", "star.fill", "sparkles"]
        case .intiRaymi:
            return ["sun.max.fill", "leaf.fill", "flame.fill", "sparkles"]
        case .guayaquilJuly:
            return ["sailboat.fill", "flag.fill", "sun.max.fill", "sparkles"]
        case .augustIndependence:
            return ["flag.circle.fill", "star.fill", "sparkles", "mountain.2.fill"]
        case .yamor:
            return ["leaf.fill", "drop.fill", "sun.max.fill", "sparkles"]
        case .guayaquilOctober:
            return ["flag.2.crossed.fill", "sparkles", "star.fill", "sun.max.fill"]
        case .rodeoMontuvio:
            return ["figure.equestrian.sports", "flame.fill", "star.fill", "sparkles"]
        case .halloween:
            return ["moon.stars.fill", "sparkles", "eye.fill", "circle.fill"]
        case .difuntos:
            return ["cup.and.saucer.fill", "leaf.fill", "flame.fill", "sparkles"]
        case .mamaNegra:
            return ["theatermasks.circle.fill", "sparkles", "flame.fill", "circle.fill"]
        case .quito:
            return ["building.columns.fill", "car.fill", "sparkles", "star.fill"]
        case .christmas:
            return ["gift.fill", "snowflake", "bell.fill", "star.fill", "sparkles", "cloud.snow.fill"]
        case .newYearsEve:
            return ["sparkles", "flame.fill", "party.popper.fill", "moon.stars.fill", "star.fill"]
        }
    }

    var particleCount: Int {
        switch self {
        case .valentinesDay: return 30
        case .christmas, .carnival, .newYearsEve: return 22
        case .halloween, .intiRaymi, .yamor: return 18
        default: return 14
        }
    }

    var motionStyle: SeasonalMotionStyle {
        switch self {
        case .guayaquilJuly, .guayaquilOctober, .rodeoMontuvio:
            return .wind
        case .newYear, .newYearsEve, .carnival:
            return .burst
        case .valentinesDay:
            return .bloom
        case .intiRaymi, .pawkarRaymi, .yamor:
            return .orbit
        default:
            return .fall
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
        case .carnival:
            return [c(0xF783AC), c(0x4DABF7), c(0x69DB7C), c(0xFFD43B), c(0xB197FC)]
        case .valentinesDay:
            return [c(0xFF4D8D), c(0xFFB3C7), c(0xF783AC), c(0xE64980), c(0xFFF0F6), c(0xC2255C)]
        case .pawkarRaymi:
            return [c(0x69DB7C), c(0xFFD43B), c(0xFF922B), c(0x38D9A9)]
        case .holyWeek:
            return [c(0x9775FA), c(0xFFD43B), c(0x8CE99A), c(0xFFFFFF, alpha: 0.75)]
        case .mothersDay:
            return [c(0xF06595), c(0xFCC2D7), c(0xFF8787), c(0xB197FC)]
        case .pichincha:
            return [c(0xFFD43B), c(0x4DABF7), c(0xFF6B6B), c(0xFFFFFF, alpha: 0.8)]
        case .fathersDay:
            return [c(0x4DABF7), c(0x74C0FC), c(0xFFD43B), c(0xADB5BD)]
        case .intiRaymi:
            return [c(0xFFD43B), c(0xFF922B), c(0xF76707), c(0x69DB7C)]
        case .guayaquilJuly, .guayaquilOctober:
            return [c(0x4DABF7), c(0xFFFFFF, alpha: 0.88), c(0xFFD43B), c(0x228BE6)]
        case .augustIndependence:
            return [c(0xFFD43B), c(0x228BE6), c(0xFA5252), c(0xFFFFFF, alpha: 0.78)]
        case .yamor:
            return [c(0xFFD43B), c(0x82C91E), c(0xFF922B), c(0x7950F2)]
        case .rodeoMontuvio:
            return [c(0xD9480F), c(0xF59F00), c(0xA16207), c(0xFFFFFF, alpha: 0.72)]
        case .halloween:
            return [c(0xF76707), c(0x845EF7), c(0x212529), c(0xFFD43B)]
        case .difuntos:
            return [c(0x862E9C), c(0xF783AC), c(0xFF922B), c(0x8CE99A)]
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
        let month = calendar.component(.month, from: localDate)
        let day = calendar.component(.day, from: localDate)

        func range(_ startMonth: Int, _ startDay: Int, _ endMonth: Int, _ endDay: Int) -> Bool {
            guard let start = makeDate(year: year, month: startMonth, day: startDay, calendar: calendar),
                  let end = makeDate(year: year, month: endMonth, day: endDay, calendar: calendar) else {
                return false
            }
            return localDate >= start && localDate <= end
        }

        func rangeAround(_ center: Date, before: Int, after: Int) -> Bool {
            guard let start = calendar.date(byAdding: .day, value: -before, to: center),
                  let end = calendar.date(byAdding: .day, value: after, to: center) else {
                return false
            }
            return localDate >= calendar.startOfDay(for: start) && localDate <= calendar.startOfDay(for: end)
        }

        let easter = easterSunday(year: year, calendar: calendar)

        // Highest-priority campaigns first.
        if range(12, 27, 12, 31) { return .newYearsEve }
        if range(12, 7, 12, 25) { return .christmas }
        if range(12, 1, 12, 6) { return .quito }
        if range(11, 4, 11, 12) { return .mamaNegra }
        if range(11, 1, 11, 3) { return .difuntos }
        if range(10, 27, 10, 31) { return .halloween }
        if range(10, 10, 10, 13) { return .rodeoMontuvio }
        if range(10, 6, 10, 9) { return .guayaquilOctober }
        if range(9, 1, 9, 15) { return .yamor }
        if range(8, 8, 8, 10) { return .augustIndependence }
        if range(7, 20, 7, 25) { return .guayaquilJuly }
        if range(6, 18, 6, 26) { return .intiRaymi }
        if let fathersDay = nthWeekday(year: year, month: 6, weekday: 1, nth: 3, calendar: calendar),
           rangeAround(fathersDay, before: 2, after: 1) { return .fathersDay }
        if range(5, 22, 5, 24) { return .pichincha }
        if let mothersDay = nthWeekday(year: year, month: 5, weekday: 1, nth: 2, calendar: calendar),
           rangeAround(mothersDay, before: 3, after: 1) { return .mothersDay }
        if range(2, 10, 2, 14) { return .valentinesDay }
        if rangeAround(easter, before: 7, after: 0) { return .holyWeek }
        if rangeAround(easter, before: 50, after: -46) { return .carnival }
        if range(3, 18, 3, 23) { return .pawkarRaymi }
        if month == 1 && (1...2).contains(day) { return .newYear }
        if month == 1 && (3...6).contains(day) { return .diablada }

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
        default:
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
        case .valentinesDay: return "Flores, corazones y planes para dos"
        case .christmas: return "Navidad con sabor de casa"
        case .newYearsEve: return "Despedimos el año en familia"
        case .carnival: return "Carnaval, color y antojos serranos"
        case .intiRaymi: return "Sol, cosecha y montaña"
        case .mothersDay: return "Un detalle bonito para mamá"
        case .fathersDay: return "Un plan para celebrar a papá"
        case .difuntos: return "Tradición, colada morada y memoria"
        default: return title
        }
    }

    func homeHeroTitle(firstName: String?) -> String {
        let greeting = firstName.map { "Hola, \($0)" } ?? "Bienvenido"
        switch self {
        case .valentinesDay: return "\(greeting)\nCelebra con amor en Los Altos"
        case .christmas: return "\(greeting)\nNavidad sabe mejor en familia"
        case .newYearsEve: return "\(greeting)\nCierra el año en Los Altos"
        case .carnival: return "\(greeting)\nCarnaval con sabor y aventura"
        case .intiRaymi: return "\(greeting)\nCelebra el sol y la montaña"
        case .mothersDay: return "\(greeting)\nMamá merece Los Altos"
        case .fathersDay: return "\(greeting)\nPapá merece una aventura"
        case .difuntos: return "\(greeting)\nTradición que abraza"
        default: return "\(greeting)\nVive Los Altos"
        }
    }
    
    func adventureHeroTitle(firstName: String?) -> String {
        let greeting = firstName.map { "Hola, \($0)" } ?? "Bienvenido"
        switch self {
        case .valentinesDay:
            return "\(greeting)\nUna aventura para compartir"
        case .carnival:
            return "\(greeting)\nCarnaval con adrenalina y sabor"
        case .pawkarRaymi:
            return "\(greeting)\nFlorece una nueva aventura"
        case .holyWeek:
            return "\(greeting)\nEscápate con calma a la montaña"
        case .mothersDay:
            return "\(greeting)\nMamá también merece aventura"
        case .fathersDay:
            return "\(greeting)\nPapá merece ruta y parrilla"
        case .intiRaymi:
            return "\(greeting)\nCelebra el sol en la montaña"
        case .christmas:
            return "\(greeting)\nNavidad con aventura familiar"
        case .newYearsEve:
            return "\(greeting)\nCierra el año con una gran ruta"
        case .newYear:
            return "\(greeting)\nEmpieza el año en Los Altos"
        case .difuntos:
            return "\(greeting)\nTradición, paisaje y familia"
        case .quito:
            return "\(greeting)\nFiestas, montaña y experiencias"
        default:
            return "\(greeting)\nVive una aventura especial"
        }
    }

    var homeHeroSubtitle: String {
        switch self {
        case .valentinesDay:
            return "Arma un plan con comida, flores visuales, corazones y experiencias para compartir sin complicarte."
        case .christmas:
            return "Reserva comida, experiencias y combos para compartir con esa sensación de casa que no se improvisa."
        case .newYearsEve:
            return "Comida, aventura y últimos recuerdos del año con descuentos y reservas desde una sola cuenta."
        case .carnival:
            return "Color, música, comida serrana y experiencias para venir con amigos o familia."
        case .intiRaymi:
            return "Sol, cosecha, montaña y experiencias para reconectar con lo nuestro."
        case .mothersDay:
            return "Sorprende a mamá con comida rica, paisajes y un plan familiar completo."
        case .fathersDay:
            return "Comida fuerte, aventura y un día distinto para celebrar a papá."
        case .difuntos:
            return "Sabores tradicionales, familia y un momento tranquilo para recordar y compartir."
        default:
            return "Pide comida, reserva experiencias, revisa combos y aprovecha premios desde una sola cuenta."
        }
    }
    
    var adventureHeroSubtitle: String {
        switch self {
        case .valentinesDay:
            return "Elige una ruta, añade comida y arma un plan para dos con corazones, flores y montaña sin complicarte."
        case .carnival:
            return "Combina cuadrones, paintball, go karts o camping con comida para venir con amigos y disfrutar sin improvisar."
        case .pawkarRaymi:
            return "Aprovecha la temporada del florecimiento: aire libre, comida serrana y experiencias para reconectar."
        case .holyWeek:
            return "Reserva una escapada tranquila, con horarios claros, comida incluida y experiencias familiares."
        case .mothersDay:
            return "Prepara un día completo para mamá: paisaje, comida rica, fotos y una experiencia que se recuerde."
        case .fathersDay:
            return "Arma una salida con ruta, adrenalina y una buena comida para celebrar a papá como se merece."
        case .intiRaymi:
            return "Sol, cosecha y montaña: actividades al aire libre con el sabor de Los Altos al final del camino."
        case .christmas:
            return "Trae a la familia, reserva una experiencia y acompáñala con comida de casa en ambiente navideño."
        case .newYearsEve:
            return "Cierra el año con una ruta, fotos, comida y una reserva lista antes de los abrazos de medianoche."
        case .difuntos:
            return "Una salida tranquila para compartir, recordar y disfrutar sabores tradicionales cerca de la montaña."
        default:
            return "Elige paquetes, actividades individuales o crea tu propio combo con comida incluida y premios disponibles."
        }
    }

    var restaurantHeroTitle: String {
        switch self {
        case .valentinesDay: return "Sabores para enamorar"
        case .christmas: return "Mesa navideña en Los Altos"
        case .newYearsEve: return "Último antojo del año"
        case .carnival: return "Antojos de Carnaval"
        case .mothersDay: return "Mamá elige primero"
        case .fathersDay: return "Para papá, bien servido"
        case .difuntos: return "Tradición en la mesa"
        default: return "Elige con antojo"
        }
    }

    var restaurantHeroSubtitle: String {
        switch self {
        case .valentinesDay: return "Platos para compartir, detalles románticos y un ambiente cálido para venir en pareja o familia."
        case .christmas: return "Sabores de casa, parrilladas, bebidas y platos para compartir sin correr en cocina."
        case .newYearsEve: return "Cierra el año con algo rico antes de los monigotes, cábalas y abrazos."
        case .difuntos: return "Una fecha para sabores tradicionales, calma y conversación en familia."
        default: return "Busca rápido o avanza paso a paso: entrada, sopa, plato fuerte, extra, postre y bebida."
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
