import SwiftUI
import ServiceManagement

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
