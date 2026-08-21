import Foundation
import JugaBarCore

public struct TestCase {
    let name: String
    let body: () throws -> Void

    public init(_ name: String, body: @escaping () throws -> Void) {
        self.name = name
        self.body = body
    }
}

public enum TestRunner {
    public struct Failure: Error, CustomStringConvertible {
        public let description: String

        public init(_ description: String) {
            self.description = description
        }
    }

    public static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() {
            throw Failure(message)
        }
    }

    public static func expectEqual(_ actual: Double, _ expected: Double, accuracy: Double) throws {
        if abs(actual - expected) > accuracy {
            throw Failure("Expected \(expected), got \(actual)")
        }
    }
}

private enum StockModelTests {
    static func all() -> [TestCase] {
        [
            TestCase("nxt signed positive rate wins over falling flag") {
                let stock = makeStock(
                    price: "10,000",
                    changeAmount: "100",
                    changeRate: "-1.23",
                    isFalling: true,
                    nxtPrice: "10,100",
                    nxtChangeAmount: "40",
                    nxtChangeRate: "+0.41",
                    isNxtFalling: true,
                    isMainOpen: false,
                    quantity: 10,
                    averagePrice: 9_900
                )

                try TestRunner.expectEqual(stock.nxtChangeRateDouble, 0.41, accuracy: 0.0001)
                try TestRunner.expectEqual(stock.currentChangeRateDouble, 0.41, accuracy: 0.0001)
                try TestRunner.expectEqual(stock.currentPriceDouble, 10_100, accuracy: 0.0001)
            },
            TestCase("unsigned nxt rate still respects falling flag") {
                let stock = makeStock(
                    price: "10,000",
                    changeAmount: "100",
                    changeRate: "1.23",
                    isFalling: false,
                    nxtPrice: "9,960",
                    nxtChangeAmount: "40",
                    nxtChangeRate: "0.41",
                    isNxtFalling: true,
                    isMainOpen: false,
                    quantity: 10,
                    averagePrice: 9_900
                )

                try TestRunner.expectEqual(stock.nxtChangeRateDouble, -0.41, accuracy: 0.0001)
                try TestRunner.expectEqual(stock.currentChangeRateDouble, -0.41, accuracy: 0.0001)
            },
            TestCase("signed change amounts drive daily gain correctly") {
                let stock = makeStock(
                    price: "10,000",
                    changeAmount: "-500",
                    changeRate: "-1.0",
                    isFalling: false,
                    nxtPrice: nil,
                    nxtChangeAmount: nil,
                    nxtChangeRate: nil,
                    isNxtFalling: false,
                    isMainOpen: true,
                    quantity: 3,
                    averagePrice: 9_900
                )

                try TestRunner.expectEqual(stock.changeAmountDouble, -500, accuracy: 0.0001)
                try TestRunner.expectEqual(stock.dailyGain, -1_500, accuracy: 0.0001)
            },
            TestCase("total gain uses current price while krx total gain uses krx price") {
                let stock = makeStock(
                    price: "10,000",
                    changeAmount: "100",
                    changeRate: "1.0",
                    isFalling: false,
                    nxtPrice: "10,200",
                    nxtChangeAmount: "200",
                    nxtChangeRate: "2.0",
                    isNxtFalling: false,
                    isMainOpen: false,
                    quantity: 5,
                    averagePrice: 9_800
                )

                try TestRunner.expectEqual(stock.totalGain ?? .nan, 2_000, accuracy: 0.0001)
                try TestRunner.expectEqual(stock.krxTotalGain ?? .nan, 1_000, accuracy: 0.0001)
            },
            TestCase("formattedWithSeparator adds thousands separator") {
                try TestRunner.expect((1234567).formattedWithSeparator == "1,234,567", "Expected thousands separator formatting")
            },
            TestCase("cash contributes to portfolio value but not gains") {
                let stock = makeStock(
                    price: "10,000",
                    changeAmount: "100",
                    changeRate: "1.0",
                    isFalling: false,
                    nxtPrice: nil,
                    nxtChangeAmount: nil,
                    nxtChangeRate: nil,
                    isNxtFalling: false,
                    isMainOpen: true,
                    quantity: 2,
                    averagePrice: 9_000
                )

                try TestRunner.expectEqual(PortfolioMetrics.stockValue(stocks: [stock], exchangeRate: 1), 20_000, accuracy: 0.0001)
                try TestRunner.expectEqual(PortfolioMetrics.totalValue(stocks: [stock], cashBalance: 50_000, exchangeRate: 1), 70_000, accuracy: 0.0001)
                try TestRunner.expectEqual(PortfolioMetrics.dailyGain(stocks: [stock], exchangeRate: 1), 200, accuracy: 0.0001)
                try TestRunner.expectEqual(PortfolioMetrics.totalReturn(stocks: [stock], exchangeRate: 1), 2_000, accuracy: 0.0001)
            },
            TestCase("flat holdings still count as win over negative market") {
                let stock = makeStock(
                    price: "10,000",
                    changeAmount: "0",
                    changeRate: "0.0",
                    isFalling: false,
                    nxtPrice: nil,
                    nxtChangeAmount: nil,
                    nxtChangeRate: nil,
                    isNxtFalling: false,
                    isMainOpen: true,
                    quantity: 1,
                    averagePrice: 10_000
                )

                let userPerformance = PortfolioMetrics.userPerformance(stocks: [stock], market: "KS")
                try TestRunner.expect(PortfolioMetrics.hasHoldings(stocks: [stock], market: "KS"), "Expected flat KOSPI holding to count as a holding")
                try TestRunner.expectEqual(userPerformance, 0, accuracy: 0.0001)
                try TestRunner.expect(userPerformance > -1.0, "Expected 0% user performance to beat a -1% market")
            },
            TestCase("cash-only portfolio has no market holdings") {
                try TestRunner.expectEqual(PortfolioMetrics.totalValue(stocks: [], cashBalance: 50_000, exchangeRate: 1), 50_000, accuracy: 0.0001)
                try TestRunner.expect(!PortfolioMetrics.hasHoldings(stocks: [], market: "KS"), "Cash should not count as KOSPI holdings")
                try TestRunner.expectEqual(PortfolioMetrics.userPerformance(stocks: [], market: "KS"), 0, accuracy: 0.0001)
            }
        ]
    }

    private static func makeStock(
        price: String,
        changeAmount: String,
        changeRate: String,
        isFalling: Bool,
        nxtPrice: String?,
        nxtChangeAmount: String?,
        nxtChangeRate: String?,
        isNxtFalling: Bool,
        isMainOpen: Bool,
        quantity: Int?,
        averagePrice: Double?
    ) -> Stock {
        Stock(
            id: "005930",
            name: "Test Stock",
            price: price,
            changeAmount: changeAmount,
            changeRate: changeRate,
            isRising: !isFalling,
            isFalling: isFalling,
            marketType: "KS",
            nxtPrice: nxtPrice,
            nxtChangeRate: nxtChangeRate,
            nxtChangeAmount: nxtChangeAmount,
            isNxtRising: !isNxtFalling,
            isNxtFalling: isNxtFalling,
            isNxtOpen: false,
            isMainOpen: isMainOpen,
            quantity: quantity,
            averagePrice: averagePrice
        )
    }
}

public func __swiftPMEntryPoint() async -> Never {
    let tests = StockModelTests.all()
    var failures: [String] = []

    for test in tests {
        do {
            try test.body()
            print("PASS: \(test.name)")
        } catch {
            let message = "FAIL: \(test.name) - \(error)"
            failures.append(message)
            print(message)
        }
    }

    if failures.isEmpty {
        print("\nAll tests passed.")
        Foundation.exit(EXIT_SUCCESS)
    } else {
        print("\n\(failures.count) test(s) failed.")
        Foundation.exit(EXIT_FAILURE)
    }
}
