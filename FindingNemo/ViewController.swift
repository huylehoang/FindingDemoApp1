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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        lblInfo.text = "Welcome"
        mainBtn.setTitle("Start", for: .normal)
        
        LocationManager.shared.currentLocation = { (location) in
            UserManager.shared.set(location: location)

            // Fetch nearby user
            Firebase.shared.startQueryNearbyUser { (connectedUser) in

                self.lblInfo.text = "Getting connected location"
                self.mainBtn.setTitle("Disconnect", for: .normal)
                
                // Updated heading if there is user ready for connecting
                LocationManager.shared.startUpdatingHeading()

                // Connect to nearby user, update current user and nearby user to firebase
                UserManager.shared.set(connectedToUUID: connectedUser.uuid) {
                    Firebase.shared.updateUser(connectedUser, withValues: .connectedUUID(connected: true)) {
                        // After updated firebase that both user are connected, start observe connected user location, this observer will not be triggered if current user is connected by another user (userConnectedObserver)
                        Firebase.shared.observeConnectedLocation { (location) in
                            UserManager.shared.set(connectedLocation: location)
                            self.rotate()
                        }
                    }
                }
            }

            // Update isFinding = true if no connected user
            if UserManager.shared.noConnedtedUUID {
                UserManager.shared.set(isFinding: true)
                self.lblInfo.text = "Current user location\n\(UserManager.shared.currentCLLocation.coordinate.latitude)\n\(UserManager.shared.currentCLLocation.coordinate.longitude)"
            }
        }

        // Update direction when updated heading, in case connected user did not change location
        LocationManager.shared.newHeading = {
            // get connected user location on firebase every time there is new heading
            Firebase.shared.getConnectedLocation { (location) in
                UserManager.shared.set(connectedLocation: location)
                self.rotate()
            }
            
            // Also detect when connected user update new location. Observer is added here because current user is connected by another user, not by fetching near by user (startQueryNearbyUser)
            Firebase.shared.observeConnectedLocation { (location) in
                UserManager.shared.set(connectedLocation: location)
                self.rotate()
            }
        }

        // Error of why location manager not working or stop updating location/heading
        LocationManager.shared.error = { (error) in
            UserManager.shared.set(isFinding: false)
            self.lblInfo.text = error.errorDescription
            self.mainBtn.setTitle("Start", for: .normal)
        }

        // Detect when another user connected to current user
        Firebase.shared.userConnectedObserver { (connectedUUID) in
            guard let connectedUUID = connectedUUID
                , connectedUUID != UserManager.shared.currentUser.uuid
                else { return }
            UserManager.shared.set(connectedToUUID: connectedUUID, inObserver: true)
            self.mainBtn.setTitle("Disconnect", for: .normal)
            LocationManager.shared.startUpdatingHeading()
        }

        // Detect when connected user disconnect from current user
        Firebase.shared.userDisconnectedObserver { (connectedUUID) in
            guard let _ = connectedUUID else { return }
            UserManager.shared.set(connectedToUUID: nil, inObserver: true)
            self.arrowImgView.transform = CGAffineTransform.identity
            LocationManager.shared.stopUpdatingLocation(bySpecific: LocationError.turnOffByDisconnectFromOtherUser)
        }
    }
    
    private func rotate() {
        self.lblInfo.text = "Direct to location\n\(UserManager.shared.connectedCLLLocation?.coordinate.latitude ?? 0.0)\n\(UserManager.shared.connectedCLLLocation?.coordinate.longitude ?? 0.0)"
        UIView.animate(withDuration: 0.3) {
            self.arrowImgView.transform = CGAffineTransform(rotationAngle: Direction.shared.computeNewAngle())
        }
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        switch sender.title(for: .normal) {
        case "Start":
            LocationManager.shared.startUpdatingLocation()
            self.lblInfo.text = "Updating current location"
            self.mainBtn.setTitle("Stop", for: .normal)
        case "Stop":
            LocationManager.shared.stopUpdatingLocation()
        case "Disconnect":
            LocationManager.shared.stopUpdatingLocation()
            arrowImgView.transform = CGAffineTransform.identity
            
            // Disconnect, update firebase both current user and connected user
            if let connectedUUID = UserManager.shared.currentUser.connectedToUUID {
                Firebase.shared.fetch(byUUID: connectedUUID) { (user) in
                    if let connectedUser = user {
                        UserManager.shared.set(connectedToUUID: nil)
                        Firebase.shared.updateUser(connectedUser, withValues: .connectedUUID(connected: false))
                    }
                }
            }
        default:
            break
        }
    }
}
