//
//  EscalationStateChip.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 27.1, 27.2
//  A pill-shaped status chip that displays the current escalation state.
//  Shape is the primary signal; color is secondary (Req 27.1).
//  In Increased Contrast mode, a 1pt solid border is rendered (Req 27.2).
//

import SwiftUI

/// A compact pill-shaped chip that displays the current escalation state
/// using both icon shape and color tint.
///
/// The chip uses the same SF Symbol shapes as the menu bar icon to maintain
/// color independence (Req 27.1): users can identify the state by shape alone.
///
/// In Increased Contrast mode (`colorSchemeContrast == .increased`), a 1pt
/// solid border is rendered around the chip (Req 27.2).
@available(macOS 14.0, *)
struct EscalationStateChip: View {

    let cupCount: Int

    // MARK: - Computed

    /// The SF Symbol name for the current escalation state (same as IconRenderer).
    private var symbolName: String {
        IconRenderer.systemImageName(for: cupCount)
    }

    /// The tint color for the current escalation state.
    private var tintColor: Color {
        IconRenderer.tint(for: cupCount)
    }

    /// A short human-readable label for the current state.
    private var stateLabel: String {
        switch cupCount {
        case 0:
            return "Idle"
        case 1:
            return "Started"
        case 2:
            return "Warming up"
        case 3:
            return "Energized"
        case 4:
            return "Warning"
        default:
            return "Danger"
        }
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbolName)
                .font(.system(.caption2, weight: .medium))
            Text(stateLabel)
                .font(.system(.caption2, weight: .medium))
        }
        .foregroundStyle(tintColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(tintColor.opacity(0.12), in: Capsule())
        .increasedContrastBorder()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Coffee level: \(stateLabel)")
    }
}
