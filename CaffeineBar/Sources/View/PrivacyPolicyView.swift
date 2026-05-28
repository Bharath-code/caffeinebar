//
//  PrivacyPolicyView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 43.1, 43.2, 43.3
//  In-app privacy policy view accessible from SettingsView.
//

import SwiftUI

/// Displays the CaffeineBar privacy policy in a scrollable view.
/// Accessible from SettingsView via a navigation link or sheet presentation.
/// The same text is hosted at https://caffeinebar.app/privacy
@available(macOS 14.0, *)
struct PrivacyPolicyView: View {

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text("Privacy Policy")
                    .font(.system(.title, weight: .bold))
                    .padding(.bottom, 4)

                // No telemetry
                sectionView(
                    title: "No Telemetry or Analytics",
                    body: "CaffeineBar does not collect any telemetry, analytics, crash reports, or usage data. There are no tracking pixels, no third-party SDKs that phone home, and no anonymous usage statistics. Your coffee habits are yours alone."
                )

                // Local data storage
                sectionView(
                    title: "All Data Stored Locally",
                    body: "All logged data — your cup count, timestamps, streak statistics, and preferences — is stored locally on your Mac using UserDefaults. Nothing leaves your machine unless you explicitly choose to enable iCloud sync in a future Ultra update."
                )

                // Keychain
                sectionView(
                    title: "License Key Storage",
                    body: "If you purchase CaffeineBar Pro or Ultra, your license key is stored exclusively in the macOS Keychain. It is never written to UserDefaults, never stored in a plaintext file, and never transmitted anywhere other than the license validation endpoint."
                )

                // Network calls
                sectionView(
                    title: "Network Usage",
                    body: "The only network call CaffeineBar makes is a periodic license validation check to Polar.sh (approximately once per week). This check verifies that your license key is still valid. No personal data, usage data, or cup-logging data is included in this request."
                )

                // No third-party sharing
                sectionView(
                    title: "No Data Shared with Third Parties",
                    body: "CaffeineBar does not share any data with third parties. There are no ad networks, no analytics providers, and no data brokers involved."
                )

                // Contact
                sectionView(
                    title: "Contact",
                    body: "If you have questions about this privacy policy, contact us at privacy@caffeinebar.app."
                )

                // Web link
                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Text("This policy is also available at:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Link("caffeinebar.app/privacy", destination: URL(string: "https://caffeinebar.app/privacy")!)
                        .font(.caption)
                }

                // Last updated
                Text("Last updated: June 2025")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 8)
            }
            .padding(24)
        }
        .frame(width: 440, height: 480)
    }

    // MARK: - Helpers

    /// Renders a titled section with body text.
    private func sectionView(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline, weight: .semibold))
            Text(body)
                .font(.system(.body))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
