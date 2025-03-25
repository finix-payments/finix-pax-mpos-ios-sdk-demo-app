//
//  String+Ext.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/26/25.
//

import Foundation

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
