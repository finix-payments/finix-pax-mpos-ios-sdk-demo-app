//
//  FinixButton.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/13/25.
//

import SwiftUI

struct FinixButton: View {
    let title: String
    var systemIcon: String?
    var isEnabled: Bool = true
    var style: ButtonStyle = .primary
    let action: () -> Void
    
    enum ButtonStyle {
        case primary
        case secondary
        case cancel
        case success
        case failed
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 16, weight: .medium))
                }
                Text(title)
                    .font(Constants.bodyFont)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(backgroundColor)
            .cornerRadius(10)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary, .cancel, .success, .failed:
            return Constants.buttonTextColor
        case .secondary:
            return Constants.buttonBackgroundColor
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Constants.buttonBackgroundColor
        case .secondary:
            return Constants.buttonDisabledBackgroundColor
        case .cancel:
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .success:
            return Color(red: 0.2, green: 0.7, blue: 0.3)
        case .failed:
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        FinixButton(title: "Scan for Devices", systemIcon: "wave.3.right", isEnabled: true, action: {})
        FinixButton(title: "Refund", isEnabled: false, action: {})
    }
    .padding()
}
