//
//  ViewController.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 15/03/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
//import FRAuth
import SwiftyJSON
import Foundation
import PingOneSignals
import FRAuth



extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}


extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}


class InitialViewController: UIViewController {
    
    @IBOutlet weak var embeddedLoginButton: UIButton!
    @IBOutlet weak var centralLoginButton: UIButton!
    @IBOutlet weak var signTransactionButton: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
        
    
    @IBAction func myUnwindAction(unwindSegue: UIStoryboardSegue) {
        print("Logging out")
        FRUser.currentUser?.logout()
        State.deviceInfo = [:]
    }

    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    
    override func viewDidLoad() {

        super.viewDidLoad()
                
        var nsDictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "FRAuthConfig", ofType: "plist") {
            nsDictionary = NSDictionary(contentsOfFile: path)
            if let hostname = nsDictionary?["forgerock_url"] {
                let hostURL = URL(string: hostname as! String)
                                
                Configuration.tenantName = hostURL?.host ?? ""
                Configuration.tenantRealm = nsDictionary?["forgerock_realm"] as! String
                if (Configuration.tenantRealm == "alpha" || Configuration.tenantRealm == "bravo") {
                    Configuration.managedObjectName =  Configuration.tenantRealm + "_user";
                } else {
                    Configuration.managedObjectName = "user";
                }
            }
        }
        
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [
                NSAttributedString.Key.font : UIFont(name: "FontAwesome5FreeSolid", size: 24)!,
                NSAttributedString.Key.foregroundColor : UIColor.darkGray,
            ], for: .normal)
        
        self.getAMServerInfo(completionHandler: { [self] in
            var realm = Configuration.tenantRealm;
            if (realm == "root") { realm = "/"; }
            if let themes = Configuration.themeConfig["realm"][realm].array {
                for theme in themes {
                    if (theme["isDefault"].boolValue) {
                        print("THEME ID: \(theme["_id"])")
                        Configuration.primaryColor = UIColor(hexString: theme["primaryColor"].stringValue)
                        
                        embeddedLoginButton.tintColor = Configuration.primaryColor
                        embeddedLoginButton.layer.cornerRadius = 10
                        embeddedLoginButton.clipsToBounds = true
                        embeddedLoginButton.titleLabel?.textAlignment = .center
                        embeddedLoginButton.layer.borderWidth = 2
                        embeddedLoginButton.layer.borderColor = Configuration.primaryColor.cgColor
                        
                        centralLoginButton.tintColor = Configuration.primaryColor
                        centralLoginButton.layer.cornerRadius = 10
                        centralLoginButton.clipsToBounds = true
                        centralLoginButton.titleLabel?.textAlignment = .center
                        centralLoginButton.layer.borderWidth = 2
                        centralLoginButton.layer.borderColor = Configuration.primaryColor.cgColor
                        
                        signTransactionButton.tintColor = Configuration.primaryColor
                        signTransactionButton.layer.cornerRadius = 10
                        signTransactionButton.clipsToBounds = true
                        signTransactionButton.titleLabel?.textAlignment = .center
                        signTransactionButton.layer.borderWidth = 2
                        signTransactionButton.layer.borderColor = Configuration.primaryColor.cgColor
                        
                        Configuration.logo = theme["logo"].stringValue
                        Configuration.backgroundImage = theme["backgroundImage"].stringValue
                        Configuration.backgroundColor = UIColor(hexString: theme["backgroundColor"].stringValue)
                        backgroundImage.backgroundColor = Configuration.backgroundColor
                        if (Configuration.backgroundImage != "") {
                            backgroundImage.load(url: URL(string:Configuration.backgroundImage)!)
                        }
                    }
                }
            }
            
            
        })
        
        self.handleSuspendedId()
        
        
        
        let initParams = POInitParams()
        initParams.envId = "05cf4d65-9569-4843-805e-58e702e7d4ff" // optional
        // If you are using the PingFed authentication API and version 1.3 of the Integration Kit, uncomment the following line to turn off the collection of behavioral data
        // initParams.behavioralDataCollection = false
        let pingOneSignals = PingOneSignals.initSDK(initParams: initParams)

        pingOneSignals.setInitCallback { error in
            if let error = error {
                print("Init failed - \(error.localizedDescription)")
            } else {
                print("PingOne Protect SDK Initialized")
            }
        }

        
        
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showCustomLogin") {
            let vc = segue.destination as! LoginViewController
            vc.journeyOverride = sender as! String
        }
    }
    
    @IBAction func embeddedLogin(_ sender: UIButton) {
        doEmbeddedLogin(journey: "")
    }
    
    
    @IBAction func signTransaction(_ sender: Any) {
        doEmbeddedLogin(journey: "Demo - Mobile Transaction Signing")
    }
    
    
    func doEmbeddedLogin(journey: String) {
        DispatchQueue.main.async() {
            self.performSegue(withIdentifier: "showCustomLogin", sender: journey)
            //let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            //let vc = storyBoard.instantiateViewController(withIdentifier: "loginView")
            //self.present(vc, animated:true, completion:nil)
        }
    }
    
    
    func success() {
        DispatchQueue.main.async() {
            self.performSegue(withIdentifier: "showMainView", sender: nil)
        }
    }
    
    
    @IBAction func centralizedLogin(_ sender: UIButton) {

        do {
            let user = FRUser.currentUser
            if ((user) == nil) {
                
                try FRAuth.start()
                //try FRAClient.start()
                
                //  BrowserBuilder
                let browserBuilder = FRUser.browser()
                browserBuilder?.set(presentingViewController: self)
                browserBuilder?.set(browserType: .nativeBrowserApp)
                //browserBuilder?.set(browserType: .sfViewController)
                //browserBuilder?.setCustomParam(key: "custom_key", value: "custom_val")
                
                //  Browser
                let browser = browserBuilder?.build()
                
                // Login
                browser?.login{ (user, error) in
                    if let error = error {
                        // Handle error
                        print("Login error:")
                        print(error)
                        if ((error as! AuthError).errorCode == AuthError.userAlreadyAuthenticated(true).errorCode) {
                            self.success()
                        } else {
                            print("Login error: \(error)")
                        }
                    }
                    else if let user = user {
                        self.success()
                    }
                }
            } else {
                success()
            }
        } catch {
            print("Login error: \(error)")
        }
    }



    func getAMServerInfo(completionHandler: @escaping ()->Void){
        let requestUrl = "https://\(Configuration.tenantName)/am/json/serverinfo/*"
        NetworkManager.request(requestUrl: requestUrl, method: "GET", completionHandler: { (data) in
            let amInfo = try! JSON(data: data!)
            Configuration.cookieName = amInfo["cookieName"].stringValue
            
            
            let requestUrl = "https://\(Configuration.tenantName)/openidm/config/ui/themerealm"
            NetworkManager.request(requestUrl: requestUrl, method: "GET", completionHandler: { [self] (data) in
                Configuration.themeConfig = try! JSON(data: data!)
                completionHandler()
            }, failureHandler: {
                print("Failed to get AM server info")
            })
            
            
        }, failureHandler: {
            print("Failed to get AM server info")
        })
    }
    
    func handleSuspendedId() {
        if (State.resumeUri != nil) {
            DispatchQueue.main.async() {
                self.performSegue(withIdentifier: "showCustomLogin", sender: nil)
            }
        }
    }
    
    

    
}
