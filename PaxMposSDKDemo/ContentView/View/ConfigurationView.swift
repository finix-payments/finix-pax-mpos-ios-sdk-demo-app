//
//  ConfigurationView.swift
//  PaxMposSDKDemo
//
//  Created by Felix Olivares on 18/03/25.
//

import SwiftUI
import PaxMposSDK

struct ConfigurationView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var allConfigs: AllEnvironmentConfigurations
    @State private var showValidationAlert = false
    @State private var missingFields: [String] = []
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        _allConfigs = State(initialValue: viewModel.userSession.allConfigs)
    }
    
    private var currentConfig: Binding<EnvironmentConfiguration> {
        Binding(
            get: {
                allConfigs.configs[allConfigs.selectedEnvironment] ?? EnvironmentConfiguration()
            },
            set: { newValue in
                allConfigs.configs[allConfigs.selectedEnvironment] = newValue
            }
        )
    }

    var body: some View {
        Form {
            Section(header: Text("ENVIRONMENT")) {
                Picker("Environment", selection: $allConfigs.selectedEnvironment) {
                    Text(Finix.Environment.Production.stringValue).tag(Finix.Environment.Production)
                    Text(Finix.Environment.Sandbox.stringValue).tag(Finix.Environment.Sandbox)
                }
                .pickerStyle(SegmentedPickerStyle())
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color(UIColor.systemGroupedBackground))
            }
            
            Section(header: Text("DEVICE")) {
                HStack {
                    Text("ID")
                        .font(Constants.headerFont)
                        .frame(width: 100, alignment: .leading)
                    ClearableTextField(title: "Enter Device ID", text: currentConfig.deviceId)
                }
            }
            
            Section(header: Text("MERCHANT")) {
                HStack {
                    Text("ID")
                        .font(Constants.headerFont)
                        .frame(width: 100, alignment: .leading)
                    ClearableTextField(title: "Enter Merchant ID", text: currentConfig.merchantId)
                }
                
                HStack {
                    Text("MID")
                        .font(Constants.headerFont)
                        .frame(width: 100, alignment: .leading)
                    ClearableTextField(title: "Enter Merchant MID", text: currentConfig.merchantMid)
                }
                
                HStack {
                    Text("Buyer ID")
                        .font(Constants.headerFont)
                        .frame(width: 100, alignment: .leading)
                    TextField("Optional", text: Binding(
                        get: { currentConfig.wrappedValue.buyerIdentityId ?? "" },
                        set: { currentConfig.wrappedValue.buyerIdentityId = $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
                    ))
                    .overlay(alignment: .trailing) {
                        if let buyerId = currentConfig.wrappedValue.buyerIdentityId, !buyerId.isEmpty {
                            Button(action: {
                                currentConfig.wrappedValue.buyerIdentityId = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .padding(5)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            
            Section(header: Text("API KEY")) {
                HStack {
                    Text("Username")
                        .font(Constants.headerFont)
                        .frame(width: 100, alignment: .leading)
                    ClearableTextField(title: "Enter Username", text: currentConfig.username)
                }
                
                HStack {
                    Text("Password")
                        .font(Constants.headerFont)
                        .frame(width: 100, alignment: .leading)
                    ClearableTextField(title: "Enter Password", text: currentConfig.password)
                }
            }
        }
        .navigationTitle("Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.showConfigurationSheet = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if validateConfiguration() {
                        viewModel.showConfigurationSheet = false
                        viewModel.saveConfiguration(allConfigs)
                    } else {
                        showValidationAlert = true
                    }
                }
                .font(.system(size: 17, weight: .medium))
            }
        }
        .alert("Missing Required Fields", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please fill in all required fields:\n\n\(missingFields.joined(separator: "\n"))")
        }
    }
    
    private func validateConfiguration() -> Bool {
        missingFields.removeAll()
        let config = currentConfig.wrappedValue
        
        if config.deviceId.trim().isEmpty {
            missingFields.append("• Device ID")
        }
        if config.merchantId.trim().isEmpty {
            missingFields.append("• Merchant ID")
        }
        if config.merchantMid.trim().isEmpty {
            missingFields.append("• Merchant MID")
        }
        if config.username.trim().isEmpty {
            missingFields.append("• Username")
        }
        if config.password.trim().isEmpty {
            missingFields.append("• Password")
        }
        
        return missingFields.isEmpty
    }
}

struct ClearableTextField: View {
    let title: String
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(title, text: $text)
                .focused($isFocused)
            
            if !text.isEmpty && isFocused {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .padding(5)
                }
                .contentShape(Rectangle())
            }
        }
    }
}
