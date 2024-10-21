//
//  Network.swift
//  iOS-base
//
//  Created by david.adams on 01/06/2021.
//  Copyright © 2021 ForgeRock. All rights reserved.
//

import Foundation
import FRAuth

class NetworkManager {
    
    init() {
    }
    
    
    static func unbindDevice(kid: String, completionHandler: @escaping ()->Void, failureHandler: @escaping ()->Void) {

        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
                                
                let claims = decode(jwtToken: FRUser.currentUser?.token?.idToken ?? "")
                let subname = claims["subname"] ?? ""

                let requestUrl = "https://\(Configuration.tenantName)/am/json/alpha/users/\(subname)/devices/2fa/binding/\(kid)"
                NetworkManager.request(requestUrl: requestUrl, method: "DELETE", completionHandler: { data in
                    if let data = data {
                        print(data)
                    }
                }, failureHandler: failureHandler)
            }
        }
    }
    
    
    static func loadUser(completionHandler: @escaping (_ data: UserProfile)->Void, failureHandler: @escaping ()->Void) {

        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
                
                let claims = decode(jwtToken: FRUser.currentUser?.token?.idToken ?? "")
                let subname = claims["subname"] ?? ""
                let requestUrl = "https://\(Configuration.tenantName)/openidm/managed/\(Configuration.managedObjectName)/\(subname)"
                NetworkManager.request(requestUrl: requestUrl, method: "GET", completionHandler: { data in
                    if let data = data {
                        let decoder = JSONDecoder()
                        do {
                            let response = try decoder.decode(UserProfile.self, from: data)
                            completionHandler(response)
                        } catch {
                            print("ERROR \(error)")
                        }
                    }
                }, failureHandler: failureHandler)
            }
        }
    }
    
    static func patchUser(field: String, stringValue: String? = nil, booleanValue: Bool? = nil, completionHandler: @escaping (_ data: UserProfile)->Void, failureHandler: @escaping ()->Void) {
        
        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
                
                var patchBody: Data = Data()
                let encoder = JSONEncoder()
                if (stringValue != nil) {
                    patchBody = try! encoder.encode([PatchString(field: field, operation: "replace", value: stringValue!)])
                } else if (booleanValue != nil) {
                    patchBody = try! encoder.encode([PatchBoolean(field: field, operation: "replace", value: booleanValue!)])
                }
                
                if (patchBody.isEmpty) {
                    failureHandler()
                } else {
                    let requestUrl = "https://\(Configuration.tenantName)/openidm/managed/\(Configuration.managedObjectName)/\(userInfo!.sub!)"
                    NetworkManager.request(requestUrl: requestUrl, method: "PATCH", body: patchBody, completionHandler: { data in
                        if let data = data {
                            let decoder = JSONDecoder()
                            let response = try? decoder.decode(UserProfile.self, from: data)
                            completionHandler(response!)
                        }
                    }, failureHandler: failureHandler)
                }
            }
        }
    }
    
    static func requestUserData(completionHandler: @escaping (_ data: Data)->Void, failureHandler: @escaping ()->Void) {
        
        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
            
                let requestUrl = "https://\(Configuration.tenantName)/openidm/managed/\(Configuration.managedObjectName)/\(userInfo!.sub!)?_fields=*,idps/*,_meta/createDate,_meta/lastChanged,_meta/termsAccepted,_meta/loginCount"
                NetworkManager.request(requestUrl: requestUrl, method: "GET", completionHandler: { data in
                    if let data = data {
                        completionHandler(data)
                    }
                }, failureHandler: failureHandler)
            }
        }
    }
    
    static func deleteUser(completionHandler: @escaping (_ data: Data)->Void, failureHandler: @escaping ()->Void) {
        
        if (FRUser.currentUser != nil) {
            FRUser.currentUser!.getUserInfo { (userInfo, error) in
                
                let requestUrl = "https://\(Configuration.tenantName)/openidm/managed/\(Configuration.managedObjectName)/\(userInfo!.sub!)"
                NetworkManager.request(requestUrl: requestUrl, method: "DELETE", completionHandler: { data in
                    if let data = data {
                        completionHandler(data)
                    }
                }, failureHandler: failureHandler)
            }
        }
    }
    
    static func request(requestUrl:String, method: String, body: Data? = nil, completionHandler: @escaping (_ data:Data?)->Void, failureHandler: @escaping ()->Void) {
        let request = NSMutableURLRequest(url: URL(string: requestUrl)!)
        request.httpMethod = method
        
        if (FRUser.currentUser?.token != nil) {
            //request.addValue("Bearer " + FRUser.currentUser?.token?.value, forHTTPHeaderField: "Authorization")
            let header = (FRUser.currentUser?.token!.buildAuthorizationHeader())!
            request.addValue(header, forHTTPHeaderField: "Authorization")
            if let cookie = FRSession.currentSession?.sessionToken?.value {
                request.addValue("\(Configuration.cookieName)=\(cookie)", forHTTPHeaderField: "Cookie")
            }
        }
        
        if (body != nil) {
            request.httpBody = body
            request.addValue("application/json", forHTTPHeaderField: "content-type")
        }
        
        print("REQUEST URL: " + request.httpMethod + " " + request.url!.absoluteString)
        print("REQUEST HEADERS: " + String(describing: request.allHTTPHeaderFields))
        
        State.urlSession.dataTask(with: request as URLRequest, completionHandler: {
            data, response, error in
            
            // A client-side error occured
            if error != nil {
                print("Failed to send request: \(String(describing: error?.localizedDescription))!")
            }
            
            let responseCode = (response as! HTTPURLResponse).statusCode
            let responseData = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("RESPONSE CODE: \(responseCode)")
            //print("RESPONSE DATA: \(String(describing: responseData))")
            
            if (responseCode == 200) {
                let dataFromString = responseData!.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)
                
                DispatchQueue.main.async(execute: {
                    completionHandler(dataFromString)
                })
            } else {
                DispatchQueue.main.async(execute: {
                    failureHandler()
                })
            }
        }).resume()
    }
}
