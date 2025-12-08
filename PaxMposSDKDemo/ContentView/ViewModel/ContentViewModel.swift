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
    @Published private(set) var logOutput: String = Constants.noActivityYet
    @Published private(set) var connectedDeviceText: String = ""
    @Published var showingAlert: Bool = false
    @Published var showingDeviceList: Bool = false {
        didSet {
            if !showingDeviceList {
                // Reset list of devices when the device list is dismissed
                devices = []
            }
        }
    }
    @Published private(set) var devices: [Device] = []
    
    @Published var showConfigurationSheet: Bool = false
    @Published var showOthersSheet: Bool = false
    @Published var showResetDeviceAlert: Bool = false
    @Published var showDisconnectDeviceAlert: Bool = false
    @Published var lastSuccessfulTransferID: String = ""
    @Published private(set) var currentTransactionStatus: ProcessCardStatus?
    @Published private(set) var currentTransactionType: FinixClient.TransactionType = .sale
    
    @Published private(set) var userSession: UserSessionData
    
    private let storage: UserSessionStorage = UserDefaultsUserSessionStorage()
    
    var alertObject: (title: String, message: String) = ("","") {
        didSet {
            showingAlert = true
        }
    }
    
    private var connectedDevice: DeviceInfo? {
        didSet {
            if let connectedDevice {
                connectedDeviceText = connectedDevice.name ?? Constants.unknownDeviceText
            } else {
                connectedDeviceText = ""
            }
        }
    }
    
    var isDeviceConnected: Bool {
        return connectedDevice != nil
    }
    
    var isSplitTransferTransaction: Bool {
        return userSession.enableSplitTransfers && !userSession.splitTransferEntries.isEmpty
    }
    
    private(set) lazy var finixClient: FinixClient = {
        let configs = userSession.allConfigs.currentEnvConfigs()
        let finixConfig = FinixConfig(
            environment: userSession.allConfigs.selectedEnvironment,
            credentials: Finix.APICredentials(username: configs.username, password: configs.password),
            merchantId: configs.merchantId,
            mid: configs.merchantMid,
            deviceType: .Pax,
            deviceId: configs.deviceId
        )
        
        let finixClient = FinixClient(config: finixConfig)
        finixClient.delegate = self
        finixClient.interactionDelegate = self
        return finixClient
    }()
    
    private let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    init() {
        self.userSession = storage.loadUserSessionData()
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
    
    func onSendDebugLogTapped() {
        finixClient.sendDebugData()
    }
    
    #warning("TODO: unused methods, consider remove")
    func onForceParameterUpdateTapped() {
        // Force parameter update by clearing UserDefaults and disconnecting/reconnecting
        guard let connectedDevice = connectedDevice else {
            appendLogOutput("No device connected to force parameter update")
            return
        }
        
        // Clear legacy tracking to force update on next connection
        var updatedDevices = UserDefaults.standard.stringArray(forKey: "didInitialUpdateFiles") ?? []
        updatedDevices.removeAll { $0 == connectedDevice.deviceId }
        UserDefaults.standard.set(updatedDevices, forKey: "didInitialUpdateFiles")
        
        // Clear parameter versions to force update on next connection
        let allVersions = UserDefaults.standard.dictionary(forKey: "parameterFileVersions") as? [String: [String: String]] ?? [:]
        var updatedVersions = allVersions
        updatedVersions.removeValue(forKey: connectedDevice.deviceId)
        UserDefaults.standard.set(updatedVersions, forKey: "parameterFileVersions")
        
        appendLogOutput("Forced parameter update for \(connectedDevice.deviceId) - will update on next connection")
    }
    
    #warning("TODO: unused methods, consider remove")
    func checkParameterVersions() {
        // Access parameter versions directly from UserDefaults for debugging
        let allVersions = UserDefaults.standard.dictionary(forKey: "parameterFileVersions") as? [String: [String: String]] ?? [:]
        
        if allVersions.isEmpty {
            appendLogOutput("No devices with parameter versions found")
        } else {
            appendLogOutput("Parameter versions for all devices:")
            for (deviceId, versionInfo) in allVersions {
                let emv = versionInfo["emvVersion"] ?? "unknown"
                let clss = versionInfo["clssVersion"] ?? "unknown"
                let updated = versionInfo["updatedAt"] ?? "unknown"
                appendLogOutput("  • \(deviceId): EMV=\(emv), CLSS=\(clss), Updated=\(updated)")
            }
        }
        
        // Show current SDK versions
        appendLogOutput("Current SDK versions:")
        appendLogOutput("  • EMV: 2.02.15_20250908")
        appendLogOutput("  • CLSS: 2.02.15_20250908")
        
        // Show if connected device needs update
        if let connectedDevice = connectedDevice {
            let deviceVersions = allVersions[connectedDevice.deviceId]
            let storedEMV = deviceVersions?["emvVersion"] ?? "unknown"
            let storedCLSS = deviceVersions?["clssVersion"] ?? "unknown"
            
            let needsEMVUpdate = storedEMV != "2.02.15_20250908"
            let needsCLSSUpdate = storedCLSS != "2.02.15_20250908"
            let needsUpdate = needsEMVUpdate || needsCLSSUpdate
            
            appendLogOutput("Connected device \(connectedDevice.deviceId) needs update: \(needsUpdate)")
        }
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
    
    func copyLastTransferIDToClipboard() {
        UIPasteboard.general.string = lastSuccessfulTransferID
    }
    
}

// MARK: - Private methods
extension ContentViewModel {
    /// Update FinixClient configuration using client.update() instead of recreating
    private func updateFinixClientConfiguration() {
        // Update all configuration at once
        let configs = userSession.allConfigs.currentEnvConfigs()
        finixClient.update(
            environment: userSession.allConfigs.selectedEnvironment,
            credentials: Finix.APICredentials(username: configs.username, password: configs.password),
            merchantId: configs.merchantId,
            mid: configs.merchantMid,
            deviceId: configs.deviceId
        )
    }

    private func startTransaction(transactionType: FinixClient.TransactionType) {
        self.currentTransactionType = transactionType
        
        guard let amountDouble = Double(amountText) else {
            alertObject = ("Missing transaction amount", "Enter a transaction amount")
            return
        }
        
        let transactionAmount = Currency(amount: Int(amountDouble * 100), code: .USD)
        
        var splitTransfers: [SplitTransfer]? = nil
        if isSplitTransferTransaction {
            splitTransfers = userSession.splitTransferEntries.compactMap { entry in
                guard let amountDouble = Double(entry.amount) else { return nil }
                let amount = Int(amountDouble * 100)
                var fee: Int?
                if let feeDouble = Double(entry.fee) {
                    fee = Int(feeDouble * 100)
                }
                let tags = parseTags(from: entry.tags)
                return SplitTransfer(merchantID: entry.merchantID, amount: amount, fee: fee, tags: tags)
            }
        }
        
        let configs = userSession.allConfigs.currentEnvConfigs()
        finixClient.startTransaction(
            amount: transactionAmount,
            type: transactionType,
            splitTransfers: splitTransfers,
            tags: parseTags(from: userSession.tagsString),
            buyerIdentityId: configs.buyerIdentityId
        )
    }
    
    private func parseTags(from text: String) -> [String: String]? {
        guard !text.isEmpty else { return nil }
        var tags: [String: String] = [:]
        let pairs = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        for pair in pairs {
            let keyValue = pair.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            if keyValue.count == 2 {
                tags[keyValue[0]] = keyValue[1]
            }
        }
        return tags.isEmpty ? nil : tags
    }
    
    /// Append a new log message to the logOutput next line
    private func appendLogOutput(_ message: String) {
        let timestamp = logDateFormatter.string(from: Date())
        self.logOutput += "\n\n[\(timestamp)] \(message)"
    }
}

// MARK: - FinixDelegate
extension ContentViewModel: FinixDelegate {
    nonisolated func didDiscoverDevice(_ deviceInfo: DeviceInfo) {
        Task { @MainActor in
            guard deviceInfo.name?.lowercased().hasPrefix("d135") == true else { return }
            
            devices.append(.init(id: deviceInfo.deviceId, name: deviceInfo.name ?? ""))
        }
    }
    
    nonisolated func deviceConnectionStatusChanged(_ state: DeviceConnectionState) {
        Task { @MainActor in
            switch state {
            case .connecting, .initializing:
                break
            case .connected(let deviceInfo):
                debugPrint("Device connected: \(deviceInfo.deviceId))")
                self.appendLogOutput("Connected: \(deviceInfo.name ?? Constants.unknownDeviceText)")
                connectedDevice = deviceInfo
            case .disconnected:
                let message = "Device disconnected"
                debugPrint(message)
                self.appendLogOutput(message)
                connectedDevice = nil
            case .error(let error):
                debugPrint("Device connection error \(error)")
                self.appendLogOutput("Device connection error \(error)")
            @unknown default:
                let message = "Unknown device connection state"
                debugPrint(message)
                self.appendLogOutput(message)
            }
        }
    }
    
    nonisolated func startTransactionStatusChanged(_ status: ProcessCardStatus) {
        // run on the main thread only since we're doing UI updates
        // startTransaction's completion handler isn't guaranteed to return on main thread
        Task { @MainActor in
            self.currentTransactionStatus = status
            
            switch status {
            case .readingCard:
                break
            case .processingCard:
                self.appendLogOutput("Processing card...")
            case .success(let transferResponse):
                debugPrint("got traceId =\(transferResponse.traceId ?? "nil")")
                debugPrint("transfer = \(transferResponse)")
                self.lastSuccessfulTransferID = transferResponse.id ?? ""
                self.appendLogOutput("Successfully processed $\(amountText) \(currentTransactionType.displayName)")
                
                onTransactionFinished()
            case .failed(let error):
                debugPrint("Transfer missing!")
                debugPrint("got error \(String(describing: error))")
                self.appendLogOutput("Transaction failed: \(String(describing: error))")
                
                onTransactionFinished()
            @unknown default:
                debugPrint("Got unknown default error!")
                self.appendLogOutput("Transaction failed: Unknown error")
            }
        }
    }
    
    private func onTransactionFinished() {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Wait for 2 seconds then reset
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            self.currentTransactionStatus = nil
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
    
    nonisolated func promptForCard(_ mode: CardSearchMode) {
        debugPrint("PROMPT FOR CARD, MODE: \(mode)")
    }
}

// MARK: - Configuration methods
extension ContentViewModel {
    func saveConfiguration(_ allConfigs: AllEnvironmentConfigurations) {
        do {
            var tempUserSession = self.userSession
            tempUserSession.allConfigs = allConfigs
            try storage.saveUserSessionData(tempUserSession)
            self.userSession = tempUserSession
            updateFinixClientConfiguration()
        } catch {
            alertObject = ("Failed to save configurations", "Please try again.")
        }
    }
    
    func saveOthersEntries(
        enableSplitTransfers: Bool,
        splitTransferEntries: [SplitTransferEntry],
        tagsString: String) {
        do {
            var tempUserSession = self.userSession
            tempUserSession.enableSplitTransfers = enableSplitTransfers
            tempUserSession.splitTransferEntries = splitTransferEntries
            tempUserSession.tagsString = tagsString
            try storage.saveUserSessionData(tempUserSession)
            self.userSession = tempUserSession
        } catch {
            alertObject = ("Failed to save entries", "Please try again.")
        }
    }
}
