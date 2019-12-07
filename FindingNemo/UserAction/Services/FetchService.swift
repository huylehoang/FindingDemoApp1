//
//  FetchService.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import FirebaseDatabase
import GeoFire

typealias FetchServiceHandler = (User?) -> Void
typealias FetchServiceSnapshotHandler = (Bool, DataSnapshot) -> Void

//private extension Double {
//    var toKM: Double {
//        return self / 1000
//    }
//}

//class FetchNearbyUserService: FirService {
//    private var geoFire: GeoFire!
//    private var geoQuery: GFQuery?
//    private var radius: Double = 5 // meters
//    lazy private var currentUser: User! = {
//        return UserManager.shared.currentUser
//    }()
//    var directionCalculator: DirectionCalculator!
//
//    init() {
//        geoFire = GeoFire(firebaseRef: self.databaseRef)
//        directionCalculator = DirectionCalculator()
//    }
//
//    func execute(completion: @escaping FetchServiceHandler) {
//        guard UserManager.shared.readyForUpdatingLocation else { return }
//        geoFire.setLocation(UserManager.shared.currentCLLocation, forKey: UserManager.shared.currentUser.uuid)
//        startQueryNearbyUser(completion: completion)
//    }
//
//    func getConnectedLocation(completion: @escaping (CGFloat)->()) {
//        guard UserManager.shared.readyForDirectionToConnectedUser else { return }
//        FetchUserService().checkConnectedCurrentUser { (isConnected) in
//            if isConnected, let connectedUUId = UserManager.shared.currentUser.connectedToUUID {
//                self.databaseRef.child(connectedUUId).observe(.childChanged) { (_) in
//                    self.geoFire.getLocationForKey(connectedUUId) { (location, error) in
//                        if location != nil {
//                            UserManager.shared.set(connectedLocation: location)
//                            LocationManager.shared.startUpdatingHeading()
//                            if let heading = LocationManager.shared.heading, let angle = self.directionCalculator.computeNewAngle(with: CGFloat(heading), andConnectedLocation: location) {
//                                completion(angle)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    private func startQueryNearbyUser(completion: @escaping FetchServiceHandler) {
//        guard UserManager.shared.needFetchNearByUser else { return }
//        geoQuery = geoFire.query(at: UserManager.shared.currentCLLocation, withRadius: radius.toKM)
//        geoQuery?.observe(.keyEntered, with: { (key, _) in
//            guard key != self.currentUser.uuid else { return }
//            FetchUserService().execute(fetchByUUID: key) { (user) in
//                if let user = user, user.isValidToConnect {
//                    completion(User(builder: UserBuilder(builderClosure: { (builder) in
//                        builder.uuid = user.uuid
//                        builder.isFinding = false
//                        builder.connectedToUUID = self.currentUser.uuid
//                    })))
//                } else {
//                    completion(nil)
//                }
//            }
//        })
//    }
//}
//
//class FetchUserService: FirService {
//    func execute(fetchByUUID uuid: String, completion: @escaping FetchServiceHandler) {
//        execute(fetchByUUID: uuid) { (exists, snapshot) in
//            if exists {
//                completion(User(builder: UserBuilder(with: snapshot)))
//            } else {
//                completion(nil)
//            }
//        }
//    }
//
//    func execute(fetchByUUID uuid: String, completion: @escaping FetchServiceSnapshotHandler) {
//        databaseRef.child(uuid).observeSingleEvent(of: .value) { (snapshot) in
//            completion(snapshot.exists(), snapshot)
//        }
//    }
//
//    func checkConnectedCurrentUser(completion: @escaping (Bool) -> Void) {
//        execute(fetchByUUID: UserManager.shared.currentUser.uuid) { (user) in
//            if let currentUser = user,
//                let connectedUUID = currentUser.connectedToUUID,
//                currentUser.isFinding == false
//            {
//                self.execute(fetchByUUID: connectedUUID) { (connectedUser) in
//                    if let connectedUser = connectedUser,
//                        let connectedUuidOfConnected = connectedUser.connectedToUUID,
//                        connectedUser.isFinding == false,
//                        connectedUuidOfConnected == UserManager.shared.currentUser.uuid
//                    {
//                        completion(true)
//                    } else {
//                        completion(false)
//                    }
//                }
//            } else {
//                completion(false)
//            }
//        }
//    }
//}
