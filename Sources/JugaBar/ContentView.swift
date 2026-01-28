import SwiftUI
import ServiceManagement

struct ContentView: View {
    @StateObject private var stockService = StockService()
    @State private var showSettings: Bool = false
    @State private var showSearch: Bool = false
    @State private var editingStock: Stock? = nil // For portfolio edit sheet
    @State private var isPortfolioMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if showSettings || showSearch {
                    Button(action: {
                        withAnimation {
                            showSettings = false
                            showSearch = false
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
                
                if !showSettings && !showSearch {
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
                                Button("Edit Portfolio") {
                                    editingStock = stock
                                }
                                Button("Remove") {
                                    stockService.removeStock(id: stock.id)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 400)
                }
                
                Divider()
                
                // 3. Portfolio Summary (Bottom - Always visible if holdings exist)
                if stockService.totalPortfolioValue > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Total Portfolio Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(stockService.totalPortfolioValue).formattedWithSeparator) 원")
                                .font(.system(size: 13, weight: .bold))
                        }
                        
                        HStack {
                            Text(isPortfolioMode ? "Total Return" : "Daily Change")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            
                            if !stockService.isMainMarketOpen && stockService.stocks.contains(where: { $0.nxtPrice != nil }) {
                                // NXT data is available (even if closed), and Main is closed
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
                                        
                                        let nxtGain = isPortfolioMode ? stockService.totalReturn : stockService.totalNxtDailyGain
                                        Text((nxtGain > 0 ? "+" : "") + "\(Int(nxtGain).formattedWithSeparator) 원")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(nxtGain >= 0 ? .red : .blue)
                                    }
                                    
                                    let krxGain = isPortfolioMode ? stockService.totalKrxReturn : stockService.totalDailyGain
                                    Text("KRX " + (krxGain > 0 ? "+" : "") + "\(Int(krxGain).formattedWithSeparator)")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                // Standard Main Market or Closed
                                let gain = isPortfolioMode ? stockService.totalReturn : stockService.totalDailyGain
                                Text((gain > 0 ? "+" : "") + "\(Int(gain).formattedWithSeparator) 원")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(gain >= 0 ? .red : .blue)
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
        .frame(width: 320)
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
        .onReceive(NotificationCenter.default.publisher(for: .resetUI)) { _ in
            showSettings = false
            showSearch = false
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
        return isPortfolioMode ? "Portfolio" : "JugaBar"
    }
    
    private func colorFor(stock: Stock) -> Color {
        if stock.isRising { return .red }
        if stock.isFalling { return .blue }
        return .primary
    }
}

struct StockRow: View {
    let stock: Stock
    let isPortfolioMode: Bool
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(stock.name)
                    .font(.system(size: 13, weight: .medium))
                
                if isPortfolioMode, let quantity = stock.quantity, quantity > 0 {
                    Text("\(quantity) shares")
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
            .frame(width: 90, alignment: .leading)
            .contentShape(Rectangle())
            // No tap gesture here anymore
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if stock.isMainOpen {
                    // Only KRX during main hours
                    Text(stock.price)
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
                        
                        Text(nxtPrice)
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
                    Text(stock.price)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(colorFor(stock: stock))
                }
                
                if isPortfolioMode, let quantity = stock.quantity, quantity > 0 {
                    if stock.isMainOpen {
                        if let totalGain = stock.totalGain {
                            Text((totalGain > 0 ? "+" : "") + "\(Int(totalGain).formattedWithSeparator)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(totalGain >= 0 ? .red : .blue)
                        } else {
                            let gain = stock.dailyGain
                            Text((gain > 0 ? "+" : "") + "\(Int(gain).formattedWithSeparator)")
                                .font(.system(size: 11))
                                .foregroundColor(gain >= 0 ? .red : .blue)
                        }
                    } else if stock.nxtPrice != nil {
                        // Show NXT Gain Primary, KRX Gain Secondary (even after 8:00 PM)
                        VStack(alignment: .trailing, spacing: 0) {
                            let totalGain = stock.totalGain ?? 0
                            
                            Text((totalGain > 0 ? "+" : "") + "\(Int(totalGain).formattedWithSeparator)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(totalGain >= 0 ? .red : .blue)
                            
                            if let krxTotal = stock.krxTotalGain {
                                Text("KRX \(Int(krxTotal).formattedWithSeparator)")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        // Closed - show final KRX
                        if let totalGain = stock.totalGain {
                            Text((totalGain > 0 ? "+" : "") + "\(Int(totalGain).formattedWithSeparator)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(totalGain >= 0 ? .red : .blue)
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
        if stock.isRising { return .red }
        if stock.isFalling { return .blue }
        return .primary
    }
}

struct PortfolioEditView: View {
    let stock: Stock
    @ObservedObject var stockService: StockService
    @Binding var isPresented: Stock?
    
    @State private var quantity: String = ""
    @State private var avgPrice: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Portfolio: \(stock.name)")
                .font(.headline)
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Quantity (Shares)")
                    .font(.caption)
                TextField("0", text: $quantity)
                    .textFieldStyle(.roundedBorder)
            }
            
            VStack(alignment: .leading) {
                Text("Average Buy Price (Optional)")
                    .font(.caption)
                TextField("Price per share", text: $avgPrice)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    isPresented = nil
                }
                
                Spacer()
                
                Button("Save") {
                    let q = Int(quantity)
                    let p = Double(avgPrice)
                    stockService.updatePortfolio(id: stock.id, quantity: q, averagePrice: p)
                    isPresented = nil
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            if let q = stock.quantity { quantity = String(q) }
            if let p = stock.averagePrice { avgPrice = String(Int(p)) }
        }
    }
}

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
                    results = stockService.searchStocks(query: newValue)
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

struct SettingsView: View {
    @ObservedObject var stockService: StockService
    @Binding var showSettings: Bool
    @State private var launchAtLogin: Bool = false
    @State private var showResetAlert: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // General Section
            VStack(alignment: .leading, spacing: 8) {
                Text("General")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { newValue in
                        updateLaunchAtLogin(newValue)
                    }
            }
            .padding(.top, 16)
            
            Divider()
            
            // Refresh Settings Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Refresh Settings")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $stockService.refreshInterval) {
                    Text("Manual (On Click)").tag(0.0)
                    Text("10 Seconds").tag(10.0)
                    Text("30 Seconds").tag(30.0)
                    Text("1 Minute").tag(60.0)
                    Text("5 Minutes").tag(300.0)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
            
            Divider()
            
            // Data Management Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Data Management")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    Text("Reset Portfolio")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.small)
                .alert("Reset Portfolio?", isPresented: $showResetAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Reset Everything", role: .destructive) {
                        stockService.resetPortfolio()
                    }
                } message: {
                    Text("This will clear all holdings AND remove all stocks from your list.")
                }
            }
            
            Spacer()
            
            Text("Tip: In 'Manual' mode, data refreshes only when you open this menu or click the refresh button.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Button("Done") {
                withAnimation {
                    showSettings = false
                }
            }
            .frame(maxWidth: .infinity)
            .controlSize(.regular)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            checkLaunchAtLogin()
        }
    }
    
    private func checkLaunchAtLogin() {
        if SMAppService.mainApp.status == .enabled {
            launchAtLogin = true
        } else {
            launchAtLogin = false
        }
    }
    
    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled { return }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notFound { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
            // Revert UI if failed
            launchAtLogin = !enabled
        }
    }
}

struct PerformanceBadge: View {
    let title: String
    let user: Double
    let market: Double
    let isOpen: Bool
    
    var isWin: Bool { user > market }
    var hasHoldings: Bool { abs(user) > 0.0001 }

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
            
            if hasHoldings {
                if isOpen {
                    Text(isWin ? "🏆 WIN" : "📉 LOSS")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(isWin ? .orange : .secondary)
                    
                    Text(String(format: "%+.1f%%", user - market))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(isWin ? .red : .blue)
                } else {
                    Text("CLOSED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%+.1f%%", user - market))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            } else {
                Text("-")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(hasHoldings && isOpen ? (isWin ? Color.orange.opacity(0.1) : Color.clear) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(hasHoldings && isOpen && isWin ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

extension Int {
    var formattedWithSeparator: String {
        return NumberFormatter.localizedString(from: NSNumber(value: self), number: .decimal)
    }
}