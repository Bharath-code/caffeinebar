//
//  LicenseManager.swift
//  CaffeineBar
//
//  Security & Licensing Agent — Requirements: 34, 38, 39, 40, 41, 42, 43
//  Stub implementation for Task 1.4. Full implementation in Task 10.1.
//

import Foundation
import Observation

// MARK: - LicenseTier

/// The resolved license tier. Ultra strictly supersedes Pro:
/// any `>= .pro` check passes for `.ultra`.
enum LicenseTier: Int, Comparable, Codable, Sendable {
    case free = 0
    case pro = 1
    case ultra = 2

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - LicenseManager

/// Observable license state container.
/// Full Keychain-backed implementation deferred to Task 10.1.
/// This stub provides the `resolvedTier` property so that views and
/// gating logic can be wired up immediately.
@available(macOS 14.0, *)
@Observable
final class LicenseManager {

    /// The current resolved license tier. Defaults to `.free`.
    /// Views react immediately to changes — no restart required (Req 23.3).
    private(set) var resolvedTier: LicenseTier = .free

    // MARK: - Stub API (full implementation in Task 10.1–10.3)

    /// Validates a license key and stores it in the Keychain.
    /// Stub: always returns `.free` until real signature verification is implemented.
    func validateAndStore(licenseKey: String) async -> ValidationResult {
        // Full implementation in Task 10.2
        return .invalidSignature
    }

    /// Performs a background re-check of the cached license.
    /// Stub: no-op until real offline cache is implemented.
    func performBackgroundRecheck() async {
        // Full implementation in Task 10.3
    }

    // MARK: - Types

    enum ValidationResult {
        case success(LicenseTier)
        case invalidSignature
        case malformed
    }
}
