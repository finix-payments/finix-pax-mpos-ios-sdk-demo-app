//
//  Constants.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/13/25.
//

import SwiftUI

struct Constants {
    static let buttonBackgroundColor = Color(red: 0.35, green: 0.47, blue: 0.74)
    static let buttonDisabledBackgroundColor = Color.gray.opacity(0.3)
    static let buttonTextColor = Color.white
    static let buttonDisabledTextColor = Color.gray
    static let buttonFont = Font.system(size: 18, weight: .semibold)
    
    static let textColor = Color.black
    static let bodyFont = Font.system(size: 18)
    static let headerFont = Font.system(.headline)
    static let footnoteFont = Font.system(.footnote)
    
    static let connectedText = "🟢 Connected to: %@"
    static let disconnectedText = "🔴 Disconnected"
    static let unknownDeviceText = "Unknown device"
}
