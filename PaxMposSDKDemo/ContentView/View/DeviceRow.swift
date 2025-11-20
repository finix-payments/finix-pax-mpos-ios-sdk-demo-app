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
        Text(device.name)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(Constants.textColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    DeviceRow(device: .init(id: "123", name: "Device 1"))
}
