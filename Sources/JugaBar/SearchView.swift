import SwiftUI
import JugaBarCore

struct SearchView: View {
    @ObservedObject var stockService: StockService
    @Binding var showSearch: Bool
    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    
    var body: some View {
        VStack {
            TextField("Search name or code", text: $query)
                .textFieldStyle(.roundedBorder)
                .onChange(of: query) { newValue in
                    Task {
                        results = await stockService.searchStocks(query: newValue)
                    }
                }
            
            List(results) { result in
                HStack {
                    VStack(alignment: .leading) {
                        Text(result.name)
                            .font(.system(size: 13, weight: .medium))
                        Text(result.code)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Add") {
                        stockService.addStock(code: result.code)
                        showSearch = false
                        query = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .padding(10)
    }
}
