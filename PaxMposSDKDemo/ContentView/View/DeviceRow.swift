//
//  DeviceRow.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/13/25.
//

import SwiftUI

struct DeviceRow: View {
    let device: Device
    
    var body: some View {
        VStack(alignment: .leading) {
            if !device.name.trim().isEmpty {
                Text(device.name)
                    .font(Constants.bodyFont)
                    .fontWeight(.bold)
            }
            Text(device.id)
                .font(Constants.footnoteFont)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    DeviceRow(device: .init(id: "123", name: "Device 1"))
}
