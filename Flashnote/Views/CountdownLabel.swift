import SwiftUI
import Combine

/// Shows a live countdown string like "in 2h" or "in 15m"
struct CountdownLabel: View {
    let date: Date
    @State private var now = Date()

    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        Label(countdownText, systemImage: "clock")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.ultraThinMaterial, in: Capsule())
            .onReceive(timer) { _ in now = Date() }
    }

    private var countdownText: String {
        let diff = date.timeIntervalSince(now)
        guard diff > 0 else { return "done" }

        let minutes = Int(diff / 60)
        let hours   = minutes / 60
        let days    = hours / 24

        if days >= 1   { return "in \(days)d" }
        if hours >= 1  { return "in \(hours)h" }
        return "in \(minutes)m"
    }
}
