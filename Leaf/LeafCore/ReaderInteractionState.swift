//
//  ReaderInteractionState.swift
//  Leaf
//

import Foundation

public enum ThemeSelection {
    public static func initialThemeID(
        storedRawValue: String?,
        fallback: LeafTheme.ThemeID = LeafTheme.defaultThemeID
    ) -> LeafTheme.ThemeID {
        guard let storedRawValue, let themeID = LeafTheme.ThemeID(rawValue: storedRawValue) else {
            return fallback
        }
        return themeID
    }

    public static func nextThemeID(
        after current: LeafTheme.ThemeID,
        availableThemes: [LeafTheme.Theme] = LeafTheme.themes,
        fallback: LeafTheme.ThemeID = LeafTheme.defaultThemeID
    ) -> LeafTheme.ThemeID {
        let themeIDs = availableThemes.map(\.id)
        guard let index = themeIDs.firstIndex(of: current), !themeIDs.isEmpty else {
            return fallback
        }
        return themeIDs[(index + 1) % themeIDs.count]
    }
}

public enum CopyModeState {
    public static func toggled(from isEnabled: Bool) -> Bool {
        !isEnabled
    }

    public static func accessibilityValue(isEnabled: Bool) -> String {
        isEnabled ? "on" : "off"
    }
}
