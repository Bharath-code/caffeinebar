//
//  PriceVariant.swift
//  CaffeineBar
//
//  Security & Licensing Agent — Requirements: 42.1, 42.2, 42.3, 42.4
//  A/B price test build flag with local conversion-event counter.
//  Task 10.4.
//

import Foundation

// MARK: - PriceVariant

/// A/B price variant for the Pro tier.
///
/// Since SPM doesn't easily support Xcode-style build flags, the variant is
/// controlled via a simple static let. Change `current` to "7.99" for the
/// alternate A/B test cohort before building.
///
/// - Requirement 42.1: Build flag `PRICE_VARIANT` = "7.99" or "9.99".
/// - Requirement 42.2: Displays matching price in SettingsView.
/// - Requirement 42.3: Persists local conversion-event count per variant.
/// - Requirement 42.4: Resolution at +48 hours per launch spec arithmetic decision rule.
enum PriceVariant {

    // MARK: - Build Flag

    /// The active price variant. Change to "7.99" for the A/B test alternate cohort.
    static let current: String = "9.99"

    // MARK: - Display

    /// Formatted price string for display (e.g., "$9.99").
    static var priceString: String {
        "$\(current)"
    }

    /// The variant identifier used for UserDefaults keying.
    static var variantID: String {
        current
    }

    // MARK: - Conversion Counter (Req 42.3)

    /// UserDefaults key for the conversion count, scoped to the active variant.
    /// Format: "caffeinebar.conversionCount.{variant}"
    private static var conversionCountKey: String {
        "caffeinebar.conversionCount.\(variantID)"
    }

    /// Records a conversion event for the current price variant.
    /// Called when a user successfully activates a Pro license.
    static func recordConversion() {
        let count = UserDefaults.standard.integer(forKey: conversionCountKey)
        UserDefaults.standard.set(count + 1, forKey: conversionCountKey)
    }

    /// The number of conversion events recorded for the current price variant.
    static var conversionCount: Int {
        UserDefaults.standard.integer(forKey: conversionCountKey)
    }
}
