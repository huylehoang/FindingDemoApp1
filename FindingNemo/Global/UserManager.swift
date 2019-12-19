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
        return !needFetchNearByUser
    }
    
    var currentCLLocation: CLLocation {
        return builder.localLocation
    }
    
    var connectedCLLLocation: CLLocation?
    
    private var builder: UserBuilder!

    private init() {
        setup()
    }
    
    private func setup() {
        builder = UserBuilder.standard
    }
    
    func set(location: CLLocationCoordinate2D) {
        builder.localLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        Firebase.shared.setLocation(lat: location.latitude, long: location.longitude)
    }
    
    func set(isFinding: Bool) {
        guard builder.isFinding != isFinding else { return }
        builder.isFinding = isFinding
        Firebase.shared.updateUser()
    }
    
    func set(connectedToUUID: String?, inObserver: Bool = false, completion: (() -> Void)? = nil) {
        builder.isFinding = false
        builder.connectedToUUID = connectedToUUID
        guard !inObserver else { return }
        Firebase.shared.updateUser(withValues: .connectedUUID(connected: connectedToUUID != nil)) {
            completion?()
        }
    }
    
    func set(connectedLocation: CLLocation?) {
        self.connectedCLLLocation = connectedLocation
    }
}
