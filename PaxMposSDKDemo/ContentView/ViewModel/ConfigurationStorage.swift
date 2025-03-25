//
//  ConfigurationStorage.swift
//  PaxMposSDKDemo
//
//  Created by Felix Olivares on 20/03/25.
//

import SwiftUI

protocol ConfigurationStorage {
    func saveConfiguration(_ config: [String: Any])
    func loadConfiguration() -> [String: Any]?
}

struct UserDefaultsConfigurationStorage: ConfigurationStorage {
    private let key: String
    
    init(key: String = "finixConfig") {
        self.key = key
    }
    
    func saveConfiguration(_ config: [String: Any]) {
        UserDefaults.standard.set(config, forKey: key)
    }
    
    func loadConfiguration() -> [String: Any]? {
        return UserDefaults.standard.dictionary(forKey: key)
    }
}
