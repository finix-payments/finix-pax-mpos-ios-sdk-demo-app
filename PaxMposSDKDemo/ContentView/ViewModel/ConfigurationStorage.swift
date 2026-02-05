//
//  ConfigurationStorage.swift
//  PaxMposSDKDemo
//
//  Created by Felix Olivares on 20/03/25.
//

import SwiftUI
import PaxMposSDK

struct EnvironmentConfiguration: Codable {
    var username: String = ""
    var password: String = ""
    var merchantId: String = ""
    var merchantMid: String = ""
    var deviceId: String = ""
    private var _buyerIdentityId: String?
    
    var buyerIdentityId: String? {
        get { _buyerIdentityId }
        set {
            if let value = newValue, value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                _buyerIdentityId = nil
            } else {
                _buyerIdentityId = newValue
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case username, password, merchantId, merchantMid, deviceId, buyerIdentityId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        merchantId = try container.decodeIfPresent(String.self, forKey: .merchantId) ?? ""
        merchantMid = try container.decodeIfPresent(String.self, forKey: .merchantMid) ?? ""
        deviceId = try container.decodeIfPresent(String.self, forKey: .deviceId) ?? ""
        
        // Only for buyerIdentityId: null → nil, preserve empty strings as-is
        if container.contains(.buyerIdentityId) {
            _buyerIdentityId = try container.decode(String?.self, forKey: .buyerIdentityId)
        } else {
            _buyerIdentityId = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(merchantId, forKey: .merchantId)
        try container.encode(merchantMid, forKey: .merchantMid)
        try container.encode(deviceId, forKey: .deviceId)
        
        // Only for buyerIdentityId: exclude nil from JSON, use "buyerIdentityId" key
        try container.encodeIfPresent(_buyerIdentityId, forKey: .buyerIdentityId)
    }
    
    // Add default initializer for creating new instances
    init() {
        // All fields already have default values
    }
}

struct AllEnvironmentConfigurations: Codable {
    var configs: [Finix.Environment: EnvironmentConfiguration] = [:]
    var selectedEnvironment: Finix.Environment = .Sandbox
    
    func currentEnvConfigs() -> EnvironmentConfiguration {
        return configs[selectedEnvironment] ?? EnvironmentConfiguration()
    }
}

struct SplitTransferEntry: Identifiable, Codable {
    var id = UUID()
    var merchantID: String = ""
    var amount: String = ""
    var fee: String = ""
    var tags: String = ""
}

struct UserSessionData: Codable {
    var allConfigs: AllEnvironmentConfigurations = AllEnvironmentConfigurations()
    var enableSplitTransfers: Bool = false
    var splitTransferEntries: [SplitTransferEntry] = []
    var tagsString: String = ""
}

protocol UserSessionStorage {
    func saveUserSessionData(_ sessionData: UserSessionData) throws
    func loadUserSessionData() -> UserSessionData
}

struct UserDefaultsUserSessionStorage: UserSessionStorage {
    private let userSessionKey = "finixUserSessionData"
    
    func saveUserSessionData(_ sessionData: UserSessionData) throws {
        // Clean up buyerIdentityId: store nil if empty string
        var sessionDataToSave = sessionData
        var allConfigs = sessionDataToSave.allConfigs
        for (env, var config) in allConfigs.configs {
            if let buyerId = config.buyerIdentityId, buyerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                config.buyerIdentityId = nil
            }
            allConfigs.configs[env] = config
        }
        sessionDataToSave.allConfigs = allConfigs
        let encoded = try JSONEncoder().encode(sessionDataToSave)
        UserDefaults.standard.set(encoded, forKey: userSessionKey)
    }
    
    func loadUserSessionData() -> UserSessionData {
        if let data = UserDefaults.standard.data(forKey: userSessionKey),
           var decoded = try? JSONDecoder().decode(UserSessionData.self, from: data) {
            // Clean up buyerIdentityId: treat empty string as nil
            var allConfigs = decoded.allConfigs
            for (env, var config) in allConfigs.configs {
                if let buyerId = config.buyerIdentityId, buyerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    config.buyerIdentityId = nil
                }
                allConfigs.configs[env] = config
            }
            decoded.allConfigs = allConfigs
            return decoded
        }
        return UserSessionData()
    }
}
