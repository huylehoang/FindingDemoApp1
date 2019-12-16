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
    var localLatitude: CLLocationDegrees!
    var localLongtitude: CLLocationDegrees!
    var connectedToUUID: String?
    var isValidToConnect: Bool
    
    init(builder: UserBuilder) {
        self.uuid = builder.uuid
        self.isFinding = builder.isFinding
        self.localLatitude = builder.localLatitude
        self.localLongtitude = builder.localLongtitude
        self.connectedToUUID = builder.connectedToUUID
        self.isValidToConnect = builder.isValidToConnect
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
}
