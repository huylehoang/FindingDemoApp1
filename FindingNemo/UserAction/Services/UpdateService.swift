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

enum NeedUpdateValues {
    case connectedUUID, basic
}

protocol UpdateService: FirService {
    var user: User! {get}
    var needUpdate: NeedUpdateValues! {get}
    func execute(updateUser user: User, withValues values: NeedUpdateValues, completion: UpdateServiceHandler?)
}

extension UpdateService {
    func userObserver(completion: @escaping FetchServiceHandler) {
        databaseRef.child(UserManager.shared.currentUser.uuid).observe(.childChanged) { (snapshot) in
            completion(User(builder: UserBuilder(with: snapshot)))
        }
    }
}

private extension UpdateService {
    var info: [String: AnyObject] {
        switch needUpdate {
        case .connectedUUID:
            return user.infoWithConnectedUUID
        case .basic:
            return user.basicInfo
        case .none:
            return [:]
        }
    }
}

class AddUserService: UpdateService {
    var user: User!
    var needUpdate: NeedUpdateValues!
    
    func execute(updateUser user: User = UserManager.shared.currentUser,
                 withValues values: NeedUpdateValues = .basic,
                 completion: UpdateServiceHandler? = nil)
    {
        self.user = user
        self.needUpdate = values
        databaseRef.child(user.uuid).setValue(self.info) {(error, _) in
            if let error = error {
                print("Error while adding user: \(error.localizedDescription)")
                completion?(false)
            } else {
                print("Success adding")
                completion?(true)
            }
        }
    }
}

class UpdateUserService: UpdateService {
    var user: User!
    var needUpdate: NeedUpdateValues!
    
    func execute(updateUser user: User = UserManager.shared.currentUser,
                 withValues values: NeedUpdateValues = .basic,
                 completion: UpdateServiceHandler? = nil)
    {
        self.user = user
        self.needUpdate = values
        FetchUserService().execute(fetchByUUID: user.uuid) { (user) in
            if let user = user {
                self.databaseRef.child(user.uuid).updateChildValues(self.info) { (error, _) in
                    if let error = error {
                        print("Error while updating user: \(error.localizedDescription)")
                        completion?(false)
                    } else {
                        print("Success updating")
                        completion?(true)
                    }
                }
            } else {
                AddUserService().execute(updateUser: self.user, withValues: self.needUpdate)
            }
        }
    }
}
