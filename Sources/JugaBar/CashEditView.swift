import SwiftUI

struct CashEditView: View {
    @ObservedObject var stockService: StockService
    @Binding var isPresented: Bool

    @State private var amount: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cash")
                .font(.headline)

            Divider()

            VStack(alignment: .leading) {
                Text("Available Cash")
                    .font(.caption)
                TextField("0", text: $amount)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(save)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }

                Spacer()

                Button("Save", action: save)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            amount = Int(stockService.cashBalance).formattedWithSeparator
        }
    }

    private var parsedAmount: Double {
        let clean = amount.replacingOccurrences(of: ",", with: "")
        return Double(clean) ?? 0
    }

    private func save() {
        stockService.cashBalance = max(0, parsedAmount)
        isPresented = false
    }
}
