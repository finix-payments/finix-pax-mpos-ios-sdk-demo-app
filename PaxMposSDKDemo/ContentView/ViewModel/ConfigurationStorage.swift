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
        let encoded = try JSONEncoder().encode(sessionData)
        UserDefaults.standard.set(encoded, forKey: userSessionKey)
    }
    
    func loadUserSessionData() -> UserSessionData {
        if let data = UserDefaults.standard.data(forKey: userSessionKey),
           let decoded = try? JSONDecoder().decode(UserSessionData.self, from: data) {
            return decoded
        }
        return UserSessionData()
    }
}
