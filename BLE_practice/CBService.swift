//
//  CBService.swift
//  BLE_practice
//
//  Created by Credo on 2023/03/09.
//

import Foundation
import CoreLocation
import CoreBluetooth

class CBService {
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    
    let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    let depthUUID = CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb")
    let angleUUID = CBUUID(string: "0000fff2-0000-1000-8000-00805f9b34fb")
    let writeUUID = CBUUID(string: "0000fff4-0000-1000-8000-00805f9b34fb")
    
    
}
