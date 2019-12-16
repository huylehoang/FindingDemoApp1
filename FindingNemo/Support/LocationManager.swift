//
//  LocationManager.swift
//  FindingNemo
//
//  Created by LeeX on 11/20/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import CoreLocation
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
    
    typealias LocationCallBack = (CLLocationCoordinate2D) -> Void
    typealias HeadingCallBack = () -> Void
    typealias ErrorCallback = (LocationError) -> Void
    var currentLocation: LocationCallBack?
    var error: ErrorCallback?
    var heading: CLLocationDirection?
    var newHeading: HeadingCallBack?
    
    private var locationManager: CLLocationManager!
    private var isUpdatingLocation: Bool = false
    private var isUpdatingHeading: Bool = false
    
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
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        print("start updating location")
        self.locationManager.startUpdatingLocation()
        isUpdatingLocation = true
    }
    
    func stopUpdatingLocation(bySpecific error: LocationError? = nil) {
        guard isUpdatingLocation else { return }
        print("stop updating location")
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
        self.currentLocation?(location.coordinate)
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
    func isNewLocation(checkBy locationDate: Date) -> Bool {
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
        guard isNewLocation(checkBy: location.timestamp) else {
            print("Location is old")
            return false
        }
        
        guard location.horizontalAccuracy > 0 else {
            print("Latitidue and longitude values are invalid.")
            return false
        }
        
        guard location.horizontalAccuracy < 100 && location.verticalAccuracy < 50 else {
            print("Accuracy is too low. ")
            print("Horizontal accuracy \(location.horizontalAccuracy)")
            print("Vertical Accuracy \(location.verticalAccuracy)\n")
            return false
        }
        
        return true
    }
    
    func valid(_ heading: CLHeading) -> Bool {
        guard isNewLocation(checkBy: heading.timestamp) else {
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
