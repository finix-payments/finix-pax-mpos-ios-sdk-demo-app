//
//  FinixButton.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/13/25.
//

import SwiftUI

struct FinixButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Constants.buttonFont)
                .foregroundColor(isEnabled ? Constants.buttonTextColor : Constants.buttonDisabledTextColor)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
        }
        .background(isEnabled ? Constants.buttonBackgroundColor : Constants.buttonDisabledBackgroundColor)
        .cornerRadius(32)
        .disabled(!isEnabled)
    }
}

#Preview {
    FinixButton(title: "Scan for Devices", isEnabled: true, action: {})
    FinixButton(title: "Refund", isEnabled: false, action: {})
}
