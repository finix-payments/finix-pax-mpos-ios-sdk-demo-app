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

    var body: some View {
        Form {
            Section(header: Text("Device Information")) {
                VStack(alignment: .leading) {
                    Text("Device ID")
                        .font(Constants.headerFont)
                    ClearableTextField(title: "Enter Device ID", text: $viewModel.deviceId)
                }
            }
            
            Section(header: Text("Account Information")) {
                VStack(alignment: .leading) {
                    Text("Username")
                        .font(Constants.headerFont)
                    ClearableTextField(title: "Enter Username", text: $viewModel.username)
                }
                
                VStack(alignment: .leading) {
                    Text("Password")
                        .font(Constants.headerFont)
                    ClearableTextField(title: "Enter Password", text: $viewModel.password)
                }
            }
            
            Section(header: Text("Finix Configuration")) {
                VStack(alignment: .leading) {
                    Text("Merchant ID")
                        .font(Constants.headerFont)
                    ClearableTextField(title: "Enter Merchant ID", text: $viewModel.merchantId)
                }
                
                VStack(alignment: .leading) {
                    Text("MID")
                        .font(Constants.headerFont)
                    ClearableTextField(title: "Enter MID", text: $viewModel.merchantMid)
                }
                
                VStack(alignment: .leading) {
                    Text("Environment")
                        .font(Constants.headerFont)
                    Picker("Environment", selection: $viewModel.environment) {
                        Text(Finix.Environment.Production.stringValue).tag(Finix.Environment.Production)
                        Text(Finix.Environment.Sandbox.stringValue).tag(Finix.Environment.Sandbox)
                        Text(Finix.Environment.QA.stringValue).tag(Finix.Environment.QA)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            Button("Restore Defaults") {
                viewModel.restoreDefaults()
            }
        }
        .navigationTitle("Configuration")
    }
}

struct ClearableTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .trailing) {
            TextField(title, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .padding(10)
                }
                .contentShape(Rectangle())
                .padding(.trailing, 8)
            }
        }
    }
}
