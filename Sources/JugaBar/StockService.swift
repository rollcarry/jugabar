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
        if isFalling { change = -change }
        return change * Double(quantity)
    }
    
    var nxtDailyGain: Double {
        guard let quantity = quantity else { return 0.0 }
        var change = nxtChangeAmountDouble
        if isNxtFalling { change = -change }
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

struct SearchResult: Identifiable {
    let id: String
    let code: String
    let name: String
    let marketType: String?
}

@MainActor
class StockService: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var marketIndices: [Stock] = []
    @Published var isMarketOpen: Bool = false
    @Published var isMainMarketOpen: Bool = false
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
        stocks.reduce(0) { $0 + $1.totalValue }
    }
    
    var totalDailyGain: Double {
        stocks.reduce(0) { $0 + $1.dailyGain }
    }
    
    var totalNxtDailyGain: Double {
        stocks.reduce(0) { $0 + $1.nxtDailyGain }
    }
    
    var totalReturn: Double {
        stocks.reduce(0) { $0 + ($1.totalGain ?? 0.0) }
    }
    
    var totalKrxReturn: Double {
        stocks.reduce(0) { $0 + ($1.krxTotalGain ?? 0.0) }
    }
    
    // Performance Calculations for "Game"
    func getMarketPerformance(market: String) -> Double {
        let indexId = market == "KS" ? "KOSPI" : "KOSDAQ"
        guard let index = marketIndices.first(where: { $0.id == indexId }) else { return 0.0 }
        return index.currentChangeRateDouble
    }
    
    func getUserPerformance(market: String) -> Double {
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
            }
        }
    }
    
    func addStock(code: String) {
        if !portfolioCodes.contains(code) {
            portfolioCodes.append(code)
            saveData()
            Task {
                await fetchStock(code: code)
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
    
    func resetPortfolio() {
        portfolioStorage = [:]
        portfolioCodes = []
        stocks = []
        UserDefaults.standard.removeObject(forKey: "portfolioStockCodes")
        UserDefaults.standard.removeObject(forKey: "portfolioStorage")
        saveData()
    }
    
    func fetchAll() async {
        await fetchMarketIndices()
        for code in portfolioCodes {
            await fetchStock(code: code)
        }
    }
    
    func searchStocks(query: String) -> [SearchResult] {
        guard !query.isEmpty else { return [] }
        return stockDatabase.filter {
            $0.name.lowercased().contains(query.lowercased()) || $0.code.contains(query)
        }
    }
    
    private func fetchMarketIndices() async {
        let codes = ["KOSPI", "KOSDAQ"]
        for code in codes {
            guard let url = URL(string: "https://m.stock.naver.com/api/index/\(code)/basic") else { continue }
            
            do {
                let (data, _) = try await session.data(from: url)
                let info = try JSONDecoder().decode(StockItem.self, from: data)
                
                let isRising = info.compareToPreviousPrice.code == "2"
                let isFalling = info.compareToPreviousPrice.code == "5"
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
                    isNxtRising: info.overMarketPriceInfo?.compareToPreviousPrice?.code == "2",
                    isNxtFalling: info.overMarketPriceInfo?.compareToPreviousPrice?.code == "5",
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
            
            let isRising = info.compareToPreviousPrice.code == "2"
            let isFalling = info.compareToPreviousPrice.code == "5"
            
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
                isNxtRising: info.overMarketPriceInfo?.compareToPreviousPrice?.code == "2",
                isNxtFalling: info.overMarketPriceInfo?.compareToPreviousPrice?.code == "5",
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
