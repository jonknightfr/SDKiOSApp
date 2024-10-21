//
//  ViewController.swift
//  PingOne Verify
//
//  Created by Ping Identity on 10/26/22.
//  Copyright © 2023 Ping Identity. All rights reserved.
//

import UIKit
import PingOneVerify

class VerifyViewController: UIViewController {
    
    @IBOutlet weak var beginButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func beginVerification() {
        print("VERIFY \(verifyQRCode)")
        let QRcodeArr = verifyQRCode.components(separatedBy: "'")
        print("CODE \(QRcodeArr[3])")
        var url: String = hexStringtoAscii(QRcodeArr[3])
        print("URL \(url)")
        PingOneVerifyClient.Builder(isOverridingAssets: false)
            .setListener(self)
            .setRootViewController(self)
//            .setUIAppearance(self.getUiAppearanceSettings())
            .setQrString(qrString: url)
            .startVerification { pingOneVerifyClient, clientBuilderError in
                
                if let clientBuilderError = clientBuilderError {
                    logerror(clientBuilderError.localizedDescription ?? "")
                    let alertController = UIAlertController(title: "Client Builder Error", message: clientBuilderError.localizedDescription, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default))
                    if let presentedViewController = self.presentedViewController {
                        presentedViewController.dismiss(animated: true) {
                            self.present(alertController, animated: true)
                        }
                    } else {
                        self.present(alertController, animated: true)
                    }
                } else {
                    //Client object was initialized successfully and the SDK will return the results in callback methods
                }
                
            }
    }
    
    private func getUiAppearanceSettings() -> UIAppearanceSettings {
        let solidButtonAppearance = ButtonAppearance(backgroundColor: .blue, textColor: .white, borderColor: .blue)
        let borderedButtonAppearance = ButtonAppearance(backgroundColor: .white, textColor: .blue, borderColor: .green)
        
        return UIAppearanceSettings()
            .setSolidButtonAppearance(solidButtonAppearance)
            .setBorderedButtonAppearance(borderedButtonAppearance)
    }
}

extension VerifyViewController: DocumentSubmissionListener {
    
    func onDocumentSubmitted(response: DocumentSubmissionResponse) {
        log("Document status: \(response.documentStatus.description)")
        log("Document submission status: \(response.documentSubmissionStatus.debugDescription)")
        log("Submitted documents: \(response.document?.keys.description ?? "Not available")")
    }
    
    func onSubmissionComplete(status: DocumentSubmissionStatus) {
        DispatchQueue.main.async {
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.performSegue(withIdentifier: "completed_segue", sender: self)
            })
        }
    }
    
    func onSubmissionError(error: DocumentSubmissionError) {
        logerror(error.localizedDescription ?? "")
        let alertController = UIAlertController(title: "Document Submission Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default))
        DispatchQueue.main.async {
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.present(alertController, animated: true)
            })
        }
    }
    
    
    
    func hexStringtoAscii(_ hexString : String) -> String {

        var str: Array = Array(hexString)
        var out: String = ""
        var i = 0;
        while (i < str.count) {
            if (String(str[i]) == "\\") {
                var hex: String = String(str[i+2]) + String(str[i+3]);
                let value = UInt32(hex, radix: 16) ?? 0
                out = out + String(Character(UnicodeScalar(value)!))
                i = i + 4
            } else {
                out = out + String(str[i])
                i = i + 1
            }
        }
        return out
    }
    
    
    
    
}
