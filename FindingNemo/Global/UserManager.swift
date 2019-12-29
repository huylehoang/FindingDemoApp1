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
    
    var needFlash: Bool {
        return builder.needFlash
    }
    
    var connectedCLLLocation: CLLocation?
    
    private var builder: UserBuilder!

    private init() {
        setup()
    }
    
    private func setup() {
        builder = UserBuilder.standard
    }
    
    func set(location: CLLocation) {
        builder.localLocation = location
        Firebase.shared.setLocation(lat: location.coordinate.latitude, long: location.coordinate.longitude)
    }
    
    func set(isFinding: Bool) {
        guard builder.isFinding != isFinding else { return }
        builder.isFinding = isFinding
        Firebase.shared.updateUser()
    }
    
    func set(connected: User) {
        builder.isFinding = false
        builder.needFlash = false
        builder.connectedToUUID = connected.uuid
        Firebase.shared.updateUser(withValues: .connectedUUID)
        Firebase.shared.updateUser(connected, withValues: .connectedUUID)
    }
    
    func set(currentUser: User?) {
        builder.isFinding = false
        if let currentUser = currentUser {
            builder.connectedToUUID = currentUser.connectedToUUID
        } else {
            builder.connectedToUUID = nil
            builder.needFlash = false
        }
    }
    
    func set(connectedLocation: CLLocation?) {
        self.connectedCLLLocation = connectedLocation
    }
    
    func set(needFlash: Bool) {
        guard builder.needFlash != needFlash else { return }
        builder.needFlash = needFlash
        Firebase.shared.updateUser(withValues: .needFlash)
    }
    
    func disconnect() {
        Firebase.shared.disconnect()
    }
}
