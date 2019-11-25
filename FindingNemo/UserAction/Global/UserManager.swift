//
//  UserManager.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import CoreLocation

class UserManager {
    static let shared = UserManager()
    var currentUser: User! {
        return User(builder: builder)
    }
    
    var readyForUpdatingLocation: Bool {
        return builder.readyForUpdatingLocation
    }
    
    var noConnedtedUUID: Bool {
        return builder.connectedToUUID == nil
    }
    
    var needFetchNearByUser: Bool {
        return builder.isFinding && noConnedtedUUID
    }
    
    var readyForDirectionToConnectedUser: Bool {
        return !needFetchNearByUser && readyForUpdatingLocation
    }
    
    var currentCLLocation: CLLocation {
        return CLLocation(latitude: builder.localLatitude, longitude: builder.localLongtitude)
    }
    
    private var connectedLatitude: CLLocationDegrees?
    private var connectedLongtitude: CLLocationDegrees?
    
    var connectedCLLLocation: CLLocation? {
        return _connectedCLLLocation
    }
    
    private var _connectedCLLLocation: CLLocation?
    
    private var builder: UserBuilder!

    init() {
        setup()
    }
    
    private func setup() {
        builder = UserBuilder.standard
        FetchUserService().execute(fetchByUUID: builder.uuid) { (exists, snapshot) in
            if exists {
                self.builder = UserBuilder(with: snapshot)
                FetchUserService().checkConnectedCurrentUser { (stillConnected) in
                    if stillConnected {
                        UserDisconnecter().execute()
                    } else {
                        if self.builder.connectedToUUID != nil {
                            self.set(connectedToUUID: nil)
                            UpdateUserService().execute(withValues: .connectedUUID(connected: false))
                        } else if self.builder.isFinding {
                            self.set(isFinding: false)
                        }
                    }
                }
            }
        }
    }
    
    func set(location: CLLocationCoordinate2D) {
        builder.localLatitude = location.latitude
        builder.localLongtitude = location.longitude
    }
    
    func set(isFinding: Bool) {
        guard builder.isFinding != isFinding else { return }
        builder.isFinding = isFinding
        UpdateUserService().execute()
    }
    
    func set(connectedToUUID: String?) {
        builder.isFinding = false
        builder.connectedToUUID = connectedToUUID
    }
    
    func set(connectedLocation: CLLocation?) {
        self._connectedCLLLocation = connectedLocation
    }
    
    func appWillTerminated() {
        self.set(connectedToUUID: nil)
        UpdateUserService().execute(withValues: .connectedUUID(connected: false))
    }
}
