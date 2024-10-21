//
//  QRPairView.swift
//  ForgeBank
//
//  Created by Jon Knight on 19/09/2019.
//  Copyright © 2019 Identity Hipsters. All rights reserved.
//


import UIKit
import AVFoundation
// import NotificationBannerSwift


/* JONK
protocol QRPairViewDelegate:class {
    func qrPairDidFinish(_ controller: QRPairView, text: String)
}
 */


func pairPhoneWithBank(code: String) -> String {
    
    return code;
}


@available(iOS 10.2, *)
class QRPairView: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var statusLabel: UILabel?
    var button: UIButton?
    var qrCodeFrameView:UIView?
    // JONK weak var delegate: QRPairViewDelegate?

    override func viewDidLoad() {
        print("QRPairView: viewDidLoad")
        super.viewDidLoad()
        
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        let rect = UIView()
        rect.frame = CGRect(x: 0, y: Int(view.frame.height)-130, width: Int(view.frame.width), height: 130)
        rect.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        view.addSubview(rect)
        view.bringSubviewToFront(rect)
        
        
        statusLabel = UILabel()
        statusLabel!.frame.origin.y = view.frame.height - 120
        statusLabel!.textAlignment = .center
        statusLabel!.textColor = UIColor.white
        statusLabel!.font = UIFont(name:"Helvetica-Light", size: 24)
        statusLabel!.text = "Scan the QR code"
        statusLabel!.sizeToFit()
        statusLabel!.center.x = CGFloat(view.center.x)
        view.addSubview(statusLabel!)
        
        
        button = UIButton()
        button?.frame = CGRect(x: Int(view.frame.width) / 2 - 30, y: Int(view.frame.height) - 80, width: 60, height: 60)
        button?.backgroundColor = .clear
        button?.layer.cornerRadius = 30
        button?.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        button?.setTitleColor(UIColor.white, for: .normal)
        button?.titleLabel!.font = UIFont(name: "FontAwesome5FreeSolid", size:28)!
        button?.setTitle("\u{f057}", for: .normal)
        button?.addTarget(self, action: #selector(finished), for: .touchUpInside)
        view.addSubview(button!)
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 4
            view.addSubview(qrCodeFrameView)
            view.bringSubviewToFront(qrCodeFrameView)
        }
        
        captureSession.startRunning()
    }
    
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }
    
    @objc func finished() {
        // JONK self.delegate?.qrPairDidFinish(self, text: "done") //assuming the delegate is assigned otherwise error
        dismiss(animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            let barCodeObject = previewLayer.transformedMetadataObject(for: metadataObject)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            
            let host = pairPhoneWithBank(code: stringValue)
            if (host != "") {
                print("Code: \(host)")
                NetworkManager.patchUser(field: "frIndexedString1", stringValue: host) { data in
                    print("Updated frIndexedString1")
                    self.statusLabel!.text = "Login Approved"
                } failureHandler: {
                    print("Failed to updated frIndexedString1")
                    self.statusLabel!.text = "Sorry, failed"
                }
                //statusLabel!.text = host
                //statusLabel!.sizeToFit()
                //button?.setTitle("\u{f058}", for: .normal)
                //statusLabel!.center.x = CGFloat(view.center.x)
            } else {
                statusLabel!.text = "Sorry, failed."
            }
        }
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
}
