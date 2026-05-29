//
//  SettingsView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 5.2, 6.5, 11.4, 15.2, 17.1, 18.3, 19.1, 21.2, 37.2, 38.3, 38.4, 42.2, 42.3, 43.1
//  Settings form with reset hour picker, bedtime & cut-off config, metabolism profile,
//  Office Mode toggles, sound controls, license key entry, price display, streak stats, and privacy policy link.
//

import SwiftUI

/// Settings view providing the daily reset hour picker, bedtime & cut-off config,
/// Office Mode controls, and streak statistics. Presentable from the settings gear in MenuBarExtraView.
@available(macOS 14.0, *)
struct SettingsView: View {

    // MARK: - Environment

    @Environment(CupStore.self) private var store
    @Environment(LicenseManager.self) private var license

    // MARK: - State

    @State private var showingPrivacyPolicy = false

    // MARK: - Local State

    /// License key text field input (Req 38.3).
    @State private var licenseKeyInput: String = ""

    /// Whether a license validation is in progress.
    @State private var isValidating: Bool = false

    /// Result message shown after license validation attempt.
    @State private var validationMessage: String?

    // MARK: - Body

    var body: some View {
        ScrollView {
            Form {
                // Current Plan (tier switcher for dev, plan display for production)
                planSection

                // License key entry (Req 38.3, 38.4)
                licenseKeySection

                // Price display (Req 42.2, 42.3)
                priceDisplaySection

                // Reset hour picker (Req 5.2)
                resetHourSection

                // Bedtime & Cut-off (Req 19.1, 18.3)
                bedtimeCutOffSection

                // Office Mode (Req 17.1, 17.2, 17.3)
                officeModeSection

                // Sound (Req 11.4, 15.2)
                soundSection

                // Sound Packs (Req 21.1, 21.2, 21.3)
                soundPackSection

                // Streak stats (Req 6.5)
                streakStatsSection

                // iCloud sync note (Req 37.2)
                syncNoteSection

                // Privacy policy (Req 43.1)
                privacyPolicySection
            }
            .formStyle(.grouped)
        }
        .frame(width: 380, height: 600)
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }

    // MARK: - Sections

    /// Current plan display with tier switcher (dev mode).
    /// In production, this will show the plan + license key entry.
    private var planSection: some View {
        Section {
            // Current tier badge
            HStack(spacing: 10) {
                Image(systemName: license.tierIcon)
                    .font(.system(.title2))
                    .foregroundStyle(tierColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CaffeineBar \(license.tierDisplayName)")
                        .font(.system(.body, weight: .semibold))
                    Text(tierDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Tier badge pill
                Text(license.tierDisplayName.uppercased())
                    .font(.system(.caption2, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tierColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(tierColor)
                    .increasedContrastBorder()
            }
            .padding(.vertical, 4)

            // Dev-mode tier picker
            Picker("Plan", selection: Binding(
                get: { license.resolvedTier },
                set: { license.setTier($0) }
            )) {
                Text("Free").tag(LicenseTier.free)
                Text("Pro — \(PriceVariant.priceString)").tag(LicenseTier.pro)
                Text("Ultra — $14.99").tag(LicenseTier.ultra)
            }
            .pickerStyle(.segmented)

            // Feature comparison
            if license.resolvedTier == .free {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Upgrade to unlock:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    featureRow("Half-life clock", icon: "clock.arrow.circlepath")
                    featureRow("Weekly graph", icon: "chart.bar.fill")
                    featureRow("Cut-off reminders", icon: "moon.zzz.fill")
                    featureRow("4 sound packs", icon: "speaker.wave.3.fill")
                    featureRow("Share streak card", icon: "square.and.arrow.up")
                }
                .padding(.top, 4)
            }

            if license.resolvedTier == .pro {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ultra adds:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    featureRow("iCloud sync across Macs", icon: "icloud.fill")
                    featureRow("Apple Health integration", icon: "heart.fill")
                    featureRow("Siri Shortcuts", icon: "wand.and.stars")
                    featureRow("Annual Wrapped card", icon: "gift.fill")
                    featureRow("Custom sound import", icon: "waveform.badge.plus")
                }
                .padding(.top, 4)
            }

            if license.resolvedTier == .ultra {
                Label("All features unlocked", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.top, 4)
            }
        } header: {
            Text("Your Plan")
        }
    }

    /// A single feature row for the upgrade comparison.
    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(.caption2))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
        }
    }

    /// Description text for the current tier.
    private var tierDescription: String {
        switch license.resolvedTier {
        case .free: return "Basic logging + 3 free sounds"
        case .pro: return "Full escalation + analytics"
        case .ultra: return "Everything + sync + health"
        }
    }

    /// Resolved color for the current tier.
    private var tierColor: Color {
        switch license.resolvedTier {
        case .free: return .secondary
        case .pro: return .orange
        case .ultra: return .purple
        }
    }

    /// Picker for the daily reset hour, 0–23, displayed in 12-hour format.
    private var resetHourSection: some View {
        Section("Daily Reset") {
            @Bindable var store = store
            Picker("Reset Hour", selection: $store.resetHour) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(formattedHour(hour))
                        .tag(hour)
                }
            }
        }
    }

    /// Bedtime picker, metabolism profile picker, and cut-off status (Reqs 18.3, 19.1, 19.2, 19.3).
    /// Only the picker is shown for all users; the cut-off indicator is Pro/Ultra gated.
    private var bedtimeCutOffSection: some View {
        Section("Bedtime & Cut-off") {
            @Bindable var store = store
            DatePicker(
                "Bedtime",
                selection: $store.bedtime,
                displayedComponents: .hourAndMinute
            )
            .help("Target bedtime for cut-off warnings")

            // Metabolism profile picker (Req 18.3)
            Picker("Metabolism", selection: $store.metabolismProfile) {
                Text("Fast metabolizer").tag(MetabolismProfile.fast)
                Text("Normal metabolizer").tag(MetabolismProfile.normal)
                Text("Slow metabolizer").tag(MetabolismProfile.slow)
            }
            .help("Affects half-life clock and cut-off calculations")

            if license.resolvedTier >= .pro {
                if let lastLog = store.todayTimestamps.last {
                    let isBeyond = CutOffReminder.isBeyondCutOff(
                        lastLogTimestamp: lastLog,
                        profile: store.metabolismProfile,
                        bedtime: store.bedtime
                    )
                    if isBeyond {
                        Label("Caffeine will be active past bedtime", systemImage: "moon.zzz.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else {
                        Label("On track for bedtime", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Label("No cups logged today", systemImage: "cup.and.saucer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Cut-off alerts require Pro", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Office Mode toggle and haptic-only sub-option (Reqs 17.1, 17.2, 17.3).
    private var officeModeSection: some View {
        Section("Office Mode") {
            @Bindable var store = store
            Toggle("Office Mode", isOn: $store.officeMode)
                .help("Caps volume to 50% or uses haptic feedback only")

            if store.officeMode {
                Toggle("Haptic only (no audio)", isOn: $store.officeModeHapticOnly)
                    .help("Replace sound with trackpad haptic tap")
                    .padding(.leading, 20)
            }
        }
    }

    /// Mute toggle and auto-mute on calls toggle (Reqs 11.4, 15.2).
    private var soundSection: some View {
        Section("Sound") {
            @Bindable var store = store
            Toggle("Mute", isOn: $store.isMuted)
                .help("Silences all sounds. Icon still updates.")

            Toggle("Auto-mute on calls", isOn: $store.autoMuteOnCalls)
                .help("Automatically mute during calls (Zoom, FaceTime)")
        }
    }

    /// Sound pack selector, Pro-gated (Reqs 21.1, 21.2, 21.3).
    private var soundPackSection: some View {
        Section("Sound Packs") {
            @Bindable var store = store
            let isPro = license.resolvedTier >= .pro

            Picker("Sound Pack", selection: $store.selectedSoundPack) {
                ForEach(SoundPackRegistry.allPacks) { pack in
                    Text(pack.displayName)
                        .tag(pack.id)
                }
            }
            .disabled(!isPro)

            if !isPro {
                Label("Requires Pro", systemImage: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Displays streak statistics: streakDays, personalRecord, totalDaysLogged.
    private var streakStatsSection: some View {
        Section("Streak Stats") {
            LabeledContent("Current Streak") {
                Text("\(store.streakDays) \(store.streakDays == 1 ? "day" : "days")")
            }
            LabeledContent("Personal Record") {
                Text("\(store.personalRecord) \(store.personalRecord == 1 ? "cup" : "cups")")
            }
            LabeledContent("Total Days Logged") {
                Text("\(store.totalDaysLogged) \(store.totalDaysLogged == 1 ? "day" : "days")")
            }
        }
    }

    /// Informational note about streak scope and future iCloud sync.
    private var syncNoteSection: some View {
        Section {
            Text("Streaks are per macOS user account; iCloud sync coming in Ultra.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    /// License key entry field with Activate button (Reqs 38.3, 38.4).
    /// Calls `LicenseManager.validateAndStore(licenseKey:)` on activation.
    private var licenseKeySection: some View {
        Section("License Key") {
            HStack {
                TextField("Paste license key", text: $licenseKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(isValidating)

                Button {
                    activateLicense()
                } label: {
                    if isValidating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Activate")
                    }
                }
                .disabled(licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isValidating)
            }

            if let message = validationMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(
                        message.contains("✓") ? .green : .red
                    )
            }
        }
    }

    /// Price display showing the current A/B variant price (Reqs 42.2, 42.3).
    private var priceDisplaySection: some View {
        Section("Pricing") {
            LabeledContent("CaffeineBar Pro") {
                Text(PriceVariant.priceString)
                    .font(.system(.body, weight: .semibold))
            }
            Text("One-time purchase. No subscription.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Privacy policy link (Req 43.1).
    private var privacyPolicySection: some View {
        Section {
            Button {
                showingPrivacyPolicy = true
            } label: {
                HStack {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

    /// Validates and stores the license key via LicenseManager.
    private func activateLicense() {
        let key = licenseKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }

        isValidating = true
        validationMessage = nil

        Task {
            let result = await license.validateAndStore(licenseKey: key)

            await MainActor.run {
                isValidating = false
                switch result {
                case .success(let tier):
                    validationMessage = "✓ Activated: \(tier == .ultra ? "Ultra" : "Pro")"
                    licenseKeyInput = ""
                    PriceVariant.recordConversion()
                case .invalidSignature:
                    validationMessage = "✗ Invalid license key"
                case .malformed:
                    validationMessage = "✗ Malformed license key"
                }
            }
        }
    }

    /// Formats a 24-hour integer (0–23) into 12-hour display (e.g., "12:00 AM", "1:00 AM").
    private func formattedHour(_ hour: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let displayHour: Int
        switch hour {
        case 0:
            displayHour = 12
        case 1...11:
            displayHour = hour
        case 12:
            displayHour = 12
        default:
            displayHour = hour - 12
        }
        return "\(displayHour):00 \(period)"
    }
}
