//
//  Finder..swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation

class UserFinder: UserOperator {
    
    lazy private var fetcher: FetchNearbyUserService = {
        return FetchNearbyUserService()
    }()
    var handler: UserHandler?
    
    func execute() {
        updateCurrentLocation()
    }
}

private extension UserFinder {
    func updateCurrentLocation() {
        LocationManager.shared.startUpdatingLocation()
        LocationManager.shared.currentLocation = { (result) in
            switch result {
            case .success(let location):
                UserManager.shared.set(isFinding: true)
                UserManager.shared.set(location: location)
                self.handler?(true, nil)
                self.startFetcher()
            case .failure(let error):
                print("Error: \(String(describing: error.errorDescription))")
                UserManager.shared.set(isFinding: false)
                self.updateService.execute(withValues: .basic)
                self.handler?(false, nil)
            }
        }
    }
    
    func startFetcher() {
        self.fetcher.execute { (user) in
            LocationManager.shared.stopUpdatingLocation()
            self.handler?(nil, user)
        }
    }
}
 
