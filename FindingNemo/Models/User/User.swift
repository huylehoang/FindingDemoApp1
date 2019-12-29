//
//  User.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import CoreLocation

struct User: UserProtocol {
    var uuid: String!
    var isFinding: Bool!
    var localLocation: CLLocation!
    var connectedToUUID: String?
    var needFlash: Bool!
    
    init(builder: UserBuilder) {
        self.uuid = builder.uuid
        self.isFinding = builder.isFinding
        self.localLocation = builder.localLocation
        self.connectedToUUID = builder.connectedToUUID
        self.needFlash = builder.needFlash
    }
    
    var basicInfo: [String: Any] {
        return [ParamKeys.isFinding.rawValue: isFinding!]
    }
    
    var infoWithConnectedUUID: [String: Any] {
        var basicInfo = self.basicInfo
        if let connectedUUID = self.connectedToUUID {
            basicInfo[ParamKeys.connectedToUUID.rawValue] = connectedUUID
        }
        return basicInfo
    }
    
    var needFlashInfo: [String: Any] {
        return [ParamKeys.needFlash.rawValue: needFlash!]
    }
}
