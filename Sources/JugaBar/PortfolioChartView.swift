import SwiftUI
import Charts
import JugaBarCore

struct PortfolioChartView: View {
    @ObservedObject var stockService: StockService
    @Binding var showChart: Bool

    private var allocationItems: [PortfolioAllocationItem] {
        var items = stockService.stocks.compactMap { stock -> PortfolioAllocationItem? in
            guard (stock.quantity ?? 0) > 0 else { return nil }
            let value = (stock.marketType == "US") ? stock.totalValue * stockService.exchangeRate : stock.totalValue
            return PortfolioAllocationItem(name: stock.name, value: value, isCash: false)
        }

        if stockService.cashBalance > 0 {
            items.append(PortfolioAllocationItem(name: "Cash", value: stockService.cashBalance, isCash: true))
        }

        return items
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Chart
            if stockService.totalPortfolioValue > 0 {
                Chart(allocationItems) { item in
                    SectorMark(
                        angle: .value("Value", item.value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Name", item.name))
                    .cornerRadius(5)
                }
                .frame(height: 350)
                .chartLegend(.hidden)
                .padding()
                
                // Legend
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(allocationItems) { item in
                            HStack {
                                HStack(spacing: 5) {
                                    if item.isCash {
                                        Image(systemName: "banknote")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }

                                    Text(item.name)
                                }
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(Int(item.value).formattedWithSeparator) 원")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                Text("\(String(format: "%.1f", (item.value / stockService.totalPortfolioValue) * 100))%")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            } else {
                Spacer()
                Text("No portfolio data available.")
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Spacer()
            
            Button("Done") {
                withAnimation {
                    showChart = false
                }
            }
            .frame(maxWidth: .infinity)
            .controlSize(.regular)
            .padding()
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct PortfolioAllocationItem: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let isCash: Bool
}
