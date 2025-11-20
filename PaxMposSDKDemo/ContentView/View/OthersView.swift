//
//  OthersView.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/26/25.
//

import SwiftUI

struct OthersView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @State private var enableSplitTransfers: Bool
    @State private var splitTransferEntries: [SplitTransferEntry]
    @State private var tagsString: String
    @State private var showValidationAlert = false
    @State private var validationMessage = ""
    
    init(viewModel: ContentViewModel) {
        self.viewModel = viewModel
        _enableSplitTransfers = State(initialValue: viewModel.userSession.enableSplitTransfers)
        _splitTransferEntries = State(initialValue: viewModel.userSession.splitTransferEntries)
        _tagsString = State(initialValue: viewModel.userSession.tagsString)
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tags")
                        .font(Constants.footnoteFont)
                        .foregroundColor(.gray)
                    TextField("key1:value1,key2:value2", text: $tagsString)
                        .font(Constants.bodyFont)
                }
            }
            
            Section {
                Toggle("Split Transfer", isOn: $enableSplitTransfers)
                    .font(Constants.bodyFont)
            }
            
            if enableSplitTransfers {
                ForEach(splitTransferEntries.indices, id: \.self) { index in
                    Section(header: HStack {
                        Text("Transfer \(index + 1)")
                        Spacer()
                        Button(action: {
                            splitTransferEntries.remove(at: index)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }) {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Merchant ID")
                                    .font(Constants.footnoteFont)
                                    .foregroundColor(.gray)
                                TextField("Merchant ID", text: $splitTransferEntries[index].merchantID)
                                    .font(Constants.bodyFont)
                            }
                            
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Amount")
                                        .font(Constants.footnoteFont)
                                        .foregroundColor(.gray)
                                    TextField("$1.23", text: $splitTransferEntries[index].amount)
                                        .keyboardType(.decimalPad)
                                        .font(Constants.bodyFont)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Fee")
                                        .font(Constants.footnoteFont)
                                        .foregroundColor(.gray)
                                    TextField("$4.56", text: $splitTransferEntries[index].fee)
                                        .keyboardType(.decimalPad)
                                        .font(Constants.bodyFont)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Tags")
                                    .font(Constants.footnoteFont)
                                    .foregroundColor(.gray)
                                TextField("key1:value1,key2:value2", text: $splitTransferEntries[index].tags)
                                    .font(Constants.bodyFont)
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        splitTransferEntries.append(SplitTransferEntry())
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Transfer")
                        }
                        .font(Constants.bodyFont)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    viewModel.showOthersSheet = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    if validateForm() {
                        viewModel.showOthersSheet = false
                        viewModel.saveOthersEntries(enableSplitTransfers: enableSplitTransfers, splitTransferEntries: splitTransferEntries, tagsString: tagsString)
                    } else {
                        showValidationAlert = true
                    }
                }
                .font(.system(size: 17, weight: .medium))
            }
        }
        .alert("Validation Error", isPresented: $showValidationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
        .preferredColorScheme(.light)
        .navigationTitle("Others")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func validateForm() -> Bool {
        if !validateTagsFormat(tagsString) {
            validationMessage = "Tags must be formatted as 'key:value' pairs separated by commas (e.g., 'key1:value1,key2:value2')"
            return false
        }
        
        if enableSplitTransfers {
            if splitTransferEntries.count < 2 {
                validationMessage = "Split transfers require at least 2 transfer entries"
                return false
            }
            
            for (index, entry) in splitTransferEntries.enumerated() {
                if entry.merchantID.trim().isEmpty {
                    validationMessage = "Transfer \(index + 1): Merchant ID is required"
                    return false
                }
                if entry.amount.trim().isEmpty {
                    validationMessage = "Transfer \(index + 1): Amount is required"
                    return false
                }
                if !validateTagsFormat(entry.tags) {
                    validationMessage = "Transfer \(index + 1): Tags must be formatted as 'key:value' pairs separated by commas"
                    return false
                }
            }
        }
        
        return true
    }
    
    private func validateTagsFormat(_ tags: String) -> Bool {
        let trimmed = tags.trim()
        
        if trimmed.isEmpty {
            return true
        }
        
        let pairs = trimmed.split(separator: ",")
        
        for pair in pairs {
            let keyValue = pair.split(separator: ":")
            if keyValue.count != 2 {
                return false
            }
            if String(keyValue[0]).trim().isEmpty || String(keyValue[1]).trim().isEmpty {
                return false
            }
        }
        
        return true
    }
}
