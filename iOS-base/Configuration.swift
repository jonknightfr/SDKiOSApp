//
//  Settings.swift
//  iOS-base
//
//  Created by david.adams on 01/06/2021.
//  Copyright © 2021 ForgeRock. All rights reserved.
//

import Foundation
import FRAuth
import FRCore
import SwiftyJSON

struct Configuration {
    static var primaryColor:UIColor = #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1)
    static var secondaryColor:UIColor = #colorLiteral(red: 0.2252391875, green: 0.3142598569, blue: 0.8514382243, alpha: 1)
    static var buttonTextColor:UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    static var logo = "FRlogo.png"
    static var backgroundImage = ""
    static var backgroundColor = UIColor.white
    static var tenantName:String = ""
    static var tenantRealm:String = ""
    static var cookieName: String = ""
    static var managedObjectName: String = "alpha_user"
    static var themeConfig:JSON = JSON("")
}
