//
//  ViewController.swift
//  FindingNemo
//
//  Created by LeeX on 11/20/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import UIKit
import FirebaseDatabase
import GeoFire

class ViewController: UIViewController {

    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var mainBtn: UIButton!
    
    private var userAction = UserAction()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lblInfo.text = "Welcome"
        mainBtn.setTitle("Start", for: .normal)
        
        userAction.action = { [unowned self] (state) in
            DispatchQueue.main.async {
                switch state {
                case .finding(let isFinding):
                    self.lblInfo.text = "\(isFinding ? "Updating " : "Stop updating") user location\nLatitude: \(String(describing: UserManager.shared.currentUser.localLatitude))\nLongtitude: \(String(describing: UserManager.shared.currentUser.localLongtitude))"
                    self.mainBtn.setTitle(isFinding ? "Stop" : "Start", for: .normal)
                case .didConnect:
                    if let uuid = UserManager.shared.currentUser.uuid {
                        self.lblInfo.text = "User did connect to \(uuid)"
                        self.mainBtn.setTitle("Disconnect", for: .normal)
                    }
                case .didDisconnect:
                    self.lblInfo.text = "Start Again!!!"
                    self.mainBtn.setTitle("Start", for: .normal)
                }
            }
        }
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender.title(for: .normal) {
        case "Start":
            userAction.startFinder()
        case "Stop":
            userAction.stopFinder()
        case "Disconnect":
            userAction.disconnect()
        default:
            break
        }
    }
}

