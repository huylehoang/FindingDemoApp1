//
//  UserOperator.swift
//  FindingNemo
//
//  Created by LeeX on 11/21/19.
//  Copyright © 2019 LeeX. All rights reserved.
//

import Foundation

protocol UserOperator {
    typealias UserHandler = (Bool?, User?) -> Void
    var handler: UserHandler? {get set}
    func execute()
}

extension UserOperator{
    var updateService: UpdateUserService {
        return UpdateUserService()
    }
}
