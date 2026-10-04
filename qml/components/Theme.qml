import QtQuick

pragma Singleton

QtObject {
    id: theme

    // Backgrounds - Smoky charcoal with slight navy tint (Semi-dark liquid glass)
    readonly property color bgBase: "#090d16"
    readonly property color bgSidebar: "#0d131f"
    readonly property color bgPanel: "#121a29"
    readonly property color bgOverlay: "#80000000"

    // Glass surfaces
    readonly property color glassCard: "#141e2e"
    readonly property color glassCardTranslucent: "#c8162236"
    readonly property color glassHover: "#1c2b42"
    readonly property color glassActive: "#243754"
    readonly property color glassInput: "#0f1622"

    // Borders
    readonly property color borderSubtle: "#1e2c40"
    readonly property color borderCard: "#26374f"
    readonly property color borderHighlight: "#3b82f6"
    readonly property color borderGlass: "#304360"

    // Accents
    readonly property color accent: "#38bdf8"
    readonly property color accentHover: "#0ea5e9"
    readonly property color accentPressed: "#0284c7"
    readonly property color accentGradientStart: "#0284c7"
    readonly property color accentGradientEnd: "#38bdf8"
    readonly property color accentSecondary: "#6366f1"

    // Text
    readonly property color textPrimary: "#f8fafc"
    readonly property color textSecondary: "#94a3b8"
    readonly property color textMuted: "#64748b"
    readonly property color textOnAccent: "#090d16"

    // Statuses
    readonly property color statusSuccess: "#22c55e"
    readonly property color statusWarning: "#f59e0b"
    readonly property color statusError: "#ef4444"
    readonly property color statusInfo: "#38bdf8"
    readonly property color statusQueued: "#94a3b8"

    // Sizing & Radius
    readonly property int radiusSmall: 6
    readonly property int radiusMedium: 10
    readonly property int radiusLarge: 14
    readonly property int radiusPill: 24

    // Spacing
    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 14
    readonly property int spacingLarge: 22
    readonly property int spacingXLarge: 32

    // Typography
    readonly property string fontFamily: "Segoe UI, -apple-system, sans-serif"
    readonly property int fontSizeTiny: 10
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeBody: 13
    readonly property int fontSizeSubheading: 15
    readonly property int fontSizeHeading: 18
    readonly property int fontSizeTitle: 24
}
