//
//  Connecter.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation

protocol UserConnectOperator: class, UserOperator {
    var connectedUser: User? {get}
    var isConnecter: Bool {get}
}

private extension UserConnectOperator {
    
    func updateDataBase() {
        guard let _ = connectedUser else {
            handler?(false, nil)
            return
        }
        updateCurrentUserToDatabase()
    }
    
    private func updateCurrentUserToDatabase() {
        UserManager.shared.set(isFinding: false)
        if isConnecter {
            if let connecterUserKey = connectedUser?.uuid {
                UserManager.shared.set(connectedToUUID: connecterUserKey)
            }
        } else {
            UserManager.shared.set(connectedToUUID: nil)
        }
        updateService.execute(withValues: .connectedUUID) { (updated) in
            if !updated {
                self.handler?(false, nil)
                return
            }
            self.updateConnectedUserToDatabase()
        }
    }
    
    private func updateConnectedUserToDatabase() {
        guard connectedUser != nil else { return }
        updateService.execute(updateUser: isConnecter ?
            connectedUser! : User(builder: UserBuilder(builderClosure: { (builder) in
                builder.uuid = self.connectedUser!.uuid
                builder.isFinding = self.connectedUser!.isFinding
                builder.connectedToUUID = nil
            })), withValues: .connectedUUID)
        { (updated) in
            self.handler?(updated, nil)
        }
    }
}

class UserConnecter: UserConnectOperator {
    var connectedUser: User?
    var handler: UserHandler?
    var isConnecter: Bool
    
    init() {
        self.isConnecter = true
    }
    
    func connect(to user: User) {
        self.connectedUser = user
    }
    
    func execute() {
        updateDataBase()
    }
    
    func checkUserIsConnectedAndStopUpdatingLocation() {
        updateService.userObserver { (user) in
            guard let user = user else { return }
            if UserManager.shared.currentUser.connectedToUUID == nil,
                let connectedUser = user.connectedToUUID,
                user.isFinding == false
            {
                LocationManager.shared.stopUpdatingLocation()
                UserManager.shared.set(connectedToUUID: connectedUser)
                self.handler?(true, nil)
            }
        }
    }
}

class UserDisconnecter: UserConnectOperator {
    var connectedUser: User?
    var isConnecter: Bool
    lazy private var fetchService = {
        return FetchUserService()
    }()
    var handler: UserHandler?
    private var retryTime = 3
    private var retryCounter = 0
    
    init() {
        self.isConnecter = false
    }
    
    func execute() {
        if let connectedUUID = UserManager.shared.currentUser.connectedToUUID {
            fetchService.execute(fetchByUUID: connectedUUID) { (user) in
                self.connectedUser = user
                self.updateDataBase()
            }
        }
    }
    
    func retry() {
        guard connectedUser != nil else { return }
        if retryCounter != retryTime {
            updateDataBase()
            retryCounter += 1
        }
    }
}
