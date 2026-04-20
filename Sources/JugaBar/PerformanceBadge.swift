import SwiftUI

struct PerformanceBadge: View {
    let title: String
    let user: Double
    let market: Double
    let isOpen: Bool
    
    var isWin: Bool { user > market }
    var hasHoldings: Bool { abs(user) > 0.0001 }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            if hasHoldings {
                if isOpen {
                    Text(isWin ? "🏆 WIN" : "📉 LOSS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(isWin ? .orange : .secondary)
                    
                    Text(String(format: "%+.1f%%", user - market))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isWin ? .red : .blue)
                } else {
                    Text("CLOSED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%+.1f%%", user - market))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            } else {
                Text("-")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(hasHoldings && isOpen ? (isWin ? Color.orange.opacity(0.1) : Color.clear) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(hasHoldings && isOpen && isWin ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}
