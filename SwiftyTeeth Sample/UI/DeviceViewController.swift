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
        // Using a Heart-Rate device for testing - this is the HR service and characteristic
        device?.read(from: "2a24", in: "180a", complete: { result in
            self.printUi("Read value: \(String(describing: result.value?.base64EncodedString()))")
        })
    }
    
    @objc func write() {
        let command = Data(bytes: [0x01])
        device?.write(data: command, to: "abcdef", in: "hijkll", complete: { result in
            self.printUi("Write with response successful? \(result.isSuccess)")
        })
    }
    
    @objc func subscribe() {
        device?.subscribe(to: "2a37", in: "180d", complete: { result in
            self.printUi("Subscribed value: \(String(describing: result.value?.base64EncodedString()))")
        })
    }
}

