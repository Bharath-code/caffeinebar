//
//  ProGateOverlay.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 23.1, 23.2, 23.3
//  Reusable blur gate for Pro-tier features.
//

import SwiftUI

/// A view modifier that overlays content with `.ultraThinMaterial` and an
/// "Unlock Pro" CTA when the user's tier is below Pro.
///
/// - When `tier < .pro`: content is blurred with a material overlay and lock icon.
/// - When `tier >= .pro`: content renders normally with no overlay.
/// - Since `LicenseManager.resolvedTier` is `@Observable`, the overlay disappears
///   immediately on tier upgrade — no restart required (Req 23.3).
/// - This modifier never deletes or hides logged data (Req 23.2).
@available(macOS 14.0, *)
struct ProGateOverlay: ViewModifier {

    let tier: LicenseTier

    func body(content: Content) -> some View {
        content
            .overlay {
                if tier < .pro {
                    ZStack {
                        Rectangle()
                            .fill(.ultraThinMaterial)

                        VStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.system(.title3))
                                .foregroundStyle(.secondary)

                            Text("Unlock Pro")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
    }
}

// MARK: - View Extension

@available(macOS 14.0, *)
extension View {
    /// Applies the Pro gate blur overlay when the tier is below Pro.
    /// Content is always rendered (never removed from the hierarchy),
    /// preserving logged data visibility per Req 23.2.
    func proGated(tier: LicenseTier) -> some View {
        modifier(ProGateOverlay(tier: tier))
    }
}
