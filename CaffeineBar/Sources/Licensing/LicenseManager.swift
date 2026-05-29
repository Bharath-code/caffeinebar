//
//  LicenseManager.swift
//  CaffeineBar
//
//  Security & Licensing Agent — Requirements: 34, 38, 39, 40, 41, 42, 43
//  Full Keychain-backed implementation (Tasks 10.1, 10.2, 10.3).
//

import Foundation
import Observation
import Security
import os.log

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

// MARK: - CachedValidation

/// Metadata for the offline validation cache (Req 41.1).
/// Stored in UserDefaults — this is cache metadata only, NOT the license key itself.
struct CachedValidation: Codable {
    let lastCheckDate: Date
    let tier: LicenseTier
}

// MARK: - LicenseManager

/// Observable license state container with Keychain-backed persistence
/// and client-side ECDSA signature verification.
@available(macOS 14.0, *)
@MainActor
@Observable
final class LicenseManager {

    // MARK: - Constants

    private static let keychainService = "app.caffeinebar.license"
    private static let keychainAccount = "polar.sh"
    private static let cacheKey = "caffeinebar.licenseCache"

    /// Cache validity: 30 days (Req 41.1).
    private static let cacheMaxAgeDays: Int = 30
    /// Background re-check interval: 7 days (Req 41.2).
    private static let recheckIntervalDays: Int = 7

    /// Placeholder ECDSA P-256 public key (base64-encoded DER/X9.63 format).
    /// Replace with the real Polar.sh public key before production.
    private static let embeddedPublicKeyBase64 = "BFqKz+VKem2jGVMxV0sLbqH7fMPQDzKMmFm7+JG0CBx8yJK3nKf0ZbXDBYJaGOLxhQ2bNRFwVp+sMbXKEhPxPGk="

    private static let logger = Logger(subsystem: "app.caffeinebar", category: "LicenseManager")

    // MARK: - Public State

    /// The current resolved license tier. Defaults to `.free`.
    /// Views react immediately to changes — no restart required (Req 23.3).
    private(set) var resolvedTier: LicenseTier = .free

    // MARK: - Private State

    /// The cached validation metadata (last check date + tier).
    private var cachedValidation: CachedValidation?

    /// Weekly background re-check timer (Req 41.2).
    private var recheckTimer: Timer?

    // MARK: - Init

    init() {
        // Restore cached validation from UserDefaults
        loadCache()
        // On init, check Keychain for existing key and validate to restore tier
        restoreTierFromKeychain()
        // Schedule weekly background re-check timer (Req 41.2)
        scheduleRecheckTimer()
    }

    // MARK: - Dev Mode Tier Override

    /// Sets the tier directly (for development/testing).
    /// Used by SettingsView for dev builds.
    func setTier(_ tier: LicenseTier) {
        resolvedTier = tier
    }

    // MARK: - Public API

    /// Validates a license key and stores it in the Keychain.
    /// On success: stores in Keychain, sets resolvedTier, returns .success(tier).
    /// On failure: returns .invalidSignature or .malformed, tier stays .free.
    func validateAndStore(licenseKey: String) async -> ValidationResult {
        // First try dev key validation (for testing)
        if let tier = validateDevKey(licenseKey) {
            writeToKeychain(licenseKey)
            resolvedTier = tier
            saveCache(tier: tier)
            return .success(tier)
        }

        // Parse as JSON payload
        guard let data = licenseKey.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .malformed
        }

        // Extract required fields
        guard let tierString = json["tier"] as? String,
              let _ = json["email"] as? String,
              let _ = json["issued"] as? String,
              let signatureBase64 = json["signature"] as? String else {
            return .malformed
        }

        // Parse tier
        guard let tier = parseTier(tierString) else {
            return .malformed
        }

        // Decode signature
        guard let signatureData = Data(base64Encoded: signatureBase64) else {
            return .malformed
        }

        // Compute canonical payload (all fields except signature, sorted keys, UTF-8)
        let canonicalPayload = computeCanonicalPayload(json: json)
        guard let payloadData = canonicalPayload.data(using: .utf8) else {
            return .malformed
        }

        // Verify ECDSA signature
        guard let publicKey = loadEmbeddedPublicKey() else {
            return .invalidSignature
        }

        if verifySignature(publicKey: publicKey, payload: payloadData, signature: signatureData) {
            writeToKeychain(licenseKey)
            resolvedTier = tier
            saveCache(tier: tier)
            return .success(tier)
        } else {
            return .invalidSignature
        }
    }

    /// Performs a background re-check of the cached license (Req 41.1, 41.2, 41.3).
    /// - Cache > 30 days old → degrade to .free
    /// - Cache > 7 days old → attempt re-validation from Keychain
    /// - Re-validation fails → degrade to .free
    /// Degradation NEVER deletes data (Req 41.4).
    func performBackgroundRecheck() async {
        guard let cache = cachedValidation else {
            // No cache means no prior successful validation — stay at current tier
            return
        }

        let now = Date()
        let daysSinceLastCheck = Calendar.current.dateComponents(
            [.day], from: cache.lastCheckDate, to: now
        ).day ?? 0

        // Cache expired (> 30 days) → degrade to .free (Req 41.1)
        if daysSinceLastCheck > Self.cacheMaxAgeDays {
            Self.logger.info("License cache expired (\(daysSinceLastCheck) days). Degrading to .free.")
            degradeToFree()
            return
        }

        // Cache stale (> 7 days) → attempt re-validation from Keychain (Req 41.2)
        if daysSinceLastCheck > Self.recheckIntervalDays {
            Self.logger.info("License cache stale (\(daysSinceLastCheck) days). Attempting re-validation.")
            let revalidationSucceeded = revalidateFromKeychain()
            if revalidationSucceeded {
                // Re-validation passed — cache is refreshed inside revalidateFromKeychain()
                Self.logger.info("Re-validation succeeded. Tier: \(String(describing: self.resolvedTier))")
            } else {
                // Revocation or invalid key → degrade to .free (Req 41.3)
                Self.logger.info("Re-validation failed. Degrading to .free.")
                degradeToFree()
            }
        }
        // If < 7 days, no action needed — tier remains as cached
    }

    // MARK: - Dev Key Validation

    /// Accepts special dev keys for testing purposes.
    /// "DEV-PRO" → .pro, "DEV-ULTRA" → .ultra
    /// ⚠️ Only available in DEBUG builds — stripped from release.
    func validateDevKey(_ key: String) -> LicenseTier? {
        #if DEBUG
        switch key.uppercased() {
        case "DEV-PRO":
            return .pro
        case "DEV-ULTRA":
            return .ultra
        default:
            return nil
        }
        #else
        return nil
        #endif
    }

    // MARK: - Types

    enum ValidationResult {
        case success(LicenseTier)
        case invalidSignature
        case malformed
    }

    // MARK: - Offline Cache (Req 41)

    /// Saves a positive validation result to UserDefaults cache.
    /// This is just cache metadata (date + tier), NOT the license key itself.
    private func saveCache(tier: LicenseTier) {
        let cache = CachedValidation(lastCheckDate: Date(), tier: tier)
        cachedValidation = cache
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: Self.cacheKey)
        }
    }

    /// Loads the cached validation metadata from UserDefaults.
    private func loadCache() {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey),
              let cache = try? JSONDecoder().decode(CachedValidation.self, from: data) else {
            cachedValidation = nil
            return
        }
        cachedValidation = cache
    }

    /// Degrades the resolved tier to `.free` without deleting any data (Req 41.4).
    /// Only the tier changes — no data is deleted, locked, or hidden.
    private func degradeToFree() {
        resolvedTier = .free
        // Clear the cache so we don't keep re-checking a stale entry
        cachedValidation = nil
        UserDefaults.standard.removeObject(forKey: Self.cacheKey)
    }

    /// Attempts to re-validate the license key stored in the Keychain.
    /// Returns `true` if re-validation succeeds, `false` otherwise.
    private func revalidateFromKeychain() -> Bool {
        guard let storedKey = readFromKeychain() else {
            return false
        }

        // Try dev key first
        if let tier = validateDevKey(storedKey) {
            resolvedTier = tier
            saveCache(tier: tier)
            return true
        }

        // Try JSON payload validation
        guard let data = storedKey.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tierString = json["tier"] as? String,
              let signatureBase64 = json["signature"] as? String,
              let signatureData = Data(base64Encoded: signatureBase64),
              let publicKey = loadEmbeddedPublicKey() else {
            return false
        }

        let canonicalPayload = computeCanonicalPayload(json: json)
        guard let payloadData = canonicalPayload.data(using: .utf8) else {
            return false
        }

        if verifySignature(publicKey: publicKey, payload: payloadData, signature: signatureData) {
            let tier = parseTier(tierString) ?? .free
            resolvedTier = tier
            saveCache(tier: tier)
            return tier != .free
        } else {
            return false
        }
    }

    // MARK: - Timer Scheduling (Req 41.2)

    /// Schedules a weekly timer to call `performBackgroundRecheck()`.
    /// Fires every 7 days to check cache staleness.
    private func scheduleRecheckTimer() {
        let interval: TimeInterval = TimeInterval(Self.recheckIntervalDays * 24 * 60 * 60) // 7 days
        recheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task {
                await self.performBackgroundRecheck()
            }
        }
    }

    // MARK: - Keychain Helpers

    /// Stores a license key string in the macOS Keychain.
    /// Uses kSecClassGenericPassword with service "app.caffeinebar.license",
    /// account "polar.sh", and kSecAttrAccessibleWhenUnlockedThisDeviceOnly.
    private func writeToKeychain(_ key: String) {
        // Delete any existing item first
        deleteFromKeychain()

        guard let keyData = key.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecAttrAccessGroup as String: "app.caffeinebar.CaffeineBar",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Self.logger.error("Keychain write failed with status: \(status)")
        }
    }

    /// Reads the stored license key from the macOS Keychain.
    /// Returns nil if no key is stored or if the read fails.
    private func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecAttrAccessGroup as String: "app.caffeinebar.CaffeineBar",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// Removes the stored license key from the macOS Keychain.
    private func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecAttrAccessGroup as String: "app.caffeinebar.CaffeineBar"
        ]

        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Signature Verification

    /// Loads the embedded ECDSA public key from the hardcoded base64 string.
    private func loadEmbeddedPublicKey() -> SecKey? {
        guard let keyData = Data(base64Encoded: Self.embeddedPublicKeyBase64) else {
            return nil
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 256
        ]

        var error: Unmanaged<CFError>?
        guard let publicKey = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error) else {
            return nil
        }

        return publicKey
    }

    /// Verifies an ECDSA signature against the given payload using the public key.
    private func verifySignature(publicKey: SecKey, payload: Data, signature: Data) -> Bool {
        var error: Unmanaged<CFError>?
        let result = SecKeyVerifySignature(
            publicKey,
            .ecdsaSignatureMessageX962SHA256,
            payload as CFData,
            signature as CFData,
            &error
        )
        return result
    }

    /// Computes the canonical payload string from a JSON dictionary.
    /// Uses JSONSerialization with .sortedKeys for deterministic output.
    /// Includes all fields except "signature".
    private func computeCanonicalPayload(json: [String: Any]) -> String {
        var filtered = json
        filtered.removeValue(forKey: "signature")

        // Use JSONSerialization with .sortedKeys for deterministic canonical form
        guard let data = try? JSONSerialization.data(
            withJSONObject: filtered,
            options: [.sortedKeys, .withoutEscapingSlashes]
        ) else {
            // Fallback: manual construction if serialization fails
            let sortedKeys = filtered.keys.sorted()
            let parts = sortedKeys.compactMap { key -> String? in
                guard let value = filtered[key] else { return nil }
                if let str = value as? String {
                    return "\"\(key)\":\"\(str)\""
                } else if let num = value as? NSNumber {
                    return "\"\(key)\":\(num)"
                }
                return "\"\(key)\":\"\(String(describing: value))\""
            }
            return "{\(parts.joined(separator: ","))}"
        }

        return String(data: data, encoding: .utf8) ?? "{}"
    }

    /// Parses a tier string into a LicenseTier value.
    private func parseTier(_ tierString: String) -> LicenseTier? {
        switch tierString.lowercased() {
        case "pro": return .pro
        case "ultra": return .ultra
        case "free": return .free
        default: return nil
        }
    }

    // MARK: - Tier Restoration

    /// Attempts to restore the license tier from a previously stored Keychain key.
    /// If a valid cache exists and is within 30 days, uses the cached tier directly.
    /// Otherwise re-validates from Keychain and updates the cache.
    private func restoreTierFromKeychain() {
        // If we have a valid cache within 30 days, trust it (Req 41.1)
        if let cache = cachedValidation {
            let daysSinceLastCheck = Calendar.current.dateComponents(
                [.day], from: cache.lastCheckDate, to: Date()
            ).day ?? 0
            if daysSinceLastCheck <= Self.cacheMaxAgeDays {
                resolvedTier = cache.tier
                return
            }
        }

        // No valid cache — re-validate from Keychain
        guard let storedKey = readFromKeychain() else {
            resolvedTier = .free
            return
        }

        // Try dev key first
        if let tier = validateDevKey(storedKey) {
            resolvedTier = tier
            saveCache(tier: tier)
            return
        }

        // Try JSON payload validation
        guard let data = storedKey.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tierString = json["tier"] as? String,
              let signatureBase64 = json["signature"] as? String,
              let signatureData = Data(base64Encoded: signatureBase64),
              let publicKey = loadEmbeddedPublicKey() else {
            resolvedTier = .free
            return
        }

        let canonicalPayload = computeCanonicalPayload(json: json)
        guard let payloadData = canonicalPayload.data(using: .utf8) else {
            resolvedTier = .free
            return
        }

        if verifySignature(publicKey: publicKey, payload: payloadData, signature: signatureData) {
            let tier = parseTier(tierString) ?? .free
            resolvedTier = tier
            saveCache(tier: tier)
        } else {
            resolvedTier = .free
        }
    }

    // MARK: - Display Helpers

    /// Human-readable name for the current tier.
    var tierDisplayName: String {
        switch resolvedTier {
        case .free: return "Free"
        case .pro: return "Pro"
        case .ultra: return "Ultra"
        }
    }

    /// SF Symbol for the current tier.
    var tierIcon: String {
        switch resolvedTier {
        case .free: return "cup.and.saucer"
        case .pro: return "star.fill"
        case .ultra: return "bolt.shield.fill"
        }
    }

    /// Color for the current tier badge.
    var tierColor: String {
        switch resolvedTier {
        case .free: return "secondary"
        case .pro: return "orange"
        case .ultra: return "purple"
        }
    }
}
