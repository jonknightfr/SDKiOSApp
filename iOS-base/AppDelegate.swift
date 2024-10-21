//
//  AppDelegate.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 15/03/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import CoreLocation
import FRAuth

@UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        //FRALog.setLogLevel(.all)
        
        locationManager.requestWhenInUseAuthorization()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
        
}


func base64UrlDecode(url: String) -> Data? {
    var base64 = url
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}


func decode(jwtToken jwt: String) -> [String: Any] {
    if (jwt != "") {
        let segments = jwt.components(separatedBy: ".")
        return decodeJWTPart(segments[1]) ?? [:]
    } else {
        return [:]
    }
}


func decodeJWTPart(_ value: String) -> [String: Any]? {
    guard let bodyData = base64UrlDecode(url: value),
        let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
            return nil
    }
    
    return payload
}

