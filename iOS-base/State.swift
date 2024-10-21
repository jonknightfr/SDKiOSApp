//
//  State.swift
//  iOS-base
//
//  Created by david.adams on 01/06/2021.
//  Copyright © 2021 ForgeRock. All rights reserved.
//

import Foundation
import FRAuth
import FRCore
import SwiftyJSON

struct State {
    static var deviceInfo:[String:Any] = [:]
    static var urlSession: URLSession = URLSession.shared
    static var userData: UserProfile? = nil
    static var resumeUri: URL? = nil
    static var overrideJourney: String = ""
}
