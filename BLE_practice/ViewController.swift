//
//  ViewController.swift
//  BLE_practice
//
//  Created by Credo on 2023/03/06.
//

import UIKit
import CoreLocation
import CoreBluetooth

class ViewController: UIViewController, CBPeripheralDelegate {
    
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var disconnectButton: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    //var service: CBService?
    
    
    let serviceUUID = CBUUID(string: "0000fff0-0000-1000-8000-00805f9b34fb")
    let depthUUID = CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb")
    let angleUUID = CBUUID(string: "0000fff2-0000-1000-8000-00805f9b34fb")
    let writeUUID = CBUUID(string: "0000fff4-0000-1000-8000-00805f9b34fb")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    @IBAction func scanButtonTapped(_ sender: UIButton) {
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        status.text = "Scanning..."
    }
    
    
    @IBAction func connectButtonTapped(_ sender: UIButton) {
        if let peripheral = peripheral {
                    centralManager.connect(peripheral, options: nil)
                }
    }
    
    @IBAction func readyButtonTapped(_ sender: UIButton) {
        if let peripheral = peripheral {
                    let bytes: [UInt8] = [0xf1]
                    let data = Data(bytes)
                    if let characteristic = peripheral.services?.first?.characteristics?.first(where: { $0.uuid == writeUUID }) {
                        peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        status.text = "Sent 'f1' to CPR-band"
                    } else {
                        status.text = "Could not find write characteristic"
                    }
                }
    }
    
    @IBAction func startButtonTapped(_ sender: UIButton) {
        if let peripheral = peripheral {
                    let bytes: [UInt8] = [0xf3]
                    let data = Data(bytes)
                    if let characteristic = peripheral.services?.first?.characteristics?.first(where: { $0.uuid == writeUUID }) {
                        peripheral.writeValue(data, for: characteristic, type: .withResponse)
                        status.text = "Sent 'f3' to CPR-band"
                    } else {
                        status.text = "Could not find write characteristic"
                    }
                }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

            // Discover characteristics for the desired service
        if let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) {
            peripheral.discoverCharacteristics([depthUUID], for: service)
            peripheral.discoverCharacteristics([angleUUID], for: service)
            peripheral.discoverCharacteristics([writeUUID], for: service)
            print("characteristic discovered")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        guard let characteristics = service.characteristics else {return}
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify){
                print("notifyable")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //print("didUpdateValueFor characteristic")
        if characteristic.uuid == depthUUID{
            let value = characteristic.value
            let intValue = parseBuf(data: (value)!)
            print("depth :", intValue)
        } else if characteristic.uuid == angleUUID{
            let value = characteristic.value
            let intValue = parseBuf(data: (value)!)
            print("angle :", intValue)
        }
    }
    
    private func parseBuf(data: Data) -> [Int] {
        var buf = [UInt8](repeating: 0x00, count: data.count)
        (data as NSData).getBytes(&buf, length: buf.count)
        buf = buf.reversed()
        var sender = [Int]()
        for i in 0..<buf.count {
            let u18 = buf[i]
            sender.append(Int(u18))
        }
        return sender
    }
}

extension ViewController:CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            scanButton.isEnabled = true
        } else {
            scanButton.isEnabled = false
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name?.contains("CPR") == true{
                central.stopScan()
                self.peripheral = peripheral
                self.peripheral?.delegate = self
                status.text = "Found CPR-band, press connect button"
            }
        }
        
        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            status.text = "Connected to CPR-band"
            // Write your code to communicate with the CPR-band here
            peripheral.discoverServices([serviceUUID])
        }
        
        func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            status.text = "Failed to connect to CPR-band"
        }
}
