//
//  ContentViewModel.swift
//  PaxMposSDKDemo
//
//  Created by Tom Nguyen on 1/13/25.
//

import SwiftUI
import PaxMposSDK

@MainActor
class ContentViewModel: ObservableObject {
    private let TEST_VERSION = "Finix-PAX-Test" // It's up to you to set this
    private let TEST_APPLICATION = "Version=2.0" // It's up to you to set this
    private let TEST_USERNAME = "UScZrfCKfP61PovTf3sAkh15"
    private let TEST_PASSWORD = "ecd256d1-7950-403c-9be6-4a1c6eda9713"
    private let TEST_ENVIRONMENT: Finix.Environment = .QA
    private let TEST_MERCHANT_ID = "MU22sfqGzpXzjdve2eDukxbg"
    private let TEST_MERCHANT_MID = "e7fc4707-bdef-4bbe-abce-6a99b3cc8562"
    private let TEST_DEVICE_ID = "DVoqLzopqkDro71WnBciSWb4"
    
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
    
    private lazy var credentials: Finix.APICredentials = {
        Finix.APICredentials(username: TEST_USERNAME, password: TEST_PASSWORD)
    }()
    
    private lazy var finixClient: FinixClient = {
        let finixClient = FinixClient(config: FinixConfig(environment: TEST_ENVIRONMENT,
                                                          credentials: credentials,
                                                          application: TEST_APPLICATION,
                                                          version: TEST_VERSION,
                                                          merchantId: TEST_MERCHANT_ID,
                                                          mid: TEST_MERCHANT_MID,
                                                          deviceType: .Pax,
                                                          deviceId: ""))
        finixClient.delegate = self
        finixClient.interactionDelegate = self
        return finixClient
    }()
    
    init(showingAlert: Bool = false,
         showingDeviceList: Bool = false,
         alertObject: (title: String, message: String) = ("", "")) {
        self.showingAlert = showingAlert
        self.showingDeviceList = showingDeviceList
        self.alertObject = alertObject
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
    
    func onUpdateFilesTapped() {
        debugPrint("didTapUpdateFiles")
        finixClient.updateCardReaderFiles { file, progress, total in
            self.appendLogOutput("uploading \(file): \(progress)/\(total)")
        }
    }
    
    func selectDevice(_ device: Device) {
        self.showingDeviceList = false
        self.appendLogOutput("Connecting to device: \(device.name)")
        self.finixClient.connectDevice(device.id)
    }
}

// MARK: - Private methods
extension ContentViewModel {
    private func startTransaction(transactionType: FinixClient.TransactionType) {
        guard let amountDouble = Double(amountText) else {
            alertObject = ("Missing transaction amount", "Enter a transaction amount")
            return
        }
        finixClient.update(deviceId: TEST_DEVICE_ID)
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

                print("got traceId =\(transferResponse.traceId)")
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
