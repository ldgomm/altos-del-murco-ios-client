//
//  AltosColours.swift
//  Altos del Murco
//
//  Created by José Ruiz on 5/4/26.
//

import Foundation
import SwiftUI

// MARK: - Theme Namespace

enum AppSectionTheme: String, Hashable, CaseIterable {
    case neutral
    case adventure
    case restaurant
    
    /// Optional watermark asset names.
    /// Add your uploaded illustrations to Assets using these names if you want them as subtle background marks.
    var watermarkAssetName: String? {
        switch self {
        case .neutral:
            return nil
        case .adventure:
            return "theme_adventure_mark"
        case .restaurant:
            return "theme_restaurant_mark"
        }
    }
}

struct ThemePalette {
    let primary: Color
    let secondary: Color
    let accent: Color
    let onPrimary: Color
    
    let background: Color
    let surface: Color
    let card: Color
    let elevatedCard: Color
    let stroke: Color
    
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    
    let success: Color
    let warning: Color
    let destructive: Color
    
    let shadow: Color
    let glow: Color
    
    let heroGradient: LinearGradient
    let softGradient: LinearGradient
    let cardGradient: LinearGradient
    let chipGradient: LinearGradient
}

enum AppTheme {
    
    enum Radius {
        static let small: CGFloat = 14
        static let medium: CGFloat = 18
        static let large: CGFloat = 22
        static let xLarge: CGFloat = 28
    }
    
    enum Metrics {
        static let fieldHeight: CGFloat = 54
        static let buttonHeight: CGFloat = 54
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let shadowRadius: CGFloat = 18
        static let shadowY: CGFloat = 10
    }
    
    static func palette(for theme: AppSectionTheme, scheme: ColorScheme) -> ThemePalette {
        switch theme {
        case .neutral:
            let primary = Color.adaptive(
                light: UIColor(hex: 0x2F3E4F),
                dark: UIColor(hex: 0xB5C2D0)
            )
            let secondary = Color.adaptive(
                light: UIColor(hex: 0x5F738A),
                dark: UIColor(hex: 0x8FA7BF)
            )
            let accent = Color.adaptive(
                light: UIColor(hex: 0x6F8FB0),
                dark: UIColor(hex: 0x9DB6D4)
            )
            let onPrimary = Color.white
            
            let background = Color.adaptive(
                light: UIColor(hex: 0xF4F7FA),
                dark: UIColor(hex: 0x0C1014)
            )
            let surface = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x12171D)
            )
            let card = Color.adaptive(
                light: UIColor(hex: 0xFBFCFD),
                dark: UIColor(hex: 0x151B22)
            )
            let elevatedCard = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x19212A)
            )
            let stroke = Color.adaptive(
                light: UIColor(hex: 0xDDE5EC),
                dark: UIColor(hex: 0x2A3542)
            )
            
            let textPrimary = Color.adaptive(
                light: UIColor(hex: 0x15202B),
                dark: UIColor(hex: 0xF1F5F9)
            )
            let textSecondary = Color.adaptive(
                light: UIColor(hex: 0x5C6B7A),
                dark: UIColor(hex: 0xA7B4C2)
            )
            let textTertiary = Color.adaptive(
                light: UIColor(hex: 0x8A97A5),
                dark: UIColor(hex: 0x728191)
            )
            
            let success = Color.adaptive(
                light: UIColor(hex: 0x2F855A),
                dark: UIColor(hex: 0x68D391)
            )
            let warning = Color.adaptive(
                light: UIColor(hex: 0xB7791F),
                dark: UIColor(hex: 0xF6AD55)
            )
            let destructive = Color.adaptive(
                light: UIColor(hex: 0xC53030),
                dark: UIColor(hex: 0xFC8181)
            )
            
            let shadow = Color.black
            let glow = Color.adaptive(
                light: UIColor(hex: 0x9DB6D4),
                dark: UIColor(hex: 0x5D7996)
            )
            
            return ThemePalette(
                primary: primary,
                secondary: secondary,
                accent: accent,
                onPrimary: onPrimary,
                background: background,
                surface: surface,
                card: card,
                elevatedCard: elevatedCard,
                stroke: stroke,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                success: success,
                warning: warning,
                destructive: destructive,
                shadow: shadow,
                glow: glow,
                heroGradient: LinearGradient(
                    colors: [primary, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                softGradient: LinearGradient(
                    colors: [
                        background,
                        accent.opacity(scheme == .dark ? 0.10 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [
                        elevatedCard,
                        card
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                chipGradient: LinearGradient(
                    colors: [
                        primary.opacity(scheme == .dark ? 0.24 : 0.14),
                        accent.opacity(scheme == .dark ? 0.16 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .adventure:
            let primary = Color.adaptive(
                light: UIColor(hex: 0x2F6B3C),
                dark: UIColor(hex: 0x7BCB69)
            )
            let secondary = Color.adaptive(
                light: UIColor(hex: 0x4D8A47),
                dark: UIColor(hex: 0x9BE07C)
            )
            let accent = Color.adaptive(
                light: UIColor(hex: 0xA6C95A),
                dark: UIColor(hex: 0xD5F08D)
            )
            let onPrimary = Color.white
            
            let background = Color.adaptive(
                light: UIColor(hex: 0xF2F7F0),
                dark: UIColor(hex: 0x0B140D)
            )
            let surface = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x111B13)
            )
            let card = Color.adaptive(
                light: UIColor(hex: 0xF8FCF6),
                dark: UIColor(hex: 0x152017)
            )
            let elevatedCard = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x19261B)
            )
            let stroke = Color.adaptive(
                light: UIColor(hex: 0xD8E7D4),
                dark: UIColor(hex: 0x2A3C2D)
            )
            
            let textPrimary = Color.adaptive(
                light: UIColor(hex: 0x142117),
                dark: UIColor(hex: 0xEEF8EE)
            )
            let textSecondary = Color.adaptive(
                light: UIColor(hex: 0x5D7260),
                dark: UIColor(hex: 0xA8BDAA)
            )
            let textTertiary = Color.adaptive(
                light: UIColor(hex: 0x839485),
                dark: UIColor(hex: 0x708172)
            )
            
            let success = Color.adaptive(
                light: UIColor(hex: 0x2F855A),
                dark: UIColor(hex: 0x68D391)
            )
            let warning = Color.adaptive(
                light: UIColor(hex: 0xB7791F),
                dark: UIColor(hex: 0xF6C15A)
            )
            let destructive = Color.adaptive(
                light: UIColor(hex: 0xC53030),
                dark: UIColor(hex: 0xFC8181)
            )
            
            let shadow = Color.black
            let glow = Color.adaptive(
                light: UIColor(hex: 0x9FD96A),
                dark: UIColor(hex: 0x59B84B)
            )
            
            return ThemePalette(
                primary: primary,
                secondary: secondary,
                accent: accent,
                onPrimary: onPrimary,
                background: background,
                surface: surface,
                card: card,
                elevatedCard: elevatedCard,
                stroke: stroke,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                success: success,
                warning: warning,
                destructive: destructive,
                shadow: shadow,
                glow: glow,
                heroGradient: LinearGradient(
                    colors: [primary, secondary, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                softGradient: LinearGradient(
                    colors: [
                        background,
                        primary.opacity(scheme == .dark ? 0.18 : 0.07),
                        accent.opacity(scheme == .dark ? 0.10 : 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [
                        elevatedCard,
                        card,
                        accent.opacity(scheme == .dark ? 0.04 : 0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                chipGradient: LinearGradient(
                    colors: [
                        primary.opacity(scheme == .dark ? 0.30 : 0.14),
                        accent.opacity(scheme == .dark ? 0.18 : 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
        case .restaurant:
            let primary = Color.adaptive(
                light: UIColor(hex: 0x3E4347),   // charcoal
                dark: UIColor(hex: 0xC2C8CE)     // soft silver
            )
            let secondary = Color.adaptive(
                light: UIColor(hex: 0x5A6066),   // graphite
                dark: UIColor(hex: 0x9BA3AB)     // muted steel
            )
            let accent = Color.adaptive(
                light: UIColor(hex: 0x8B7D67),   // aged brass / vintage taupe
                dark: UIColor(hex: 0xC5B79E)     // soft antique metal
            )
            let onPrimary = Color.white
            
            let background = Color.adaptive(
                light: UIColor(hex: 0xF3F2F0),   // warm stone
                dark: UIColor(hex: 0x0D0F11)     // deep charcoal black
            )
            let surface = Color.adaptive(
                light: UIColor(hex: 0xFCFBFA),   // soft neutral
                dark: UIColor(hex: 0x14171A)     // dark graphite
            )
            let card = Color.adaptive(
                light: UIColor(hex: 0xF7F5F3),   // vintage paper-stone
                dark: UIColor(hex: 0x1A1E22)     // lifted dark card
            )
            let elevatedCard = Color.adaptive(
                light: UIColor(hex: 0xFFFFFF),
                dark: UIColor(hex: 0x20252A)
            )
            let stroke = Color.adaptive(
                light: UIColor(hex: 0xD8D4CE),   // soft border
                dark: UIColor(hex: 0x333940)     // subtle dark divider
            )
            
            let textPrimary = Color.adaptive(
                light: UIColor(hex: 0x1C1F22),
                dark: UIColor(hex: 0xF3F5F7)
            )
            let textSecondary = Color.adaptive(
                light: UIColor(hex: 0x666D74),
                dark: UIColor(hex: 0xB1B8BF)
            )
            let textTertiary = Color.adaptive(
                light: UIColor(hex: 0x8A9096),
                dark: UIColor(hex: 0x7A838C)
            )
            
            let success = Color.adaptive(
                light: UIColor(hex: 0x2F855A),
                dark: UIColor(hex: 0x68D391)
            )
            let warning = Color.adaptive(
                light: UIColor(hex: 0x9C7B3D),   // muted vintage gold
                dark: UIColor(hex: 0xD6B56E)
            )
            let destructive = Color.adaptive(
                light: UIColor(hex: 0xC94C4C),
                dark: UIColor(hex: 0xFC8181)
            )
            
            let shadow = Color.black
            let glow = Color.adaptive(
                light: UIColor(hex: 0xA79A84),   // subtle warm smoke
                dark: UIColor(hex: 0x7B7468)
            )
            
            return ThemePalette(
                primary: primary,
                secondary: secondary,
                accent: accent,
                onPrimary: onPrimary,
                background: background,
                surface: surface,
                card: card,
                elevatedCard: elevatedCard,
                stroke: stroke,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                success: success,
                warning: warning,
                destructive: destructive,
                shadow: shadow,
                glow: glow,
                heroGradient: LinearGradient(
                    colors: [primary, secondary, accent],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                softGradient: LinearGradient(
                    colors: [
                        background,
                        primary.opacity(scheme == .dark ? 0.16 : 0.05),
                        accent.opacity(scheme == .dark ? 0.10 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                cardGradient: LinearGradient(
                    colors: [
                        elevatedCard,
                        card,
                        accent.opacity(scheme == .dark ? 0.035 : 0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                chipGradient: LinearGradient(
                    colors: [
                        primary.opacity(scheme == .dark ? 0.28 : 0.12),
                        accent.opacity(scheme == .dark ? 0.14 : 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
    }
}

// MARK: - Background System

struct BrandScreenBackground: View {
    let theme: AppSectionTheme
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        ZStack {
            palette.background
                .ignoresSafeArea()
            
            palette.softGradient
                .ignoresSafeArea()
            
            switch theme {
            case .neutral:
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.14 : 0.10))
                    .frame(width: 300, height: 300)
                    .blur(radius: 90)
                    .offset(x: -120, y: -220)
                
            case .adventure:
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.22 : 0.16))
                    .frame(width: 320, height: 320)
                    .blur(radius: 90)
                    .offset(x: -140, y: -240)
                
                Circle()
                    .fill(palette.secondary.opacity(colorScheme == .dark ? 0.16 : 0.10))
                    .frame(width: 240, height: 240)
                    .blur(radius: 80)
                    .offset(x: 150, y: 260)
                
            case .restaurant:
                Circle()
                    .fill(palette.glow.opacity(colorScheme == .dark ? 0.22 : 0.16))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: 120, y: -220)
                
                Circle()
                    .fill(palette.primary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                    .frame(width: 260, height: 260)
                    .blur(radius: 90)
                    .offset(x: -150, y: 280)
            }
            
            BrandWatermark(theme: theme)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 70)
                .padding(.trailing, 20)
                .opacity(colorScheme == .dark ? 0.05 : 0.08)
        }
    }
}

struct BrandWatermark: View {
    let theme: AppSectionTheme
    
    var body: some View {
        Group {
            if let assetName = theme.watermarkAssetName, UIImage(named: assetName) != nil {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Reusable Components

struct BrandSectionHeader: View {
    let theme: AppSectionTheme
    let title: String
    let subtitle: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(theme: AppSectionTheme, title: String, subtitle: String? = nil) {
        self.theme = theme
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Capsule()
                    .fill(palette.heroGradient)
                    .frame(width: 28, height: 8)
                
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(palette.textPrimary)
            }
            
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct BrandIconBubble: View {
    let theme: AppSectionTheme
    let systemImage: String
    var size: CGFloat = 48
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        ZStack {
            Circle()
                .fill(palette.chipGradient)
                .overlay(
                    Circle()
                        .stroke(palette.stroke, lineWidth: 1)
                )
            
            Image(systemName: systemImage)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(palette.primary)
        }
        .frame(width: size, height: size)
    }
}

struct BrandBadge: View {
    let theme: AppSectionTheme
    let title: String
    var selected: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(selected ? palette.onPrimary : palette.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(selected ? AnyShapeStyle(palette.heroGradient) : AnyShapeStyle(palette.chipGradient))
            )
            .overlay(
                Capsule()
                    .stroke(selected ? palette.primary.opacity(0.0) : palette.stroke, lineWidth: 1)
            )
    }
}

// MARK: - Button Styles

struct BrandPrimaryButtonStyle: ButtonStyle {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        let pressed = configuration.isPressed
        
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(palette.onPrimary.opacity(isEnabled ? 1 : 0.75))
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(isEnabled ? AnyShapeStyle(palette.heroGradient) : AnyShapeStyle(palette.stroke))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18), lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.32 : 0.14),
                radius: pressed ? 10 : AppTheme.Metrics.shadowRadius,
                x: 0,
                y: pressed ? 4 : AppTheme.Metrics.shadowY
            )
            .scaleEffect(pressed ? 0.985 : 1.0)
            .animation(.easeOut(duration: 0.18), value: pressed)
    }
}

struct BrandSecondaryButtonStyle: ButtonStyle {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        let pressed = configuration.isPressed
        
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(isEnabled ? palette.textPrimary : palette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Metrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.18 : 0.08),
                radius: pressed ? 8 : 14,
                x: 0,
                y: pressed ? 3 : 8
            )
            .scaleEffect(pressed ? 0.988 : 1.0)
            .animation(.easeOut(duration: 0.18), value: pressed)
    }
}

// MARK: - View Modifiers

struct BrandScreenModifier: ViewModifier {
    let theme: AppSectionTheme
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .tint(palette.primary)
            .foregroundStyle(palette.textPrimary)
            .background(BrandScreenBackground(theme: theme))
    }
}

struct BrandCardModifier: ViewModifier {
    let theme: AppSectionTheme
    var emphasized: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .padding(AppTheme.Metrics.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.xLarge, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                if emphasized {
                    Capsule()
                        .fill(palette.heroGradient)
                        .frame(width: 62, height: 6)
                        .padding(16)
                }
            }
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.24 : 0.10),
                radius: AppTheme.Metrics.shadowRadius,
                x: 0,
                y: AppTheme.Metrics.shadowY
            )
    }
}

struct BrandTextFieldModifier: ViewModifier {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .foregroundStyle(palette.textPrimary)
            .tint(palette.primary)
            .padding(.horizontal, 16)
            .frame(minHeight: AppTheme.Metrics.fieldHeight)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(palette.elevatedCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.12 : 0.04),
                radius: 8,
                x: 0,
                y: 3
            )
    }
}

struct BrandListRowModifier: ViewModifier {
    let theme: AppSectionTheme
    
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        let palette = AppTheme.palette(for: theme, scheme: colorScheme)
        
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .fill(palette.cardGradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large, style: .continuous)
                    .stroke(palette.stroke, lineWidth: 1)
            )
            .shadow(
                color: palette.shadow.opacity(colorScheme == .dark ? 0.16 : 0.06),
                radius: 10,
                x: 0,
                y: 5
            )
    }
}

// MARK: - View Convenience API

extension View {
    func appScreenStyle(_ theme: AppSectionTheme) -> some View {
        modifier(BrandScreenModifier(theme: theme))
    }
    
    func appCardStyle(_ theme: AppSectionTheme, emphasized: Bool = false) -> some View {
        modifier(BrandCardModifier(theme: theme, emphasized: emphasized))
    }
    
    func appTextFieldStyle(_ theme: AppSectionTheme) -> some View {
        modifier(BrandTextFieldModifier(theme: theme))
    }
    
    func appListRowStyle(_ theme: AppSectionTheme) -> some View {
        modifier(BrandListRowModifier(theme: theme))
    }
}

// MARK: - UINavigationBar / UITabBar Appearance

@MainActor
enum ThemeAppearance {
    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }
    
    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor.label
    }
    
    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.82)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.10)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Helpers

extension Color {
    static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            }
        )
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
