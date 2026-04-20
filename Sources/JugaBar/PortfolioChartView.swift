import SwiftUI
import Charts
import JugaBarCore

struct PortfolioChartView: View {
    @ObservedObject var stockService: StockService
    @Binding var showChart: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Chart
            if stockService.totalPortfolioValue > 0 {
                Chart(stockService.stocks.filter { ($0.quantity ?? 0) > 0 }) { stock in
                    let value = (stock.marketType == "US") ? stock.totalValue * stockService.exchangeRate : stock.totalValue
                    SectorMark(
                        angle: .value("Value", value),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Name", stock.name))
                    .cornerRadius(5)
                }
                .frame(height: 350)
                .chartLegend(.hidden)
                .padding()
                
                // Legend
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(stockService.stocks.filter { ($0.quantity ?? 0) > 0 }) { stock in
                            HStack {
                                Text(stock.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                let value = (stock.marketType == "US") ? stock.totalValue * stockService.exchangeRate : stock.totalValue
                                Text("\(Int(value).formattedWithSeparator) 원")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                Text("\(String(format: "%.1f", (value / stockService.totalPortfolioValue) * 100))%")
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
