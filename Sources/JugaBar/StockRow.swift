import SwiftUI
import JugaBarCore

struct StockRow: View {
    let stock: Stock
    let isPortfolioMode: Bool
    let onEdit: () -> Void
    
    var currencyPrefix: String {
        return stock.marketType == "US" ? "$" : ""
    }
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.system(size: 13, weight: .medium))
                
                if isPortfolioMode, let quantity = stock.quantity, quantity > 0 {
                    HStack(spacing: 4) {
                        Text("\(quantity) shares")
                        if let avg = stock.averagePrice {
                            Text("@\(currencyPrefix)\(Int(avg).formattedWithSeparator)") // US stocks often have decimals, Int might truncate cents.
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                } else {
                    Text(stock.id)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 140, alignment: .leading)
            .contentShape(Rectangle())
            // No tap gesture here anymore
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if stock.isMainOpen {
                    // Only KRX during main hours
                    Text(currencyPrefix + stock.price)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(colorFor(stock: stock))
                } else if let nxtPrice = stock.nxtPrice {
                    // Both during non-main hours if NXT data exists (even if NXT is now closed)
                    HStack(spacing: 4) {
                        if stock.isNxtOpen {
                            Text("NXT")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(3)
                        } else {
                            Text("NXT·F")
                                .font(.system(size: 8, weight: .heavy))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(3)
                        }
                        
                        Text(currencyPrefix + nxtPrice)
                            .font(.system(size: 13, weight: .bold))
                        
                        let nxtRate = stock.nxtChangeRate ?? stock.changeRate
                        Text("\(nxtRate)%")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(colorFor(stock: stock))
                    
                    // KRX Secondary
                    Text("KRX \(stock.price) (\(stock.changeRate)%)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                } else {
                    // Default to KRX if no NXT data
                    Text(currencyPrefix + stock.price)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(colorFor(stock: stock))
                }
                
                if isPortfolioMode, let quantity = stock.quantity, quantity > 0 {
                    Text("\(currencyPrefix)\(Int(stock.totalValue).formattedWithSeparator)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)

                    if stock.isMainOpen {
                        if let totalGain = stock.totalGain {
                            Text((totalGain > 0 ? "+" : "") + "\(currencyPrefix)\(Int(totalGain).formattedWithSeparator)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(totalGain > 0 ? .red : (totalGain < 0 ? .blue : .primary))
                        } else {
                            let gain = stock.dailyGain
                            Text((gain > 0 ? "+" : "") + "\(currencyPrefix)\(Int(gain).formattedWithSeparator)")
                                .font(.system(size: 11))
                                .foregroundColor(gain > 0 ? .red : (gain < 0 ? .blue : .primary))
                        }
                    } else if stock.nxtPrice != nil {
                        // Show NXT Gain Primary, KRX Gain Secondary (even after 8:00 PM)
                        VStack(alignment: .trailing, spacing: 0) {
                            let totalGain = stock.totalGain ?? 0
                            
                            Text((totalGain > 0 ? "+" : "") + "\(currencyPrefix)\(Int(totalGain).formattedWithSeparator)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(totalGain > 0 ? .red : (totalGain < 0 ? .blue : .primary))
                            
                            if let krxTotal = stock.krxTotalGain {
                                Text("KRX \(Int(krxTotal).formattedWithSeparator)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        // Closed - show final KRX
                        if let totalGain = stock.totalGain {
                            Text((totalGain > 0 ? "+" : "") + "\(currencyPrefix)\(Int(totalGain).formattedWithSeparator)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(totalGain > 0 ? .red : (totalGain < 0 ? .blue : .primary))
                        }
                    }
                } else if stock.isMainOpen {
                    // Only show percentage here when not in portfolio mode during main hours
                    Text("\(stock.changeRate)%")
                        .font(.system(size: 11))
                        .foregroundColor(colorFor(stock: stock))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorFor(stock: Stock) -> Color {
        if !stock.isMainOpen && stock.nxtPrice != nil {
            let nxtRate = stock.nxtChangeRateDouble
            if nxtRate > 0 { return .red }
            if nxtRate < 0 { return .blue }
            return .primary
        }
        let rate = stock.changeRateDouble
        if rate > 0 { return .red }
        if rate < 0 { return .blue }
        return .primary
    }
}
