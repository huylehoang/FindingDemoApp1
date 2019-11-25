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
    
    var needFetchNearByUser: Bool {
        return builder.isFinding && builder.connectedToUUID == nil
    }
    
    var currentCLLocation: CLLocation {
        return CLLocation(latitude: builder.localLatitude, longitude: builder.localLongtitude)
    }
    
    private var builder: UserBuilder!

    init() {
        setup()
    }
    
    private func setup() {
        builder = UserBuilder.standard
        FetchUserService().execute(fetchByUUID: builder.uuid) { (exists, snapshot) in
            if exists {
                self.builder = UserBuilder(with: snapshot)
            }
        }
    }
    
    func set(location: CLLocationCoordinate2D) {
        builder.localLatitude = location.latitude
        builder.localLongtitude = location.longitude
    }
    
    func set(isFinding: Bool) {
        if builder.connectedToUUID == nil && builder.isFinding {
            builder.isFinding = false
            UpdateUserService().execute()
        } else if builder.isFinding != isFinding {
            builder.isFinding = isFinding
            UpdateUserService().execute()
        }
    }
    
    func set(connectedToUUID: String?) {
        builder.isFinding = !(connectedToUUID != nil)
        builder.connectedToUUID = connectedToUUID
    }
}
