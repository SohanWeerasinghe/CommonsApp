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
        var body: some View {
            /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
        }
    }
}
