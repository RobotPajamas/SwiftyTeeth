//
//  DeviceViewController.swift
//  SwiftyTeeth
//
//  Created by Suresh Joshi on 2017-02-05.
//
//

import UIKit
import SwiftyTeeth

class DeviceViewController: UIViewController {
    
    let serviceUuid = UUID(uuidString: "00726f62-6f74-7061-6a61-6d61732e6361")
    let txUuid = UUID(uuidString: "01726f62-6f74-7061-6a61-6d61732e6361")
    let rxUuid = UUID(uuidString: "02726f62-6f74-7061-6a61-6d61732e6361")
    
    @IBOutlet weak var textView: UITextView!
    
    var device: Device?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let readButton = UIBarButtonItem(title: "Read", style: .plain, target: self, action: #selector(read))
        let subscribeButton = UIBarButtonItem(title: "Subscribe", style: .plain, target: self, action: #selector(subscribe))
        let writeButton = UIBarButtonItem(title: "Write", style: .plain, target: self, action: #selector(write))
        self.navigationItem.rightBarButtonItems = [readButton, subscribeButton, writeButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = ""
        connect()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        device?.disconnect()
    }
    
    fileprivate func printUi(_ text: String?) {
        print(text ?? "")
        DispatchQueue.main.async {
            self.textView.text.append((text ?? "") + "\n")
        }
    }
}


// MARK: - SwiftyTeethable
extension DeviceViewController {
    
    // Connect and iterate through services/characteristics
    func connect() {
        device?.connect(complete: { isConnected in
            guard isConnected == true else {
                return
            }
                
            self.printUi("App: Device is connected? \(isConnected)")
            print("App: Starting service discovery...")
            self.device?.discoverServices(complete: { result in
                let services = result.value ?? []
                services.forEach {
                    self.printUi("App: Discovering characteristics for service: \($0.uuid.uuidString)")
                    self.device?.discoverCharacteristics(for: $0, complete: { result in
                        let service = result.value?.service
                        let characteristics = result.value?.characteristics ?? []
                        characteristics.forEach {
                            self.printUi("App: Discovered characteristic: \($0.uuid.uuidString) in \(String(describing: service?.uuid.uuidString))")
                        }
                        
                        if service == services.last {
                            self.printUi("App: All services/characteristics discovered")
                        }
                    })
                }
            })

        })
    }
    
    func disconnect() {
        device?.disconnect()
    }
    
    @objc func read() {
        device?.read(from: rxUuid!.uuidString, in: serviceUuid!.uuidString) { result in
            guard let value = result.value else {
                self.printUi("Read returned nil")
                return
            }
            self.printUi("Read value: \([UInt8](value))")
        }
    }
    
    @objc func write() {
        let command = Data([0x01])
        device?.write(data: command, to: txUuid!.uuidString, in: serviceUuid!.uuidString) { result in
            self.printUi("Write with response successful? \(result.isSuccess)")
        }
    }
    
    @objc func subscribe() {
        device?.subscribe(to: rxUuid!.uuidString, in: serviceUuid!.uuidString) { result in
            guard let value = result.value else {
                self.printUi("Subscribed value returned nil")
                return
            }
            self.printUi("Subscribed value: \([UInt8](value))")
        }
    }
}

