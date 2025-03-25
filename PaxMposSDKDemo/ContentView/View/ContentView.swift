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
            ZStack {
                Color.white
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        hideKeyboard()
                    }
                VStack(alignment: .center, spacing: 10) {
                    FinixButton(title: "Scan for Devices") {
                        viewModel.onScanForDevicesTapped()
                    }
                    
                    FinixButton(title: "Disconnect current device") {
                        viewModel.onDisconnectCurrentDeviceTapped()
                    }
                    
                    TextField("Amount", text: $viewModel.amountText)
                        .disabled(!viewModel.isDeviceConnected)
                        .keyboardType(.decimalPad)
                        .font(Constants.bodyFont)
                        .foregroundColor(Constants.textColor)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray, lineWidth: 1)
                                .fill(viewModel.isDeviceConnected ? .white : Constants.buttonDisabledBackgroundColor)
                        )
                    
                    HStack(spacing: 16) {
                        FinixButton(title: "Sale",
                                    isEnabled: viewModel.isDeviceConnected) {
                            viewModel.onSaleTapped()
                        }
                        
                        FinixButton(title: "Auth",
                                    isEnabled: viewModel.isDeviceConnected) {
                            viewModel.onAuthTapped()
                        }
                        
                        FinixButton(title: "Refund",
                                    isEnabled: viewModel.isDeviceConnected) {
                            viewModel.onRefundTapped()
                        }
                    }
                    
                    FinixButton(title: "Cancel",
                                isEnabled: viewModel.isDeviceConnected) {
                        viewModel.onCancelTapped()
                    }
                    
                    FinixButton(title: "Clear Logs") {
                        viewModel.onClearLogsTapped()
                    }
                    
                    FinixButton(title: "Update Files",
                                isEnabled: viewModel.isDeviceConnected) {
                        viewModel.onUpdateFilesTapped()
                    }
                    
                    Text(viewModel.connectedDeviceText)
                        .font(Constants.headerFont)
                        .foregroundColor(Constants.textColor)
                    
                    ScrollView {
                        ScrollViewReader { proxy in
                            Text(viewModel.logOutput)
                                .font(Constants.footnoteFont)
                                .foregroundColor(Constants.textColor)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                .padding(16)
                                .id("bottom")
                                .onChange(of: viewModel.logOutput) {
                                    withAnimation {
                                        proxy.scrollTo("bottom", anchor: .bottom)
                                    }
                                }
                        }
                    }
                    .background(Constants.buttonDisabledBackgroundColor)
                    .cornerRadius(8)
                    
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showConfigurationSheet = true
                    }) {
                        Image(systemName: "gearshape.fill")  // Settings icon
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
                DeviceListView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showConfigurationSheet) {
                NavigationView {
                    ConfigurationView(viewModel: viewModel)
                        .navigationBarItems(trailing: Button("Save") {
                            viewModel.saveConfiguration()
                            viewModel.showConfigurationSheet = false
                        })
                        .navigationBarItems(leading: Button("Close") {
                            viewModel.showConfigurationSheet = false
                        })
                }
                .interactiveDismissDisabled()
            }
            .preferredColorScheme(.light)
        }
        .onAppear {
            viewModel.loadConfiguration()
        }
    }
}

//#Preview {
//    ContentView(viewModel: ContentViewModel())
//}
