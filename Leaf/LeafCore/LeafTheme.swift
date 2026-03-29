//
//  LeafTheme.swift
//  Leaf
//
//  Created by Neeraj Kumar on 24/02/26.
//

import SwiftUI

public struct LeafTheme {
    public struct Colors {
        public let background: Color
        public let text: Color
        public let secondary: Color
        public let accent: Color
        public let codeBackground: Color
        public let quoteBorder: Color
    }

    public struct Theme: Identifiable {
        public let id: ThemeID
        public let name: String
        public let colors: Colors
        public let isDark: Bool
    }

    public enum ThemeID: String, CaseIterable, Identifiable {
        case redGraphite
        case darkGraphite
        case highContrast
        case rosePine
        case tokyoNight
        case solaceMist
        case tidalDusk
        case voltNoir
        case crimsonCircuit

        public var id: String { rawValue }
    }

    public struct Metrics {
        public let scale: CGFloat
        public let bodyFontSize: CGFloat
        public let codeFontSize: CGFloat
        public let lineSpacing: CGFloat
        public let paragraphSpacing: CGFloat
        public let listSpacing: CGFloat
        public let contentMaxWidth: CGFloat
        public let verticalPadding: CGFloat
    }

    public static let defaultThemeID: ThemeID = .highContrast

    public static let themes: [Theme] = [
        Theme(
            id: .redGraphite,
            name: "Ember Linen",
            colors: Colors(
                background: color(0xF9F7F3),
                text: color(0x2C2C2E),
                secondary: color(0x6E6E73),
                accent: color(0xE05656),
                codeBackground: color(0xEFECEA),
                quoteBorder: color(0xE0DDD8)
            ),
            isDark: false
        ),
        Theme(
            id: .darkGraphite,
            name: "Night Slate",
            colors: Colors(
                background: color(0x1C1D20),
                text: color(0xE7E7E7),
                secondary: color(0x9AA0A6),
                accent: color(0x58A6FF),
                codeBackground: color(0x26282C),
                quoteBorder: color(0x333843)
            ),
            isDark: true
        ),
        Theme(
            id: .highContrast,
            name: "Paper Bright",
            colors: Colors(
                background: color(0xFFFFFF),
                text: color(0x111111),
                secondary: color(0x4B4B4B),
                accent: color(0x2F7AFF),
                codeBackground: color(0xF2F2F2),
                quoteBorder: color(0xD0D0D0)
            ),
            isDark: false
        ),
        Theme(
            id: .rosePine,
            name: "Velvet Plum",
            colors: Colors(
                background: color(0x1F1D2E),
                text: color(0xE0DEF4),
                secondary: color(0x908CAA),
                accent: color(0xEB6F92),
                codeBackground: color(0x26233A),
                quoteBorder: color(0x3C3854)
            ),
            isDark: true
        ),
        Theme(
            id: .tokyoNight,
            name: "Indigo Metro",
            colors: Colors(
                background: color(0x1A1B26),
                text: color(0xC0CAF5),
                secondary: color(0x9AA5CE),
                accent: color(0x7AA2F7),
                codeBackground: color(0x24283B),
                quoteBorder: color(0x343B58)
            ),
            isDark: true
        ),
        Theme(
            id: .solaceMist,
            name: "Solace Mist",
            colors: Colors(
                background: color(0xF6F0E6),
                text: color(0x2B2A28),
                secondary: color(0x6C645B),
                accent: color(0x3A8FB7),
                codeBackground: color(0xE9E1D4),
                quoteBorder: color(0xD8CEBF)
            ),
            isDark: false
        ),
        Theme(
            id: .tidalDusk,
            name: "Tidal Dusk",
            colors: Colors(
                background: color(0x1E2A2E),
                text: color(0xE3E0D8),
                secondary: color(0xA7B0A7),
                accent: color(0x4FB3C6),
                codeBackground: color(0x2A3D43),
                quoteBorder: color(0x32464E)
            ),
            isDark: true
        ),
        Theme(
            id: .voltNoir,
            name: "Volt Noir",
            colors: Colors(
                background: color(0x0B0F14),
                text: color(0xE7EEF6),
                secondary: color(0x9AA6B2),
                accent: color(0xFFD400),
                codeBackground: color(0x141F2B),
                quoteBorder: color(0x1A2836)
            ),
            isDark: true
        ),
        Theme(
            id: .crimsonCircuit,
            name: "Crimson Circuit",
            colors: Colors(
                background: color(0x0E1116),
                text: color(0xE9E6E2),
                secondary: color(0xAFA9A3),
                accent: color(0xFF2D55),
                codeBackground: color(0x1A202A),
                quoteBorder: color(0x232B36)
            ),
            isDark: true
        )
    ]

    public static func theme(for id: ThemeID) -> Theme {
        themes.first { $0.id == id } ?? themes[0]
    }

    public static func theme(for rawValue: String) -> Theme {
        guard let id = ThemeID(rawValue: rawValue) else {
            return theme(for: defaultThemeID)
        }
        return theme(for: id)
    }

    private static let contentMaxWidth: CGFloat = 720
    private static let bodyFontSize: CGFloat = 16
    private static let codeFontSize: CGFloat = 15
    private static let lineSpacing: CGFloat = 6
    private static let paragraphSpacing: CGFloat = 14
    private static let listSpacing: CGFloat = 8
    private static let verticalPadding: CGFloat = 48

    public static func metrics(scale: CGFloat) -> Metrics {
        let clamped = max(0.8, min(scale, 1.6))
        return Metrics(
            scale: clamped,
            bodyFontSize: bodyFontSize * clamped,
            codeFontSize: codeFontSize * clamped,
            lineSpacing: lineSpacing * clamped,
            paragraphSpacing: paragraphSpacing * clamped,
            listSpacing: listSpacing * clamped,
            contentMaxWidth: contentMaxWidth,
            verticalPadding: verticalPadding * clamped
        )
    }

    public static func headingFont(level: Int, scale: CGFloat) -> Font {
        let scaled = max(0.8, min(scale, 1.6))
        switch level {
        case 1:
            return .system(size: 32 * scaled, weight: .semibold)
        case 2:
            return .system(size: 26 * scaled, weight: .semibold)
        case 3:
            return .system(size: 22 * scaled, weight: .semibold)
        case 4:
            return .system(size: 19 * scaled, weight: .semibold)
        case 5:
            return .system(size: 17 * scaled, weight: .semibold)
        default:
            return .system(size: 16 * scaled, weight: .semibold)
        }
    }

    public static func inlineFont(isStrong: Bool, isEmphasis: Bool, isCode: Bool, scale: CGFloat) -> Font {
        let scaled = max(0.8, min(scale, 1.6))
        let size = (isCode ? codeFontSize : bodyFontSize) * scaled
        let weight: Font.Weight = isStrong ? .semibold : .regular
        let design: Font.Design = isCode ? .monospaced : .default
        var font = Font.system(size: size, weight: weight, design: design)
        if isEmphasis {
            font = font.italic()
        }
        return font
    }

    private static func color(_ hex: Int, opacity: Double = 1) -> Color {
        Color(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
