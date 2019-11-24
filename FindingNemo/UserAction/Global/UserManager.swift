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
    
    var currentCLLocation: CLLocation {
        return CLLocation(latitude: builder.localLatitude, longitude: builder.localLongtitude)
    }
    
    private var builder: UserBuilder!

    init() {
        builder = UserBuilder.standard
    }
    
    func set(latitude: CLLocationDegrees) {
        builder.localLatitude = latitude
    }
    
    func set(longtitude: CLLocationDegrees) {
        builder.localLongtitude = longtitude
    }
    
    func set(isFinding: Bool) {
        builder.isFinding = isFinding
    }
    
    func set(connectedToUUID: String?) {
        builder.connectedToUUID = connectedToUUID
    }
}
