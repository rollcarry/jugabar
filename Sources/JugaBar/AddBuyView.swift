import SwiftUI
import JugaBarCore

struct AddBuyView: View {
    let stock: Stock
    @ObservedObject var stockService: StockService
    @Binding var isPresented: Stock?
    
    @State private var quantity: String = ""
    @State private var price: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Buy: \(stock.name)")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Additional Quantity")
                    .font(.caption)
                TextField("0", text: $quantity)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading) {
                Text("Buy Price (per share)")
                    .font(.caption)
                TextField("Price", text: $price)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = nil
                }
                
                Spacer()
                
                Button("Add") {
                    if let q = Int(quantity), let p = Double(price) {
                        stockService.addBuy(id: stock.id, price: p, quantity: q)
                        isPresented = nil
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(Int(quantity) == nil || Double(price) == nil)
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            // Default to current price (removing commas)
            let cleanPrice = stock.price.replacingOccurrences(of: ",", with: "")
            price = cleanPrice
        }
    }
}
