//
//  ViewController.swift
//  FindingNemo
//
//  Created by LeeX on 11/20/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import UIKit
import CoreLocation
class ViewController: UIViewController {

    @IBOutlet weak var arrowImgView: UIImageView!
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var mainBtn: UIButton!
    
    private var userAction = UserAction()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lblInfo.text = "Welcome"
        mainBtn.setTitle("Start", for: .normal)
        setupUserAction()

    }
    

    @IBAction func buttonPressed(_ sender: UIButton) {
        guard let title = sender.title(for: .normal) else { return }
        buttonAction(withTitle: title)
    }
}

private extension ViewController {
    func setupUserAction() {
        userAction.action = { [unowned self] (state) in
            DispatchQueue.main.async {
                switch state {
                case .finding:
                    self.lblInfo.text = "Updating user location\nLatitude: \(String(describing: UserManager.shared.currentUser.localLatitude))\nLongtitude: \(String(describing: UserManager.shared.currentUser.localLongtitude))"
                    self.mainBtn.setTitle("Stop", for: .normal)
                case .didConnect:
                    if let uuid = UserManager.shared.currentUser.uuid {
                        self.lblInfo.text = "User did connect to \(uuid)"
                        self.mainBtn.setTitle("Disconnect", for: .normal)
                    }
                case .direction(let angle):
                    UIView.animate(withDuration: 0.5) {
                        self.arrowImgView.transform = CGAffineTransform(rotationAngle: angle)
                    }
                case .didDisconnect:
                    self.lblInfo.text = "Start Again!!!"
                    self.mainBtn.setTitle("Start", for: .normal)
                case .locationError(let error):
                    self.lblInfo.text = "Stop updating user location:\n\(error.errorDescription ?? "")"
                    self.mainBtn.setTitle("Start", for: .normal)
                    self.arrowImgView.transform = CGAffineTransform.identity
                }
            }
        }
    }
    
    func buttonAction(withTitle title: String) {
        switch title {
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
