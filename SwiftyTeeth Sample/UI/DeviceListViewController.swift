//
//  DeviceListViewController.swift
//  SwiftyTeeth Sample
//
//  Created by Basem Emara on 10/27/16.
//
//

import UIKit
import SwiftyTeeth

class DeviceListViewController: UITableViewController {
    
    fileprivate var devices = [Device]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let scanButton = UIBarButtonItem(title: "Scan", style: .plain, target: self, action: #selector(scanTapped))
        self.navigationItem.rightBarButtonItem = scanButton
    }
}


// MARK: - SwiftyTeethable
extension DeviceListViewController: SwiftyTeethable {
    func scanTapped() {
        // TODO: Use the changes API to update the list
        swiftyTeeth.scan(for: 1) { devices in
            self.devices = devices
            self.tableView.reloadData()
        }
    }
}


// MARK: - UITableViewDelegate
extension DeviceListViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)
        let device = devices[indexPath.row]
        print("Try to connect")
        device.connect { isConnected in
            print("isConnected? \(isConnected)")
            device.discoverServices(complete: { services, error in
                for service in services {
                    device.discoverCharacteristics(for: service, complete: { error in
                        
                    })
                }
            })
        }
    }
    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
//        
//        // Only perform segue if we have beacon previously in range
//        let beaconModel = BeaconManager.shared.assignedBeacons[indexPath.row]
//        guard BeaconManager.shared.beacons[beaconModel.macAddress] != nil else {
//            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
//            return
//        }
//        
//        performSegueWithIdentifier(popoverSegue, sender: cell)
//    }
}


// MARK: - UITableViewDataSource
extension DeviceListViewController {
    
    static let cellIdentifier = "cellIdentifier"
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeviceListViewController.cellIdentifier, for: indexPath)
        
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = device.id
        return cell
    }
}
