//
//  FirstViewController.swift
//  SwiftyTeeth Sample
//
//  Created by Basem Emara on 10/27/16.
//
//

import UIKit
import SwiftyTeeth

class FirstViewController: UIViewController, SwiftyTeethable {

    @IBOutlet weak var resultLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func stateTapped() {
//        resultLabel.text = "\(swiftyTeeth.state.rawValue)"
    }
    
    @IBAction func scanTapped() {
        swiftyTeeth.scan(for: 1) { peripherals in
            self.resultLabel.text = "TODO"
            print(peripherals)
        }
    }
}

