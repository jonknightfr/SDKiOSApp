//
//  MainView.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 21/09/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import FRAuth
import FRAuthenticator
import MapKit
import CoreLocation
import SwiftyJSON

class MainView: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var profileTabButton: UIBarButtonItem!
    @IBOutlet weak var diagTabButton: UIBarButtonItem!
    @IBOutlet weak var qrTabButton: UIBarButtonItem!
    @IBOutlet weak var quitTabButton: UIBarButtonItem!
    @IBOutlet weak var codeView: UIStackView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var bestBuy: UIImageView!
    @IBOutlet weak var profileImage: UIImageView!
    
    var timer: Timer?
    var code: OathTokenCode?
    var mechanism: TOTPMechanism?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileTabButton.title = "\u{f007}"
        diagTabButton.title = "\u{f05a}"
        quitTabButton.title = "\u{f2f5}"
        qrTabButton.title = "\u{f029}"
        mapView.layer.borderWidth = 3
        mapView.layer.borderColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        mapView.layer.cornerRadius = 125
        
        profileImage.layer.cornerRadius = 25
        profileImage.layer.borderColor = Configuration.primaryColor.cgColor
        profileImage.layer.borderWidth = 1
        
        progressView.tintColor = Configuration.primaryColor
        self.loadUser()
    }
    
    func loadUser() {
        
        if ((FRUser.currentUser?.token?.scope ?? "").contains("gold")) {
            self.bestBuy.image = UIImage.init(named: "gold")
        } else if ((FRUser.currentUser?.token?.scope ?? "").contains("silver")) {
            self.bestBuy.image = UIImage.init(named: "silver")
        } else if ((FRUser.currentUser?.token?.scope ?? "").contains("bronze")) {
            self.bestBuy.image = UIImage.init(named: "bronze")
        }
        
        NetworkManager.loadUser(completionHandler: { data in
            self.titleLabel.text = "Welcome Back \(data.givenName ?? "")!"
            State.userData = data
            self.resetCodeView()
            
            //if let profileImageUrl = State.userData?.profileImage {
            //    DispatchQueue.global().async {
            //        let data = try? Data(contentsOf: URL(string:profileImageUrl)!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
            //        DispatchQueue.main.async {
            //            self.profileImage.image = UIImage(data: data!)
            //        }
            //    }
            //}
                    
            if let data = State.userData {
                if (!(data.frIndexedMultivalued1?.isEmpty ?? true)) {
                    if let json = try? JSON(data: (data.frIndexedMultivalued1?.first?.data(using: .utf8))!) {
                        print(json)
                        let latitude = json["location"]["latitude"].stringValue
                        let longitude = json["location"]["longitude"].stringValue
                        
                        let annotation = MKPointAnnotation()
                        annotation.title = "Your last login"
                        let coord = CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!)
                        annotation.coordinate = coord
                        
                        self.mapView.addAnnotation(annotation)
                        self.mapView.setCenter(CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude)!, longitude: CLLocationDegrees(longitude)!), animated: true)
                    }
                }
            }
            
            
        }, failureHandler: {
            print("Failed to get user profile")
        })
    }
    
    @objc func resetCodeView() {
        
        // Clear previous code, timer and UI elements
        self.codeView.subviews.first?.removeFromSuperview()
        self.timer?.invalidate()
        self.timer = Timer()
        self.progressView.isHidden = true
        
        let buttonStack = MainView.createHorizontalStack(uiElements: [])
        
        let button = UIButton()
        button.setTitle("Generate Login Code", for: .normal)
        button.addTarget(self, action:#selector(generateCode), for: .touchUpInside)
        
        button.backgroundColor = .clear
        button.layer.cornerRadius = 5
        button.layer.borderWidth = 1
        button.layer.borderColor = Configuration.primaryColor.cgColor
        button.setTitleColor(Configuration.primaryColor, for: .normal)
        button.titleLabel?.font =  UIFont.systemFont(ofSize: 18)
        button.frame.size = CGSize(width: 40.0, height: 20.0)
        button.layer.cornerRadius = 6
        button.contentEdgeInsets = UIEdgeInsets(
            top: 10,
            left: 10,
            bottom: 10,
            right: 10
        )
        buttonStack.addArrangedSubview(button)
        
        let stack = MainView.createVerticalStack(uiElements: [buttonStack])
        
        self.codeView.addArrangedSubview(stack)
    }
    
    func updateCodeView() {
        
        if let code = self.code {
            self.codeView.subviews.first?.removeFromSuperview()
            
            let codeLabelStack = MainView.createHorizontalStack(uiElements: [])
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = code.code
            label.font = label.font.withSize(40)
            label.textColor = Configuration.primaryColor
            codeLabelStack.addArrangedSubview(label)
            
            let timestamp = NSDate().timeIntervalSince1970
            
            let remainingLabelStack = MainView.createHorizontalStack(uiElements: [])
            let remainingLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            remainingLabel.textColor = Configuration.primaryColor
            remainingLabel.textAlignment = NSTextAlignment.center
            remainingLabel.text = "New code in " + String(Int(code.until! - timestamp)) + " seconds"
            remainingLabel.font = label.font.withSize(14)
            
            let cancelButton = UIButton()
            cancelButton.setTitleColor(Configuration.primaryColor, for: .normal)
            cancelButton.setTitle("(cancel)", for: .normal)
            cancelButton.titleLabel?.font =  label.font.withSize(14)
            cancelButton.addTarget(self, action: #selector(self.resetCodeView), for: .touchUpInside)
            
            remainingLabelStack.addArrangedSubview(remainingLabel)
            remainingLabelStack.addArrangedSubview(cancelButton)
            
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if self.code!.progress >= 1.0 {
                    self.code = nil
                    timer.invalidate()
                    self.generateCode()
                }
                let timestamp = NSDate().timeIntervalSince1970
                remainingLabel.text = "New code in " + String(Int((self.code?.until!)! - timestamp)) + " seconds"
                UIView.animate(withDuration: 0.1) {
                    self.progressView.setProgress(self.code!.progress, animated: true)
                }
                self.progressView.isHidden = false
            }
            
            // Fire first one immediately
            self.timer?.fire()
            
            let stack = MainView.createVerticalStack(uiElements: [codeLabelStack, remainingLabelStack])
            
            self.codeView.addArrangedSubview(stack)
        }
    }
    
    @objc func generateCode() {
        guard let fraClient = FRAClient.shared else {
            print("FRAuthenticator SDK is not initialized")
            return
        }
        
        let accounts = fraClient.getAllAccounts()
        
        var oathMechanism: TOTPMechanism? = nil
        
        for (account) in accounts {
            if (account.accountName == State.userData?.userName) {
                for (mechanism) in account.mechanisms {
                    if (mechanism is TOTPMechanism) {
                        oathMechanism = mechanism as? TOTPMechanism
                    }
                }
            }
        }
        
        if (oathMechanism != nil) {
            do {
                // Generate OathTokenCode
                let code = try oathMechanism?.generateCode()
                // Update UI with generated code
                
                if (code != nil) {
                    self.code = code
                    self.mechanism = oathMechanism
                    self.updateCodeView()
                }
            } catch {
                // Handle any error for generating OATH code
                print("Failed to generate OathTokenCode")
            }
        } else {
            print("Failed to find OathMechanism for this account")
        }
    }
    
    static func createVerticalStack(uiElements: [UIView]) -> UIStackView {
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        
        for element in uiElements {
            stack.addArrangedSubview(element)
        }
        
        return stack
    }
    
    static func createHorizontalStack(uiElements: [UIView]) -> UIStackView {
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        
        for element in uiElements {
            stack.addArrangedSubview(element)
        }
        
        return stack
    }
}
