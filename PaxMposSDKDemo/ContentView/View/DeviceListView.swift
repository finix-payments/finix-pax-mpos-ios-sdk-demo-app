//
//  DeviceListView.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/13/25.
//

import SwiftUI

struct DeviceListView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("COMPATIBLE DEVICES")
                    .font(Constants.footnoteFont)
                    .foregroundColor(.gray)
                ProgressView()
                    .scaleEffect(0.8)
                Spacer()
            }
            .padding(.top)
            
            if !viewModel.devices.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.devices) { device in
                        DeviceRow(device: device)
                            .onTapGesture {
                                viewModel.selectDevice(device)
                            }
                        
                        if device.id != viewModel.devices.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            
            Text("Ensure your PAX D135 device is turned on.")
                .font(Constants.footnoteFont)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Scanning for Devices")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    DeviceListView(viewModel: ContentViewModel())
}
