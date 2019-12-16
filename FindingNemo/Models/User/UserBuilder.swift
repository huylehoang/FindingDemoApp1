//
//  UserBuilder.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import CoreLocation
import FirebaseFirestore

extension DocumentSnapshot {
    func subcrip(_ key: ParamKeys) -> Any? {
        return self.get(key.rawValue)
    }
}

private extension CLLocationDegrees {
    var isValid: Bool {
        return self != CLLocationDegrees.zero
    }
}

enum ParamKeys: String {
    case uuid = "uuid"
    case isFinding = "isFinding"
    case lat = "lat"
    case long = "long"
    case connectedToUUID = "connectedToUUID"
}

protocol UserProtocol {
    var uuid: String! {get}
    var isFinding: Bool! {get set}
    var localLatitude: CLLocationDegrees! {get set}
    var localLongtitude: CLLocationDegrees! {get set}
    var connectedToUUID: String? {get set}
    var isValidToConnect: Bool {get}
}

extension UserProtocol {
    var readyForUpdatingLocation: Bool {
        return localLatitude != nil && localLatitude.isValid && localLongtitude != nil && localLongtitude.isValid
    }
}

class UserBuilder: UserProtocol {
    var uuid: String! = ""
    var isFinding: Bool! = false
    var localLatitude: CLLocationDegrees! = CLLocationDegrees.zero
    var localLongtitude: CLLocationDegrees! = CLLocationDegrees.zero
    var connectedToUUID: String? = nil
    var isValidToConnect: Bool = false
    
    typealias BuilderClosure = (UserBuilder) -> ()
    
    init(with snapshot: DocumentSnapshot? = nil, builderClosure: BuilderClosure? = nil) {
        if let snapshot = snapshot {
            self.uuid = snapshot.documentID
            self.isFinding = snapshot.subcrip(.isFinding) as? Bool ?? false
            self.connectedToUUID = snapshot.subcrip(.connectedToUUID) as? String
            self.isValidToConnect = isFinding && connectedToUUID == nil
        }
        builderClosure?(self)
    }
}

extension UserBuilder {
    static var standard: UserBuilder {
        return UserBuilder { (builder) in
            builder.uuid = UIDevice.current.identifierForVendor!.uuidString
        }
    }
}
