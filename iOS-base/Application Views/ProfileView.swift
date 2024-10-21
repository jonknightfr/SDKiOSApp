//
//  ProfileView.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 20/09/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import FRAuth
import SwiftyJSON

class ProfileView: UIViewController {

    // TODO make list of attributes dynamic
    @IBOutlet weak var firstNameInput: UITextField!
    @IBOutlet weak var lastNameInput: UITextField!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var telephoneInput: UITextField!
    @IBOutlet weak var addressInput: UITextField!
    @IBOutlet weak var updatesSwitch: UISwitch!
    @IBOutlet weak var marketingSwitch: UISwitch!
    @IBOutlet weak var downloadDataButton: UIButton!
    @IBOutlet weak var deleteDataButton: UIButton!
    
    @IBOutlet weak var personalTitle: UILabel!
    @IBOutlet weak var privacyTitle: UILabel!
    @IBOutlet weak var manageTitle: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated:true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO process user profile attributes as configured and returned from NetworkManager

        downloadDataButton.backgroundColor = Configuration.primaryColor
        downloadDataButton.layer.cornerRadius = 10
        deleteDataButton.backgroundColor = Configuration.primaryColor
        deleteDataButton.layer.cornerRadius = 10
        personalTitle.textColor = Configuration.primaryColor
        privacyTitle.textColor = Configuration.primaryColor
        manageTitle.textColor = Configuration.primaryColor
        updatesSwitch.onTintColor = Configuration.primaryColor
        marketingSwitch.onTintColor = Configuration.primaryColor
        
        self.loadUserData()
    }
    
    func loadUserData() {
        NetworkManager.loadUser(completionHandler: { data in
            State.userData = data
            self.updateDisplay()
        }, failureHandler: {
            print("Failed to get user info")
        })
    }
    
    func updateDisplay() {
        emailLabel.text = State.userData?.mail
        firstNameInput.text = State.userData?.givenName
        lastNameInput.text = State.userData?.sn
        telephoneInput.text = State.userData?.telephoneNumber
        addressInput.text = State.userData?.postalAddress
        if let prefs = State.userData!.preferences {
            updatesSwitch.isOn = prefs.updates ?? false
            marketingSwitch.isOn = prefs.marketing ?? false
        }
        
        if let profileImageUrl = State.userData?.profileImage {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: URL(string:profileImageUrl)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                DispatchQueue.main.async {
                    self.profileImage.image = UIImage(data: data!)
                }
            }
        }
    }
    
    @IBAction func givenNameChanged(_ sender: UITextField) {
        NetworkManager.patchUser(field: "givenName", stringValue: sender.text!) { data in
            self.loadUserData()
            self.showToast(message: "Profile Updated", font: .systemFont(ofSize: 12.0))
        } failureHandler: {
            self.loadUserData()
        }
    }
    
    @IBAction func snChanged(_ sender: UITextField) {
        NetworkManager.patchUser(field: "sn", stringValue: sender.text!) { data in
            self.loadUserData()
        } failureHandler: {
            self.loadUserData()
        }
    }
    
    @IBAction func telephoneNumberChanged(_ sender: UITextField) {
        NetworkManager.patchUser(field: "telephoneNumber", stringValue: sender.text!) { data in
            self.loadUserData()
        } failureHandler: {
            self.loadUserData()
        }
    }
    @IBAction func postalAddressChanged(_ sender: UITextField) {
        NetworkManager.patchUser(field: "postalAddress", stringValue: sender.text!) { data in
            self.loadUserData()
        } failureHandler: {
            self.loadUserData()
        }
    }
    
    @IBAction func updatesSwitchChanged(_ sender: UISwitch) {
        NetworkManager.patchUser(field: "/preferences/updates", booleanValue: sender.isOn) { data in
            self.loadUserData()
        } failureHandler: {
            self.loadUserData()
        }
    }
    
    @IBAction func marketingSwitchChanged(_ sender: UISwitch) {
        NetworkManager.patchUser(field: "/preferences/marketing", booleanValue: sender.isOn) { data in
            self.loadUserData()
        } failureHandler: {
            self.loadUserData()
        }
    }
    
    @IBAction func downloadDataClicked(_ sender: Any) {
        NetworkManager.requestUserData(completionHandler: { data in
            let dataString = String(decoding: data, as: UTF8.self)
            let alert = UIAlertController(title: "Your Data", message: dataString, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Hide", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }, failureHandler: {
            print("Failed to get user info")
        })
    }
    
    @IBAction func deleteDataClicked(_ sender: Any) {
        
        let alert = UIAlertController(title: "Delete Your Data", message: "Are you sure you want to close your account and delete all your data?", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let allowAction = UIAlertAction(title: "Yes, I'm sure", style: .default) { (_) in
            NetworkManager.deleteUser(completionHandler: { data in
                print("User deleted")
                
                // Log out and segue to initial view
                let user = FRUser.currentUser
                if ((user) != nil) {
                    user!.logout()
                }
                DispatchQueue.main.async() {
                    self.performSegue(withIdentifier: "showInitialView", sender: nil)
                }
            }, failureHandler: {
                print("Failed to get user info")
            })
        }
        
        alert.addAction(cancelAction)
        alert.addAction(allowAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showToast(message : String, font: UIFont) {

        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height/6, width: 150, height: 50))
        toastLabel.backgroundColor = UIColor.green.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
             toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}
