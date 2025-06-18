//
//  ContentViewModel.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/26/25.
//

import SwiftUI
import PaxMposSDK
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var amountText: String = "3.14"
    @Published private(set) var logOutput: String = "Logs will appear here"
    @Published private(set) var connectedDeviceText: String = Constants.disconnectedText
    @Published var showingAlert: Bool
    @Published var showingDeviceList: Bool {
        didSet {
            if !showingDeviceList {
                // Reset list of devices when the device list is dismissed
                devices = []
            }
        }
    }
    @Published private(set) var devices: [Device] = []
    
    @Published var showConfigurationSheet: Bool = false
    // Published configuration properties for UI bindings
    @Published var environment: Finix.Environment = .QA
    @Published var username: String = Constants.username
    @Published var password: String = Constants.password
    @Published var merchantId: String = Constants.merchantId
    @Published var merchantMid: String = Constants.merchantMid
    @Published var deviceId: String = Constants.deviceId
    
    // A flag to reinit the FinixClient when the configuration changes
    @Published var reinitFinixClient: Bool = false
    
    private let storage: ConfigurationStorage
    
    var alertObject: (title: String, message: String) {
        didSet {
            showingAlert = true
        }
    }
    
    private var connectedDevice: DeviceInfo? {
        didSet {
            if let connectedDevice {
                connectedDeviceText = String(format: Constants.connectedText, connectedDevice.name ?? Constants.unknownDeviceText)
            } else {
                connectedDeviceText = Constants.disconnectedText
            }
        }
    }
    
    var isDeviceConnected: Bool {
        return connectedDevice != nil
    }
    
    /// Create a FinixConfig object from current values
    private var finixConfig: FinixConfig {
        FinixConfig(
            environment: environment,
            credentials: Finix.APICredentials(username: username, password: password),
            merchantId: merchantId,
            mid: merchantMid,
            deviceType: .Pax,
            deviceId: deviceId
        )
    }
    
    private var cancellable: AnyCancellable?
    
    private(set) lazy var finixClient: FinixClient = {
        return getFinixClient()
    }()
    
    init(showingAlert: Bool = false,
         showingDeviceList: Bool = false,
         alertObject: (title: String, message: String) = ("", ""),
         storage: ConfigurationStorage = UserDefaultsConfigurationStorage()) {
        self.showingAlert = showingAlert
        self.showingDeviceList = showingDeviceList
        self.alertObject = alertObject
        self.storage = storage
        
        cancellable = $reinitFinixClient.sink { [weak self] reinitFinixClient in
            guard let self = self, reinitFinixClient else { return }
            // TODO: refactor how username and password are used so we can get rid of configSaved.
            // Currently, they are set in FinixClient.init, so we need to recreate the client when they change.
            self.finixClient = self.getFinixClient()
            self.reinitFinixClient = false
        }
    }
    
    func onScanForDevicesTapped() {
        debugPrint("didTapScan")
        self.showingDeviceList = true
        finixClient.startScan()
    }
    
    func onDisconnectCurrentDeviceTapped() {
        debugPrint("didTapDisconnect")
        _ = finixClient.disconnectDevice()
    }
    
    func onSaleTapped() {
        debugPrint("didTapSale")
        startTransaction(transactionType: .sale)
    }
    
    func onAuthTapped() {
        debugPrint("didTapAuth")
        startTransaction(transactionType: .auth)
    }
    
    func onRefundTapped() {
        debugPrint("didTapRefund")
        startTransaction(transactionType: .refund)
    }
    
    func onCancelTapped() {
        debugPrint("didTapCancel")
        finixClient.stopCurrentOperation()
    }

    func onClearLogsTapped() {
        self.logOutput = ""
    }
    
    func onResetDeviceTapped() {
        debugPrint("didTapResetDevice")
        guard let connectedDevice else {
            appendLogOutput("No device connected")
            return
        }
        
        finixClient.resetDevice(deviceId: connectedDevice.deviceId, statusCallback: { file, progress, total in
            self.appendLogOutput("updating \(file): \(progress)/\(total)")
        }, completion: {
            self.appendLogOutput("finished resetting device")
        })
    }
    
    func selectDevice(_ device: Device) {
        self.showingDeviceList = false
        self.appendLogOutput("Connecting to device: \(device.name)...")
        self.finixClient.connectDevice(device.id)
    }
}

// MARK: - Private methods
extension ContentViewModel {
    private func getFinixClient() -> FinixClient {
        let finixClient = FinixClient(config: finixConfig)
        finixClient.delegate = self
        finixClient.interactionDelegate = self
        return finixClient
    }

    private func startTransaction(transactionType: FinixClient.TransactionType) {
        guard let amountDouble = Double(amountText) else {
            alertObject = ("Missing transaction amount", "Enter a transaction amount")
            return
        }
        finixClient.update(deviceId: deviceId)
        let transactionAmount = Currency(amount: Int(amountDouble * 100), code: .USD)
        finixClient.startTransaction(amount: transactionAmount, type: transactionType) { transferResponse, error in
            // run on the main thread only since we're doing UI updates
            // startTransaction's completion handler isn't guaranteed to return on main thread
            Task { @MainActor in
                guard let transferResponse = transferResponse else {
                    debugPrint("Transfer missing!")
                    debugPrint("got error \(String(describing: error))")
                    self.alertObject = ("Transfer Missing", "Got error \(String(describing: error))")
                    return
                }

                debugPrint("got traceId =\(transferResponse.traceId)")
                debugPrint("transfer = \(transferResponse)")
                self.alertObject = ("Transaction Done", "\(transferResponse)")
            }
        }
    }
    
    /// Append a new log message to the logOutput next line
    private func appendLogOutput(_ message: String) {
        self.logOutput += "\n" + message
    }
}

// MARK: - FinixDelegate
extension ContentViewModel: FinixDelegate {
    nonisolated func didDiscoverDevice(_ deviceInfo: DeviceInfo) {
        Task { @MainActor in
            devices.append(.init(id: deviceInfo.deviceId, name: deviceInfo.name ?? ""))
        }
    }

    nonisolated func deviceDidConnect(_ deviceInfo: DeviceInfo) {
        Task { @MainActor in
            debugPrint("Device connected: \(deviceInfo.deviceId))")
            self.appendLogOutput("Connected: \(deviceInfo.name ?? Constants.unknownDeviceText)")
            connectedDevice = deviceInfo
        }
    }

    nonisolated func deviceDidDisconnect() {
        Task { @MainActor in
            let message = "Device disconnected"
            debugPrint(message)
            self.appendLogOutput(message)
            connectedDevice = nil
        }
    }

    nonisolated func deviceDidError(_ error: any Error) {
        Task { @MainActor in
            debugPrint("Device connection error \(error)")
            self.appendLogOutput("Device connection error \(error)")
        }
    }
}

// MARK: - FinixClientDeviceInteractionDelegate
extension ContentViewModel: FinixClientDeviceInteractionDelegate {
    nonisolated func onDisplayText(_ text: String) {
        Task { @MainActor in
            debugPrint("SHOW PROMPT: \(text)")
            self.appendLogOutput(text)
        }
    }

    nonisolated func onRemoveCard() {
        Task { @MainActor in
            self.appendLogOutput("Card Removed")
        }
    }
}

// MARK: - Configuration methods
extension ContentViewModel {
    /// Save configuration to Storage
    func saveConfiguration() {
        let configDict: [UserDefaultsKey: Any] = [
            .environment: environment.stringValue,
            .username: username,
            .password: password,
            .merchantId: merchantId,
            .mid: merchantMid,
            .deviceId: deviceId
        ]
        let stringKeyedDict = Dictionary(uniqueKeysWithValues: configDict.map { (key, value) in (key.rawValue, value) })
        
        storage.saveConfiguration(stringKeyedDict)
        
        reinitFinixClient = true
    }
    
    func restoreDefaults() {
        let configDict: [UserDefaultsKey: Any] = [
            .environment: Finix.Environment.QA.stringValue,
            .username: Constants.username,
            .password: Constants.password,
            .merchantId: Constants.merchantId,
            .mid: Constants.merchantMid,
            .deviceId: Constants.deviceId
        ]
        let stringKeyedDict = Dictionary(uniqueKeysWithValues: configDict.map { (key, value) in (key.rawValue, value) })
        
        storage.saveConfiguration(stringKeyedDict)
        
        environment = .QA
        username = Constants.username
        password = Constants.password
        merchantId = Constants.merchantId
        merchantMid = Constants.merchantMid
        deviceId = Constants.deviceId
        
        reinitFinixClient = true
    }

    /// Load configuration from Storage
    func loadConfiguration() {
        guard let savedConfig = storage.loadConfiguration() else { return }
        
        if let envString = savedConfig[UserDefaultsKey.environment.rawValue] as? String,
            let env = Finix.Environment(from: envString) {
            environment = env
        }
        username = savedConfig[UserDefaultsKey.username.rawValue] as? String ?? ""
        password = savedConfig[UserDefaultsKey.password.rawValue] as? String ?? ""
        merchantId = savedConfig[UserDefaultsKey.merchantId.rawValue] as? String ?? ""
        merchantMid = savedConfig[UserDefaultsKey.mid.rawValue] as? String ?? ""
        deviceId = savedConfig[UserDefaultsKey.deviceId.rawValue] as? String ?? ""
        
        reinitFinixClient = true
    }
}
