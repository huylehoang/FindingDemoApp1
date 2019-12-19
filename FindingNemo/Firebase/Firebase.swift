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
    case connectedUUID(connected: Bool), basic
}

private extension NeedUpdateValues {
    func info(of user: User) -> [String: Any] {
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
    
    private var ref: CollectionReference = Firestore.firestore().collection("Users")
    private var currentUserRef: DocumentReference!
    
    private var geoFire: GeoFirestore!
    private var geoQuery: GFSCircleQuery?
    private var connectedUserListener: ListenerRegistration?
    private var radius: Double = 5 // meters
    
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
    
    func observeConnectedLocation(completion: @escaping (CLLocation)->()) {
        guard UserManager.shared.readyForDirectionToConnectedUser
            , let connectedUUID = UserManager.shared.currentUser.connectedToUUID
            else { return }
        connectedUserListener = self.ref.document(connectedUUID).addSnapshotListener { (_, error) in
            if error == nil {
                self.getConnectedLocation { (location) in
                    completion(location)
                }
            }
        }
    }
    
    func getConnectedLocation(completion: @escaping (CLLocation)->()) {
        guard let connectedUUID = UserManager.shared.currentUser.connectedToUUID else { return }
        self.geoFire.getLocation(forDocumentWithID: connectedUUID) { (location: CLLocation?, _) in
            if let location = location {
                UserManager.shared.set(connectedLocation: location)
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
                    withValues values: NeedUpdateValues = .basic,
                    completion: (() -> Void)? = nil)
    {
        ref.document(user.uuid).setData(values.info(of: user), merge: true) { (error) in
            if let error = error {
                print("Error while updating user: \(error.localizedDescription)")
            } else {
                print("Success updating \(String(describing: user.uuid))")
                self.removeConnectedIfNeeded(of: user, checkBy: values) {
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
                self.ref.document(user.uuid).updateData([ParamKeys.connectedToUUID.rawValue: FieldValue.delete()]) { (error) in
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
    
    func appWillTerminate() {
        self.ref.document(UserManager.shared.currentUser.uuid).updateData([
            ParamKeys.isFinding.rawValue: false,
            ParamKeys.connectedToUUID.rawValue: FieldValue.delete()
        ])
        guard let connectedUUID = UserManager.shared.currentUser.connectedToUUID
            else { return }
        self.ref.document(connectedUUID).updateData([
            ParamKeys.connectedToUUID.rawValue: FieldValue.delete()
        ])
    }
    
    func userConnectionObserver(completion: @escaping (String?) -> Void) {
        currentUserRef.addSnapshotListener { (snapshot, error) in
            guard error == nil, let snapshot = snapshot, snapshot.exists
                else { return }
            if UserManager.shared.noConnedtedUUID
                , let connectedUUID = self.completionResult(with: snapshot)
            {
                completion(connectedUUID)
            } else if !UserManager.shared.noConnedtedUUID
                , self.completionResult(with: snapshot) == nil
            {
                completion(nil)
            }
        }
    }
    
    private func completionResult(with snapshot: DocumentSnapshot) -> String? {
        return snapshot.subcrip(ParamKeys.connectedToUUID) as? String
    }
    
}
