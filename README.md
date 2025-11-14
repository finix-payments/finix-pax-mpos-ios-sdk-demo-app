# finix-pax-mpos-ios-sdk-demo-app

## Overview
This repository hosts the demo application for [finix-pax-mpos-ios-sdk](https://github.com/finix-payments/finix-pax-mpos-ios-sdk)

## Installation Guide
1. Clone the repository:
```bash
git clone https://github.com/finix-payments/finix-pax-mpos-ios-sdk-demo-app.git
```
2. Open the demo project:
```
finix-pax-mpos-ios-sdk-demo-app/PaxMposSDKDemo.xcodeproj
```
3. Run on a physical device:
    1. Tap `More` icon in the top-right corner, then `Configuration`, and fill out the credentials. i.e: Username, password, merchant ID, etc.
    2. Tap `More` icon, then `Others`, and add `Tags` or `Split Transfers`, if needed.
    3. Tap `Scan for Devices` to show the device list view and start scanning.
     When running for the first time after installing, the bluetooth permission prompt will be shown.
     Tap `Allow` and dismiss the device list view, then tap `Scan for Devices` again.
     **This behavior can be improved by prompting the bluetooth permission before tapping `Scan for Devices`
     for the first time.**
    4. Select the device you want to pair with.
    5. After the device is connected, adjust the amount in the text field, and try Sale, Auth, or Refund buttons
       to initiate a transaction.
    6. Interact with the mPOS device with a card to finish the transaction.
