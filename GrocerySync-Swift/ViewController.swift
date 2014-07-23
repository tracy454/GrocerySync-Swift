//
//  ViewController.swift
//  GrocerySync-Swift
//
//  Created by Mark Tracy on 7/4/14.
//  Copyright (c) 2014 Mark Tracy Special Engineering. All rights reserved.
//

import UIKit

class ViewController: UIViewController, CBLUITableDelegate, UITextFieldDelegate, UIAlertViewDelegate {
    
    // These are not created until sometime after initialization, therefore they must be Optionals
    var database: CBLDatabase?
    var remoteSyncURL: NSURL?
    var pull: CBLReplication?
    var push: CBLReplication?
    var syncError: NSError?
    
    // Ordinary outlets added with IB
    @IBOutlet var addItemBackground: UIImageView
    @IBOutlet var addItemTextField: UITextField
    @IBOutlet var tableView: UITableView
    
    // It thinks there is already a 'navigationItem' but it is not reachable, so do this:
    @IBOutlet var navItem: UINavigationItem
    
    // This object is instantiated in the storyboard
    // If you use IB to add this outlet, it wants to default to 'strong' but you don't want that
    @IBOutlet var dataSource: CBLUITableSource
    
    
    // These UI elements are created programmatically as appropriate, not in the storyboard
    // therefore they are Optionals
    var syncButton: UIBarButtonItem?
    var progress: UIProgressView?
    
    var showingSyncButton = false
    
    let kBGColor: UIColor? = UIColor(patternImage: UIImage(named: "item_background"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        showSyncButton()
        tableView.backgroundView = nil
        tableView.backgroundColor = UIColor.clearColor()
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        useDatabase(appDelegate.database)
        
        // set up sorted view for the table
        if let dbView = database!.viewNamed("byDate") {
            if let aQuery = dbView.createQuery() {
                if let liveQuery = aQuery.asLiveQuery() {
                    liveQuery.descending = true
                    dataSource!.query = liveQuery
                    dataSource!.labelProperty = "text"
                }
            }
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func useDatabase(theDatabase: CBLDatabase?) {
        database = theDatabase
        if !database {
            return
        }
        // map function that indexes the items by date
        let theView = database!.viewNamed("byDate")
        theView.setMapBlock({doc, emit in
            if let date: AnyObject? = doc["created_at"] {
                emit(date, doc)
            }
            }, reduceBlock: nil, version: "1.1")
        
        // validation function that checks the date format
        database!.setValidationNamed("created_at",
            asBlock: {newRevision, context in
                if newRevision.isDeletion {
                    return
                }
                let date: AnyObject? = newRevision.properties["created_at"]
                if date && !CBLJSON.dateWithJSONObject(date) {
                    context.rejectWithMessage("invalid date: \(date!.description)")
                }
                })
    }
    
    // CBLUITableDelegate
    
    func couchTableSource(source: CBLUITableSource,
        willUseCell cell: UITableViewCell,
        forRow row: CBLQueryRow) {
            cell.backgroundColor = kBGColor
            cell.selectionStyle = UITableViewCellSelectionStyle.Gray
            
            cell.textLabel.font = UIFont(name: "Helvetica", size: 16.0)
            
            let rowValue = row.value as Dictionary<String, AnyObject>
            let checkValue : AnyObject? = rowValue["check"]
            let checked: Bool = checkValue ? checkValue!.boolValue : false
            if checked {
                cell.textLabel.textColor = UIColor.grayColor()
                cell.imageView.image = UIImage(named: "list_area___checkbox___checked.png")
            } else {
                cell.textLabel.textColor = UIColor.blackColor()
                cell.imageView.image = UIImage(named: "list_area___checkbox___unchecked.png")
            }
    }
    
    // UITableViewDelegate via CBLUITableDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> Float {
        return 50.0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Ask the table source for the query row and then get the document
        let row = dataSource.rowAtIndex(indexPath.row)
        let doc = row.document
        // toggle the check
        var docData = doc.properties as Dictionary<String, AnyObject>
        let checkValue : AnyObject! = docData["check"]
        let newCheck = checkValue ? !checkValue!.boolValue : true
        docData["check"] = newCheck
        var error: NSError?
        if (!doc.putProperties(docData, error: &error)) {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            appDelegate.showAlert("Unable to update item", error: error, fatal: false)
        }
    }
    
    // UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        addItemBackground.highlighted = true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        addItemBackground.highlighted = false
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        let text = addItemTextField.text
        if (!text || text.isEmpty) {
            return
        }
        addItemTextField.text = nil
        
        let docData = ["text" : text,
            "check" : false,
            "created_at" : CBLJSON.JSONObjectWithDate(NSDate(timeIntervalSinceNow: 0))]
        let newDoc = database!.createDocument()
        var error: NSError?
        // attempt to save the new document
        if (!newDoc.putProperties(docData, error: &error)) {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            appDelegate.showAlert("Unable to create item", error: error, fatal: false)
        }
    }
    
    // Editing the list
    
    func checkedDocuments() -> Array<CBLDocument> {
        var checkDocs: Array<CBLDocument> = Array()
        let rows = dataSource!.rows as? Array<CBLQueryRow>
        if !rows {
            return checkDocs
        }
        for row in rows! {
            let doc = row.document
            let checked = doc ? doc["check"].boolValue : false
            if (checked == true) {
                checkDocs.append(doc)
            }
        }
        return checkDocs
    }
    
    @IBAction func deleteCheckedItems(sender: AnyObject?) {
        let checked = checkedDocuments().count
        if checked == 0 {
            return
        }
        let plural = checked == 1 ? "" : "s"
        let msg = "Are you sure you want to remove the \(checked) checked-off item\(plural)?"
        let confirm = UIAlertView(title: "Remove Completed Items?", message: msg, delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Remove")
        confirm.show()
    }
    
    func alertView(alertView: UIAlertView!, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            return
        }
        var error: NSError?
        if !dataSource.deleteDocuments(checkedDocuments(), error: &error) {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            appDelegate.showAlert("Unable to delete", error: error, fatal: false)
        }
    }
    
    // Navigation
    
    @IBAction func configureSync(sender: AnyObject?) {
        performSegueWithIdentifier("config", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        super.prepareForSegue(segue, sender: sender)
    }
    
    
    func showSyncButton() {
        if !showingSyncButton {
            showingSyncButton = true

            syncButton = UIBarButtonItem(title: "Configure", style: UIBarButtonItemStyle.Bordered, target: self, action: "configureSync:")
            navItem.rightBarButtonItem = syncButton
        }
    }
    
    func showSyncStatus() {
        if !showingSyncButton {
            return
        }
        
        showingSyncButton = false
        if !progress {  // wait until we actually need one before initializing
            progress = UIProgressView(progressViewStyle: UIProgressViewStyle.Default)
            var frame = progress!.frame
            frame.size.width = view.frame.width * 0.25
            progress!.frame = frame
        }
        let progressItem: UIBarButtonItem? = UIBarButtonItem(customView: progress)
        progressItem!.enabled = false
        navItem.rightBarButtonItem = progressItem
    }
    
    func forgetSync() {
        let noteCenter = NSNotificationCenter.defaultCenter()
        if pull {
            noteCenter.removeObserver(self, name: nil, object: pull)
            pull = nil
        }
        if push {
            noteCenter.removeObserver(self, name: nil, object: push)
            push = nil
        }
    }
    
    func updateSyncURL() {
        if !database {
            return
        }
        
        // Since URLs are first-class default values...
        let newRemoteURL = NSUserDefaults.standardUserDefaults().URLForKey("syncpoint")
        
        forgetSync()
        
        if newRemoteURL {
            pull = database!.createPullReplication(newRemoteURL)
            if pull {
                pull!.continuous = true
            }
            push = database!.createPushReplication(newRemoteURL)
            if push {
                push!.continuous = true
            }
            
            // set up notifications for progress bar
            let noteCenter = NSNotificationCenter.defaultCenter()
            noteCenter.addObserver(self, selector: "replicationProgress:", name: kCBLReplicationChangeNotification, object: push)
            noteCenter.addObserver(self, selector: "replicationProgress:", name: kCBLReplicationChangeNotification, object: pull)
            
            if pull {
                pull!.start()
            }
            if push {
                push!.start()
            }
        }
    }

    func replicationProgress(noteCenter: NSNotificationCenter) {
        if (pull && pull!.status.value == kCBLReplicationActive.value) ||
            (push && push!.status.value == kCBLReplicationActive.value) {
                var completed: UInt32 = pull ? pull!.completedChangesCount : 0
                completed = push ? completed + push!.completedChangesCount : completed
                var total: UInt32 = pull ? pull!.changesCount : 0
                total = push ? total + push!.changesCount : total
                total = max(1, total)
                if progress {
                    progress!.progress = Float(completed) / Float(total)
                }
        }
        // see if we have any new sync errors
        let errorPull: NSError? = pull ? pull!.lastError : nil
        let errorPush: NSError? = push ? push!.lastError : nil
        let error = errorPull ? errorPull : errorPush
        if error != syncError {
            syncError = error
            if syncError {
                let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
                appDelegate.showAlert("Unable to sync", error: error, fatal: false)
            }
        }
    }
}

