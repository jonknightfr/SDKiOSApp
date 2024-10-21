import UIKit
import FRDeviceBinding

import FRAuth
import FRAuthenticator
import FRProximity
import SwiftyJSON
import CoreNFC
import PingOneSignals

import PingOneVerify


// Global variables
var verifyQRCode: String = "";



class LoginViewController: UIViewController, PlatformAuthenticatorRegistrationDelegate, PlatformAuthenticatorAuthenticationDelegate, NFCTagReaderSessionDelegate {
        
    func localKeyExistsAndPasskeysAreAvailable() {
        print("WHAT?")
    }
    
    @IBOutlet weak var callbackView: UIStackView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var stackView: UIView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    var nfcSession: NFCTagReaderSession?
    var journeyOverride: String = ""
    
    private var node: Node?
    private var user: FRUser?
    private var error: Error?
    var activeCallbacks : [Any] = [Any]()

    @IBOutlet weak var pageHeader: UILabel!
    @IBOutlet weak var pageDescription: UILabel!
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(self.dismissKeyboard))
        
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        nextButton.backgroundColor = Configuration.primaryColor
        nextButton.setTitleColor(Configuration.buttonTextColor, for: .normal)
        nextButton.titleLabel?.font =  UIFont.systemFont(ofSize: 14)
        nextButton.frame.size = CGSize(width: 40.0, height: 20.0)
        nextButton.layer.cornerRadius = 6
        //nextButton.contentEdgeInsets = UIEdgeInsets(
        //    top: 10,
        //    left: 10,
        //    bottom: 10,
        //    right: 10
        //)
       
        pageHeader.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1) //Configuration.primaryColor
        pageDescription.textColor = Configuration.primaryColor
        logoImage.load(url: URL(string:Configuration.logo)!)
        if Configuration.backgroundImage != "" {
            backgroundImage.load(url: URL(string:Configuration.backgroundImage)!)
        } else {
            backgroundImage.backgroundColor = Configuration.backgroundColor
        }
        
        restartButton.setTitleColor(Configuration.primaryColor, for: .normal)
        
        stackView.layer.cornerRadius = 6

        FRLog.setLogLevel([.verbose, .network])
        self.initialiseSDK()
        
        let pingOneSignals = PingOneSignals.sharedInstance()
        pingOneSignals?.getData { data, error in
            if let data = data {
                print("Got Protect data")
            } else if let error = error {
                print("error getting data: \(error)")
            }
        }
    }
    
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        self.processInputAndSubmit()
    }
    
    
    @IBAction func restartButtonPressed(_ sender: Any) {
        self.node = nil
        self.user = nil
        self.error = nil
        State.resumeUri = nil
        
        self.initialiseSDK()
    }
    
    static func createHorizontalStack(uiElements: [UIView], distribution: UIStackView.Distribution = .fillEqually) -> UIStackView {
        
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = distribution
        stack.spacing = 8
        
        for element in uiElements {
            stack.addArrangedSubview(element)
        }
        
        return stack
    }
    
    static func createVerticalStack(uiElements: [UIView], alignment: UIStackView.Alignment = .leading) -> UIStackView {
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = alignment
        
        //stack.distribution = .fillProportionally
        stack.distribution = .equalCentering
        stack.spacing = 20
        
        for element in uiElements {
            stack.addArrangedSubview(element)
        }
        
        return stack
    }
    
    static func createTextField(placeholder: String?, text: String?) -> UITextField {
        let textField: UITextField = UITextField(frame: CGRect(x: 0, y: 0, width: 300.00, height: 30.00));
        //textField.placeholder = placeholder
        textField.text = text
        textField.borderStyle = UITextField.BorderStyle.roundedRect
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)  // Configuration.primaryColor
        textField.font =  UIFont.systemFont(ofSize: 14)

        textField.attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        let widthConstraint = textField.widthAnchor.constraint(equalToConstant: 300)
        widthConstraint.priority = UILayoutPriority.defaultHigh
        widthConstraint.isActive = true

        return textField
    }
    
    static func createPolicyViolationLabel(description: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.textAlignment = NSTextAlignment.center
        label.textColor = Configuration.primaryColor
        label.text = "• \(description)"
        label.font = label.font.withSize(10)

        return label
    }
    
    static func createFieldLabel(description: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 25))
        label.textAlignment = NSTextAlignment.left
        label.text = description
        label.font = label.font.withSize(10)
        label.textColor = Configuration.primaryColor
        return label
    }
    
    
    func initialiseSDK() {
                
        self.resetActiveCallbacks()

        do {
            //let user = FRUser.currentUser
            //if ((user) != nil) {
            //    user!.logout()
            //}
            
            FRAClient.start()
            print("SDK initialized successfully")
            FRAuth.shared = nil

            var nsDictionary: NSDictionary?
            let path = Bundle.main.path(forResource: "FRAuthConfig", ofType: "plist")
            nsDictionary = NSDictionary(contentsOfFile: path ?? "")

            if (journeyOverride == "") { journeyOverride = (nsDictionary?["forgerock_auth_service_name"] as? String)! }
            print("JOURNEY: \(journeyOverride)")
            

            let options = FROptions(url: nsDictionary?["forgerock_url"] as! String,
                                    realm: nsDictionary?["forgerock_realm"] as! String,
                                    cookieName: nsDictionary?["forgerock_cookie_name"] as? String,
                                    authServiceName: journeyOverride,
                                    oauthClientId: nsDictionary?["forgerock_oauth_client_id"] as? String,
                                    oauthRedirectUri: nsDictionary?["forgerock_oauth_redirect_uri"] as? String,
                                    oauthScope: nsDictionary?["forgerock_oauth_scope"] as? String)
            
            try FRAuth.start(options: options)
            
            let resumeUri = State.resumeUri
            State.resumeUri = nil
            
            if (resumeUri == nil) {
                FRUser.login {(user: FRUser?, node, error) in
                    self.user = user;
                    self.node = node;
                    self.error = error;
                    
                    if error != nil, let error = error as? AuthError {
                        // User already authenticated
                        if (error.errorCode == AuthError.userAlreadyAuthenticated(true).errorCode) {
                        //if (error.code == 1000020) {
                            FRUser.currentUser?.logout()
                            self.initialiseSDK()
                        } else {
                            self.failure()
                        }
                    } else {
                        self.handleNode()
                    }
                }
            } else {
                FRSession.authenticate(resumeURI: resumeUri!) { (token: Token?, node, error) in
                    self.node = node;
                    self.error = error;
                    
                    if error != nil, let error = error as? AuthError {
                        // User already authenticated - log out
                        
                        if (error.errorCode == AuthError.userAlreadyAuthenticated(true).errorCode) {

                        //if (error.code == 1000020) {
                            FRUser.currentUser?.logout()
                            self.initialiseSDK()
                        } else {
                            self.failure()
                        }
                    } else {
                        if (token == nil) {
                            self.node?.next { (user: FRUser?, node: Node?, error: Error?) in
                                self.node = node
                                self.user = user
                                self.error = error
                                
                                self.handleNode()
                            }
                        } else {
                            self.user = FRUser.currentUser
                            self.success()
                        }
                    }
                }
            }
        }
        
        catch {
            print(error)
        }
         
    }
    
    func resetActiveCallbacks() {
        
        DispatchQueue.main.async() {
            //self.pageHeader?.uiElement.removeFromSuperview()
            //self.pageDescription?.uiElement.removeFromSuperview()
            self.pageHeader.text = ""
            self.pageDescription.text = ""
            
            for (activeCallback) in self.activeCallbacks {
                
                // TODO refactor into interfaces/classes to group common behaviour
                if activeCallback is Name, let activeCallback = activeCallback as? Name {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is ValidatedCreateUsername, let activeCallback = activeCallback as? ValidatedCreateUsername {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is Password, let activeCallback = activeCallback as? Password {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is ValidatedCreatePassword, let activeCallback = activeCallback as? ValidatedCreatePassword {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is PollingWait, let activeCallback = activeCallback as? PollingWait {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is Choice, let activeCallback = activeCallback as? Choice {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is TextOutput, let activeCallback = activeCallback as? TextOutput {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is SuspendedTextOutput, let activeCallback = activeCallback as? SuspendedTextOutput {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is Confirmation, let activeCallback = activeCallback as? Confirmation {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is DeviceProfile, let activeCallback = activeCallback as? DeviceProfile {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is StringAttributeInput, let activeCallback = activeCallback as? StringAttributeInput {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is BooleanAttributeInput, let activeCallback = activeCallback as? BooleanAttributeInput {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is NumberAttributeInput, let activeCallback = activeCallback as? NumberAttributeInput {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                } else if activeCallback is TermsAndConditions, let activeCallback = activeCallback as? TermsAndConditions {
                    self.removeFromView(uiElement: activeCallback.uiElement)
                }
            }
            
            self.activeCallbacks.removeAll()
        }
    }
    
    func hideControlButtons() {
        // TODO hide next and restart buttons
        self.restartButton.isHidden = true
        self.nextButton.isHidden = true
    }
    
    func showControlButtons() {
        // TODO show next and restart buttons
        self.restartButton.setTitleColor(Configuration.primaryColor, for: .normal)
        self.nextButton.backgroundColor = Configuration.primaryColor
        self.restartButton.isHidden = false
        self.nextButton.isHidden = false
    }
    
    func removeFromView(uiElement: UIView) {
        if (uiElement.superview == self.callbackView) {
            uiElement.removeFromSuperview()
        } else {
            uiElement.superview?.removeFromSuperview()
        }
    }
    
    
    func handleTheme(stage: String) {
        print(stage)
        if let data = stage.data(using: .utf8) {
            if let json = try? JSON(data: data) {

                let substring = json["themeId"].stringValue
                    
                if let themes = Configuration.themeConfig["realm"][Configuration.tenantRealm].array {
                    for theme in themes {
                        if (theme["_id"].stringValue == substring) {
                            Configuration.primaryColor = UIColor(hexString: theme["primaryColor"].stringValue)
                            Configuration.logo = theme["logo"].stringValue
                            Configuration.backgroundImage = theme["backgroundImage"].stringValue
                            logoImage.load(url: URL(string:Configuration.logo)!)
                            Configuration.backgroundColor = UIColor(hexString: theme["backgroundColor"].stringValue)
                            if (Configuration.backgroundImage != "") {
                                backgroundImage.load(url: URL(string:Configuration.backgroundImage)!)
                            } else {
                                backgroundImage.image = nil
                                backgroundImage.backgroundColor = Configuration.backgroundColor
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    func handleNode() {
        
        if let _ = self.user {
            self.success()
        }
        else if let node = self.node {
            print("Node object received, handle the node")
            
            DispatchQueue.main.async {
                
                if let stage = node.stage {
                    self.handleTheme(stage: stage)
                }
                
                // Assume we will need control buttons
                self.showControlButtons()
                
                // Set page header and description if available
                if (node.pageHeader != nil) {
                    self.pageHeader.text = node.pageHeader!
                }
                
                if (node.pageDescription != nil) {
                    self.pageDescription.attributedText = node.pageDescription!.htmlAttributedString(size: 12, color: Configuration.primaryColor)
                }
                
                // Iterate through callbacks and process
                for callback: Callback in node.callbacks {
                    print("🟢🟢🟢🟢 CALLBACK TYPE: \(callback.type)")
                    
                    if callback.type == "NameCallback", let callback = callback as? NameCallback {
                        let activeCallback = Name(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        if (activeCallback.callback.prompt == "#NFC#") {
                            //self.startNFC()
                            activeCallback.callback.setValue("homer");
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                self.processInputAndSubmit()
                            }
                        } else {
                            self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                        }
                    } else if callback.type == "ValidatedCreateUsernameCallback", let callback = callback as? ValidatedCreateUsernameCallback {
                        let activeCallback = ValidatedCreateUsername(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "PasswordCallback", let callback = callback as? PasswordCallback {
                        let activeCallback = Password(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "ValidatedCreatePasswordCallback", let callback = callback as? ValidatedCreatePasswordCallback {
                        let activeCallback = ValidatedCreatePassword(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "PollingWaitCallback", let callback = callback as? PollingWaitCallback {
                        let activeCallback = PollingWait(callback: callback, submit: self.processInputAndSubmit)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "ChoiceCallback", let callback = callback as? ChoiceCallback {
                        let activeCallback = Choice(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        
                        // Add action for all buttons
                        for stack in activeCallback.uiElement.subviews {
                            if stack is UIStackView {
                                for subView in stack.subviews {
                                    if subView is UIButton, let subView = subView as? UIButton {
                                        print("Found button " + subView.title(for: .normal)!)
                                        
                                        subView.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                                    }
                                }
                            }
                        }
                        
                        // Hide control buttons
                        self.hideControlButtons()
                        
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "TextOutputCallback", let callback = callback as? TextOutputCallback {
                        
                        // Suppress output if this is a QR code
                        if ((callback.messageType == .unknown) || callback.message.contains("barcode") || callback.message.contains("window.")) {
                            // JONK: needs better logic to distinguish a Verify set of callbacks from other QR code flows
                            if (verifyQRCode == "") {
                                verifyQRCode = callback.message
                                DispatchQueue.main.async() {
                                    self.performSegue(withIdentifier: "show_verify", sender: nil)
                                }
                            }
                        } else {
                            let activeCallback = TextOutput(callback: callback)
                            self.activeCallbacks.append(activeCallback)
                            self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                        }
                    } else if callback.type == "SuspendedTextOutputCallback", let callback = callback as? SuspendedTextOutputCallback {
                        let activeCallback = SuspendedTextOutput(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "ConfirmationCallback", let callback = callback as? ConfirmationCallback {
                        let activeCallback = Confirmation(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        
                        // Add action for all buttons
                        for stack in activeCallback.uiElement.subviews {
                            if stack is UIStackView {
                                for subView in stack.subviews {
                                    if subView is UIButton, let subView = subView as? UIButton {
                                        print("Found button " + subView.title(for: .normal)!)
                                        
                                        subView.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                                    }
                                }
                            }
                        }
                        
                        // Hide control buttons
                        self.hideControlButtons()
                        
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "DeviceProfileCallback", let callback = callback as? DeviceProfileCallback {
                        let activeCallback = DeviceProfile(callback: callback, submit: self.processInputAndSubmit)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "StringAttributeInputCallback", let callback = callback as? StringAttributeInputCallback {
                        let activeCallback = StringAttributeInput(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "BooleanAttributeInputCallback", let callback = callback as? BooleanAttributeInputCallback {
                        let activeCallback = BooleanAttributeInput(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        activeCallback.uiInputElement.addTarget(self, action: #selector(self.switchAction), for: UIControl.Event.valueChanged)
                        self.callbackView.addArrangedSubview(activeCallback.uiElement)
                    } else if callback.type == "NumberAttributeInputCallback", let callback = callback as? NumberAttributeInputCallback {
                        let activeCallback = NumberAttributeInput(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "TermsAndConditionsCallback", let callback = callback as? TermsAndConditionsCallback {
                        let activeCallback = TermsAndConditions(callback: callback)
                        self.activeCallbacks.append(activeCallback)
                        
                        // TODO add button listener
                        for subView in activeCallback.uiElement.subviews {
                            if subView is UIButton, let subView = subView as? UIButton {
                                print("Found button " + subView.title(for: .normal)!)
                                subView.addTarget(self, action: #selector(self.buttonAction), for: .touchUpInside)
                            }
                        }
                        
                        self.callbackView.addArrangedSubview(LoginViewController.createHorizontalStack(uiElements: [activeCallback.uiElement]))
                    } else if callback.type == "WebAuthnRegistrationCallback", let callback = callback as? WebAuthnRegistrationCallback {
                        
                        callback.delegate = self
                        
                        // Hide control buttons
                        self.hideControlButtons()
                        
                        // Note that the `Node` parameter in `.register()` is an optional parameter.
                        // If the node is provided, the SDK automatically sets the error outcome or attestation to the designated HiddenValueCallback
                        callback.register(node: node, usePasskeysIfAvailable: true) { (attestation) in
                            // Registration is successful
                            // Submit the Node using Node.next()
                            print("WebAuthn Registration is successful")
                            self.processInputAndSubmit()
                        } onError: { (error) in
                            // An error occurred during the registration process
                            // Submit the Node using Node.next()
                            print("WebAuthn Registration failed")
                            self.processInputAndSubmit()
                        }
                    } else if callback.type == "WebAuthnAuthenticationCallback", let callback = callback as? WebAuthnAuthenticationCallback {
                        
                        callback.delegate = self
                        
                        // Hide control buttons
                        self.hideControlButtons()
                        
                        // Note that the `Node` parameter in `.authenticate()` is an optional parameter.
                        // If the node is provided, the SDK automatically sets the assertion to the designated HiddenValueCallback
                        callback.authenticate(node: node, usePasskeysIfAvailable: true) { (assertion) in
                            // Authentication is successful
                            // Submit the Node using Node.next()
                            print("WebAuthn Authentication is successful")
                            self.processInputAndSubmit()
                        } onError: { (error) in
                            // An error occurred during the authentication process
                            // Submit the Node using Node.next()
                            print("WebAuthn Authentication failed")
                            self.processInputAndSubmit()
                        }
                    } else if callback.type == "HiddenValueCallback", let callback = callback as? HiddenValueCallback {
                        let callbackValue = String(describing: callback.getValue())
                        if (callbackValue.contains("mfaDeviceRegistration")) {
                            
                            // Hide control buttons
                            self.hideControlButtons()
                            
                            let output = callback.response.filter { element in
                                return element.key == "output"
                            }
                            
                            let outputValue = output.first?.value
                            
                            if let outputValue = outputValue as? [[String : Any]] {
                                let valueElement = outputValue.first?.filter { element in
                                    element.key == "value"
                                }
                                
                                let urlValue = valueElement?.first!.value
                                let url = URL(string: urlValue as! String)
                                
                                guard let fraClient = FRAClient.shared else {
                                    print("FRAuthenticator SDK is not initialized")
                                    return
                                }
                                 
                                // JONK
                                if (url?.scheme == "otpauth") {
                                    let accounts:[Account] = fraClient.getAllAccounts()
                                    for account in accounts {
                                        print(account.accountName)
                                        for (mechanism) in account.mechanisms {
                                            if (mechanism is TOTPMechanism) {
                                                fraClient.removeMechanism(mechanism: mechanism)
                                            }
                                        }
                                    }
                                }
                                
                                fraClient.createMechanismFromUri(uri: url!, onSuccess: { (mechanism) in
                                    // called when device enrollment was successful.
                                    print("device enrollment was successful")
                                    self.processInputAndSubmit()
                                }, onError: { (error) in
                                    // called when device enrollment has failed.
                                    print("device enrollment has failed: " + error.localizedDescription)
                                    self.processInputAndSubmit()
                                })
                            }
                        }
                    } else if callback.type == "DeviceBindingCallback", let callback = callback as? DeviceBindingCallback {
                        callback.setDeviceName(UIDevice.current.name)
                        callback.bind() { result in
                            switch result {
                            case.success:
                                print("DEVICE BINDING SUCCESS")
                            case.failure(let error):
                                print("DEVICE BINDING FAILED \(error)")
                            }
                            self.processInputAndSubmit()
                        }
                    } else if callback.type == "DeviceSigningVerifierCallback", let callback = callback as? DeviceSigningVerifierCallback {
                        callback.sign(
                            customClaims: [
                                "platform": "iOS",
                                "signedDate": Int(Date().timeIntervalSince1970)
                            ]
                        ) { result in
                            switch result {
                            case.success:
                                print("DEVICE SIGNING SUCCESS")
                            case.failure(let error):
                                print("DEVICE SIGNING FAILED \(error)")
                            }
                            self.processInputAndSubmit()
                        }
                    } else {
                        print("Unsupported callback: \(callback.type)")
                    }
                }
            }
        }
        else {
            self.failure()
        }
    }
    
    
    func processInputAndSubmit() {
        print("processInputAndSubmit()")
        // Iterate through the interactive callbacks currently displayed
        for (activeCallback) in self.activeCallbacks {
            
            if activeCallback is Name, let activeCallback = activeCallback as? Name {
                if (activeCallback.callback.prompt != "#NFC#") {
                    for subview in activeCallback.uiElement.subviews {
                        if subview is UITextField, let subview = subview as? UITextField {
                            activeCallback.callback.setValue(subview.text!)
                        }
                    }
                }
            } else if activeCallback is ValidatedCreateUsername, let activeCallback = activeCallback as? ValidatedCreateUsername {
                for subview in activeCallback.uiElement.subviews {
                    if subview is UITextField, let subview = subview as? UITextField {
                        activeCallback.callback.setValue(subview.text!)
                    }
                }
            } else if activeCallback is Password, let activeCallback = activeCallback as? Password {
                for subview in activeCallback.uiElement.subviews {
                    if subview is UITextField, let subview = subview as? UITextField {
                        activeCallback.callback.setValue(subview.text!)
                    }
                }
            } else if activeCallback is ValidatedCreatePassword, let activeCallback = activeCallback as? ValidatedCreatePassword {
                for subview in activeCallback.uiElement.subviews {
                    if subview is UITextField, let subview = subview as? UITextField {
                        activeCallback.callback.setValue(subview.text!)
                    }
                }
            } else if activeCallback is StringAttributeInput, let activeCallback = activeCallback as? StringAttributeInput {
                for subview in activeCallback.uiElement.subviews {
                    if subview is UITextField, let subview = subview as? UITextField {
                        activeCallback.callback.setValue(subview.text!)
                    }
                }
            } else if activeCallback is NumberAttributeInput, let activeCallback = activeCallback as? NumberAttributeInput {
                for subview in activeCallback.uiElement.subviews {
                    if subview is UITextField, let subview = subview as? UITextField {
                        activeCallback.callback.setValue(Double(subview.text!))
                    }
                }
            }
        }
        
        self.resetActiveCallbacks()
        
        self.node?.next { (user: FRUser?, node: Node?, error: Error?) in
            self.node = node
            self.user = user
            self.error = error
            
            self.handleNode()
        }
    }
    
    
    func success() {
        print("User is authenticated")
        
        self.setupTokenManagementPolicy()
        
        // TODO add tokens to keychain
        //KeychainWrapper.standard.set(tokens, forKey: "accessToken")
        //KeychainWrapper.standard.set(tokens?.idToken, forKey: "oidcToken")
        
        DispatchQueue.main.async() {
            self.performSegue(withIdentifier: "showMain", sender: nil)
        }
    }
    
    func failure() {
        print ("Something went wrong: \(String(describing: self.error))")
        
        let alert = UIAlertController(title: "Login Failed", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
            print("Cancelled")
            self.node = nil
            self.user = nil
            self.error = nil
            State.resumeUri = nil
            self.initialiseSDK()
        })

        alert.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    func setupTokenManagementPolicy() {
        
        URLProtocol.registerClass(FRURLProtocol.self)
        
        // Initially we only need to access the IDM login URL. Later end-user managed object will be added.
        let policy = TokenManagementPolicy(validatingURL: [
            URL(string:"https://\(Configuration.tenantName)/openidm/info/login")!
        ])
        
        FRURLProtocol.tokenManagementPolicy = policy
        
        // Configure FRURLProtocol for HTTP client
        let config = URLSessionConfiguration.default
        config.protocolClasses = [FRURLProtocol.self]
        State.urlSession = URLSession(configuration: config)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        var readyToSubmit = false
        for activeCallback in self.activeCallbacks {
            if activeCallback is Choice, let activeCallback: Choice = activeCallback as? Choice {
                activeCallback.callback.setValue(activeCallback.callback.choices.firstIndex(of: sender.title(for: .normal)!))
                readyToSubmit = true
            } else if activeCallback is Confirmation, let activeCallback: Confirmation = activeCallback as? Confirmation {
                activeCallback.callback.value = activeCallback.callback.options?.firstIndex(of: sender.title(for: .normal)!)
                readyToSubmit = true
            } else if activeCallback is TermsAndConditions, let activeCallback: TermsAndConditions = activeCallback as? TermsAndConditions {
                self.present(activeCallback.alert, animated: true, completion: nil)
            }
        }
        
        if (readyToSubmit) {
            self.processInputAndSubmit()
        }
    }
    
    @objc func switchAction(sender: UISwitch) {
        for activeCallback in self.activeCallbacks {
            if activeCallback is BooleanAttributeInput, let activeCallback: BooleanAttributeInput = activeCallback as? BooleanAttributeInput {
                if (activeCallback.uiInputElement == sender) {
                    activeCallback.callback.setValue(sender.isOn)
                }
            }
        }
    }
    
    /*
     WebAuthn
     */
    
    func excludeCredentialDescriptorConsent(consentCallback: @escaping WebAuthnUserConsentCallback) {
        let alert = UIAlertController(title: "Exclude Credentials", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            consentCallback(.reject)
        })
        let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
            consentCallback(.allow)
        }
        alert.addAction(cancelAction)
        alert.addAction(allowAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func createNewCredentialConsent(keyName: String, rpName: String, rpId: String?, userName: String, userDisplayName: String, consentCallback: @escaping WebAuthnUserConsentCallback) {
        let alert = UIAlertController(title: "Enable Biometrics", message: "\(rpName) would like to enable biometrics", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            consentCallback(.reject)
        })
        let allowAction = UIAlertAction(title: "Allow", style: .default) { (_) in
            consentCallback(.allow)
        }
        alert.addAction(cancelAction)
        alert.addAction(allowAction)
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func selectCredential(keyNames: [String], selectionCallback: @escaping WebAuthnCredentialsSelectionCallback) {
        let actionSheet = UIAlertController(title: "Select Credentials", message: nil, preferredStyle: .actionSheet)
        
        for keyName in keyNames {
            actionSheet.addAction(UIAlertAction(title: keyName, style: .default, handler: { (action) in
                selectionCallback(keyName)
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            selectionCallback(nil)
        }))
        
        if actionSheet.popoverPresentationController != nil {
            actionSheet.popoverPresentationController?.sourceView = self.callbackView
            actionSheet.popoverPresentationController?.sourceRect = self.callbackView.bounds
        }
        
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
    
    /*
     Controls
     */
    
    class Header {
        var uiElement: UILabel
        
        init(text: String) {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.font = label.font.withSize(40)
            label.contentMode = .scaleToFill
            label.numberOfLines = 0
            label.text = text
            
            self.uiElement = label
        }
    }
    
    class Description {
        var uiElement: UILabel
        
        init(text: String) {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.font = label.font.withSize(25)
            label.contentMode = .scaleToFill
            label.numberOfLines = 0
            label.text = text
            
            self.uiElement = label
        }
    }
    
    /*
     Callbacks
     */
    
    class Name {
        
        var callback: NameCallback
        var uiElement: UIView
        
        init(callback: NameCallback) {
            let textField = LoginViewController.createTextField(placeholder:callback.prompt, text: callback.getValue() as? String)
            
            let label = LoginViewController.createFieldLabel(description: callback.prompt!)
            
            let stack = createVerticalStack(uiElements: [label, textField])
            
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class Password {
        
        var callback: PasswordCallback
        var uiElement: UIView
        
        init(callback: PasswordCallback) {
            
            let textField = LoginViewController.createTextField(placeholder:callback.prompt, text: nil)
            textField.isSecureTextEntry = true
            textField.textContentType = UITextContentType.oneTimeCode
            
            let label = LoginViewController.createFieldLabel(description: callback.prompt!)
            
            let stack = createVerticalStack(uiElements: [label, textField])
            
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class ValidatedCreateUsername {
        
        var callback: ValidatedCreateUsernameCallback
        var uiElement: UIView
        
        init(callback: ValidatedCreateUsernameCallback) {
            let textField = LoginViewController.createTextField(placeholder:callback.prompt, text: callback.getValue() as? String)
            
            let policyStack = createVerticalStack(uiElements: [])
            
            if let failedPolicies = callback.failedPolicies {
                for policy in failedPolicies {
                    let label = LoginViewController.createPolicyViolationLabel(description: policy.failedDescription())
                    policyStack.addArrangedSubview(label)
                }
            }
            
            let label = LoginViewController.createFieldLabel(description: callback.prompt!)
            
            let stack = createVerticalStack(uiElements: [label, textField, policyStack])
            
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class ValidatedCreatePassword {
        
        var callback: ValidatedCreatePasswordCallback
        var uiElement: UIView
        
        init(callback: ValidatedCreatePasswordCallback) {
            
            let textField = LoginViewController.createTextField(placeholder:callback.prompt, text: nil)
            textField.isSecureTextEntry = true
            
            let policyStack = createVerticalStack(uiElements: [])
            
            if let failedPolicies = callback.failedPolicies {
                for policy in failedPolicies {
                    if (policy.policyRequirement == "LENGTH_BASED") {
                        let length: Int = policy.params?["min-password-length"]! as! Int
                        if (length != 0) {
                            let label = LoginViewController.createPolicyViolationLabel(description: "Must be at least " + String(length) + " characters long")
                            policyStack.addArrangedSubview(label)
                        }
                    }
                    
                    if (policy.policyRequirement == "CHARACTER_SET") {
                        let characterSets: [String] = policy.params?["character-sets"]! as! [String]
                        for characterSet in characterSets {
                            if (characterSet == "1:0123456789") {
                                let label = LoginViewController.createPolicyViolationLabel(description: "Number (0-9)")
                                policyStack.addArrangedSubview(label)
                            } else if (characterSet == "1:ABCDEFGHIJKLMNOPQRSTUVWXYZ") {
                                let label = LoginViewController.createPolicyViolationLabel(description: "Upper Case Letter")
                                policyStack.addArrangedSubview(label)
                            } else if (characterSet == "1:abcdefghijklmnopqrstuvwxyz") {
                                let label = LoginViewController.createPolicyViolationLabel(description: "Lower Case Letter")
                                policyStack.addArrangedSubview(label)
                            }
                        }
                    }
                }
            }
            
            let label = LoginViewController.createFieldLabel(description: callback.prompt!)
            
            let stack = createVerticalStack(uiElements: [label, textField, policyStack])
            
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class Choice {
        var callback: ChoiceCallback
        var uiElement: UIView
        
        init(callback: ChoiceCallback) {
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = .center
            label.text = callback.prompt
            //label.font =  label.font.withSize(10)
            label.numberOfLines = 0
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.sizeToFit()
            label.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1) //Configuration.primaryColor
            
            
            let labelStack = createHorizontalStack(uiElements: [label])
            var buttonStack: UIStackView
            if (callback.choices.count > 2){
                buttonStack = createVerticalStack(uiElements: [], alignment: .fill)
            } else {
                buttonStack = createHorizontalStack(uiElements: [])
            }
            
            for choice in callback.choices {
                let button = UIButton()
                button.backgroundColor = Configuration.primaryColor
                button.setTitle(choice, for: .normal)
                button.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
                button.titleLabel?.font =  label.font.withSize(14)
                button.frame.size = CGSize(width: 200.0, height: 20.0)
                button.layer.cornerRadius = 6
                button.contentEdgeInsets = UIEdgeInsets(
                    top: 6,
                    left: 10,
                    bottom: 6,
                    right: 10
                )
                    
                buttonStack.addArrangedSubview(button)
            }
            
            let stack = createVerticalStack(uiElements: [labelStack, buttonStack], alignment: .center)
            
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class Confirmation {
        var callback: ConfirmationCallback
        var uiElement: UIView
        
        init(callback: ConfirmationCallback) {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = .right
            label.text = callback.prompt
            label.font =  label.font.withSize(10)
            label.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1) //Configuration.primaryColor
            
            let labelStack = createHorizontalStack(uiElements: [label])
            let buttonStack = createHorizontalStack(uiElements: [])
            
            for choice in callback.options! {
                let button = UIButton()
                button.backgroundColor = Configuration.primaryColor
                button.setTitle(choice, for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font =  label.font.withSize(14)
                button.frame.size = CGSize(width: 40.0, height: 20.0)
                button.layer.cornerRadius = 6
                button.contentEdgeInsets = UIEdgeInsets(
                    top: 10,
                    left: 10,
                    bottom: 10,
                    right: 10
                )
                buttonStack.addArrangedSubview(button)

            }
            
            let stack = createVerticalStack(uiElements: [buttonStack, labelStack], alignment: .center)

            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class TextOutput {
        
        var callback: TextOutputCallback
        var uiElement: UILabel
        
        init(callback: TextOutputCallback) {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = callback.message
            label.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            label.numberOfLines = 0
            label.lineBreakMode = NSLineBreakMode.byWordWrapping
            label.sizeToFit()
            
            self.callback = callback
            self.uiElement = label
        }
    }
    
    class SuspendedTextOutput {
        
        var callback: SuspendedTextOutputCallback
        var uiElement: UILabel
        
        init(callback: SuspendedTextOutputCallback) {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = callback.message
            label.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)

            self.callback = callback
            self.uiElement = label
        }
    }
    
    class PollingWait {
        var callback: PollingWaitCallback
        var uiElement: UIView
        
        init(callback: PollingWaitCallback, submit: (() -> Void)?) {
            // Create spinner
            let activityView = UIActivityIndicatorView(style: .large)
            activityView.startAnimating()
            
            // Create label with prompt
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = callback.message
            label.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
            
            let stack = createVerticalStack(uiElements: [label, activityView])
            
            self.callback = callback
            self.uiElement = stack
            
            // Wait for the period specified in the callback before calling callback function
            self.wait(submit: submit)
        }
        
        func wait(submit: (() -> Void)?) {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(Int(self.callback.waitTime))) {
                if (submit != nil) {
                    print("PollingWait submit()")
                    submit!()
                }
            }
        }
    }
    
    class DeviceProfile {
        var callback: DeviceProfileCallback
        var uiElement: UIView
        
        init(callback: DeviceProfileCallback, submit: (() -> Void)?) {
            // Create spinner
            let activityView = UIActivityIndicatorView(style: .large)
            activityView.startAnimating()
            
            // Create label with prompt
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = callback.message
            
            let stack = createVerticalStack(uiElements: [label, activityView])
            
            self.callback = callback
            self.uiElement = stack
            
            // Process the device profile requirements then invoke the submit function
            self.process(submit: submit)
        }
        
        func process(submit: (() -> Void)?) {
            let semaphore = DispatchSemaphore(value: 1)
            semaphore.wait()
            callback.execute { _ in
                semaphore.signal()
                
                submit!()
            }
        }
    }
    
    class StringAttributeInput {
        
        var callback: StringAttributeInputCallback
        var uiElement: UIView
        
        init(callback: StringAttributeInputCallback) {
            let textField = LoginViewController.createTextField(placeholder:callback.prompt, text: callback.getValue() as? String)
            
            let label = LoginViewController.createFieldLabel(description: callback.prompt!)
            
            let stack = createVerticalStack(uiElements: [label, textField])

            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class BooleanAttributeInput {
        
        var callback: BooleanAttributeInputCallback
        var uiElement: UIStackView
        var uiInputElement: UISwitch
        
        init(callback: BooleanAttributeInputCallback) {
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = callback.prompt
            label.textColor = Configuration.primaryColor
            label.font =  label.font.withSize(14)

            self.callback = callback
            self.uiInputElement = UISwitch()
            self.uiInputElement.onTintColor = Configuration.primaryColor
            
            let stack = createHorizontalStack(uiElements: [label, self.uiInputElement], distribution: .fill)
            
            self.uiElement = stack
        }
    }
    
    class NumberAttributeInput {
        
        var callback: NumberAttributeInputCallback
        var uiElement: UIView
        
        init(callback: NumberAttributeInputCallback) {
            let textField = LoginViewController.createTextField(placeholder:callback.prompt, text: callback.getValue() as? String)
            let label = LoginViewController.createFieldLabel(description: callback.prompt!)
            
            let stack = createVerticalStack(uiElements: [label, textField])
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    class TermsAndConditions {
        var callback: TermsAndConditionsCallback
        var uiElement: UIView
        var alert:UIAlertController
        
        init(callback: TermsAndConditionsCallback) {
            
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
            label.textAlignment = NSTextAlignment.center
            label.text = "By proceeding you agree to our "
            label.textColor = .gray
            label.font =  label.font.withSize(14)

            let showTermsButton = UIButton()
            showTermsButton.setTitle("Terms and Conditions.", for: .normal)
            showTermsButton.setTitleColor(Configuration.primaryColor, for: .normal)
            showTermsButton.titleLabel?.font =  label.font.withSize(14)

            let stack = createVerticalStack(uiElements: [label, showTermsButton])
            
            self.alert = UIAlertController(title: "Terms & Conditions", message: callback.terms, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Hide", style: .cancel, handler: nil)
            self.alert.addAction(cancelAction)
            
            // Implied acceptance by clicking next
            callback.setValue(true)
            
            self.callback = callback
            self.uiElement = stack
        }
    }
    
    
    // NFC processing
    // Error handling again
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) { print("ERROR") }
    
    // Additionally there's a function that's called when the session begins
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) { print("SESSION BEGIN") }
    
    // Note that an NFCTag array is passed into this function, not a [NFCNDEFMessage]
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        session.connect(to: tags.first!) { (error: Error?) in
            if error != nil {
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }
            
            print("Connected to tag!")
            
            switch tags.first! {
            case .miFare(let discoveredTag):
                print("Got a MiFare tag!", discoveredTag.identifier, discoveredTag.mifareFamily)
                print("JONK: \(discoveredTag.identifier.base64EncodedString())")
                session.alertMessage = "Read tag."
                session.invalidate()
                
                if self.activeCallbacks.first is Name, let activeCallback: Name = self.activeCallbacks.first as? Name {
                    activeCallback.callback.setValue(discoveredTag.identifier.base64EncodedString())
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.processInputAndSubmit()
                    }
                }
                
            case .feliCa(let discoveredTag):
                print("Got a FeliCa tag!", discoveredTag.currentSystemCode, discoveredTag.currentIDm)
            case .iso15693(let discoveredTag):
                print("Got a ISO 15693 tag!", discoveredTag.icManufacturerCode, discoveredTag.icSerialNumber, discoveredTag.identifier)
            case .iso7816(let discoveredTag):
                print("Got a ISO 7816 tag!", discoveredTag.initialSelectedAID, discoveredTag.identifier)
            @unknown default:
                session.invalidate(errorMessage: "Unsupported tag!")
            }
        }
    }
    
    func startNFC() {
        nfcSession = NFCTagReaderSession.init(pollingOption: [.iso14443, .iso15693], delegate: self, queue: nil)
        nfcSession?.begin()
    }
}



extension String {
    func htmlAttributedString(size: CGFloat, color: UIColor) -> NSAttributedString? {
        let htmlTemplate = """
        <!doctype html>
        <html>
          <head>
            <style>
              body {
                color: #303030;
                font-family: -apple-system;
                font-size: \(size)px;
              }
              a {
                color: \(color.hexString!);
                text-decoration: none;
              }
            </style>
          </head>
          <body>
            <center>
                \(self)
            </center>
          </body>
        </html>
        """
        
        guard let data = htmlTemplate.data(using: .utf8) else {
            return nil
        }
                
        guard let attributedString = try? NSMutableAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html],
            documentAttributes: nil
        ) else {
            return nil
        }
        
        return attributedString
    }
}

extension UIColor {
    var hexString:String? {
        if let components = self.cgColor.components {
            let r = components[0]
            let g = components[1]
            let b = components[2]
            return  String(format: "#%02x%02x%02x", (Int)(r * 255), (Int)(g * 255), (Int)(b * 255))
        }
        return nil
    }
}
