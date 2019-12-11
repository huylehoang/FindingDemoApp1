//
//  Firebase.swift
//  FindingNemo
//
//  Created by LeeX on 12/7/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import FirebaseDatabase
import GeoFire

enum NeedUpdateValues {
    case connectedUUID(connected: Bool), basic
    
    func info(of user: User) -> [String: AnyObject] {
        switch self {
        case .connectedUUID(let connect):
            if connect {
                return user.infoWithConnectedUUID
            } else {
                return user.basicInfo
            }
        case .basic:
            return user.basicInfo
        }
    }
}

private extension Double {
    var toKM: Double {
        return self / 1000
    }
}

class Firebase {
    static let shared = Firebase()
    
    private var databaseRef: DatabaseReference = Database.database().reference().child("Users")
    private var currentUserRef: DatabaseReference!
    
    private var geoFire: GeoFire!
    private var geoQuery: GFQuery?
    private var radius: Double = 100 // meters
    
    private init() {
        geoFire = GeoFire(firebaseRef: databaseRef)
        currentUserRef = databaseRef.child(UserManager.shared.currentUser.uuid)
    }
    
    private func checkConnectedCurrentUser(completion: @escaping (Bool) -> Void) {
        fetch(byUUID: UserManager.shared.currentUser.uuid) { (user) in
            if let user = user,
                let connectedUUID = user.connectedToUUID,
                user.isFinding == false
            {
                self.fetch(byUUID: connectedUUID) { (connectedUser) in
                    if let connectedUser = connectedUser,
                        let connectedUuidOfConnected = connectedUser.connectedToUUID,
                        connectedUser.isFinding == false,
                        connectedUuidOfConnected == UserManager.shared.currentUser.uuid
                    {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
        }
    }
    
    func setLocation(lat: CLLocationDegrees, long: CLLocationDegrees) {
         geoFire.setLocation(CLLocation(latitude: lat, longitude: long), forKey: UserManager.shared.currentUser.uuid)
    }
    
    func fetch(byUUID uuid: String, completion: @escaping (User?) -> Void) {
        databaseRef.child(uuid).observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                completion(User(builder: UserBuilder(with: snapshot)))
            } else {
                completion(nil)
            }
        }
    }
    
    func observeConnectedLocation(completion: @escaping (CLLocation)->()) {
        guard UserManager.shared.readyForDirectionToConnectedUser
            , let connectedUUID = UserManager.shared.currentUser.connectedToUUID
            else { return }
        self.databaseRef.child(connectedUUID).observe(.childChanged) { (_) in
            self.getConnectedLocation { (location) in
                completion(location)
            }
        }
    }
    
    func getConnectedLocation(completion: @escaping (CLLocation)->()) {
        guard let connectedUUID = UserManager.shared.currentUser.connectedToUUID
            else { return }
        self.geoFire.getLocationForKey(connectedUUID) { (location, error) in
            if location != nil {
                UserManager.shared.set(connectedLocation: location)
                completion(location!)
            }
        }
    }
    
    func startQueryNearbyUser(completion: @escaping (User) -> Void) {
        guard UserManager.shared.needFetchNearByUser else { return }
        geoQuery = geoFire.query(at: UserManager.shared.currentCLLocation, withRadius: radius.toKM)
        geoQuery?.observe(.keyEntered, with: { (key, _) in
            guard key != UserManager.shared.currentUser.uuid else { return }
            self.fetch(byUUID: key) { (user) in
                if let user = user, user.isValidToConnect {
                    completion(User(builder: UserBuilder(builderClosure: { (builder) in
                        builder.uuid = user.uuid
                        builder.isFinding = false
                        builder.connectedToUUID = UserManager.shared.currentUser.uuid
                    })))
                }
            }
        })
    }
    
    func addUser(_ user: User, withValues values: NeedUpdateValues = .basic, completion: (() -> Void)? = nil) {
        databaseRef.child(user.uuid).setValue(values.info(of: user)) {(error, _) in
            if let error = error {
                print("Error while adding user: \(error.localizedDescription)")
            } else {
                print("Success adding \(String(describing: user.uuid))")
                completion?()
            }
            
        }
    }
    
    func updateUser(_ user: User = UserManager.shared.currentUser,
                    withValues values: NeedUpdateValues = .basic,
                    completion: (() -> Void)? = nil)
    {
        fetch(byUUID: user.uuid) { (tmpUser) in
            if let _ = tmpUser {
                self.databaseRef.child(user.uuid).updateChildValues(values.info(of: user)) { (error, _) in
                    if let error = error {
                        print("Error while updating user: \(error.localizedDescription)")
                    } else {
                        print("Success updating \(String(describing: user.uuid))")
                        self.removeConnectedIfNeeded(of: user, checkBy: values) {
                            completion?()
                        }
                    }
                }
            } else {
                self.addUser(user, withValues: values) {
                    completion?()
                }
            }
        }
    }
    
    private func removeConnectedIfNeeded(of user: User,
                                         checkBy values: NeedUpdateValues,
                                         completion: (() -> Void)? = nil)
    {
        switch values {
        case .basic:
            completion?()
        case .connectedUUID(let connected):
            if !connected {
                self.databaseRef.child(user.uuid).child(ParamKeys.connectedToUUID.rawValue).removeValue { (error, _) in
                    if let error = error {
                        print("Remove connected uuid error \(error.localizedDescription)")
                    } else {
                        print("Success removing connected uuid")
                        completion?()
                    }
                }
            } else {
                completion?()
            }
        }
        
    }
    
    func userConnectedObserver(completion: @escaping (String?) -> Void) {
        currentUserRef.observe(.childAdded) { (snapshot) in
            completion(self.completionResult(with: snapshot))
        }
    }
    
    func userDisconnectedObserver(completion: @escaping (String?) -> Void) {
        currentUserRef.observe(.childRemoved) { (snapshot) in
            completion(self.completionResult(with: snapshot))
        }
    }
    
    private func completionResult(with snapshot: DataSnapshot) -> String? {
        guard snapshot.key == ParamKeys.connectedToUUID.rawValue else { return nil }
        return snapshot.value as? String
    }
}
