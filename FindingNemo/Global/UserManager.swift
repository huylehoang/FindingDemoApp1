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
    
    func set(connected: User?, inObserver: Bool = false, completion: (() -> Void)? = nil) {
        builder.isFinding = false
        if let connectedUser = connected {
            builder.connectedToUUID = connectedUser.uuid
            if !inObserver {
                Firebase.shared.updateUser(withValues: .connectedUUID(connected: true))
                Firebase.shared.updateUser(connectedUser, withValues: .connectedUUID(connected: true))
            }
        } else {
            if !inObserver {
                disconnect()
            }
            builder.connectedToUUID = nil
        }
    }
    
    func set(connectedLocation: CLLocation?) {
        self.connectedCLLLocation = connectedLocation
    }
    
    func disconnect() {
        if let connectedUUID = UserManager.shared.currentUser.connectedToUUID {
            Firebase.shared.fetch(byUUID: connectedUUID) { (connectedUser) in
                self.fetchAndDisconnect(connectedUser)
            }
        } else {
            Firebase.shared.fetch(byUUID: currentUser.uuid) { (user) in
                if let connectedUUID = user?.connectedToUUID {
                    Firebase.shared.fetch(byUUID: connectedUUID) { (connectedUser) in
                        self.fetchAndDisconnect(connectedUser)
                    }
                }
            }
        }
    }
    
    private func fetchAndDisconnect(_ connectedUser: User?) {
        Firebase.shared.updateUser(withValues: .connectedUUID(connected: false))
        guard let connectedUser = connectedUser else { return }
        Firebase.shared.updateUser(connectedUser, withValues: .connectedUUID(connected: false))
    }
}
