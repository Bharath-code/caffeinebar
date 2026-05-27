//
//  IconRenderer.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 27.1
//  Renders escalating menu bar icons based on today's cup count.
//  Shape conveys state primarily; color is secondary (Req 27.1).
//

import AppKit
import SwiftUI

/// Provides static methods to resolve the menu bar icon, tint color,
/// accessibility label, and SF Symbol name for a given cup count.
///
/// Escalation mapping (Reqs 1.1–1.7):
/// - 0: outline cup (system gray) — "No cups logged."
/// - 1: filled cup (default tint) — "1 cup logged."
/// - 2: filled cup + steam (default tint) — "2 cups logged."
/// - 3: bolt/lightning (default tint) — "3 cups logged. Energized."
/// - 4: exclamation triangle (warning) — "4 cups logged. Warning."
/// - 5+: skull (danger) — "{N} cups logged. Danger."
@available(macOS 14.0, *)
struct IconRenderer {

    // MARK: - Public API

    /// Returns the SF Symbol name for the given cup count (Reqs 1.1–1.7).
    /// Each escalation state uses a distinct shape to ensure color independence (Req 27.1).
    static func systemImageName(for count: Int) -> String {
        switch count {
        case 0:
            return "cup.and.saucer"
        case 1:
            return "cup.and.saucer.fill"
        case 2:
            return "smoke.fill"
        case 3:
            return "bolt.fill"
        case 4:
            return "exclamationmark.triangle.fill"
        default:
            return "skull.fill"
        }
    }

    /// Returns the menu bar icon as a template `NSImage` for the given cup count (Req 1.8).
    /// Template rendering ensures proper appearance in both Light and Dark menu bars.
    static func icon(for count: Int) -> NSImage {
        let symbolName = systemImageName(for: count)
        let accessibilityDesc = accessibilityLabel(for: count)

        let image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: accessibilityDesc
        ) ?? NSImage()

        // Apply a point size configuration for consistent menu bar sizing
        let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let configured = image.withSymbolConfiguration(config) ?? image

        // Template mode ensures the system renders the icon correctly
        // in both light and dark menu bars (Req 1.8)
        configured.isTemplate = true

        return configured
    }

    /// Returns the tint color for the given cup count.
    /// Color is a secondary signal — shape is primary (Req 27.1).
    /// States 0–3 use default/system colors; 4 uses warning; 5+ uses danger.
    static func tint(for count: Int) -> Color {
        switch count {
        case 0:
            return Color.gray
        case 1, 2, 3:
            return Color.primary
        case 4:
            return Color("status.warning")
        default:
            return Color("status.danger")
        }
    }

    /// Returns the VoiceOver accessibility label for the menu bar icon (Req 29.2).
    /// Includes cut-off warning when `isInCutoff` is true (Req 19.2).
    static func accessibilityLabel(for count: Int, isInCutoff: Bool = false) -> String {
        var label: String

        switch count {
        case 0:
            label = "CaffeineBar. No cups logged."
        case 1:
            label = "CaffeineBar. 1 cup logged."
        case 2:
            label = "CaffeineBar. 2 cups logged."
        case 3:
            label = "CaffeineBar. 3 cups logged. Energized."
        case 4:
            label = "CaffeineBar. 4 cups logged. Warning."
        default:
            label = "CaffeineBar. \(count) cups logged. Danger."
        }

        if isInCutoff {
            label += " Approaching cut-off."
        }

        return label
    }
}
