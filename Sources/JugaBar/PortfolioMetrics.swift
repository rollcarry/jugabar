import Foundation

public enum PortfolioMetrics {
    public static func stockValue(stocks: [Stock], exchangeRate: Double) -> Double {
        stocks.reduce(0) {
            let value = $1.totalValue
            return $0 + ($1.marketType == "US" ? value * exchangeRate : value)
        }
    }

    public static func totalValue(stocks: [Stock], cashBalance: Double, exchangeRate: Double) -> Double {
        stockValue(stocks: stocks, exchangeRate: exchangeRate) + cashBalance
    }

    public static func dailyGain(stocks: [Stock], exchangeRate: Double) -> Double {
        stocks.reduce(0) {
            let value = $1.dailyGain
            return $0 + ($1.marketType == "US" ? value * exchangeRate : value)
        }
    }

    public static func totalReturn(stocks: [Stock], exchangeRate: Double) -> Double {
        stocks.reduce(0) {
            let value = $1.totalGain ?? 0.0
            return $0 + ($1.marketType == "US" ? value * exchangeRate : value)
        }
    }

    public static func hasHoldings(stocks: [Stock], market: String) -> Bool {
        stocks.contains { ($0.marketType ?? "KS") == market && ($0.quantity ?? 0) > 0 }
    }

    public static func userPerformance(stocks: [Stock], market: String) -> Double {
        let filteredStocks = stocks.filter { ($0.marketType ?? "KS") == market && ($0.quantity ?? 0) > 0 }
        guard !filteredStocks.isEmpty else { return 0.0 }

        let totalValue = filteredStocks.reduce(0) { $0 + $1.totalValue }
        guard totalValue > 0 else { return 0.0 }

        return filteredStocks.reduce(0) { result, stock in
            let weight = stock.totalValue / totalValue
            return result + stock.currentChangeRateDouble * weight
        }
    }
}
