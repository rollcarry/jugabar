import Foundation
import Combine

public struct StockInfo: Codable, Identifiable {
    public var id: String { stockItem.itemCode }
    public let stockItem: StockItem
}

public struct StockItem: Codable {
    public let itemCode: String
    public let stockName: String
    public let closePrice: String
    public let compareToPreviousClosePrice: String
    public let fluctuationsRatio: String
    public let compareToPreviousPrice: CompToPrev
    public let stockExchangeType: StockExchange?
    public let marketStatus: String? // OPEN, CLOSE, etc.
    public let overMarketPriceInfo: OverMarketPriceInfo?
}

public struct OverMarketPriceInfo: Codable {
    public let overMarketStatus: String? // OPEN, CLOSE
    public let overPrice: String?
    public let fluctuationsRatio: String?
    public let compareToPreviousClosePrice: String?
    public let compareToPreviousPrice: CompToPrev?
}

public struct StockExchange: Codable {
    public let code: String // KS (KOSPI) or KQ (KOSDAQ)
}

public struct CompToPrev: Codable {
    public let code: String
    public let text: String
    
    public var isRising: Bool { ["1", "2"].contains(code) }
    public var isFalling: Bool { ["4", "5"].contains(code) }
}

public struct Stock: Identifiable, Codable {
    public let id: String
    public let name: String
    public let price: String
    public let changeAmount: String
    public let changeRate: String
    public let isRising: Bool
    public let isFalling: Bool
    public let marketType: String? // KS or KQ
    public let nxtPrice: String?
    public let nxtChangeRate: String?
    public let nxtChangeAmount: String?
    public let isNxtRising: Bool
    public let isNxtFalling: Bool
    public let isNxtOpen: Bool
    public let isMainOpen: Bool
    
    // Portfolio Data
    public var quantity: Int?
    public var averagePrice: Double?

    public init(
        id: String,
        name: String,
        price: String,
        changeAmount: String,
        changeRate: String,
        isRising: Bool,
        isFalling: Bool,
        marketType: String?,
        nxtPrice: String?,
        nxtChangeRate: String?,
        nxtChangeAmount: String?,
        isNxtRising: Bool,
        isNxtFalling: Bool,
        isNxtOpen: Bool,
        isMainOpen: Bool,
        quantity: Int? = nil,
        averagePrice: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.changeAmount = changeAmount
        self.changeRate = changeRate
        self.isRising = isRising
        self.isFalling = isFalling
        self.marketType = marketType
        self.nxtPrice = nxtPrice
        self.nxtChangeRate = nxtChangeRate
        self.nxtChangeAmount = nxtChangeAmount
        self.isNxtRising = isNxtRising
        self.isNxtFalling = isNxtFalling
        self.isNxtOpen = isNxtOpen
        self.isMainOpen = isMainOpen
        self.quantity = quantity
        self.averagePrice = averagePrice
    }
    
    private func signedValue(_ string: String?, falling: Bool) -> Double {
        guard let string = string else { return 0.0 }
        let value = parsePrice(string)
        if string.contains("-") { return -abs(value) }
        if string.contains("+") { return abs(value) }
        if falling && value > 0 { return -value }
        return value
    }
    
    // Calculated Properties
    public var currentPriceDouble: Double {
        if !isMainOpen, let nxt = nxtPrice {
            return parsePrice(nxt)
        }
        return parsePrice(price)
    }
    
    public var currentChangeRateDouble: Double {
        if !isMainOpen, let nxtRate = nxtChangeRate {
            return signedValue(nxtRate, falling: isNxtFalling)
        }
        return signedValue(changeRate, falling: isFalling)
    }
    
    public var changeRateDouble: Double {
        signedValue(changeRate, falling: isFalling)
    }
    
    public var nxtChangeRateDouble: Double {
        signedValue(nxtChangeRate, falling: isNxtFalling)
    }
    
    public var changeAmountDouble: Double {
        return signedValue(changeAmount, falling: isFalling)
    }
    
    public var nxtChangeAmountDouble: Double {
        return signedValue(nxtChangeAmount, falling: isNxtFalling)
    }
    
    public var totalValue: Double {
        guard let quantity = quantity else { return 0.0 }
        return currentPriceDouble * Double(quantity)
    }
    
    public var dailyGain: Double {
        guard let quantity = quantity else { return 0.0 }
        var change = changeAmountDouble
        if isFalling && change > 0 { change = -change }
        return change * Double(quantity)
    }
    
    public var nxtDailyGain: Double {
        guard let quantity = quantity else { return 0.0 }
        var change = nxtChangeAmountDouble
        if isNxtFalling && change > 0 { change = -change }
        return change * Double(quantity)
    }
    
    public var totalGain: Double? {
        guard let quantity = quantity, let avg = averagePrice else { return nil }
        return (currentPriceDouble - avg) * Double(quantity)
    }
    
    public var krxTotalGain: Double? {
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

public struct PortfolioItem: Codable {
    public let quantity: Int
    public let averagePrice: Double?

    public init(quantity: Int, averagePrice: Double?) {
        self.quantity = quantity
        self.averagePrice = averagePrice
    }
}

public struct MarketValueResponse: Codable {
    public let stocks: [MarketStock]
}

public struct MarketStock: Codable {
    public let itemCode: String
    public let stockName: String
}

public struct YahooChartResponse: Codable {
    public let chart: YahooChartResult
}

public struct YahooChartResult: Codable {
    public let result: [YahooChartMetaWrapper]?
    public let error: YahooError?
}

public struct YahooError: Codable {
    public let code: String
    public let description: String
}

public struct YahooChartMetaWrapper: Codable {
    public let meta: YahooMeta
}

public struct YahooMeta: Codable {
    public let symbol: String
    public let regularMarketPrice: Double
    public let previousClose: Double?
    public let chartPreviousClose: Double?
    public let longName: String?
    public let shortName: String?
    public let instrumentType: String?
}

public struct YahooSearchResponse: Codable {
    public let quotes: [YahooQuote]
}

public struct YahooQuote: Codable {
    public let symbol: String
    public let shortname: String?
    public let longname: String?
    public let quoteType: String?
    public let exchange: String?
}

public struct SearchResult: Identifiable {
    public let id: String
    public let code: String
    public let name: String
    public let marketType: String?

    public init(id: String, code: String, name: String, marketType: String?) {
        self.id = id
        self.code = code
        self.name = name
        self.marketType = marketType
    }
}

public struct ExchangeRateResponse: Codable {
    public let exchangeInfo: ExchangeInfo
}

public struct ExchangeInfo: Codable {
    public let closePrice: String
}

public enum SortMode: String, Codable, CaseIterable {
    case manual = "Manual"
    case value = "Value"
    case gain = "Return %"
    case daily = "Daily %"
    case name = "Name"
    
    public var icon: String {
        switch self {
        case .manual: return "hand.tap"
        case .value: return "dollarsign.circle"
        case .gain: return "chart.line.uptrend.xyaxis"
        case .daily: return "percent"
        case .name: return "textformat.abc"
        }
    }
}
