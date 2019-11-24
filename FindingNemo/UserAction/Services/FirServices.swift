//
//  FirServices.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation
import FirebaseDatabase

protocol FirService {
    
}

extension FirService {
    var databaseRef: DatabaseReference! {
        return Database.database().reference().child(USERS_KEY)
    }
    
    private var USERS_KEY: String {
        return "Users"
    }
}
