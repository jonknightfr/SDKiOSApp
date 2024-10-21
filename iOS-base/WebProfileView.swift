//
//  WebProfileView.swift
//  SDK App
//
//  Created by jon knight on 09/05/2024.
//  Copyright © 2024 ForgeRock. All rights reserved.
//


import FRAuth
import WebKit

class WebProfileView: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cookie = HTTPCookie(properties: [
            .domain: Configuration.tenantName,
            .path: "/",
            .name:  Configuration.cookieName,
            .value: FRSession.currentSession?.sessionToken?.value,
            .version: 1,
            .secure: true,
            .expires: NSNull.self,
            .init(rawValue: "HttpOnly"): true
        ])!

        webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
        webView.load(URLRequest(url: URL(string: "https://\(Configuration.tenantName)/enduser/?realm=/\(Configuration.tenantRealm)#/profile")!))
        //webView.load(URLRequest(url: URL(string: "https://tokens-forgerock.glitch.me/index.html")!))
    }
}
