import SwiftUI

enum Theme {

    // MARK: - Core Dark Colours

    // Dark navy used for headings and the bottom navigation
    static let ink = Color(hex: "111B31")

    // Slightly lighter navy
    static let inkLight = Color(hex: "253149")

    // Divider colour used on dark backgrounds
    static let inkLine = Color(hex: "3B465A")


    // MARK: - Main Backgrounds

    // Main screen background
    static let paper = Color(hex: "F5F6F8")

    // White cards and input areas
    static let card = Color.white


    // MARK: - Main Brand Colours

    // Main purple used for buttons and selected controls
    static let purple = Color(hex: "7161D1")

    // Slightly darker purple for pressed states
    static let purpleDark = Color(hex: "5F50BC")


    // MARK: - Status Colours

    static let success = Color(hex: "49AD91")
    static let danger = Color(hex: "E27667")
    static let warning = Color(hex: "D5A63F")
    static let info = Color(hex: "5594DE")


    // MARK: - Reference UI Colours

    // Main dark text used throughout the reference screens
    static let appNavy = Color(hex: "172034")

    // Secondary grey text
    static let appMuted = Color(hex: "8A92A1")

    // Lighter icon / tertiary text
    static let appTertiary = Color(hex: "9AA1AE")

    // Main reference purple
    static let appPurple = Color(hex: "786EEA")

    // Darker purple used for smaller accents
    static let appPurpleDark = Color(hex: "6759BD")

    // Pale purple background
    static let appPurpleSoft = Color(hex: "ECE8FF")

    // Green status colour
    static let appGreen = Color(hex: "3FA380")

    // Pale green status background
    static let appGreenSoft = Color(hex: "E8F8F2")

    // Bright mint status indicator
    static let appMint = Color(hex: "64E0B1")

    // Blue used for event labels
    static let appEventBlue = Color(hex: "344D88")

    // Standard card border used by reference screens
    static let appBorder = Color(hex: "E0E3E8")


    // MARK: - Wall Background Colours

    static let wallBackgroundTop = Color(hex: "FBFAF7")

    static let wallBackgroundBottom = Color(hex: "F1F3F6")


    // MARK: - Text Colours

    static let textPrimary = Color(hex: "111B31")

    static let textMuted = Color(hex: "7D8190")

    static let textOnInk = Color.white

    static let textOnInkMuted = Color(hex: "B8BFCC")


    // MARK: - Borders

    static let hairline = Color(hex: "E6E7EB")


    // MARK: - Compatibility Colours

    // These names are already used by the existing screens.
    // Keep them so the project continues to build.

    static let brass = purple

    static let brassDark = purpleDark

    static let clay = danger

    static let sage = success


    // MARK: - Fonts

    static func display(
        _ size: CGFloat,
        weight: Font.Weight = .bold
    ) -> Font {

        return .system(
            size: size,
            weight: weight,
            design: .rounded
        )
    }

    static func ui(
        _ size: CGFloat,
        weight: Font.Weight = .regular
    ) -> Font {

        return .system(
            size: size,
            weight: weight,
            design: .rounded
        )
    }

    static func mono(
        _ size: CGFloat,
        weight: Font.Weight = .semibold
    ) -> Font {

        return .system(
            size: size,
            weight: weight,
            design: .monospaced
        )
    }


    // MARK: - Layout

    static let cardRadius: CGFloat = 18

    static let smallRadius: CGFloat = 12

    static let buttonHeight: CGFloat = 50

    static let screenPadding: CGFloat = 20

    static let sectionSpacing: CGFloat = 24

    static let cardPadding: CGFloat = 16
}


// MARK: - Hex Colour Support

extension Color {

    init(hex: String) {

        let cleaned = hex.trimmingCharacters(
            in: .alphanumerics.inverted
        )

        var value: UInt64 = 0

        Scanner(string: cleaned).scanHexInt64(&value)

        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255

        self.init(
            red: red,
            green: green,
            blue: blue
        )
    }
}
