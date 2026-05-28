//
//  ShareCardView.swift
//  CaffeineBar
//
//  SwiftUI Frontend Agent — Requirements: 7.1, 7.2, 7.3, 7.4
//  Offscreen-rendered streak card copied to NSPasteboard as high-DPI PNG.
//

import SwiftUI
import AppKit

/// A shareable streak card that renders the user's coffee stats as a visually
/// appealing image and copies it to the system pasteboard.
///
/// - Renders offscreen via `ImageRenderer` at native scale (Req 7.1).
/// - Includes: cup count, streakDays, personalRecord, `caffeinebar.app` watermark (Req 7.2).
/// - Writes PNG to `NSPasteboard.general` (Req 7.3).
/// - Hidden behind Pro gate for Free users (Req 7.4 — parent handles gating).
@available(macOS 14.0, *)
struct ShareCardView: View {

    let cupCount: Int
    let streakDays: Int
    let personalRecord: Int

    var body: some View {
        cardContent
    }

    // MARK: - Card Content

    /// The visual card layout rendered both on-screen and offscreen.
    private var cardContent: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("CaffeineBar")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white.opacity(0.9))

            // Hero cup count
            VStack(spacing: 4) {
                Text("\(cupCount)")
                    .font(.system(size: 64, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(cupCount == 1 ? "cup today" : "cups today")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }

            // Stats row
            HStack(spacing: 24) {
                statItem(value: "\(streakDays)", label: "day streak")
                statItem(value: "\(personalRecord)", label: "record")
            }
            .padding(.top, 4)

            Spacer(minLength: 8)

            // Watermark (Req 7.2)
            Text("caffeinebar.app")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
        .frame(width: 280, height: 320)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.12, blue: 0.20),
                            Color(red: 0.08, green: 0.06, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Stat Item

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Render to Pasteboard (Reqs 7.1, 7.3)

    /// Renders the card offscreen via `ImageRenderer` at native scale and writes
    /// the resulting PNG to `NSPasteboard.general`.
    @MainActor
    func renderToPasteboard() {
        let renderer = ImageRenderer(content: cardContent)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2.0

        guard let nsImage = renderer.nsImage else { return }

        guard let tiffData = nsImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(pngData, forType: .png)
    }
}
