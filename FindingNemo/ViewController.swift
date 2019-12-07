//
//  ViewController.swift
//  FindingNemo
//
//  Created by LeeX on 11/20/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var arrowImgView: UIImageView!
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var mainBtn: UIButton!
    
    var directionCalculator = DirectionCalculator()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lblInfo.text = "Welcome"
        mainBtn.setTitle("Start", for: .normal)
//        LocationManager.shared.startUpdatingLocation()
        
    }
    

    @IBAction func buttonPressed(_ sender: UIButton) {
        LocationManager.shared.startUpdatingLocation()
        LocationManager.shared.currentLocation = { (location) in
            UserManager.shared.set(location: location)
            Firebase.shared.setLocation(lat: location.latitude, long: location.longitude)
            
            Firebase.shared.startQueryNearbyUser { (connectedUser) in
                UserManager.shared.set(connectedToUUID: connectedUser.uuid)
                Firebase.shared.updateUser(connectedUser, withValues: .connectedUUID(connected: true))
                Firebase.shared.getConnectedLocation { (location) in
                    UserManager.shared.set(isFinding: false)
                    UserManager.shared.set(connectedLocation: location)
                    LocationManager.shared.startUpdatingHeading()
                    if let heading = LocationManager.shared.heading, let angle = self.directionCalculator.computeNewAngle(with: CGFloat(heading), andConnectedLocation: location) {
                        self.lblInfo.text = "Connected location\n\(location.coordinate.latitude)\n\(location.coordinate.longitude)"
                        UIView.animate(withDuration: 0.5) {
                            self.arrowImgView.transform = CGAffineTransform(rotationAngle: angle)
                        }
                    }
                }
            }
            if UserManager.shared.noConnedtedUUID {
                UserManager.shared.set(isFinding: true)
                
                self.lblInfo.text = "Current user location\n\(UserManager.shared.currentCLLocation.coordinate.latitude)\n\(UserManager.shared.currentCLLocation.coordinate.longitude)"
                Firebase.shared.updateUser(UserManager.shared.currentUser)
            }
        }
    }
}

//private extension ViewController {
//    func setupUserAction() {
//        userAction.action = { [unowned self] (state) in
//            DispatchQueue.main.async {
//                switch state {
//                case .finding:
//                    self.lblInfo.text = "Updating user location\nLatitude: \(String(describing: UserManager.shared.currentUser.localLatitude))\nLongtitude: \(String(describing: UserManager.shared.currentUser.localLongtitude))"
//                    self.mainBtn.setTitle("Stop", for: .normal)
//                case .didConnect:
//                    if let uuid = UserManager.shared.currentUser.uuid {
////                        self.lblInfo.text = "My \n\(UserManager.shared.currentUser.localLatitude)\n \(UserManager.shared.currentUser.localLongtitude)\n\nConnected\n\(UserManager.shared.connectedCLLLocation?.coordinate.latitude ?? 0)\n \(UserManager.shared.connectedCLLLocation?.coordinate.longitude ?? 0)"
//                        self.mainBtn.setTitle("Disconnect", for: .normal)
//                    }
//                case .direction(let angle):
//                    self.lblInfo.text = "My \n\(UserManager.shared.currentUser.localLatitude)\n \(UserManager.shared.currentUser.localLongtitude)\n\nConnected\n\(UserManager.shared.connectedCLLLocation?.coordinate.latitude ?? 0)\n \(UserManager.shared.connectedCLLLocation?.coordinate.longitude ?? 0)"
//                    UIView.animate(withDuration: 0.5) {
//                        self.arrowImgView.transform = CGAffineTransform(rotationAngle: angle)
//                    }
//                case .didDisconnect:
//                    self.lblInfo.text = "Start Again!!!"
//                    self.mainBtn.setTitle("Start", for: .normal)
//                case .locationError(let error):
//                    self.lblInfo.text = "Stop updating user location:\n\(error.errorDescription ?? "")"
//                    self.mainBtn.setTitle("Start", for: .normal)
//                    self.arrowImgView.transform = CGAffineTransform.identity
//                }
//            }
//        }
//    }
//
//    func convertDouble(_ x: CLLocationDegrees) -> Double {
//      let y = Double(round(1000*x)/1000)
//      return y
//    }
//
//    func buttonAction(withTitle title: String) {
//        switch title {
//        case "Start":
//            userAction.startFinder()
//        case "Stop":
//            userAction.stopFinder()
//        case "Disconnect":
//            userAction.disconnect()
//        default:
//            break
//        }
//    }
//}
