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
    @IBOutlet weak var lblDistance: UILabel!
    @IBOutlet weak var lblInfo: UILabel!
    @IBOutlet weak var lblSubInfo: UILabel!
    @IBOutlet weak var lblDeviceMotion: UILabel!
    @IBOutlet weak var mainBtn: UIButton!
    @IBOutlet weak var lblLocationMangerState: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reset(error: nil)
        setup()
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        pressed(sender)
    }
}

private extension ViewController {
    func setup() {
        LocationManager.shared.currentLocation = { (location) in
            UserManager.shared.set(location: location)

            // Fetch nearby user
            Firebase.shared.startQueryNearbyUser { (connectedUser) in

                self.lblInfo.text = "Getting connected location"
                self.mainBtn.setTitle("Disconnect", for: .normal)
                
                // Updated heading if there is user ready for connecting
                LocationManager.shared.startUpdatingHeading()

                // Connect to nearby user, update current user and nearby user to firebase
                UserManager.shared.set(connected: connectedUser)
                // After updated firebase that both user are connected, start observe connected user location, this observer will not be triggered if current user is connected by another user (userConnectedObserver)
                self.observeConnectedLocation()
            }

            // Update isFinding = true if no connected user
            if UserManager.shared.noConnedtedUUID && UserManager.shared.readyForUpdatingLocation {
                UserManager.shared.set(isFinding: true)
                self.lblInfo.text = "Current user location\n\(UserManager.shared.currentCLLocation.coordinate.latitude)\n\(UserManager.shared.currentCLLocation.coordinate.longitude)"
            } else {
                self.rotate()
            }
        }
        
        LocationManager.shared.processing = { (processing) in
            self.lblSubInfo.text = processing
        }
        
        LocationManager.shared.deviceMotion = { (deviceMotion) in
            self.lblDeviceMotion.text = deviceMotion
        }
        
        LocationManager.shared.state = { (state) in
            self.lblLocationMangerState.text = state
        }

        // Update direction when updated heading, in case connected user did not change location
        LocationManager.shared.newHeading = {
            // get connected user location on firebase every time there is new heading
            Firebase.shared.getConnectedLocation { (location) in
                UserManager.shared.set(connectedLocation: location)
                self.rotate()
            }
        }

        // Error of why location manager not working or stop updating location/heading
        LocationManager.shared.error = { (error) in
            Firebase.shared.disconnect {
                UserManager.shared.reset()
                Firebase.shared.resetListener()
                self.reset(error: error.errorDescription)
            }
        }
    }
    
    func currentUserObsever() {
        // Detect when another user connected/disconnected to current user
        Firebase.shared.currentUserObsever { (currentUser) in
            guard let currentUser = currentUser else { return }
            UserManager.shared.set(currentUser: currentUser)
            self.lblInfo.text = "Getting connected location"
            self.mainBtn.setTitle("Disconnect", for: .normal)
            LocationManager.shared.startUpdatingHeading()
            // Detect when connected user update new location. Observer is added here because current user is connected by another user, not by fetching near by user (startQueryNearbyUser)
            self.observeConnectedLocation()
            
        }
    }
    
    func observeConnectedLocation() {
        Firebase.shared.connectedUserObserver { (location, needFlash) in
            guard let location = location else {
                LocationManager.shared.stopUpdatingLocation(bySpecific: LocationError.turnOffByDisconnectFromOtherUser)
                return
            }
            UserManager.shared.set(connectedLocation: location)
            
            UserManager.shared.set(needFlash: needFlash)
            self.rotate()
        }
    }
    
    func rotate() {
        self.lblInfo.text = "Direct to location\n\(UserManager.shared.connectedCLLLocation?.coordinate.latitude ?? 0.0)\n\(UserManager.shared.connectedCLLLocation?.coordinate.longitude ?? 0.0)"
        if UserManager.shared.currentUser.needFlash,
            let distance = Direction.shared.distance
        {
            if distance > Direction.shared.disconnectThreshold {
                LocationManager.shared.stopUpdatingLocation()
            } else {
                self.lblDistance.text = "Distance to connected: \(distance) meters"
            }
        } else {
            if let distance = Direction.shared.distance, distance < Direction.shared.flashThreshold {
                UserManager.shared.set(needFlash: true)
                showArrow(false)
                self.lblDistance.text = "Distance to connected: \(distance) meters"
            } else {
                showArrow(true)
                UIView.animate(withDuration: 0.3) {
                    self.arrowImgView.transform = CGAffineTransform(rotationAngle: Direction.shared.angle)
                }
            }
        }
    }
    
    func showArrow(_ show: Bool) {
        if arrowImgView.isHidden == show {
            arrowImgView.isHidden = !show
        }
        if lblDistance.isHidden != show {
            lblDistance.isHidden = show
        }
    }
    
    func reset(error: String?) {
        self.lblInfo.text = error ?? "Welcome"
        self.mainBtn.setTitle("Start", for: .normal)
        lblSubInfo.text = "Location Processing Info"
        lblDeviceMotion.text = "Device Motion Info"
        lblDistance.text = ""
        arrowImgView.transform = CGAffineTransform.identity
        showArrow(true)
    }
    
    func pressed(_ button: UIButton) {
        switch button.title(for: .normal) {
        case "Start":
            LocationManager.shared.startUpdatingLocation()
            currentUserObsever()
            self.lblInfo.text = "Updating current location"
            self.mainBtn.setTitle("Stop", for: .normal)
        case "Stop", "Disconnect":
            LocationManager.shared.stopUpdatingLocation()
        default:
            break
        }
    }
}
