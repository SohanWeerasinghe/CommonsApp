//
//  Components.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

//This use to show the unit number in the small squere
struct UnitBadge: View {
    let unit: String
    var size: CGFloat = 36
    
    var body: some View {
        Text(unit)
            .font(Theme.mono(size * 0.34))
            .foregroundStyle(Theme.textPrimary)
            .frame(width: size, height: size)
            .background(Theme.paper)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.22)
                    .stroke(Theme.brassDark, lineWidth: 1.2)
            )
    }
    
    struct PlaqueCard<Content: View>: View {
        
        @ViewBuilder var content : Content
        
        var body: some View {
            content
                .padding(16)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cardRadius)
                    .stroke(Theme.hairline, lineWidth: 1)
                )
                .overlay(
                    Circle()
                        .fill(Theme.brass)
                        .frame(width: 5, height: 5)
                        .padding(10),
                    alignment: .topLeading
                )
        }
    }
    
    // rounded tag for catergory labels
    
    struct Pill: View {
        
        let text : String
        var filled: Bool = false
        
        var body: some View {
            Text(text)
                .font(Theme.ui(12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .foregroundStyle(filled ? Theme.ink : Theme.textMuted)
                .background(filled ? Theme.brass : Theme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(filled ? .clear : Theme.hairline, lineWidth:1)
                )
        }
    }
    
    //primary buttons
    
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.ui(15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .foregroundStyle(Theme.ink)
                .background(Theme.brass)
                .clipShape(Capsule())
                .opacity(configuration.isPressed ? 0.8 : 1)
        }
    }
    
    //secondary buttons - only the outlines
    
    struct OutlineButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(Theme.ui(15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(Theme.textPrimary)
                .overlay(Capsule().stroke(Theme.brass, lineWidth: 1.3))
                .opacity(configuration.isPressed ? 0.7 : 1)
        }
    }
    
    //Section title
    
    struct SectionHeader: View {
        let title: String

        var body: some View {
            Text(title.uppercased())
                .font(Theme.ui(12, weight: .semibold))
                .foregroundStyle(Theme.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// for add relativeDescription to any Date value
extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
