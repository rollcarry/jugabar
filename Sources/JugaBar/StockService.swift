import Foundation
import Combine

struct StockInfo: Codable, Identifiable {
    var id: String { stockItem.itemCode }
    let stockItem: StockItem
}

struct StockItem: Codable {
    let itemCode: String
    let stockName: String
    let closePrice: String
    let compareToPreviousClosePrice: String
    let fluctuationsRatio: String
    let compareToPreviousPrice: CompToPrev
    let stockExchangeType: StockExchange?
    let marketStatus: String? // OPEN, CLOSE, etc.
    let overMarketPriceInfo: OverMarketPriceInfo?
}

struct OverMarketPriceInfo: Codable {
    let overMarketStatus: String? // OPEN, CLOSE
    let overPrice: String?
    let fluctuationsRatio: String?
    let compareToPreviousClosePrice: String?
    let compareToPreviousPrice: CompToPrev?
}

struct StockExchange: Codable {
    let code: String // KS (KOSPI) or KQ (KOSDAQ)
}

struct CompToPrev: Codable {
    let code: String
    let text: String
    
    var isRising: Bool { ["1", "2"].contains(code) }
    var isFalling: Bool { ["4", "5"].contains(code) }
}

struct Stock: Identifiable, Codable {
    let id: String
    let name: String
    let price: String
    let changeAmount: String
    let changeRate: String
    let isRising: Bool
    let isFalling: Bool
    let marketType: String? // KS or KQ
    let nxtPrice: String?
    let nxtChangeRate: String?
    let nxtChangeAmount: String?
    let isNxtRising: Bool
    let isNxtFalling: Bool
    let isNxtOpen: Bool
    let isMainOpen: Bool
    
    // Portfolio Data
    var quantity: Int?
    var averagePrice: Double?
    
    // Calculated Properties
    var currentPriceDouble: Double {
        if isNxtOpen, let nxt = nxtPrice {
            return parsePrice(nxt)
        }
        return parsePrice(price)
    }
    
    var currentChangeRateDouble: Double {
        if isNxtOpen, let nxtRate = nxtChangeRate {
            return parsePrice(nxtRate)
        }
        return parsePrice(changeRate)
    }
    
    var changeRateDouble: Double {
        return parsePrice(changeRate)
    }
    
    var changeAmountDouble: Double {
        return parsePrice(changeAmount)
    }
    
    var nxtChangeAmountDouble: Double {
        return parsePrice(nxtChangeAmount)
    }
    
    var totalValue: Double {
        guard let quantity = quantity else { return 0.0 }
        return currentPriceDouble * Double(quantity)
    }
    
    var dailyGain: Double {
        guard let quantity = quantity else { return 0.0 }
        var change = changeAmountDouble
        if isFalling && change > 0 { change = -change }
        return change * Double(quantity)
    }
    
    var nxtDailyGain: Double {
        guard let quantity = quantity else { return 0.0 }
        var change = nxtChangeAmountDouble
        if isNxtFalling && change > 0 { change = -change }
        return change * Double(quantity)
    }
    
    var totalGain: Double? {
        guard let quantity = quantity, let avg = averagePrice else { return nil }
        return (currentPriceDouble - avg) * Double(quantity)
    }
    
    var krxTotalGain: Double? {
        guard let quantity = quantity, let avg = averagePrice else { return nil }
        let krxPrice = parsePrice(price)
        return (krxPrice - avg) * Double(quantity)
    }

    private func parsePrice(_ string: String?) -> Double {
        guard let string = string else { return 0.0 }
        let clean = string.replacingOccurrences(of: ",", with: "")
        return Double(clean) ?? 0.0
    }
}

struct PortfolioItem: Codable {
    let quantity: Int
    let averagePrice: Double?
}

struct MarketValueResponse: Codable {
    let stocks: [MarketStock]
}

struct MarketStock: Codable {
    let itemCode: String
    let stockName: String
}

struct YahooChartResponse: Codable {
    let chart: YahooChartResult
}

struct YahooChartResult: Codable {
    let result: [YahooChartMetaWrapper]?
    let error: YahooError?
}

struct YahooError: Codable {
    let code: String
    let description: String
}

struct YahooChartMetaWrapper: Codable {
    let meta: YahooMeta
}

struct YahooMeta: Codable {
    let symbol: String
    let regularMarketPrice: Double
    let previousClose: Double?
    let chartPreviousClose: Double?
    let longName: String?
    let shortName: String?
    let instrumentType: String?
}

struct YahooSearchResponse: Codable {
    let quotes: [YahooQuote]
}

struct YahooQuote: Codable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let quoteType: String?
    let exchange: String?
}

struct SearchResult: Identifiable {
    let id: String
    let code: String
    let name: String
    let marketType: String?
}

struct ExchangeRateResponse: Codable {
    let exchangeInfo: ExchangeInfo
}

struct ExchangeInfo: Codable {
    let closePrice: String
}

@MainActor
class StockService: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var marketIndices: [Stock] = []
    @Published var isMarketOpen: Bool = false
    @Published var isMainMarketOpen: Bool = false
    @Published var exchangeRate: Double = 1.0 // USD to KRW
    @Published var refreshInterval: Double {
        didSet {
            UserDefaults.standard.set(refreshInterval, forKey: "refreshInterval")
            startTimer()
        }
    }
    
    private var portfolioStorage: [String: PortfolioItem] = [:]
    private var stockDatabase: [SearchResult] = []
    private var portfolioCodes: [String] = []
    private var timerTask: Task<Void, Never>?
    private let session = URLSession.shared
    
    private func parsePrice(_ string: String?) -> Double {
        guard let string = string else { return 0.0 }
        let clean = string.replacingOccurrences(of: ",", with: "")
        return Double(clean) ?? 0.0
    }
    
    var totalPortfolioValue: Double {
        stocks.reduce(0) {
            let val = $1.totalValue
            return $0 + ($1.marketType == "US" ? val * exchangeRate : val)
        }
    }
    
    var totalDailyGain: Double {
        stocks.reduce(0) {
            let val = $1.dailyGain
            return $0 + ($1.marketType == "US" ? val * exchangeRate : val)
        }
    }
    
    var totalNxtDailyGain: Double {
        stocks.reduce(0) {
            let val = $1.nxtDailyGain
            return $0 + ($1.marketType == "US" ? val * exchangeRate : val)
        }
    }
    
    var totalReturn: Double {
        stocks.reduce(0) {
            let val = $1.totalGain ?? 0.0
            return $0 + ($1.marketType == "US" ? val * exchangeRate : val)
        }
    }
    
    var totalKrxReturn: Double {
        stocks.reduce(0) {
            let val = $1.krxTotalGain ?? 0.0
            // KRX Return is strictly KRX, but if we mix, we should respect currency?
            // Actually 'krxTotalGain' was a specific property for dual-listed or main market.
            // For US stocks, this might not apply or be same as totalGain.
            // Let's assume US stocks don't have separate 'KRX' gain.
            if $1.marketType == "US" { return $0 } // Skip US for KRX specific total? Or include converted?
            // Context: totalKrxReturn was used to show "KRX" secondary line. 
            // If I have US stocks, they shouldn't contribute to "KRX" line.
            return $0 + val
        }
    }
    
    // Performance Calculations for "Game"
    func getMarketPerformance(market: String) -> Double {
        let indexId = market == "KS" ? "KOSPI" : "KOSDAQ"
        guard let index = marketIndices.first(where: { $0.id == indexId }) else { return 0.0 }
        return index.currentChangeRateDouble
    }
    
    func getUserPerformance(market: String) -> Double {
        // Only filter stocks that match the market type (KS/KQ).
        // US stocks (marketType "US") should be ignored here as they don't belong to KOSPI/KOSDAQ.
        let filteredStocks = stocks.filter { ($0.marketType ?? "KS") == market && ($0.quantity ?? 0) > 0 }
        guard !filteredStocks.isEmpty else { return 0.0 }
        
        let totalValue = filteredStocks.reduce(0) { $0 + $1.totalValue }
        guard totalValue > 0 else { return 0.0 }
        
        // Use percentage change based on current prices (including NXT)
        var totalWeightedChange: Double = 0.0
        for stock in filteredStocks {
            let weight = stock.totalValue / totalValue
            totalWeightedChange += stock.currentChangeRateDouble * weight
        }
        return totalWeightedChange
    }
    
    init() {
        if UserDefaults.standard.object(forKey: "refreshInterval") != nil {
            self.refreshInterval = UserDefaults.standard.double(forKey: "refreshInterval")
        } else {
            self.refreshInterval = 60.0
        }
        
        migrateOldData()
        loadData()
        
        Task {
            await fetchExchangeRate() // Fetch rate first
            await fetchAll()
            await buildStockDatabase()
        }
        
        startTimer()
    }
    
    func startTimer() {
        timerTask?.cancel()
        guard refreshInterval > 0 else { return }
        
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(refreshInterval * 1_000_000_000))
                await fetchAll()
                await fetchExchangeRate() // Update rate periodically
            }
        }
    }
    
    private func fetchExchangeRate() async {
        guard let url = URL(string: "https://api.stock.naver.com/marketindex/exchange/FX_USDKRW") else { return }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            let clean = response.exchangeInfo.closePrice.replacingOccurrences(of: ",", with: "")
            if let rate = Double(clean) {
                self.exchangeRate = rate
            }
        } catch {
            print("Exchange Rate Fetch Error: \(error)")
        }
    }
    
    func addStock(code: String) {
        if !portfolioCodes.contains(code) {
            portfolioCodes.append(code)
            saveData()
            Task {
                if isUSStock(code) {
                    await fetchYahooStock(code: code)
                } else {
                    await fetchStock(code: code)
                }
            }
        }
    }
    
    func removeStock(id: String) {
        portfolioCodes.removeAll { $0 == id }
        portfolioStorage.removeValue(forKey: id)
        stocks.removeAll { $0.id == id }
        saveData()
    }
    
    func updatePortfolio(id: String, quantity: Int?, averagePrice: Double?) {
        if let q = quantity {
            portfolioStorage[id] = PortfolioItem(quantity: q, averagePrice: averagePrice)
        } else {
            portfolioStorage.removeValue(forKey: id)
        }
        
        if let index = stocks.firstIndex(where: { $0.id == id }) {
            stocks[index].quantity = quantity
            stocks[index].averagePrice = averagePrice
        }
        
        saveData()
    }
    
    func addBuy(id: String, price: Double, quantity: Int) {
        guard quantity > 0 else { return }
        
        var newQuantity = quantity
        var newAveragePrice = price
        
        if let currentItem = portfolioStorage[id] {
            let totalOldValue = (currentItem.averagePrice ?? 0.0) * Double(currentItem.quantity)
            let totalNewValue = price * Double(quantity)
            let totalQuantity = currentItem.quantity + quantity
            
            newQuantity = totalQuantity
            newAveragePrice = (totalOldValue + totalNewValue) / Double(totalQuantity)
        }
        
        updatePortfolio(id: id, quantity: newQuantity, averagePrice: newAveragePrice)
    }
    
    func resetPortfolio() {
        portfolioStorage = [:]
        portfolioCodes = []
        stocks = []
        UserDefaults.standard.removeObject(forKey: "portfolioStockCodes")
        UserDefaults.standard.removeObject(forKey: "portfolioStorage")
        saveData()
    }
    
    func isUSStock(_ code: String) -> Bool {
        return code.rangeOfCharacter(from: .letters) != nil
    }

    func fetchAll() async {
        await fetchMarketIndices()
        for code in portfolioCodes {
            if isUSStock(code) {
                await fetchYahooStock(code: code)
            } else {
                await fetchStock(code: code)
            }
        }
    }
    
    func searchStocks(query: String) async -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        
        // Local Search (Korea)
        let localResults = stockDatabase.filter {
            $0.name.lowercased().contains(query.lowercased()) || $0.code.contains(query)
        }
        
        // Remote Search (Yahoo/US) if query has letters
        var yahooResults: [SearchResult] = []
        if query.rangeOfCharacter(from: .letters) != nil {
            yahooResults = await searchYahooStocks(query: query)
        }
        
        return localResults + yahooResults
    }
    
    private func searchYahooStocks(query: String) async -> [SearchResult] {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v1/finance/search?q=\(query)&quotesCount=5&newsCount=0") else { return [] }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(YahooSearchResponse.self, from: data)
            
            return response.quotes.compactMap { quote in
                guard let symbol = quote.symbol.split(separator: ".").first else { return nil } // remove exchange suffix if present for simplicity? No, keep it for precision if needed, but simple US tickers don't have it.
                // Actually keep full symbol if it's not simple
                let cleanSymbol = quote.symbol 
                
                return SearchResult(
                    id: cleanSymbol,
                    code: cleanSymbol,
                    name: quote.shortname ?? quote.longname ?? cleanSymbol,
                    marketType: "US"
                )
            }
        } catch {
            print("Yahoo Search Error: \(error)")
            return []
        }
    }

    private func fetchYahooStock(code: String) async {
        guard let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(code)?interval=1d&range=1d") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, _) = try await session.data(for: request)
            let response = try JSONDecoder().decode(YahooChartResponse.self, from: data)
            
            guard let result = response.chart.result?.first?.meta else { return }
            
            let currentPrice = result.regularMarketPrice
            // Calculate change from previous close
            let prevClose = result.chartPreviousClose ?? result.previousClose ?? currentPrice
            let changeAmount = currentPrice - prevClose
            let changeRate = prevClose != 0 ? (changeAmount / prevClose) * 100.0 : 0.0
            
            let isRising = changeAmount > 0
            let isFalling = changeAmount < 0
            
            // Format strings
            let priceStr = String(format: "%.2f", currentPrice)
            let changeAmountStr = String(format: "%.2f", abs(changeAmount))
            let changeRateStr = String(format: "%.2f", abs(changeRate))
            
            let portfolioItem = portfolioStorage[code]
            
            let newStock = Stock(
                id: result.symbol,
                name: result.shortName ?? result.longName ?? result.symbol,
                price: priceStr,
                changeAmount: changeAmountStr,
                changeRate: changeRateStr,
                isRising: isRising,
                isFalling: isFalling,
                marketType: "US",
                nxtPrice: nil,
                nxtChangeRate: nil,
                nxtChangeAmount: nil,
                isNxtRising: false,
                isNxtFalling: false,
                isNxtOpen: false,
                isMainOpen: true, // Simplified
                quantity: portfolioItem?.quantity,
                averagePrice: portfolioItem?.averagePrice
            )
            
            updateOrAppend(stock: newStock)
        } catch {
            print("Fetching error for \(code): \(error)")
        }
    }

    private func fetchMarketIndices() async {
        let codes = ["KOSPI", "KOSDAQ"]
        for code in codes {
            guard let url = URL(string: "https://m.stock.naver.com/api/index/\(code)/basic") else { continue }
            
            do {
                let (data, _) = try await session.data(from: url)
                let info = try JSONDecoder().decode(StockItem.self, from: data)
                
                let isRising = info.compareToPreviousPrice.isRising
                let isFalling = info.compareToPreviousPrice.isFalling
                let isMainOpen = info.marketStatus == "OPEN"
                let isNxtOpen = info.overMarketPriceInfo?.overMarketStatus == "OPEN"
                
                let index = Stock(
                    id: info.itemCode,
                    name: info.stockName,
                    price: info.closePrice,
                    changeAmount: info.compareToPreviousClosePrice,
                    changeRate: info.fluctuationsRatio,
                    isRising: isRising,
                    isFalling: isFalling,
                    marketType: code, // KOSPI or KOSDAQ
                    nxtPrice: info.overMarketPriceInfo?.overPrice,
                    nxtChangeRate: info.overMarketPriceInfo?.fluctuationsRatio,
                    nxtChangeAmount: info.overMarketPriceInfo?.compareToPreviousClosePrice,
                    isNxtRising: info.overMarketPriceInfo?.compareToPreviousPrice?.isRising ?? false,
                    isNxtFalling: info.overMarketPriceInfo?.compareToPreviousPrice?.isFalling ?? false,
                    isNxtOpen: isNxtOpen,
                    isMainOpen: isMainOpen
                )
                updateOrAppendIndex(stock: index)
            } catch {
                print("Index error for \(code): \(error)")
            }
        }
    }
    
    private func updateOrAppendIndex(stock: Stock) {
        if let index = marketIndices.firstIndex(where: { $0.id == stock.id }) {
            marketIndices[index] = stock
        } else {
            marketIndices.append(stock)
        }
        marketIndices.sort { ($0.id == "KOSPI" || $0.id == "KOSPI") && ($1.id == "KOSDAQ" || $1.id == "KOSDAQ") }
    }

    private func fetchStock(code: String) async {
        guard let url = URL(string: "https://m.stock.naver.com/api/stock/\(code)/basic") else { return }
        
        do {
            let (data, _) = try await session.data(from: url)
            let info = try JSONDecoder().decode(StockItem.self, from: data)
            
            let isRising = info.compareToPreviousPrice.isRising
            let isFalling = info.compareToPreviousPrice.isFalling
            
            let isMainOpen = info.marketStatus == "OPEN"
            let isNxtOpen = info.overMarketPriceInfo?.overMarketStatus == "OPEN"
            
            self.isMainMarketOpen = isMainOpen
            self.isMarketOpen = isMainOpen || isNxtOpen
            
            let portfolioItem = portfolioStorage[info.itemCode]
            
            let newStock = Stock(
                id: info.itemCode,
                name: info.stockName,
                price: info.closePrice,
                changeAmount: info.compareToPreviousClosePrice,
                changeRate: info.fluctuationsRatio,
                isRising: isRising,
                isFalling: isFalling,
                marketType: info.stockExchangeType?.code,
                nxtPrice: info.overMarketPriceInfo?.overPrice,
                nxtChangeRate: info.overMarketPriceInfo?.fluctuationsRatio,
                nxtChangeAmount: info.overMarketPriceInfo?.compareToPreviousClosePrice,
                isNxtRising: info.overMarketPriceInfo?.compareToPreviousPrice?.isRising ?? false,
                isNxtFalling: info.overMarketPriceInfo?.compareToPreviousPrice?.isFalling ?? false,
                isNxtOpen: isNxtOpen,
                isMainOpen: isMainOpen,
                quantity: portfolioItem?.quantity,
                averagePrice: portfolioItem?.averagePrice
            )
            
            updateOrAppend(stock: newStock)
        } catch {
            print("Fetching error for \(code): \(error)")
        }
    }
    
    private func updateOrAppend(stock: Stock) {
        if let index = stocks.firstIndex(where: { $0.id == stock.id }) {
            stocks[index] = stock
        } else {
            stocks.append(stock)
        }
        stocks.sort {
            guard let idx1 = portfolioCodes.firstIndex(of: $0.id),
                  let idx2 = portfolioCodes.firstIndex(of: $1.id) else { return false }
            return idx1 < idx2
        }
    }
    
    private func saveData() {
        UserDefaults.standard.set(portfolioCodes, forKey: "portfolioStockCodes")
        if let encoded = try? JSONEncoder().encode(portfolioStorage) {
            UserDefaults.standard.set(encoded, forKey: "portfolioStorage")
        }
    }
    
    private func migrateOldData() {
        // Migration from old keys if they exist
        if let oldCodes = UserDefaults.standard.array(forKey: "watchedStockCodes") as? [String] {
            portfolioCodes = oldCodes
            UserDefaults.standard.removeObject(forKey: "watchedStockCodes")
            saveData()
        }
    }
    
    private func loadData() {
        if let savedCodes = UserDefaults.standard.array(forKey: "portfolioStockCodes") as? [String] {
            portfolioCodes = savedCodes
        }
        
        if let savedPortfolio = UserDefaults.standard.data(forKey: "portfolioStorage"),
           let decoded = try? JSONDecoder().decode([String: PortfolioItem].self, from: savedPortfolio) {
            portfolioStorage = decoded
        }
    }
    
    private func buildStockDatabase() async {
        let markets = ["KOSPI", "KOSDAQ"]
        var allStocks: [SearchResult] = []
        for market in markets {
            for page in 1...2 {
                if let stocks = await fetchMarketPage(market: market, page: page) {
                    allStocks.append(contentsOf: stocks)
                }
            }
        }
        self.stockDatabase = allStocks
    }
    
    private func fetchMarketPage(market: String, page: Int) async -> [SearchResult]? {
        guard let url = URL(string: "https://m.stock.naver.com/api/stocks/marketValue/\(market)?page=\(page)&pageSize=100") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(MarketValueResponse.self, from: data)
            return response.stocks.map { SearchResult(id: $0.itemCode, code: $0.itemCode, name: $0.stockName, marketType: market == "KOSPI" ? "KS" : "KQ") }
        } catch {
            return nil
        }
    }
}
