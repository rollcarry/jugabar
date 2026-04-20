import SwiftUI
import AppKit
import JugaBarCore

struct ContentView: View {
    @StateObject private var stockService = StockService()
    @State private var showSettings: Bool = false
    @State private var showSearch: Bool = false
    @State private var showChart: Bool = false
    @State private var editingStock: Stock? = nil // For portfolio edit sheet
    @State private var addingBuyStock: Stock? = nil // For add buy sheet
    @State private var isPortfolioMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if showSettings || showSearch || showChart {
                    Button(action: {
                        withAnimation {
                            showSettings = false
                            showSearch = false
                            showChart = false
                        }
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing, 4)
                }
                
                Text(viewTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !showSettings && !showSearch && !showChart {
                    Menu {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Button(action: {
                                stockService.sortMode = mode
                            }) {
                                HStack {
                                    Text(mode.rawValue)
                                    if stockService.sortMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                    Image(systemName: mode.icon)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(stockService.sortMode == .manual ? .secondary : .accentColor)
                    }
                    .buttonStyle(.borderless)
                    .help("Sort Stocks")
                    
                    Button(action: {
                        Task {
                            await stockService.fetchAll()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh Now")
                    
                    Button(action: {
                        withAnimation {
                            showSettings.toggle()
                        }
                    }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.borderless)
                    .help("Settings")
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            .zIndex(1)

            Divider()

            if showSettings {
                SettingsView(stockService: stockService, showSettings: $showSettings)
                    .frame(height: 450)
                    .clipped()
                    .transition(.opacity) // Cleaner transition
            } else if showSearch {
                SearchView(stockService: stockService, showSearch: $showSearch)
                    .frame(height: 350)
                    .transition(.opacity)
            } else if showChart {
                 PortfolioChartView(stockService: stockService, showChart: $showChart)
                    .frame(height: 550)
                    .transition(.opacity)
            } else {
                // 1. Market Indices Section (Top)
                if !stockService.marketIndices.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(stockService.marketIndices) { index in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(index.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 4) {
                                    Text(index.price)
                                        .font(.system(size: 13, weight: .bold))
                                    Text(index.changeRate + "%")
                                        .font(.system(size: 11))
                                        .foregroundColor(colorFor(stock: index))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                    
                    Divider()
                }

                // Gaming Feature: Beat the Market Summary
                if stockService.totalPortfolioValue > 0 {
                    HStack(spacing: 8) {
                        PerformanceBadge(title: "KOSPI", user: stockService.getUserPerformance(market: "KS"), market: stockService.getMarketPerformance(market: "KS"), isOpen: stockService.isMarketOpen)
                        PerformanceBadge(title: "KOSDAQ", user: stockService.getUserPerformance(market: "KQ"), market: stockService.getMarketPerformance(market: "KQ"), isOpen: stockService.isMarketOpen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.03))
                    
                    Divider()
                }
                
                // 2. Stock List (Middle)
                if stockService.stocks.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.3))
                        Text("Your Portfolio is Empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Click 'Add' to track your first stock.")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                        Spacer()
                    }
                    .frame(height: 400)
                } else {
                    List {
                        ForEach(stockService.stocks) { stock in
                            StockRow(stock: stock, isPortfolioMode: isPortfolioMode, onEdit: {
                                editingStock = stock
                            })
                            .contextMenu {
                                Button("Add Buy") {
                                    addingBuyStock = stock
                                }
                                Button("Edit Portfolio") {
                                    editingStock = stock
                                }
                                Button("Remove") {
                                    stockService.removeStock(id: stock.id)
                                }
                            }
                        }
                        .onMove(perform: stockService.moveStock)
                    }
                    .listStyle(.plain)
                    .frame(height: 400)
                }
                
                Divider()
                
                // 3. Portfolio Summary (Visible only in Portfolio Mode if holdings exist)
                if isPortfolioMode && stockService.totalPortfolioValue > 0 {
                    VStack(spacing: 4) {
                        // Row 1: Total Value
                        HStack {
                            Text("Total Portfolio Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(stockService.totalPortfolioValue).formattedWithSeparator) 원")
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        // Row 2: Daily Change
                        HStack {
                            Text("Daily Change")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            if !stockService.isMainMarketOpen && stockService.stocks.contains(where: { $0.nxtPrice != nil }) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    HStack(spacing: 4) {
                                        let isAnyNxtOpen = stockService.stocks.contains(where: { $0.isNxtOpen })
                                        Text(isAnyNxtOpen ? "NXT" : "NXT·F")
                                            .font(.system(size: 7, weight: .heavy))
                                            .padding(.horizontal, 3)
                                            .padding(.vertical, 1)
                                            .background(isAnyNxtOpen ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.2))
                                            .cornerRadius(3)
                                            .foregroundColor(isAnyNxtOpen ? .orange : .secondary)
                                        
                                        let nxtDaily = stockService.totalNxtDailyGain
                                        Text((nxtDaily > 0 ? "+" : "") + "\(Int(nxtDaily).formattedWithSeparator) 원")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(nxtDaily > 0 ? .red : (nxtDaily < 0 ? .blue : .primary))
                                    }
                                    let krxDaily = stockService.totalDailyGain
                                    Text("KRX " + (krxDaily > 0 ? "+" : "") + "\(Int(krxDaily).formattedWithSeparator)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                let gain = stockService.totalDailyGain
                                Text((gain > 0 ? "+" : "") + "\(Int(gain).formattedWithSeparator) 원")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(gain > 0 ? .red : (gain < 0 ? .blue : .primary))
                            }
                        }

                        // Row 3: Total Return
                        HStack {
                            Text("Total Return")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            if !stockService.isMainMarketOpen && stockService.stocks.contains(where: { $0.nxtPrice != nil }) {
                                VStack(alignment: .trailing, spacing: 0) {
                                    let nxtReturn = stockService.totalReturn
                                    Text((nxtReturn > 0 ? "+" : "") + "\(Int(nxtReturn).formattedWithSeparator) 원")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(nxtReturn > 0 ? .red : (nxtReturn < 0 ? .blue : .primary))
                                    
                                    let krxReturn = stockService.totalKrxReturn
                                    Text("KRX " + (krxReturn > 0 ? "+" : "") + "\(Int(krxReturn).formattedWithSeparator)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                let totalReturn = stockService.totalReturn
                                Text((totalReturn > 0 ? "+" : "") + "\(Int(totalReturn).formattedWithSeparator) 원")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(totalReturn >= 0 ? .red : .blue)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .windowBackgroundColor))
                    Divider()
                }

                // 4. Footer controls
                HStack {
                    Toggle("Portfolio", isOn: $isPortfolioMode)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                        .font(.caption)
                    
                    if isPortfolioMode {
                        Button(action: {
                            withAnimation {
                                showChart = true
                            }
                        }) {
                            Image(systemName: "chart.pie")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                        .help("View Allocation")
                        .padding(.leading, 8)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showSearch = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Add")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .padding()
            }
        }
        .frame(width: 360)
        .onAppear {
            if stockService.refreshInterval == 0 {
                Task {
                    await stockService.fetchAll()
                }
            }
        }
        .sheet(item: $editingStock) { stock in
            PortfolioEditView(stock: stock, stockService: stockService, isPresented: $editingStock)
        }
        .sheet(item: $addingBuyStock) { stock in
            AddBuyView(stock: stock, stockService: stockService, isPresented: $addingBuyStock)
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetUI)) { _ in
            showSettings = false
            showSearch = false
            showChart = false
            if stockService.refreshInterval == 0 {
                Task {
                    await stockService.fetchAll()
                }
            }
        }
    }
    
    @State private var showTotalReturn: Bool = false
    
    private var viewTitle: String {
        if showSettings { return "Settings" }
        if showSearch { return "Add Stock" }
        if showChart { return "Allocation" }
        return isPortfolioMode ? "Portfolio" : "JugaBar"
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
