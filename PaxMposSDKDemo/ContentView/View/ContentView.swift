//
//  ContentView.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/24/25.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel: ContentViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: ContentViewModel())
    }
    
    var body: some View {
        NavigationView {
            Form {
                if viewModel.isDeviceConnected {
                    deviceSection
                    transactionSection
                } else {
                    scanSection
                }
                
                logsSection
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewModel.showConfigurationSheet = true
                        } label: {
                            Label("Configuration", systemImage: "gearshape")
                        }
                        Button {
                            viewModel.showOthersSheet = true
                        } label: {
                            Label("Others", systemImage: "ellipsis")
                        }
                        if viewModel.isDeviceConnected {
                            Button {
                                viewModel.onSendDebugLogTapped()
                            } label: {
                                Label("Send Debug Log", systemImage: "paperplane")
                            }
                            Button(role: .destructive) {
                                viewModel.showResetDeviceAlert = true
                            } label: {
                                Label("Reset Device", systemImage: "arrow.counterclockwise")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .renderingMode(.template)
                            .foregroundColor(Constants.buttonBackgroundColor)
                    }
                }
            }
            .alert(viewModel.alertObject.title, isPresented: $viewModel.showingAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertObject.message)
            }
            .sheet(isPresented: $viewModel.showingDeviceList) {
                NavigationView {
                    DeviceListView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $viewModel.showConfigurationSheet) {
                NavigationView {
                    ConfigurationView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $viewModel.showOthersSheet) {
                NavigationView {
                    OthersView(viewModel: viewModel)
                }
            }
            .alert("Reset Device?", isPresented: $viewModel.showResetDeviceAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    viewModel.onResetDeviceTapped()
                }
            } message: {
                Text("This will clear and reload files on the connected device.")
            }
            .alert("Disconnect Device?", isPresented: $viewModel.showDisconnectDeviceAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Disconnect") {
                    viewModel.onDisconnectCurrentDeviceTapped()
                }
            } message: {
                Text("This device will be unpaired and you'll need to scan for it again to reconnect.")
            }
            .navigationTitle("Finix + PAX D135")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Sections
    
    private var scanSection: some View {
        Section(header: Text("DEVICE")) {
            FinixButton(title: "Scan for Devices") {
                viewModel.onScanForDevicesTapped()
            }
            selectedEnvironment
        }
    }
    
    private var deviceSection: some View {
        Section(header: Text("DEVICE")) {
            HStack {
                Text(viewModel.connectedDeviceText)
                    .font(Constants.bodyFont)
                    .foregroundColor(Constants.textColor)
                
                Spacer()
                
                Button(action: {
                    viewModel.showDisconnectDeviceAlert = true
                }) {
                    Text("Disconnect")
                        .font(Constants.bodyFont)
                        .foregroundColor(Constants.buttonBackgroundColor)
                }
            }
            
            selectedEnvironment
        }
    }
    
    private var transactionSection: some View {
        Section(header: transactionHeader) {
            HStack(spacing: 8) {
                Text("Amount")
                    .font(Constants.bodyFont)
                    .foregroundColor(Constants.textColor)
                    .frame(width: 100, alignment: .leading)
                
                HStack(spacing: 4) {
                    Text("$")
                        .font(Constants.bodyFont)
                        .foregroundColor(.gray)
                    
                    TextField("0.00", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .font(Constants.bodyFont)
                        .foregroundColor(Constants.textColor)
                }
            }
            
            if !viewModel.userSession.tagsString.isEmpty {
                Text("Tags: \(viewModel.userSession.tagsString)")
                    .font(Constants.bodyFont)
                    .foregroundColor(Constants.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if viewModel.isSplitTransferTransaction {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Split Transfers:")
                        .font(Constants.bodyFont)
                        .foregroundColor(Constants.textColor)
                    
                    ForEach(viewModel.userSession.splitTransferEntries) { entry in
                        Text("Merchant: \(entry.merchantID), Amount: $\(entry.amount)")
                            .font(Constants.bodyFont)
                            .foregroundColor(Constants.textColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            transactionButtons
            
            if viewModel.lastSuccessfulTransferID != "" {
                HStack {
                    Button(action: {
                        viewModel.copyLastTransferIDToClipboard()
                    }) {
                        Image(systemName: "doc.on.doc.fill")
                            .renderingMode(.template)
                            .foregroundColor(Constants.buttonBackgroundColor)
                    }
                    Text(viewModel.lastSuccessfulTransferID)
                        .font(Constants.bodyFont)
                        .foregroundColor(Constants.textColor)
                }
            }
        }
    }
    
    private var transactionHeader: some View {
        HStack(spacing: 8) {
            Text("TRANSACTION")
            
            if [.readingCard, .processingCard].contains(viewModel.currentTransactionStatus) {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
    }
    
    @ViewBuilder
    private var transactionButtons: some View {
        switch viewModel.currentTransactionStatus {
        case .readingCard, .processingCard:
            FinixButton(title: "Cancel \(viewModel.currentTransactionType.displayName)", style: .cancel, action: {
                viewModel.onCancelTapped()
            })
        case .success:
            FinixButton(title: "\(viewModel.currentTransactionType.displayName) Complete", style: .success, action: {})
        case .failed:
            FinixButton(title: "\(viewModel.currentTransactionType.displayName) Failed", style: .failed, action: {})
        default:
            HStack(spacing: 8) {
                FinixButton(title: "Sale", style: .secondary) {
                    viewModel.onSaleTapped()
                }
                
                FinixButton(title: "Auth", style: .secondary) {
                    viewModel.onAuthTapped()
                }
                
                FinixButton(title: "Refund", style: .secondary) {
                    viewModel.onRefundTapped()
                }
            }
        }
    }
    
    private var logsSection: some View {
        Section(header: logsHeader) {
            ScrollView {
                ScrollViewReader { proxy in
                    Text(viewModel.logOutput)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(Constants.textColor)
                        .frame(maxWidth: .infinity, minHeight: 276, alignment: .topLeading)
                        .padding(12)
                        .background(Color(uiColor: .systemGroupedBackground))
                        .cornerRadius(8)
                        .id("bottom")
                        .onChange(of: viewModel.logOutput) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                }
            }
            .frame(height: 300)
            .padding(16)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }
    
    private var logsHeader: some View {
        HStack {
            Text("LOGS")
            
            Spacer()
            
            if !viewModel.logOutput.isEmpty && viewModel.logOutput != Constants.noActivityYet {
                Button(action: {
                    viewModel.onClearLogsTapped()
                }) {
                    Text("Clear")
                        .font(Font.system(size: 15))
                        .foregroundColor(Constants.buttonBackgroundColor)
                }
            }
        }
    }
    
    private var selectedEnvironment: some View {
        Text("Selected environment: \(viewModel.userSession.allConfigs.selectedEnvironment.stringValue)")
            .font(Constants.bodyFont)
            .foregroundColor(Constants.textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//#Preview {
//    ContentView(viewModel: ContentViewModel())
//}
