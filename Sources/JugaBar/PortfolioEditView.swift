import SwiftUI
import JugaBarCore

struct PortfolioEditView: View {
    let stock: Stock
    @ObservedObject var stockService: StockService
    @Binding var isPresented: Stock?
    
    @State private var quantity: String = ""
    @State private var avgPrice: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Portfolio: \(stock.name)")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Quantity (Shares)")
                    .font(.caption)
                TextField("0", text: $quantity)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading) {
                Text("Average Buy Price (Optional)")
                    .font(.caption)
                TextField("Price per share", text: $avgPrice)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = nil
                }
                
                Spacer()
                
                Button("Save") {
                    let q = Int(quantity)
                    let p = Double(avgPrice)
                    stockService.updatePortfolio(id: stock.id, quantity: q, averagePrice: p)
                    isPresented = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            if let q = stock.quantity { quantity = String(q) }
            if let p = stock.averagePrice { avgPrice = String(Int(p)) }
        }
    }
}
