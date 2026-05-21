import SwiftUI

// Pill-shaped status label: tinted background + coloured text.
struct StatusBadge: View {
    let status: LeadStatus

    var body: some View {
        Text(status.shortLabel.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .tracking(0.5)
            .foregroundStyle(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.color.opacity(0.13), in: Capsule())
    }
}
