//
//  View+Ext.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/26/25.
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil)
    }
}
