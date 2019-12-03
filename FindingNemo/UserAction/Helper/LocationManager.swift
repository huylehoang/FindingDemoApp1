//
//  LocationManager.swift
//  FindingNemo
//
//  Created by LeeX on 11/20/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import CoreLocation

enum LocationError: LocalizedError {
    case serviceNotFound
    case accessDenied
    case invalidLocation
    case turnOff
    case turnOffByDisconnectFromOtherUser
    case other(Error)
    
    var errorDescription: String? {
        switch self {
        case .serviceNotFound:
            return "Location services are not enabled"
        case .accessDenied:
            return "Location Access (Always) denied"
        case.invalidLocation:
            return "Cannot get the user location"
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
    typealias HeadingCallBack = (CLLocationDirection) -> Void
    typealias ErrorCallback = (LocationError) -> Void
    var currentLocation: LocationCallBack?
    var currentHeading: HeadingCallBack?
    var error: ErrorCallback?
    
    private var locationManager: CLLocationManager!
    private var isUpdatingLocation: Bool = false
    private var isUpdatingHeading: Bool = false
    private var distanceFilter: CLLocationDistance = 2.5
    private var headingFilter: CLLocationDegrees = 5
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = distanceFilter
        self.locationManager.headingFilter = headingFilter
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestLocation()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startUpdatingLocation() {
        guard !isUpdatingLocation else { return }
        self.locationManager.startUpdatingLocation()
        isUpdatingLocation = true
    }
    
    func stopUpdatingLocation(bySpecific error: LocationError? = nil) {
        guard isUpdatingLocation else { return }
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
        self.locationManager.startUpdatingHeading()
        isUpdatingHeading = true
    }
    
    private func stopUpdatingHeading() {
        guard isUpdatingHeading else { return }
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
        case .authorizedAlways:
            self.startUpdatingLocation()
        case .authorizedWhenInUse, .denied, .restricted:
            self.error?(.accessDenied)
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
        @unknown default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            self.error?(.invalidLocation)
            return
        }
        self.currentLocation?(location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.currentHeading?(newHeading.trueHeading)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error?(.other(error))
    }
}
