//
//  AppDelegate.swift
//  ReactiveProgramming
//
//  Created by Szymon Mrozek on 01/10/2019.
//  Copyright © 2019 SzymonMrozek. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let storyboad = UIStoryboard(name: "Main", bundle: .main)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = storyboad.instantiateInitialViewController(
            creator: { coder in
                return ViewController(
                    coder: coder,
                    webService: WebServiceImp()
                )
            }
        )
        window?.makeKeyAndVisible()
        
        return true
    }
}

