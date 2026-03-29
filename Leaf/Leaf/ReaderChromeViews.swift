import SwiftUI

struct LeafToolbarTitleView: View {
    let documentTitle: String?
    let colors: LeafTheme.Colors

    var body: some View {
        VStack(spacing: 2) {
            if let documentTitle {
                Text(documentTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colors.text)
                    .lineLimit(1)
            } else {
                Text(UICopy.Toolbar.appTitle)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.9)
                    .textCase(.uppercase)
                    .foregroundStyle(colors.secondary)
                Text(UICopy.Toolbar.readyStateTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colors.text)
            }
        }
        .frame(minWidth: 168)
    }
}

struct LeafToolbarChromeButton<Label: View>: View {
    let colors: LeafTheme.Colors
    let isActive: Bool
    let action: () -> Void
    let accessibilityIdentifier: String?
    let accessibilityValue: String?
    @ViewBuilder let label: () -> Label

    @ViewBuilder
    var body: some View {
        let button = Button(action: action) {
            label()
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? colors.accent : colors.secondary)
                .frame(minWidth: 30, minHeight: 28)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isActive ? colors.selectionFill : colors.chromeSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9)
                        .stroke(isActive ? colors.selectionBorder : colors.chromeBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)

        if let accessibilityIdentifier, let accessibilityValue {
            button
                .accessibilityIdentifier(accessibilityIdentifier)
                .accessibilityValue(accessibilityValue)
        } else if let accessibilityIdentifier {
            button.accessibilityIdentifier(accessibilityIdentifier)
        } else if let accessibilityValue {
            button.accessibilityValue(accessibilityValue)
        } else {
            button
        }
    }
}

struct LeafChromeGroup<Content: View>: View {
    let colors: LeafTheme.Colors
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: 8) {
            content()
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colors.chromeSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.chromeBorder, lineWidth: 1)
        )
    }
}

struct ReaderSubheaderView: View {
    let colors: LeafTheme.Colors
    let documentTitle: String

    var body: some View {
        HStack {
            Text(documentTitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(colors.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
        .background(.thinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(colors.chromeBorder.opacity(0.6))
                .frame(height: 1)
        }
    }
}

struct SidebarEmptyStateView: View {
    let colors: LeafTheme.Colors

    var body: some View {
        VStack(spacing: 14) {
            LeafMascotMark(colors: colors, size: 52, accentScale: 0.9)

            VStack(spacing: 5) {
                Text(UICopy.Sidebar.emptyTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colors.text)

                Text(UICopy.Sidebar.emptyMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(colors.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 170)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 18)
        .background(colors.sidebarBackground)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sidebarEmptyState")
    }
}

struct ReaderEmptyStateView: View {
    let theme: LeafTheme.Theme
    let metrics: LeafTheme.Metrics
    let openAction: () -> Void

    private var colors: LeafTheme.Colors {
        theme.colors
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompactLayout = geometry.size.height < 860
            let mascotSize: CGFloat = isCompactLayout ? 62 : 74
            let contentSpacing: CGFloat = isCompactLayout ? 18 : 24
            let headlineSize: CGFloat = isCompactLayout ? 24 : 28

            ZStack {
                EmptyStateAtmosphere(colors: colors)

                VStack(spacing: 0) {
                    Spacer(minLength: max(28, geometry.size.height * 0.055))

                    VStack(spacing: contentSpacing) {
                        LeafMascotMark(colors: colors, size: mascotSize, accentScale: 1.0)

                        Text(UICopy.EmptyState.headline)
                            .font(.system(size: headlineSize, weight: .semibold))
                            .foregroundStyle(colors.text)
                            .multilineTextAlignment(.center)

                        Button(action: openAction) {
                            HStack(spacing: 10) {
                                Image(systemName: "folder.badge.plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text(UICopy.EmptyState.primaryAction)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(buttonTextColor)
                            .padding(.horizontal, 18)
                            .padding(.vertical, isCompactLayout ? 11 : 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colors.accent)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("emptyStateOpenButton")

                        EmptyStatePreviewCard(colors: colors, metrics: metrics, isCompact: isCompactLayout)
                            .frame(maxWidth: isCompactLayout ? 480 : 500)
                            .accessibilityIdentifier("emptyStatePreview")

                        Text(UICopy.Shortcuts.inlineHint)
                            .font(.system(size: 12))
                            .foregroundStyle(colors.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 360)
                    }
                    .frame(maxWidth: 560)
                    .padding(.horizontal, 28)

                    Spacer(minLength: max(28, geometry.size.height * 0.065))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("emptyStateHero")
    }

    private var buttonTextColor: Color {
        theme.isDark ? Color.black.opacity(0.88) : Color.white
    }
}

struct KeyboardShortcutsSheet: View {
    let theme: LeafTheme.Theme

    @Environment(\.dismiss) private var dismiss

    private var colors: LeafTheme.Colors {
        theme.colors
    }

    private var sections: [ShortcutSection] {
        [
            ShortcutSection(
                title: UICopy.Shortcuts.navigationSection,
                items: [
                    ShortcutReference(
                        title: UICopy.Shortcuts.toggleSidebar,
                        keys: ["Tab"]
                    ),
                    ShortcutReference(
                        title: UICopy.Shortcuts.moveThroughFiles,
                        context: UICopy.Shortcuts.moveThroughFilesContext,
                        keys: ["↑", "↓"]
                    )
                ]
            ),
            ShortcutSection(
                title: UICopy.Shortcuts.themesSection,
                items: [
                    ShortcutReference(
                        title: UICopy.Shortcuts.toggleThemes,
                        keys: ["⇧", "Tab"]
                    ),
                    ShortcutReference(
                        title: UICopy.Shortcuts.nextTheme,
                        context: UICopy.Shortcuts.nextThemeContext,
                        keys: ["Tab"]
                    )
                ]
            ),
            ShortcutSection(
                title: UICopy.Shortcuts.readingSection,
                items: [
                    ShortcutReference(
                        title: UICopy.Shortcuts.increaseTextSize,
                        keys: ["⌘", "+"]
                    ),
                    ShortcutReference(
                        title: UICopy.Shortcuts.decreaseTextSize,
                        keys: ["⌘", "-"]
                    )
                ]
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(UICopy.Shortcuts.sheetTitle)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(colors.text)

                    Text(UICopy.Shortcuts.sheetSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(colors.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(UICopy.Shortcuts.done) {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(colors.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(colors.chromeSurface)
                )
                .overlay(
                    Capsule()
                        .stroke(colors.chromeBorder, lineWidth: 1)
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 22)
            .padding(.bottom, 18)

            Rectangle()
                .fill(colors.chromeBorder.opacity(0.7))
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(sections) { section in
                        ShortcutSectionCard(section: section, colors: colors)
                    }
                }
                .padding(24)
            }
        }
        .background(colors.background)
        .preferredColorScheme(theme.isDark ? .dark : .light)
        .accessibilityIdentifier("keyboardShortcutsSheet")
    }
}

private struct EmptyStatePreviewCard: View {
    let colors: LeafTheme.Colors
    let metrics: LeafTheme.Metrics
    let isCompact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isCompact ? 14 : 18) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(colors.accent.opacity(0.2))
                    .frame(width: 9, height: 9)
                Text(UICopy.PreviewCard.fileName)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(colors.secondary)
                Spacer()
                Text(UICopy.PreviewCard.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(colors.secondary)
            }

            VStack(alignment: .leading, spacing: isCompact ? 12 : 14) {
                Text(UICopy.PreviewCard.title)
                    .font(LeafTheme.headingFont(level: 2, scale: min(metrics.scale, 1.0)))
                    .foregroundStyle(colors.text)

                Text(UICopy.PreviewCard.body)
                    .font(.system(size: metrics.bodyFontSize))
                    .foregroundStyle(colors.text)
                    .lineSpacing(metrics.lineSpacing)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: isCompact ? 392 : 420, alignment: .leading)

                RoundedRectangle(cornerRadius: 10)
                    .fill(colors.codeBackground.opacity(0.95))
                    .frame(height: isCompact ? 56 : 64)
                    .overlay(alignment: .leading) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(UICopy.PreviewCard.codeLanguage)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(colors.secondary)
                            Text(UICopy.PreviewCard.codeLineOne)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(colors.text)
                            Text(UICopy.PreviewCard.codeLineTwo)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(colors.secondary)
                        }
                        .padding(.horizontal, 14)
                    }
            }
        }
        .padding(isCompact ? 20 : 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colors.background.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(colors.quoteBorder.opacity(0.95), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 28, x: 0, y: 14)
    }
}

private struct ShortcutSection: Identifiable {
    let id: String
    let title: String
    let items: [ShortcutReference]

    init(title: String, items: [ShortcutReference]) {
        self.id = title
        self.title = title
        self.items = items
    }
}

private struct ShortcutReference: Identifiable {
    let title: String
    let context: String?
    let keys: [String]

    var id: String {
        "\(title)-\(keys.joined(separator: "+"))"
    }

    init(title: String, context: String? = nil, keys: [String]) {
        self.title = title
        self.context = context
        self.keys = keys
    }
}

private struct ShortcutSectionCard: View {
    let section: ShortcutSection
    let colors: LeafTheme.Colors

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(section.title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(colors.secondary)

            VStack(spacing: 12) {
                ForEach(section.items) { item in
                    ShortcutReferenceRow(item: item, colors: colors)
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(colors.chromeSurface.opacity(0.78))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(colors.chromeBorder.opacity(0.95), lineWidth: 1)
        )
    }
}

private struct ShortcutReferenceRow: View {
    let item: ShortcutReference
    let colors: LeafTheme.Colors

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(colors.text)

                if let context = item.context {
                    Text(context)
                        .font(.system(size: 11))
                        .foregroundStyle(colors.secondary)
                }
            }

            Spacer(minLength: 0)

            ShortcutKeycapsView(keys: item.keys, colors: colors)
        }
    }
}

private struct ShortcutKeycapsView: View {
    let keys: [String]
    let colors: LeafTheme.Colors

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(keys.enumerated()), id: \.offset) { entry in
                ShortcutKeycap(text: entry.element, colors: colors)
            }
        }
    }
}

private struct ShortcutKeycap: View {
    let text: String
    let colors: LeafTheme.Colors

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(colors.text.opacity(0.88))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(colors.chromeSurface.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(colors.chromeBorder.opacity(0.58), lineWidth: 1)
            )
    }
}

private struct EmptyStateAtmosphere: View {
    let colors: LeafTheme.Colors

    var body: some View {
        ZStack {
            Circle()
                .fill(colors.accent.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 24)
                .offset(x: -140, y: -110)

            RoundedRectangle(cornerRadius: 120)
                .fill(colors.codeBackground.opacity(0.25))
                .frame(width: 460, height: 260)
                .rotationEffect(.degrees(-12))
                .blur(radius: 20)
                .offset(x: 180, y: 120)
        }
        .allowsHitTesting(false)
    }
}

private struct LeafMascotMark: View {
    let colors: LeafTheme.Colors
    let size: CGFloat
    let accentScale: CGFloat

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(colors.background.opacity(0.94))
                .frame(width: size, height: size * 0.72)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                        .stroke(colors.quoteBorder, lineWidth: 1)
                )
                .overlay(alignment: .center) {
                    VStack(spacing: size * 0.1) {
                        HStack(spacing: size * 0.16) {
                            Circle()
                                .fill(colors.text.opacity(0.86))
                                .frame(width: size * 0.08, height: size * 0.08)
                            Circle()
                                .fill(colors.text.opacity(0.86))
                                .frame(width: size * 0.08, height: size * 0.08)
                        }
                        RoundedRectangle(cornerRadius: size * 0.04)
                            .fill(colors.text.opacity(0.82))
                            .frame(width: size * 0.18, height: size * 0.04)
                    }
                }

            Ellipse()
                .fill(colors.accent.opacity(0.92))
                .frame(width: size * 0.26 * accentScale, height: size * 0.18 * accentScale)
                .rotationEffect(.degrees(30))
                .offset(x: size * 0.06, y: -size * 0.08)

            Ellipse()
                .fill(colors.accent.opacity(0.28))
                .frame(width: size * 0.14, height: size * 0.09)
                .offset(x: -size * 0.12, y: size * 0.4)

            Ellipse()
                .fill(colors.accent.opacity(0.28))
                .frame(width: size * 0.14, height: size * 0.09)
                .offset(x: -size * 0.36, y: size * 0.4)
        }
        .shadow(color: colors.accent.opacity(0.12), radius: 16, x: 0, y: 8)
        .accessibilityHidden(true)
    }
}
