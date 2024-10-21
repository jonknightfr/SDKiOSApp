//
//  SceneDelegate.swift
//  Demo App with SDK
//
//  Created by Jon Knight on 15/03/2020.
//  Copyright © 2020 ForgeRock. All rights reserved.
//

import UIKit
import FRAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }
    
    // JONK: handles centralized login flow as well as launch via applink, QR code, etc
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        let url = URLContexts.first!.url as NSURL
        let components = URLComponents(string: url.absoluteString!)
        
        let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
        self.window?.rootViewController?.present(alert, animated: true, completion: nil)
        
        // If incoming specific journey request, e.g., frauth://com.forgerock.jonk?service=MyLogin
        if let journey = components?.queryItems?.first(where: { $0.name == "service" })?.value {
            print("URL \(journey)")
            
            if (window?.rootViewController == nil) {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let newRoot = storyboard.instantiateInitialViewController() else {
                    return // This shouldn't happen
                }
                self.window?.rootViewController = newRoot
                
                let alert = UIAlertController(title: "Alert", message: "Message", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
                newRoot.present(alert, animated: true, completion: nil)
            }
            
            let vc = window?.rootViewController as? InitialViewController
            vc?.doEmbeddedLogin(journey: journey)
        } 
        // Else it's a returning centralised login flow. See: https://backstage.forgerock.com/docs/sdks/latest/sdks/use-cases/how-to-configure-centralized-ui.html
        else
        {
            Browser.validateBrowserLogin(url: url as URL)
        }

        /*
        if let url = URLContexts.first?.url {
            print(url)
            
            State.resumeUri = url
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let newRoot = storyboard.instantiateInitialViewController() else {
            return // This shouldn't happen
        }
        self.window?.rootViewController = newRoot
         */
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
    
}

