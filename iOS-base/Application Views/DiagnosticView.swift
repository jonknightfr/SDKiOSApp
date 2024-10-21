//
//  DiagnosticView.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 20/09/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import FRAuth
import FRDeviceBinding

class DiagnosticView: UIViewController {

    @IBOutlet weak var diagnosticView: UITextView!
    
    @IBAction func unBind(_ sender: Any) {
        let userKeys = FRUserKeys().loadAll()
        for userKey in userKeys {
            print("Deleting key \(userKey)")
            
            do {
                try FRUserKeys().delete(
                    userKey: userKey,
                    forceDelete: false      // don't fail if unable to delete matching public key in AM
                )
            }
            catch {
                print("Failed to delete public key from server")
            }
            
            NetworkManager.unbindDevice(kid: userKey.kid) {
                print("Unbound server")
            } failureHandler: {
                print("Failed to unbind server")
            }

        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        diagnosticView.layer.borderWidth = 1
        diagnosticView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        /*oauthButton.backgroundColor = primaryColor
        oauthButton.layer.cornerRadius = 10
        oidcButton.backgroundColor = primaryColor
        oidcButton.layer.cornerRadius = 10
        deviceButton.backgroundColor = primaryColor
        deviceButton.layer.cornerRadius = 10*/

        oauthButton(self)
    }
    
    
    @IBAction func oauthButton(_ sender: Any) {
        let keyAttr = [NSAttributedString.Key.foregroundColor: UIColor.red, .font:UIFont.boldSystemFont(ofSize: 14)] as [NSAttributedString.Key : Any]
        let valueAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), .font:UIFont.systemFont(ofSize: 14)] as [NSAttributedString.Key : Any]

        let claimStr = NSMutableAttributedString(string: "token_type: ", attributes: keyAttr)
        claimStr.append(NSMutableAttributedString(string: "\(FRUser.currentUser?.token?.tokenType ?? "")\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "scope: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(FRUser.currentUser?.token?.scope ?? "")\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "expires: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(String(describing: FRUser.currentUser?.token?.expiration))\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "access_token: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(FRUser.currentUser?.token?.value ?? "")\n", attributes: valueAttributes))
 
        claimStr.append(NSMutableAttributedString(string: "refresh_token: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(FRUser.currentUser?.token?.refreshToken ?? "")\n", attributes: valueAttributes))

        claimStr.append(NSMutableAttributedString(string: "id_token: ", attributes: keyAttr))
        claimStr.append(NSMutableAttributedString(string: "\(FRUser.currentUser?.token?.idToken ?? "")\n", attributes: valueAttributes))

        diagnosticView.attributedText = claimStr

    }
    
    
    @IBAction func oidcButton(_ sender: Any) {
        let keyAttr = [NSAttributedString.Key.foregroundColor: UIColor.red, .font:UIFont.boldSystemFont(ofSize: 14)] as [NSAttributedString.Key : Any]
        let valueAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), .font:UIFont.systemFont(ofSize: 14)] as [NSAttributedString.Key : Any]

        let claims = decode(jwtToken: FRUser.currentUser?.token?.idToken ?? "")
        let claimStr = NSMutableAttributedString(string: "{\n")
        
        claims.forEach {
            claimStr.append(NSMutableAttributedString(string: "\t\($0): ", attributes: keyAttr))
            claimStr.append(NSMutableAttributedString(string: "\($1)\n", attributes: valueAttributes))
        }
        claimStr.append(NSMutableAttributedString(string: "}"))
        diagnosticView.attributedText = claimStr
    }
    
    
    @IBAction func deviceButton(_ sender: Any) {
        let keyAttr = [NSAttributedString.Key.foregroundColor: UIColor.red, .font:UIFont.boldSystemFont(ofSize: 14)] as [NSAttributedString.Key : Any]
        let valueAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2745098174, green: 0.4862745106, blue: 0.1411764771, alpha: 1), .font:UIFont.systemFont(ofSize: 14)] as [NSAttributedString.Key : Any]

        let claimStr = NSMutableAttributedString(string: "{\n")
        
        FRDevice.currentDevice?.getProfile(completion: { (deviceProfile) in
            State.deviceInfo = deviceProfile
            
            State.deviceInfo.forEach {
                claimStr.append(NSMutableAttributedString(string: "\t\($0): ", attributes: keyAttr))
                claimStr.append(NSMutableAttributedString(string: "\($1)\n", attributes: valueAttributes))
            }
            claimStr.append(NSMutableAttributedString(string: "}"))

            self.diagnosticView.attributedText = claimStr
        })
        
        
    }

}
