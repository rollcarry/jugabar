import SwiftUI
import JugaBarCore

struct CashRow: View {
    let amount: Double
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "banknote")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("Cash")
                        .font(.system(size: 13, weight: .medium))
                }

                Text("Available")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(width: 140, alignment: .leading)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(amount).formattedWithSeparator) 원")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)

                Text("0 원")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .contextMenu {
            Button("Edit Cash", action: onEdit)
        }
    }
}
