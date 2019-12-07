//
//  UpdateService.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import FirebaseDatabase

typealias UpdateServiceHandler = (Bool) -> Void

//enum NeedUpdateValues {
//    case connectedUUID(connected: Bool), basic
//}

//protocol UpdateService: FirService {
//    var user: User! {get}
//    var needUpdate: NeedUpdateValues! {get}
//    func execute(updateUser user: User, withValues values: NeedUpdateValues, completion: UpdateServiceHandler?)
//}

//extension UpdateService {
//    private var currentUserRef: DatabaseReference {
//        return databaseRef.child(UserManager.shared.currentUser.uuid)
//    }
//    
//    func userConnectedObserver(completion: @escaping (String?) -> Void) {
//        currentUserRef.observe(.childAdded) { (snapshot) in
//            completion(self.completionResult(with: snapshot))
//        }
//    }
//    
//    func userDisconnectedObserver(completion: @escaping (String?) -> Void) {
//        currentUserRef.observe(.childRemoved) { (snapshot) in
//            completion(self.completionResult(with: snapshot))
//        }
//    }
//    
//    private func completionResult(with snapshot: DataSnapshot) -> String? {
//        guard snapshot.key == ParamKeys.connectedToUUID.rawValue else { return nil }
//        return snapshot.value as? String
//    }
//}

//private extension UpdateService {
//    var info: [String: AnyObject] {
//        switch needUpdate {
//        case .connectedUUID(let connect):
//            if connect {
//                return user.infoWithConnectedUUID
//            } else {
//                return user.basicInfo
//            }
//        case .basic:
//            return user.basicInfo
//        case .none:
//            return [:]
//        }
//    }
//}

//class AddUserService: UpdateService {
//    var user: User!
//    var needUpdate: NeedUpdateValues!
//
//    func execute(updateUser user: User = UserManager.shared.currentUser,
//                 withValues values: NeedUpdateValues = .basic,
//                 completion: UpdateServiceHandler? = nil)
//    {
//        self.user = user
//        self.needUpdate = values
//        databaseRef.child(user.uuid).setValue(self.info) {(error, _) in
//            if let error = error {
//                print("Error while adding user: \(error.localizedDescription)")
//                completion?(false)
//            } else {
//                print("Success adding \(String(describing: user.uuid))")
//                completion?(true)
//            }
//        }
//    }
//}
//
//class UpdateUserService: UpdateService {
//    var user: User!
//    var needUpdate: NeedUpdateValues!
//
//    func execute(updateUser user: User = UserManager.shared.currentUser,
//                 withValues values: NeedUpdateValues = .basic,
//                 completion: UpdateServiceHandler? = nil)
//    {
//        self.user = user
//        self.needUpdate = values
//        FetchUserService().execute(fetchByUUID: user.uuid) { (user) in
//            if let user = user {
//                self.databaseRef.child(user.uuid).updateChildValues(self.info) { (error, _) in
//                    if let error = error {
//                        print("Error while updating user: \(error.localizedDescription)")
//                        completion?(false)
//                    } else {
//                        print("Success updating \(String(describing: user.uuid))")
//                        self.removeConnectedIfNeeded(checkBy: values) { (updated) in
//                            completion?(updated)
//                        }
//                    }
//                }
//            } else {
//                AddUserService().execute(updateUser: self.user, withValues: self.needUpdate)
//            }
//        }
//    }
//
//    private func removeConnectedIfNeeded(checkBy values: NeedUpdateValues,
//                                         completion: @escaping UpdateServiceHandler)
//    {
//        switch values {
//        case.basic:
//            completion(true)
//        case .connectedUUID(let connected):
//            if connected {
//                completion(true)
//            } else {
//                self.databaseRef.child(user.uuid).child(ParamKeys.connectedToUUID.rawValue).removeValue { (error, _) in
//                    if let error = error {
//                        print("Remove connected uuid error \(error.localizedDescription)")
//                        completion(false)
//                    } else {
//                        print("Success removing connected uuid")
//                        completion(true)
//                    }
//                }
//            }
//        }
//
//    }
//}
