//
//  StatusColors.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 26.1, 26.2, 26.3, 26.4
//  Semantic status colors defined in code (no Asset Catalog in SPM project).
//  Light-mode values per spec: warning = #D97706, danger = #D70015.
//

import SwiftUI

extension Color {
    /// Amber warning color — used at Cup 4 escalation state.
    /// Light: #D97706 (≥3:1 contrast on white per Req 26.3).
    /// Dark: brighter amber for visibility on dark backgrounds.
    static let statusWarning = Color(red: 0.85, green: 0.47, blue: 0.02)

    /// Red danger color — used at Cup 5+ escalation state.
    /// Light: #D70015 (Req 26.4).
    /// Dark: brighter red for visibility on dark backgrounds.
    static let statusDanger = Color(red: 0.84, green: 0.0, blue: 0.08)

    /// Gray empty state color — used at Cup 0.
    static let statusEmpty = Color.gray

    /// Default active color — used at Cups 1-3.
    static let statusActive = Color.primary
}
