//
//  SecondaryButton.swift
//  Vector
//
//  Created by Adam Zaatar on 8/22/25.
// File: UI/Components/SecondaryButton.swift
//

import Foundation
import SwiftUI

/// A secondary-styled button for less prominent actions.
/// - Visual style: outlined capsule, monochrome-friendly.
/// - Accessibility: maintains minimum tap target, clear labels.
/// - Consistency: complements `PrimaryButton`.
public struct SecondaryButton: View {
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(Typography.body)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .minTapTarget()
    }
}

// MARK: - Previews

#if DEBUG
struct SecondaryButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SecondaryButton("Cancel", systemImage: "xmark") {}
            SecondaryButton("Learn More") {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
