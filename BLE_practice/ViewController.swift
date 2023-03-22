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
    
    @IBOutlet weak var depth_text: UILabel!
    @IBOutlet weak var angle_image: UIImageView!
    @IBOutlet weak var anne: UIImageView!
    @IBOutlet weak var bottom_btn: UIButton!
    @IBOutlet weak var bar_btn: UIButton!
    @IBOutlet weak var top2_btn: UIButton!
    @IBOutlet weak var top_btn: UIButton!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var readyButton: UIButton!
    @IBOutlet weak var disconnectButton: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    
    var isanimate:Bool!
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
        anne.image = UIImage(named: "anne.png")
        angle_image.image = UIImage(named: "angle_green.png")
        isanimate = false
        view.bringSubviewToFront(top_btn)
        view.bringSubviewToFront(top2_btn)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bar_btn.center = CGPoint(x: anne.center.x, y: anne.frame.minY)
        top_btn.center = CGPoint(x: anne.center.x, y: anne.frame.minY)
        top2_btn.center = CGPoint(x: anne.center.x, y: anne.frame.minY)
        bottom_btn.center = CGPoint(x: anne.center.x, y: anne.frame.maxY)
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
            let integervalue = intValue.first!
            print("depth :", integervalue)
            self.depth_text.text = String(integervalue)
            if(integervalue < 35){
                if(isanimate == false){
                    isanimate = true
                    underanimate()
                    underanimate_move()
                }
            } else if(integervalue > 60){
                if(isanimate == false){
                    isanimate = true
                    overanimate()
                    overanimate_move()
                }
            } else{
                if(isanimate == false){
                    isanimate = true
                    correctanimate()
                    correctanimate_move()
                }
            }
        } else if characteristic.uuid == angleUUID{
            let value = characteristic.value
            let intValue = parseBuf(data: (value)!)
            let integervalue = intValue.first!
            print("angle :", intValue)
            if(integervalue < 30){
                angle_image.image = UIImage(named: "angle_red.png")
            } else if(integervalue > 60){
                angle_image.image = UIImage(named: "angle_green.png")
            } else{
                angle_image.image = UIImage(named: "angle_orange.png")
            }
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
    
    func correctanimate(){
        self.bar_btn.configuration?.background.backgroundColor = UIColor.green
        var origincolor = self.bottom_btn.configuration?.background.backgroundColor
        self.bottom_btn.configuration?.background.backgroundColor = UIColor.green
        let originalFrame = self.bar_btn.frame
        print(originalFrame)
        let newHeight = self.bottom_btn.frame.minY - self.bar_btn.frame.minY
        self.bar_btn.frame.size.height = newHeight
        self.bar_btn.center.y += (newHeight - self.bar_btn.frame.size.height) / 2
        UIView.animate(withDuration: 0.3, animations: {
            //self.bar_btn.backgroundColor = UIColor.green
            self.bar_btn.layoutIfNeeded()
        }, completion: { finished in
            // 애니메이션이 완료된 후 실행할 코드
            self.bar_btn.frame = originalFrame
            self.bottom_btn.configuration?.background.backgroundColor = origincolor
            self.isanimate = false
        })
        
    }
    
    func correctanimate_move(){
        let originalFrame = self.top_btn.frame
        print(originalFrame)
        top_btn.center = CGPoint(x: anne.center.x, y: anne.frame.minY)
        bottom_btn.center = CGPoint(x: anne.center.x, y: anne.frame.maxY)
        UIView.animate(withDuration:0.3, animations:
        {
            self.top_btn.center.y = self.bottom_btn.center.y
        })
        {(finished) in
            self.top_btn.center = CGPoint(x: self.anne.center.x, y: self.anne.frame.minY)
            self.bottom_btn.center = CGPoint(x: self.anne.center.x, y: self.anne.frame.maxY)
        }
    }
    
    func underanimate(){
        self.bar_btn.configuration?.background.backgroundColor = UIColor.red
        var origincolor = self.bottom_btn.configuration?.background.backgroundColor
        self.bottom_btn.configuration?.background.backgroundColor = UIColor.red
        let originalFrame = self.bar_btn.frame
        print(originalFrame)
        let newHeight = (self.bottom_btn.frame.minY - self.bar_btn.frame.minY) / 3 * 2
        self.bar_btn.frame.size.height = newHeight
        self.bar_btn.center.y += (newHeight - self.bar_btn.frame.size.height) / 2
        UIView.animate(withDuration: 0.3, animations: {
            //self.bar_btn.backgroundColor = UIColor.green
            self.bar_btn.layoutIfNeeded()
        }, completion: { finished in
            // 애니메이션이 완료된 후 실행할 코드
            self.bar_btn.frame = originalFrame
            self.bottom_btn.configuration?.background.backgroundColor = origincolor
            self.isanimate = false
        })
    }
    
    func underanimate_move(){
        let originalFrame = self.top_btn.frame
        print(originalFrame)
        top_btn.center = CGPoint(x: anne.center.x, y: anne.frame.minY)
        bottom_btn.center = CGPoint(x: anne.center.x, y: anne.frame.maxY)
        UIView.animate(withDuration:0.3, animations:
        {
            self.top_btn.center.y += (self.bottom_btn.center.y - self.top_btn.center.y) / 3 * 2
        })
        {(finished) in
            self.top_btn.center = CGPoint(x: self.anne.center.x, y: self.anne.frame.minY)
            self.bottom_btn.center = CGPoint(x: self.anne.center.x, y: self.anne.frame.maxY)
        }
    }
    
    func overanimate(){
        self.bar_btn.configuration?.background.backgroundColor = UIColor.red
        var origincolor = self.bottom_btn.configuration?.background.backgroundColor
        self.bottom_btn.configuration?.background.backgroundColor = UIColor.red
        let originalFrame = self.bar_btn.frame
        print(originalFrame)
        let newHeight = (self.bottom_btn.frame.minY - self.bar_btn.frame.minY) / 3 * 4
        self.bar_btn.frame.size.height = newHeight
        self.bar_btn.center.y += (newHeight - self.bar_btn.frame.size.height) / 2
        UIView.animate(withDuration: 0.3, animations: {
            //self.bar_btn.backgroundColor = UIColor.green
            self.bar_btn.layoutIfNeeded()
        }, completion: { finished in
            // 애니메이션이 완료된 후 실행할 코드
            self.bar_btn.frame = originalFrame
            self.bottom_btn.configuration?.background.backgroundColor = origincolor
            self.isanimate = false
        })
    }
    
    func overanimate_move(){
        let originalFrame = self.top_btn.frame
        print(originalFrame)
        top_btn.center = CGPoint(x: anne.center.x, y: anne.frame.minY)
        bottom_btn.center = CGPoint(x: anne.center.x, y: anne.frame.maxY)
        UIView.animate(withDuration:0.3, animations:
        {
            self.top_btn.center.y += (self.bottom_btn.center.y - self.top_btn.center.y) / 3 * 4
        })
        {(finished) in
            self.top_btn.center = CGPoint(x: self.anne.center.x, y: self.anne.frame.minY)
            self.bottom_btn.center = CGPoint(x: self.anne.center.x, y: self.anne.frame.maxY)
        }
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
