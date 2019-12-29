//
//  LocationManager.swift
//  FindingNemo
//
//  Created by LeeX on 11/20/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import UIKit

enum LocationError: LocalizedError {
    case serviceNotFound
    case accessDenied
    case turnOff
    case turnOffByDisconnectFromOtherUser
    case other(Error)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            return "Location services are not enabled"
        case .accessDenied:
            return "Location Access (Always) denied"
        case .turnOff:
            return "Turn off updating location"
        case .turnOffByDisconnectFromOtherUser:
            return "Disconnect from other user"
        case .other(let error):
            return error.localizedDescription
        }
    }
}

class LocationManager: NSObject {
    static let shared = LocationManager()
    
    typealias LocationCallBack = (CLLocation) -> Void
    typealias HeadingCallBack = () -> Void
    typealias ErrorCallback = (LocationError) -> Void
    typealias InfoCallback = (String) -> Void
    var currentLocation: LocationCallBack?
    var error: ErrorCallback?
    var heading: CLLocationDirection?
    var newHeading: HeadingCallBack?
    var deviceMotion: InfoCallback?
    var processing: InfoCallback?
    
    private var locationManager: CLLocationManager!
    private var activityManager: CMMotionActivityManager!
    private var pedometer: CMPedometer!
    private var isUpdatingLocation: Bool = false
    private var isUpdatingHeading: Bool = false
    private var isMoving = false {
        didSet {
            if isMoving == false {
                movingDistance = nil
                pedometer.stopUpdates()
            }
        }
    }
    private var movingDistance: Double?
    
    private override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = true
        self.activityManager = CMMotionActivityManager()
        self.pedometer = CMPedometer()
    }
    
    func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        print("start updating location")
        self.locationManager.startUpdatingLocation()
        self.startMotionActivity()
        isUpdatingLocation = true
    }
    
    private func startMotionActivity() {
        guard CMMotionActivityManager.isActivityAvailable() else { return }
        self.activityManager.startActivityUpdates(to: .main) { (motionActivity) in
            guard let motion = motionActivity else {
                print("no motion\n")
                self.isMoving = false
                self.deviceMotion?("no motion, isMoving: \(self.isMoving)")
                return
            }
            guard motion.confidence.rawValue > 0 else {
                print("motion confidence is too low\n")
                self.isMoving = false
                self.deviceMotion?("motion confidence is too low, isMoving: \(self.isMoving)")
                return
            }
            guard self.isNewEvent(checkBy: motion.startDate) else {
                print("start date is not new\n")
                self.isMoving = false
                self.deviceMotion?("start date is not new, isMoving: \(self.isMoving)")
                return
            }
            if motion.stationary || motion.unknown {
                print("Is standing\n")
                self.deviceMotion?("Stationary Or Unknown, isMoving: \(self.isMoving)")
                self.isMoving = false
            } else {
                if motion.walking || motion.running || motion.cycling || motion.automotive {
                    print("Is moving\n")
                    self.isMoving = true
                    var movingMotion = ""
                    if motion.walking {
                        movingMotion = "Walking"
                    } else if motion.running {
                        movingMotion = "Running"
                    } else if motion.cycling {
                        movingMotion = "Cycling"
                    } else if motion.automotive {
                        movingMotion = "Automotive"
                    }
                    self.deviceMotion?("\(movingMotion), isMoving: \(self.isMoving)")
                    self.startUpdatePedometer(from: motion.startDate)
                }
            }
        }
    }
    
    private func startUpdatePedometer(from date: Date) {
        pedometer.startUpdates(from: date) { (pedometerData, error) in
            guard let pedometerData = pedometerData
                , error == nil
                , let distance = pedometerData.distance as? Double
                else { return }
            print("Estimated distance travelled: \(distance)")
            self.movingDistance = distance
            self.deviceMotion?("Estimated distance travelled: \(distance)")
        }
    }
    
    func stopUpdatingLocation(bySpecific error: LocationError? = nil) {
        guard isUpdatingLocation else { return }
        print("stop updating location")
        self.activityManager.stopActivityUpdates()
        self.pedometer.stopUpdates()
        self.locationManager.stopUpdatingLocation()
        self.stopUpdatingHeading()
        isUpdatingLocation = false
        if let error = error {
            self.error?(error)
        } else {
            self.error?(.turnOff)
        }
    }
    
    func startUpdatingHeading() {
        guard !isUpdatingHeading else { return }
        print("start updating heading")
        self.locationManager.startUpdatingHeading()
        isUpdatingHeading = true
    }
    
    private func stopUpdatingHeading() {
        guard isUpdatingHeading else { return }
        print("stop updating heading")
        self.locationManager.stopUpdatingHeading()
        isUpdatingHeading = false
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard CLLocationManager.locationServicesEnabled() else {
            error?(.serviceNotFound)
            return
        }
        switch status {
        case .authorizedWhenInUse, .denied, .restricted:
            self.error?(.accessDenied)
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
        default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isUpdatingLocation, let location = locations.last, valid(location)
            else { return }
        self.currentLocation?(location)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isUpdatingHeading, valid(newHeading) else { return }
        self.heading = -1.0 * (newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading)
        self.newHeading?()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error?(.other(error))
    }
}

private extension LocationManager {
    func isNewEvent(checkBy locationDate: Date) -> Bool {
        guard let diffSeconds = Calendar.current.dateComponents([.second]
            , from: locationDate
            , to: Date()).second
            , diffSeconds == 0 else
        {
            return false
        }
        return true
    }
    
    func valid(_ location: CLLocation) -> Bool {
        guard isNewEvent(checkBy: location.timestamp) else {
            print("Location is old\n")
            self.processing?("Location is old")
            return false
        }
        
        guard location.horizontalAccuracy > 0 else {
            print("Latitidue and longitude values are invalid.\n")
            self.processing?("Latitidue and longitude values are invalid.")
            return false
        }
        
        guard !UserManager.shared.readyForUpdatingLocation
            || (UserManager.shared.readyForUpdatingLocation
                && location.horizontalAccuracy <= UserManager.shared.currentCLLocation.horizontalAccuracy) else
        {
            if UserManager.shared.readyForUpdatingLocation {
                print("New location accuracy \(location.horizontalAccuracy) is lower than last location accuracy \(UserManager.shared.currentCLLocation.horizontalAccuracy)\n")
                self.processing?("New location accuracy \(location.horizontalAccuracy) is lower than last location accuracy \(UserManager.shared.currentCLLocation.horizontalAccuracy)")
            }
            return false
        }
        
        guard location.horizontalAccuracy < 80 else {
            print("Accuracy is too low \(location.horizontalAccuracy)\n")
            self.processing?("Accuracy is too low \(location.horizontalAccuracy)")
            return false
        }
        
        guard UserManager.shared.readyForUpdatingLocation else {
            print("First Location \(location.coordinate)\n")
            self.processing?("First Location \(location.coordinate)\n")
            return true
        }
        
        let distance = location.distance(from: UserManager.shared.currentCLLocation)
        if isMoving, let distanceTravelled = self.movingDistance {
            if distance <= distanceTravelled + 1.2 {
                print("New location while moving: \(location.coordinate)\n")
                self.processing?("New location while moving: \(location.coordinate)")
                return true
            }  else {
                print("Location distance from last location is greater than estimated distance")
                print("Location distance: \(distance)")
                print("Estimated distance travelled: \(distanceTravelled)\n")
                self.processing?("Location distance from last location is greater than estimated distance\nLocation distance:\n \(distance) meters\nEstimated distance travelled:\n \(distanceTravelled) meters")
                return false
            }
        } else {
            let passedTime = location.timestamp.timeIntervalSince(UserManager.shared.currentCLLocation.timestamp)
            if passedTime >= 30 {
                if distance <= 1.2 {
                    print("New location while standing: \(location.coordinate)")
                    print("Distance to last location: \(distance)\n")
                    self.processing?("New location while standing:\n \(location.coordinate.latitude)\n\(location.coordinate.longitude)\nDistance to last location:\n \(distance)")
                    return true
                } else {
                    if passedTime >= 60 {
                        print("There are any new location updated for too long (60 seconds)")
                        print("Distance to last location: \(distance)")
                        print("Passed time (seconds): \(passedTime)\n")
                        self.processing?("There are any new location updated for too long (60 seconds)\nDistance to last location: \(distance)\nPassed time (seconds):\n \(passedTime)")
                        return true
                    } else {
                        print("New location change significant to last location while standing: \(distance)")
                        print("Passed time (seconds): \(passedTime)\n")
                        self.processing?("New location change significant to last location while standing:\n \(distance)\nPassed time (seconds):\n \(passedTime)")
                        return false
                    }
                }
            } else {
                print("Not passed 30 seconds since the last updated location")
                print("Passed time (seconds): \(passedTime)\n")
                self.processing?("Not passed 30 seconds since the last updated location\nPassed time (seconds):\n \(passedTime)")
                return false
            }
        }
    }
    
    func valid(_ heading: CLHeading) -> Bool {
        guard isNewEvent(checkBy: heading.timestamp) else {
            print("Heading is old")
            return false
        }
        
        guard heading.headingAccuracy > 0 else {
            print("Heading is not accurate \(heading.headingAccuracy)")
            return false
        }
        
        return true
    }
}
