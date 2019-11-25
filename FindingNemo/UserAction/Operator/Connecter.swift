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
    var fetchUserService: FetchUserService {
        return FetchUserService()
    }
}

private extension UserConnectOperator {
    func updateDataBase() {
        if let connecter = self as? UserConnecter {
            connecter.isConnecting = true
        }
        guard let _ = connectedUser else {
            handler?(false, nil)
            return
        }
        updateCurrentUserToDatabase()
    }
    
    private func updateCurrentUserToDatabase() {
        if isConnecter {
            if let connecterUserKey = connectedUser?.uuid {
                UserManager.shared.set(connectedToUUID: connecterUserKey)
            }
        } else {
            UserManager.shared.set(connectedToUUID: nil)
        }
        updateService.execute(withValues: .connectedUUID(connected: isConnecter)) { (updated) in
            if !updated {
                self.handler?(false, nil)
                return
            }
            self.updateConnectedUserToDatabase()
        }
    }
    
    private func updateConnectedUserToDatabase() {
        guard connectedUser != nil else { return }
        if isConnecter {
            updateService.execute(updateUser: connectedUser!, withValues: .connectedUUID(connected: true)) { (updated) in
                if updated {
                    self.fetchUserService.checkConnectedCurrentUser { (isConnected) in
                        self.handler?(isConnected, nil)
                    }
                }
            }
        } else {
            updateService.execute(updateUser: User(builder: UserBuilder(builderClosure: { (builder) in
                builder.uuid = self.connectedUser!.uuid
                builder.isFinding = false
                builder.connectedToUUID = nil
            })), withValues: .connectedUUID(connected: false)) { (isDisconnected) in
                self.handler?(isDisconnected, nil)
            }
        }
    }
}

class UserConnecter: UserConnectOperator {
    var connectedUser: User?
    var handler: UserHandler?
    var isConnecter: Bool
    fileprivate var observeConnectivity = false
    fileprivate var isConnecting = false
    
    init() {
        self.isConnecter = true
    }
    
    func connect(to user: User) {
        self.connectedUser = user
    }
    
    func execute() {
        guard observeConnectivity == false else { return }
        updateDataBase()
    }
    
    func reset() {
        observeConnectivity = false
        isConnecting = false
    }
    
    func checkUserIsConnectedAndStopUpdatingLocation() {
        setupConnectedObserver()
        setupDisConnectedObserver()
    }
    
    private func setupConnectedObserver() {
        updateService.userConnectedObserver { (connectedUUID) in
            guard self.isConnecting == false, let connectedUUID = connectedUUID else { return }
            if UserManager.shared.currentUser.connectedToUUID == nil,
                connectedUUID != UserManager.shared.currentUser.uuid
            {
                self.checkUserConnectivity(with: connectedUUID)
            }
        }
    }
    
    private func setupDisConnectedObserver() {
        updateService.userDisconnectedObserver { (connectedUUID) in
            guard self.isConnecting == false, let _ = connectedUUID else { return }
            if UserManager.shared.currentUser.connectedToUUID != nil {
                LocationManager.shared.stopUpdatingLocation(bySpecific: LocationError.turnOffByDisconnectFromOtherUser)
                self.checkUserConnectivity(with: nil)
            }
        }
    }
    
    private func checkUserConnectivity(with connectedUUID: String?) {
        observeConnectivity = true
        UserManager.shared.set(connectedToUUID: connectedUUID)
        self.handler?(connectedUUID != nil, UserManager.shared.currentUser)
    }
}

class UserDisconnecter: UserConnectOperator {
    var connectedUser: User?
    var isConnecter: Bool
    var handler: UserHandler?
    private var retryTime = 3
    private var retryCounter = 0
    
    init() {
        self.isConnecter = false
    }
    
    func execute() {
        if let connectedUUID = UserManager.shared.currentUser.connectedToUUID {
            fetchUserService.execute(fetchByUUID: connectedUUID) { (user) in
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
