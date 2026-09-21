//
//  Theme.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

enum Theme {
    
    //Colours
    
    static let ink        = Color(hex: "1B2432")   // deep navy — nav bars, tab bar
    static let inkLight   = Color(hex: "28334A")   // lighter navy — cards on dark bg
    static let inkLine    = Color(hex: "3A465E")   // dividers on navy

    static let paper      = Color(hex: "F6F1E6")   // warm off-white — scroll backgrounds
    static let card       = Color(hex: "FFFEFA")   // pure card surface

    static let brass      = Color(hex: "BD9A4E")   // primary accent / buttons
    static let brassDark  = Color(hex: "8F7136")   // pressed state / secondary

    static let clay       = Color(hex: "A9543B")   // urgent / maintenance
    static let sage       = Color(hex: "5F7F5C")   // verified / success

    static let textPrimary     = Color(hex: "20242B")
    static let textMuted       = Color(hex: "6E6656")
    static let textOnInk       = Color(hex: "F3EFE4")
    static let textOnInkMuted  = Color(hex: "9AA3B5")

    static let hairline   = Color(hex: "E3DAC3")   // subtle borders
    
    //Typography

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    static func mono(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    //Shape

    static let cardRadius: CGFloat = 12
}
extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8)  & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}


