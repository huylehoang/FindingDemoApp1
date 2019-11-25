//
//  Finder..swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation

class UserFinder: UserOperator, DirectionProtocol {
    
    lazy private var fetcher: FetchNearbyUserService = {
        return FetchNearbyUserService()
    }()
    lazy private var directionCalculator: DirectionCalculator = {
        return DirectionCalculator()
    }()
    var handler: UserHandler?
    var locationError: ((LocationError) -> Void)?
    var calculatedAngle: DirectionAngleCallBack?
    
    func execute() {
        updateCurrentLocation()
    }
    
    func startCalculateDirection() {
        directionCalculator.calculatedAngle = { (angle) in
            self.calculatedAngle?(angle)
        }
        directionCalculator.execute()
    }
}

private extension UserFinder {
    func updateCurrentLocation() {
        LocationManager.shared.startUpdatingLocation()
        LocationManager.shared.currentLocation = { (location) in
            UserManager.shared.set(location: location)
            self.startFetcher()
            if UserManager.shared.noConnedtedUUID {
                UserManager.shared.set(isFinding: true)
                self.handler?(UserManager.shared.currentUser.isFinding, nil)
            }
        }
        LocationManager.shared.error = { (error) in
            print("Error: \(String(describing: error.errorDescription))")
            UserManager.shared.set(isFinding: false)
            self.locationError?(error)
        }
    }
    
    func startFetcher() {
        self.fetcher.execute { (user) in
            self.handler?(nil, user)
        }
    }
}
 
