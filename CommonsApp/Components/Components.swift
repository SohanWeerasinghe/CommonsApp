//
//  Components.swift
//  CommonsApp
//
//  Created by Sohan Weerasinghe on 21/9/2026.
//

import SwiftUI

struct UnitBadge: View {

    let unit: String
    var size: CGFloat = 36

    var body: some View {

        Text(unit)
            .font(Theme.mono(size * 0.34))
            .foregroundStyle(Theme.textPrimary)
            .frame(width: size, height: size)
            .background(Theme.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: size * 0.22
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: size * 0.22
                )
                .stroke(
                    Theme.hairline,
                    lineWidth: 1
                )
            )
    }
}


struct ResidentAvatar: View {

    let initials: String
    var size: CGFloat = 44
    var backgroundColor: Color = Theme.purple

    var body: some View {

        ZStack {

            Circle()
                .fill(backgroundColor)

            Text(initials.uppercased())
                .font(
                    Theme.ui(
                        size * 0.34,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Color.white)
        }
        .frame(
            width: size,
            height: size
        )
    }
}


struct AppCard<Content: View>: View {

    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {

        content
            .padding(Theme.cardPadding)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(Theme.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.cardRadius
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Theme.cardRadius
                )
                .stroke(
                    Theme.hairline,
                    lineWidth: 1
                )
            )
    }
}

struct PlaqueCard<Content: View>: View {

    @ViewBuilder var content: Content

    var body: some View {

        content
            .padding(Theme.cardPadding)
            .background(Theme.card)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.cardRadius
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: Theme.cardRadius
                )
                .stroke(
                    Theme.hairline,
                    lineWidth: 1
                )
            )
    }
}

struct Pill: View {

    let text: String
    var filled: Bool = false

    var body: some View {

        Text(text)
            .font(
                Theme.ui(
                    12,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                filled
                ? Color.white
                : Theme.textMuted
            )
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                filled
                ? Theme.purple
                : Theme.card
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        filled
                        ? Color.clear
                        : Theme.hairline,
                        lineWidth: 1
                    )
            )
    }
}

struct StatusDot: View {

    let color: Color
    var size: CGFloat = 8

    var body: some View {

        Circle()
            .fill(color)
            .frame(
                width: size,
                height: size
            )
    }
}


struct StatusLabel: View {

    let text: String
    let color: Color

    var body: some View {

        HStack(spacing: 7) {

            StatusDot(
                color: color,
                size: 8
            )

            Text(text)
                .font(
                    Theme.ui(
                        12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Theme.textMuted)
        }
    }
}


struct PrimaryButtonStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(
                Theme.ui(
                    16,
                    weight: .semibold
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .foregroundStyle(Color.white)
            .background(
                configuration.isPressed
                ? Theme.purpleDark
                : Theme.purple
            )
            .clipShape(Capsule())
    }
}

struct OutlineButtonStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(
                Theme.ui(
                    16,
                    weight: .semibold
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .foregroundStyle(Theme.purple)
            .background(Theme.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        Theme.purple,
                        lineWidth: 1.5
                    )
            )
            .opacity(
                configuration.isPressed
                ? 0.7
                : 1
            )
    }
}


struct DestructiveButtonStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .font(
                Theme.ui(
                    16,
                    weight: .semibold
                )
            )
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .foregroundStyle(Color.white)
            .background(Theme.danger)
            .clipShape(Capsule())
            .opacity(
                configuration.isPressed
                ? 0.8
                : 1
            )
    }
}

struct SectionHeader: View {

    let title: String

    var body: some View {

        Text(title)
            .font(
                Theme.ui(
                    13,
                    weight: .semibold
                )
            )
            .foregroundStyle(Theme.textMuted)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }
}


struct ScreenHeading: View {

    let eyebrow: String?
    let title: String

    init(
        eyebrow: String? = nil,
        title: String
    ) {
        self.eyebrow = eyebrow
        self.title = title
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            if let eyebrow = eyebrow {

                Text(eyebrow.uppercased())
                    .font(
                        Theme.ui(
                            11,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Theme.textMuted)
                    .tracking(1)
            }

            Text(title)
                .font(
                    Theme.display(
                        28,
                        weight: .bold
                    )
                )
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}


struct AppSearchField: View {

    let placeholder: String
    @Binding var text: String

    var body: some View {

        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.textMuted)

            TextField(
                placeholder,
                text: $text
            )
            .font(
                Theme.ui(
                    15
                )
            )
            .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(Theme.card)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    Theme.hairline,
                    lineWidth: 1
                )
        )
    }
}

struct AppEmptyState: View {

    let icon: String
    let title: String
    let message: String

    var body: some View {

        VStack(spacing: 12) {

            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(Theme.purple)

            Text(title)
                .font(
                    Theme.ui(
                        17,
                        weight: .semibold
                    )
                )
                .foregroundStyle(Theme.textPrimary)

            Text(message)
                .font(
                    Theme.ui(
                        14
                    )
                )
                .foregroundStyle(Theme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
    }
}

extension Date {

    var relativeDescription: String {

        let formatter = RelativeDateTimeFormatter()

        formatter.unitsStyle = .abbreviated

        return formatter.localizedString(
            for: self,
            relativeTo: Date()
        )
    }
}
