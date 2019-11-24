//
//  UserAction.swift
//  FindingNemo
//
//  Created by LeeX on 11/22/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation

enum UserActionState {
    case finding(_ isFinding: Bool)
    case didConnect
    case didDisconnect
}

protocol UserActionProtocol {
    var action: ((UserActionState) -> Void)? {get set}
    func startFinder()
    func stopFinder()
    func disconnect()
}

class UserAction: UserActionProtocol {
    lazy private var userActionHandler: UserActionProtocol = {
        return UserActionHandler()
    }()
    
    var action: ((UserActionState) -> Void)?
    
    init() {
        userActionHandler.action = { (state) in
            self.action?(state)
        }
    }
     
    func startFinder() {
        userActionHandler.startFinder()
    }
    
    func stopFinder() {
        userActionHandler.stopFinder()
    }
    
    func disconnect() {
        userActionHandler.disconnect()
    }
}

private class UserActionHandler: UserActionProtocol {
    lazy private var finder: UserOperator = {
        return UserFinder()
    }()
    lazy private var connecter: UserOperator = {
        return UserConnecter()
    }()
    lazy private var disconnecter: UserOperator = {
        return UserDisconnecter()
    }()
    
    var action: ((UserActionState) -> Void)?
    
    init() {
        setup()
    }
    
    private func setup() {
        (connecter as! UserConnecter).checkUserIsConnectedAndStopUpdatingLocation()
        
        connecter.handler = { (connected, _) in
            guard let connected = connected else { return }
            if connected {
                print("Connected")
                self.action?(.didConnect)
            } else {
                print("Re-finding")
                self.finder.execute()
            }
        }
        
        disconnecter.handler = { (disconnected, _) in
            guard let disconnected = disconnected else { return }
            if disconnected {
                print("Disconnected")
                self.action?(.didDisconnect)
            } else {
                print("Error while disconnecting")
                (self.disconnecter as! UserDisconnecter).retry()
            }
        }
        
        finder.handler = { (isFinding, connectedUser) in
            if let isFinding = isFinding {
                self.action?(.finding(isFinding))
            } else if let user = connectedUser {
                (self.connecter as! UserConnecter).connect(to: user)
                self.connecter.execute()
            }
        }
    }
    
    func startFinder() {
        finder.execute()
    }
    
    func stopFinder() {
        LocationManager.shared.stopUpdatingLocation()
    }
    
    func disconnect() {
        disconnecter.execute()
    }
}


