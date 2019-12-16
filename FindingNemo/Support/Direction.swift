//
//  Direction.swift
//  FindingNemo
//
//  Created by LeeX on 11/25/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import UIKit
import CoreLocation

class Direction {
    
    static let shared = Direction()
    
    var angle: CGFloat {
        return computeNewAngle()
    }
    
    private init() {}
    
    private func computeNewAngle() -> CGFloat {
        let heading: CGFloat = {
            guard let newHeading = LocationManager.shared.heading
                , let latestLocationBearing = latestLocationBearing
                else { return 0.0 }
            let originalHeading = latestLocationBearing + CGFloat(newHeading).degreesToRadians
            switch UIDevice.current.orientation {
            case .faceDown: return -originalHeading//  seem like can't detect when device is face down, need test more
            default: return originalHeading
            }
        }()
        return heading
    }
}

private extension Direction {
    var currentLocation: CLLocation? {
        guard UserManager.shared.readyForDirectionToConnectedUser else { return nil }
        return UserManager.shared.currentCLLocation
    }
    
    var connectedLocation: CLLocation? {
        return UserManager.shared.connectedCLLLocation
    }

    var latestLocationBearing: CGFloat? {
        guard let currentLocation = self.currentLocation
            , let connectedLocation = self.connectedLocation
            else { return nil }
        return currentLocation.bearingToLocationRadian(connectedLocation)
    }
    
//    func orientationAdjustment() -> CGFloat {
//        let isFaceDown: Bool = {
//            switch UIDevice.current.orientation {
//            case .faceDown: return true
//            default: return false
//            }
//        }()
//
//        if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation {
//            let adjAngle: CGFloat = {
//                switch interfaceOrientation {
//                case .landscapeLeft:  return 90
//                case .landscapeRight: return -90
//                case .portrait, .unknown: return 0
//                case .portraitUpsideDown: return isFaceDown ? 180 : -180
//                @unknown default: return 0
//                }
//            }()
//            return adjAngle
//        }
//        return 0
//    }
    
    
}

 extension CLLocation {
    func bearingToLocationRadian(_ destinationLocation: CLLocation) -> CGFloat {
        
        let lat1 = self.coordinate.latitude.degreesToRadians
        let lon1 = self.coordinate.longitude.degreesToRadians

        let lat2 = destinationLocation.coordinate.latitude.degreesToRadians
        let lon2 = destinationLocation.coordinate.longitude.degreesToRadians

        let dLon = lon2 - lon1

        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return CGFloat(radiansBearing)
    }
    
    func bearingToLocationDegrees(destinationLocation: CLLocation) -> CGFloat {
        return bearingToLocationRadian(destinationLocation).radiansToDegrees
    }
}

 extension CGFloat {
    var degreesToRadians: CGFloat { return self * .pi / 180 }
    var radiansToDegrees: CGFloat { return self * 180 / .pi }
}

private extension Double {
    var degreesToRadians: Double { return Double(CGFloat(self).degreesToRadians) }
    var radiansToDegrees: Double { return Double(CGFloat(self).radiansToDegrees) }
}
