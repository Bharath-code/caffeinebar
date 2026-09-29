//
//  SoundPackRegistry.swift
//  CaffeineBar
//
//  Audio & Media Agent — Requirements: 9.1, 9.2, 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 21
//

import Foundation

// MARK: - SoundPack

/// A themed set of escalation sound assets mapped to cup counts.
struct SoundPack: Identifiable, Sendable {
    let id: String
    let displayName: String

    /// Assets for cups 1–5 (indexed 0–4). Index 0 = cup 1, etc.
    let cupAssets: [String]

    /// Chaos pool assets for cup 6+ (Pro only). Rotated via modulo.
    let chaosPool: [String]

    /// The subdirectory name inside the Sounds bundle resource folder.
    var subdirectory: String { id }
}

// MARK: - SoundPackRegistry

/// Registry of all bundled sound packs and the cup-to-sound resolution logic.
/// Satisfies Req 21 (bundled packs) and Req 10 (cup-to-sound mapping with tier gating).
@available(macOS 14.0, *)
enum SoundPackRegistry {

    // MARK: - Bundled Packs

    static let defaultPack = SoundPack(
        id: "Default",
        displayName: "Default",
        cupAssets: [
            "cup1_chime",       // Cup 1: soft chime (Free)
            "cup2_ding",        // Cup 2: approving ding (Free)
            "cup3_hmm",         // Cup 3: hmm voice (Free)
            "cup4_stethoscope", // Cup 4: stethoscope concern (Pro)
            "cup5_ambulance"    // Cup 5: ambulance siren (Pro)
        ],
        chaosPool: [
            "cup6_siren",       // Cup 6+: rotating chaos (Pro)
            "cup6_airhorn",
            "cup6_dialup",
            "cup6_wilhelm"
        ]
    )

    static let yourMomPack = SoundPack(
        id: "YourMom",
        displayName: "Your Mom",
        cupAssets: [
            "cup1_chime",
            "cup2_ding",
            "cup3_hmm",
            "cup4_stethoscope",
            "cup5_ambulance"
        ],
        chaosPool: [
            "cup6_siren",
            "cup6_airhorn",
            "cup6_dialup",
            "cup6_wilhelm"
        ]
    )

    static let gordonRamsayPack = SoundPack(
        id: "GordonRamsay",
        displayName: "Gordon Ramsay",
        cupAssets: [
            "cup1_chime",
            "cup2_ding",
            "cup3_hmm",
            "cup4_stethoscope",
            "cup5_ambulance"
        ],
        chaosPool: [
            "cup6_siren",
            "cup6_airhorn",
            "cup6_dialup",
            "cup6_wilhelm"
        ]
    )

    static let nasaPack = SoundPack(
        id: "NASA",
        displayName: "NASA Mission Control",
        cupAssets: [
            "cup1_chime",
            "cup2_ding",
            "cup3_hmm",
            "cup4_stethoscope",
            "cup5_ambulance"
        ],
        chaosPool: [
            "cup6_siren",
            "cup6_airhorn",
            "cup6_dialup",
            "cup6_wilhelm"
        ]
    )

    static let accountantPack = SoundPack(
        id: "Accountant",
        displayName: "The Accountant",
        cupAssets: [
            "cup1_chime",
            "cup2_ding",
            "cup3_hmm",
            "cup4_stethoscope",
            "cup5_ambulance"
        ],
        chaosPool: [
            "cup6_siren",
            "cup6_airhorn",
            "cup6_dialup",
            "cup6_wilhelm"
        ]
    )

    /// All bundled packs available in the app.
    static let allPacks: [SoundPack] = [
        defaultPack,
        yourMomPack,
        gordonRamsayPack,
        nasaPack,
        accountantPack
    ]

    /// Packs whose cup-1 asset has real audio. Themed packs ship as 0-byte
    /// placeholders until recorded, so they stay hidden from the picker (Req 13).
    static let availablePacks: [SoundPack] = allPacks.filter { pack in
        guard let url = assetURL(pack.cupAssets[0], pack: pack),
              let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return false }
        return size > 0
    }

    /// SwiftPM's `Bundle.module` looks for the resource bundle at the `.app` root,
    /// which only exists on the build machine. Shipped apps keep it in Contents/Resources.
    static let resources: Bundle = Bundle.main
        .url(forResource: "CaffeineBar_CaffeineBar", withExtension: "bundle")
        .flatMap(Bundle.init(url:)) ?? .module

    // MARK: - Pack Lookup

    /// Returns the pack matching the given ID, or the default pack if not found or not recorded yet.
    static func pack(for id: String) -> SoundPack {
        availablePacks.first { $0.id == id } ?? defaultPack
    }

    private static func assetURL(_ name: String, pack: SoundPack) -> URL? {
        resources.url(forResource: name, withExtension: "m4a", subdirectory: "Sounds/\(pack.subdirectory)")
    }

    // MARK: - Cup-to-Sound Resolution

    /// Resolves the sound asset URL for a given cup count, pack, and license tier.
    ///
    /// - Parameters:
    ///   - cupCount: The current cup count (1-based).
    ///   - pack: The active sound pack.
    ///   - tier: The user's resolved license tier.
    /// - Returns: The URL of the sound asset to play, or `nil` if the sound is gated
    ///   (Free tier at cup 4+) or the asset cannot be found in the bundle.
    ///
    /// Mapping (Req 10):
    /// - Cup 1: "soft chime" (Free)
    /// - Cup 2: "approving ding" (Free)
    /// - Cup 3: "hmm voice" (Free)
    /// - Cup 4: "stethoscope concern" (requires tier >= .pro)
    /// - Cup 5: "ambulance siren" (requires tier >= .pro)
    /// - Cup 6+: rotating chaos pool (requires tier >= .pro)
    static func resolveAssetURL(
        for cupCount: Int,
        pack: SoundPack,
        tier: LicenseTier
    ) -> URL? {
        guard cupCount >= 1 else { return nil }

        // Cups 4+ require Pro or Ultra (Req 10.4, 10.5, 10.6)
        if cupCount >= 4 && tier < .pro {
            return nil
        }

        let assetName: String

        if cupCount <= 5 {
            // Cups 1–5: direct index mapping (0-based array)
            let index = cupCount - 1
            guard index < pack.cupAssets.count else { return nil }
            assetName = pack.cupAssets[index]
        } else {
            // Cup 6+: rotating chaos pool via modulo (Req 10.6)
            guard !pack.chaosPool.isEmpty else { return nil }
            let chaosIndex = (cupCount - 6) % pack.chaosPool.count
            assetName = pack.chaosPool[chaosIndex]
        }

        return assetURL(assetName, pack: pack)
    }
}
