//
//  Firebase.swift
//  FindingNemo
//
//  Created by LeeX on 12/7/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import Firebase
import Geofirestore
import CoreLocation

enum NeedUpdateValues {
    case connectedUUID, needFlash, basic
}

private extension NeedUpdateValues {
    func info(of user: User) -> [String: Any] {
        switch self {
        case .connectedUUID:
            return user.infoWithConnectedUUID
        case .needFlash:
            return user.needFlashInfo
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
    
    private var ref: CollectionReference = Firestore.firestore().collection("Users")
    private var currentUserRef: DocumentReference!
    
    private var geoFire: GeoFirestore!
    private var geoQuery: GFSCircleQuery?
    private var connectedUserListener: ListenerRegistration?
    private var radius: Double = 10 // meters
    
    private init() {
        geoFire = GeoFirestore(collectionRef: ref)
        currentUserRef = ref.document(UserManager.shared.currentUser.uuid)
    }
    
    func resetListener() {
        if connectedUserListener != nil {
            connectedUserListener?.remove()
            connectedUserListener = nil
        }
        geoQuery = nil
    }
    
    func setLocation(lat: CLLocationDegrees, long: CLLocationDegrees) {
        geoFire.setLocation(location: CLLocation(latitude: lat, longitude: long), forDocumentWithID: UserManager.shared.currentUser.uuid)
    }
    
    func fetch(byUUID uuid: String, completion: @escaping (User?) -> Void) {
        ref.document(uuid).getDocument(source: .server) { (snapshot, error) in
            if let snapshot = snapshot, snapshot.exists {
                completion(User(builder: UserBuilder(with: snapshot)))
            } else {
                completion(nil)
            }
        }
    }
    
    func observeConnectedLocation(completion: @escaping (CLLocation?, Bool)->()) {
        guard UserManager.shared.readyForDirectionToConnectedUser
            , let connectedUUID = UserManager.shared.currentUser.connectedToUUID
            else { return }
        connectedUserListener = self.ref.document(connectedUUID).addSnapshotListener { (snapshot, error) in
            if let snapshot = snapshot, snapshot.exists {
                if error == nil {
                    self.getConnectedLocation { (location) in
                        completion(location, snapshot.subcrip(.needFlash) as? Bool ?? false)
                    }
                }
            } else {
                completion(nil, false)
                self.resetListener()
            }
        }
    }
    
    func getConnectedLocation(completion: @escaping (CLLocation)->()) {
        guard let connectedUUID = UserManager.shared.currentUser.connectedToUUID else { return }
        self.geoFire.getLocation(forDocumentWithID: connectedUUID) { (location: CLLocation?, _) in
            if let location = location {
                completion(location)
            }
        }
    }
    
    func startQueryNearbyUser(completion: @escaping (User) -> Void) {
        guard UserManager.shared.needFetchNearByUser else {
            if geoQuery != nil { geoQuery = nil }
            return
        }
        geoQuery = geoFire.query(withCenter: UserManager.shared.currentCLLocation, radius: radius.toKM)
        _ = geoQuery?.observe(.documentEntered, with: { (tmpKey, _) in
            guard let key = tmpKey
                , key != UserManager.shared.currentUser.uuid
                , UserManager.shared.needFetchNearByUser // currently can't find out a way to remove query observer, add condition to avoid connect to new user entered while connecting
                else { return }
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
    
    func updateUser(_ user: User = UserManager.shared.currentUser,
                    withValues values: NeedUpdateValues = .basic)
    {
        ref.document(user.uuid).setData(values.info(of: user), merge: true) { (error) in
            if let error = error {
                print("Error while updating user: \(error.localizedDescription)")
            } else {
                print("Success updating \(String(describing: user.uuid))")
            }
        }
    }
    
    func disconnect() {
//        self.ref.document(UserManager.shared.currentUser.uuid).updateData(disconnectData)
        self.ref.document(UserManager.shared.currentUser.uuid).delete()
        guard let connectedUUID = UserManager.shared.currentUser.connectedToUUID
            else { return }
//        self.ref.document(connectedUUID).updateData(disconnectData)
        self.ref.document(connectedUUID).delete()
    }
    
    func userConnectionObserver(completion: @escaping (User?) -> Void) {
        currentUserRef.addSnapshotListener { (snapshot, error) in
            guard error == nil, let snapshot = snapshot, snapshot.exists else {
                self.resetListener()
                completion(nil)
                return
            }
            if UserManager.shared.noConnedtedUUID
                , self.checkUserIsConnected(with: snapshot)
            {
                completion(User(builder: UserBuilder(with: snapshot)))
            }
        }
    }
    
    private func checkUserIsConnected(with snapshot: DocumentSnapshot) -> Bool {
        if let connectedUUID = snapshot.subcrip(ParamKeys.connectedToUUID) as? String {
            return connectedUUID != UserManager.shared.currentUser.uuid
        } else {
            return false
        }
    }
    
}
