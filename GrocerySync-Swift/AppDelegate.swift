//
//  AppDelegate.swift
//  GrocerySync-Swift
//
//  Created by Mark Tracy on 7/4/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//

import UIKit

let kDatabaseName: String? = "grocery-sync"
let kDefaultSyncDbURL: NSURL?      // define this to provide a default URL for database sync

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate {
                            
    var window: UIWindow?
    
    var database: CBLDatabase?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        // Override point for customization after application launch.
        // CBL setup
        #if kDefaultSyncDbURL
            let defaults = NSUserDefaults.standardUserDefaults()
            let appDefaults = ["syncpoint" : kDefaultSyncDbURL]
            defaults.registerDefaults(appDefaults)
            defaults.synchronize()
        #endif
        
        var error: NSError?
        database = CBLManager.sharedInstance().databaseNamed(kDatabaseName, error: &error)
        if !database {
            showAlert("Unable to make a database", error: error, fatal: true)
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // Display an error alert. if "Fatal" the app quits when this is dismissed.
    func showAlert(message: String, error: NSError?, fatal: Bool) {
        let titl = (fatal ? "Fatal error" : "Error")
        let msg = (error ? "\(message)\n\n\(error!.localizedDescription)" : message)
        let dele: UIAlertViewDelegate? = (fatal ? self : nil)
        let cancelTitle: String? = (fatal ? "Quit" : "OK")
        let alert = UIAlertView(title: titl,
            message: msg,
            delegate: dele,
            cancelButtonTitle: cancelTitle)

        alert.show()
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex: Int) {
        exit(0)
    }
}

