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
        case .other(let error):
            return error.localizedDescription
        }
    }
}

class LocationManager: NSObject {
    static let shared = LocationManager()
    
    typealias UpdatedLocation = (Result<CLLocationCoordinate2D, LocationError>) -> Void
    var currentLocation: UpdatedLocation?
    
    private var locationManager: CLLocationManager!
    private var isUpdating: Bool = false
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        self.locationManager = CLLocationManager()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.distanceFilter = 2.5
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestLocation()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    func startUpdatingLocation() {
        guard !isUpdating else { return }
        self.locationManager.startUpdatingLocation()
        isUpdating = true
    }
    
    func stopUpdatingLocation() {
        guard isUpdating else { return }
        self.locationManager.stopUpdatingLocation()
        isUpdating = false
        currentLocation?(.failure(.turnOff))
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard CLLocationManager.locationServicesEnabled() else {
            currentLocation?(.failure(.serviceNotFound))
            return
        }
        switch status {
        case .authorizedAlways:
            startUpdatingLocation()
        case .authorizedWhenInUse, .denied, .restricted:
            currentLocation?(.failure(.accessDenied))
        case .notDetermined:
            self.locationManager.requestAlwaysAuthorization()
        @unknown default:
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            currentLocation?(.failure(.invalidLocation))
            return
        }
        currentLocation?(.success(location.coordinate))
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        currentLocation?(.failure(.other(error)))
    }
}
