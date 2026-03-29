import Testing

struct ReaderInteractionStateTests {
    @Test func initialThemeUsesStoredValueWhenValid() {
        let restored = ThemeSelection.initialThemeID(storedRawValue: LeafTheme.ThemeID.tokyoNight.rawValue)

        #expect(restored == .tokyoNight)
    }

    @Test func initialThemeFallsBackWhenStoredValueIsInvalid() {
        let restored = ThemeSelection.initialThemeID(storedRawValue: "not-a-theme")

        #expect(restored == LeafTheme.defaultThemeID)
    }

    @Test func nextThemeAdvancesToFollowingTheme() {
        let next = ThemeSelection.nextThemeID(after: .redGraphite)

        #expect(next == .darkGraphite)
    }

    @Test func nextThemeWrapsFromLastThemeToFirst() {
        let next = ThemeSelection.nextThemeID(after: .crimsonCircuit)

        #expect(next == .redGraphite)
    }

    @Test func copyModeToggleFlipsState() {
        #expect(CopyModeState.toggled(from: false) == true)
        #expect(CopyModeState.toggled(from: true) == false)
    }

    @Test func copyModeAccessibilityValueMatchesState() {
        #expect(CopyModeState.accessibilityValue(isEnabled: false) == "off")
        #expect(CopyModeState.accessibilityValue(isEnabled: true) == "on")
    }
}
