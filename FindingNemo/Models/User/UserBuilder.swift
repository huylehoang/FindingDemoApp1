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
    var localLocation: CLLocation! {get set}
    var connectedToUUID: String? {get set}
}

extension UserProtocol {
    var readyForUpdatingLocation: Bool {
        return localLocation.coordinate.latitude.isValid && localLocation.coordinate.longitude.isValid
    }
    
    var isValidToConnect: Bool {
        return isFinding && connectedToUUID == nil
    }
}

class UserBuilder: UserProtocol {
    var uuid: String! = ""
    var isFinding: Bool! = false
    var localLocation: CLLocation! = CLLocation(latitude: CLLocationDegrees.zero, longitude: CLLocationDegrees.zero)
    var connectedToUUID: String? = nil
    
    typealias BuilderClosure = (UserBuilder) -> ()
    
    init(with snapshot: DocumentSnapshot? = nil, builderClosure: BuilderClosure? = nil) {
        if let snapshot = snapshot {
            self.uuid = snapshot.documentID
            self.isFinding = snapshot.subcrip(.isFinding) as? Bool ?? false
            self.connectedToUUID = snapshot.subcrip(.connectedToUUID) as? String
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
