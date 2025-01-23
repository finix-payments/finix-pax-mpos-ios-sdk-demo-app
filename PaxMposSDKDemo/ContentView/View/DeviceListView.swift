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
        List(viewModel.devices) { device in
            DeviceRow(device: device)
                .onTapGesture {
                    viewModel.selectDevice(device)
                }
        }
    }
}

#Preview {
    DeviceListView(viewModel: ContentViewModel())
}
