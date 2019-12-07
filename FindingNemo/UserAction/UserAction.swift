//
//  UserAction.swift
//  FindingNemo
//
//  Created by LeeX on 11/22/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import UIKit

//enum UserActionState {
//    case finding
//    case didConnect
//    case didDisconnect
//    case direction(angle: CGFloat)
//    case locationError(errror: LocationError)
//}
//
//protocol UserActionProtocol {
//    var action: ((UserActionState) -> Void)? {get set}
//    func startFinder()
//    func stopFinder()
//    func disconnect()
//}
//
//class UserAction: UserActionProtocol {
//    lazy private var userActionHandler: UserActionProtocol = {
//        return UserActionHandler()
//    }()
//    
//    var action: ((UserActionState) -> Void)?
//    
//    init() {
//        userActionHandler.action = { (state) in
//            self.action?(state)
//        }
//    }
//     
//    func startFinder() {
//        userActionHandler.startFinder()
//    }
//    
//    func stopFinder() {
//        userActionHandler.stopFinder()
//    }
//    
//    func disconnect() {
//        userActionHandler.disconnect()
//    }
//}
//
//private class UserActionHandler: UserActionProtocol {
//    lazy private var finder: UserOperator = {
//        return UserFinder()
//    }()
//    lazy private var connecter: UserOperator = {
//        return UserConnecter()
//    }()
//    lazy private var disconnecter: UserOperator = {
//        return UserDisconnecter()
//    }()
//    
//    var action: ((UserActionState) -> Void)?
//    
//    init() {
//        setup()
//    }
//    
//    private func setup() {
//        connecter.asConnecter.checkUserIsConnectedAndStopUpdatingLocation()
//        
//        connecter.handler = { (connected, user) in
//            guard let connected = connected else { return }
//            if connected {
//                print("Connected")
//                self.finder.asFinder.startCalculateDirection()
//                self.action?(.didConnect)
//            } else {
//                if user == nil {
//                    print("Re-finding")
//                    self.finder.execute()
//                } else {
//                    print("Connected User is disconnected")
//                }
//            }
//            self.connecter.asConnecter.reset()
//        }
//        
//        disconnecter.handler = { (disconnected, _) in
//            guard let disconnected = disconnected else { return }
//            if disconnected {
//                print("Disconnected")
//                self.disconnecter.asDisconnecter.reset()
//                self.action?(.didDisconnect)
//            } else {
//                print("Error while disconnecting")
//                self.disconnecter.asDisconnecter.retry()
//            }
//        }
//        
//        finder.handler = { (isFinding, connectedUser) in
//            if let _ = isFinding {
//                self.action?(.finding)
//            } else if let user = connectedUser {
//                self.connecter.asConnecter.connect(to: user)
//                self.connecter.execute()
//            }
//        }
//        
//        finder.asFinder.calculatedAngle = { (angle) in
//            self.action?(.direction(angle: angle))
//        }
//        
//        finder.asFinder.locationError = { (error) in
//            self.action?(.locationError(errror: error))
//        }
//    }
//    
//    func startFinder() {
//        finder.execute()
//    }
//    
//    func stopFinder() {
//        LocationManager.shared.stopUpdatingLocation()
//    }
//    
//    func disconnect() {
//        LocationManager.shared.stopUpdatingLocation()
//        disconnecter.execute()
//    }
//}
//
//private extension UserOperator {
//    var asFinder: UserFinder {
//        return self as! UserFinder
//    }
//    
//    var asConnecter: UserConnecter {
//        return self as! UserConnecter
//    }
//    
//    var asDisconnecter: UserDisconnecter {
//        return self as! UserDisconnecter
//    }
//}
