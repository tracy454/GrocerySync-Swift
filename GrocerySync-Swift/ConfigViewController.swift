//
//  ConfigViewController.swift
//  GrocerySync-Swift
//
//  Created by Mark Tracy on 7/4/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//

import UIKit

class ConfigViewController: UIViewController, UITextFieldDelegate, UIAlertViewDelegate  {

    @IBOutlet weak var doneNavButton: UIBarButtonItem!

    @IBOutlet weak var urlField: UITextField!
    
/*
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
*/
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let syncURL = NSUserDefaults.standardUserDefaults().URLForKey("syncpoint")
        if syncURL {
        urlField.text = syncURL!.absoluteString
        }

    }
    
// Textfield delegate
    func textFieldShouldEndEditing(textField: UITextField!) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
//  #pragma mark - Navigation
/*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue?, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
*/
    @IBAction func done(sender: UIBarButtonItem) {
        var remoteURLString: String? = urlField.text
        if (remoteURLString && !remoteURLString!.isEmpty) {  // try to make a URL
            var remoteURL: NSURL? = NSURL(string: remoteURLString)
            if remoteURL {
                if let scheme: String? = remoteURL!.scheme {
                    if scheme!.hasPrefix("http") {
                        let path: String? = remoteURL!.path
                        if (!path || path!.isEmpty || path! == "/") {  // supply default database name
                            remoteURL = remoteURL!.URLByAppendingPathComponent(kDatabaseName)
                        }
                        NSUserDefaults.standardUserDefaults().setURL(remoteURL, forKey: "syncpoint")
                        performSegueWithIdentifier("list", sender: self)
                        return
                    }
                }
            }
            // bad URL
            let errorAlert = UIAlertView(title: "Invalid URL", message: "Fix or Cancel?", delegate: self, cancelButtonTitle: "Fix")
            errorAlert.addButtonWithTitle("Cancel")
            errorAlert.show()
            return
        }
        // the text field is blank, so we are not going to sync
        NSUserDefaults.standardUserDefaults().setURL(nil, forKey: "syncpoint")
        performSegueWithIdentifier("list", sender: sender)
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex > 0 {  // Cancel action is to return to list
            performSegueWithIdentifier("list", sender: self)
        } // else Fix action is to fall through and try editing the URL again
    }

    @IBAction func cancel(sender: UIBarButtonItem) {
        performSegueWithIdentifier("list", sender: sender)
    }
}
