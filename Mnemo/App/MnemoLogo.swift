import SwiftUI

struct MnemoLogo: View {
    enum Size {
        case small, medium, large
    }

    var size: Size = .medium

    var body: some View {
        HStack(spacing: iconTextSpacing) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.blue.gradient)
            Text("Mnemo")
                .font(textFont)
                .fontWeight(.bold)
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: 20
        case .medium: 36
        case .large: 72
        }
    }

    private var iconTextSpacing: CGFloat {
        switch size {
        case .small: 6
        case .medium: 10
        case .large: 16
        }
    }

    private var textFont: Font {
        switch size {
        case .small: .headline
        case .medium: .title2
        case .large: .largeTitle
        }
    }
}
