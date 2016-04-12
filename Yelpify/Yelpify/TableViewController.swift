//
//  TableViewController.swift
//  Yelpify
//
//  Created by Ryan Yue on 4/9/16.
//  Copyright © 2016 Yelpify. All rights reserved.
//

import UIKit
import ParseUI
import Parse

struct playlist
{
    static var playlistname: String!
}

class TableViewController: UITableViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, CLLocationManagerDelegate {
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if (PFUser.currentUser() == nil) {
            let logInViewController = PFLogInViewController()
            logInViewController.delegate = self
            
            let signUpViewController = PFSignUpViewController()
            signUpViewController.delegate = self
            
            logInViewController.signUpController = signUpViewController
            
            self.presentViewController(logInViewController, animated: true, completion: nil)
            
            
        }
    }
    
    var locationManager = CLLocationManager()
    let client = YelpAPIClient()
    var parameters = ["ll": "", "category_filter": "pizza", "radius_filter": "3000", "sort": "0"]
    var playlists_location = []
    var playlists_user = []
    
    var userlatitude: Double!
    var userlongitude: Double!
    var inputTextField: UITextField!
    
    @IBAction func showPlaylistAlert(sender: UIBarButtonItem) {
        print("hello")
        let alertController = UIAlertController(title: "Create new playlist", message: "Enter name of playlist.", preferredStyle: UIAlertControllerStyle.Alert)
        
        alertController.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Playlist Name"
            textField.secureTextEntry = false
            self.inputTextField = textField
        })
        let deleteAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Destructive, handler: {(alert :UIAlertAction!) in
            self.view.endEditing(true)
            print("Delete button tapped")
        })
        alertController.addAction(deleteAction)
        let okAction = UIAlertAction(title: "Enter", style: UIAlertActionStyle.Default, handler: {(alert :UIAlertAction!) in
            let query = PFQuery(className: "Playlists")
            query.whereKey("createdbyuser", equalTo: (PFUser.currentUser()?.username!)!)
            query.whereKey("playlistName", equalTo: self.inputTextField.text!)
            query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
                if ((error) == nil)
                {
                    dispatch_async(dispatch_get_main_queue(), {
                        if (objects!.count == 0)
                        {
                            let object = PFObject(className: "Playlists")
                            object["playlistName"] = self.inputTextField.text!
                            object["createdbyuser"] = PFUser.currentUser()?.username!
                            object.saveInBackgroundWithBlock {(success, error) -> Void in
                                if (error == nil)
                                {
                                    playlist.playlistname = self.inputTextField.text!
                                    self.performSegueWithIdentifier("createPlaylist", sender: self)
                                }
                                else
                                {
                                    print(error?.userInfo)
                                }
                            }
                        }
                        else
                        {
                            print("You have already created this playlist")
                        }
                    })
                }
                else
                {
                    print(error?.description)
                }
            }
        })
        alertController.addAction(okAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }

    func fetchNearbyPlaylists()
    {
        let query:PFQuery = PFQuery(className: "Playlists")
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: userlatitude, longitude: userlongitude), withinMiles: 1000000000.0)
        query.orderByAscending("location")
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if ((error) == nil)
            {
                dispatch_async(dispatch_get_main_queue(), {
                    self.playlists_location = objects!
                    self.tableView.reloadData()
                })
            }
            else
            {
                print(error?.userInfo)
            }
        }
    }

    func fetchUserPlaylists()
    {
        let query: PFQuery = PFQuery(className: "Playlists")
        query.whereKey("createdbyuser", equalTo: (PFUser.currentUser()?.username)!)
        query.orderByDescending("updatedAt")
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if ((error) == nil)
            {
                dispatch_async(dispatch_get_main_queue(), {
                    print("user playlists")
                    self.playlists_user = objects!
                    self.tableView.reloadData()
                })
            }
            else
            {
                print(error?.userInfo)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        print(userLocation.coordinate)
        userlatitude = latitude
        userlongitude = longitude
        fetchNearbyPlaylists()
        fetchUserPlaylists()
        parameters["ll"] = String(latitude) + "," + String(longitude)
    }
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error.description)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse
        {
            //print("Authorized")
        }
    }
    
    func logInViewController(logInController: PFLogInViewController, shouldBeginLogInWithUsername username: String, password: String) -> Bool {
        if (!username.isEmpty || !password.isEmpty)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        print("failed to login")
    }
    func signUpViewController(signUpController: PFSignUpViewController, shouldBeginSignUp info: [String : String]) -> Bool {
        if let password = info["password"]
        {
            return password.utf16.count >= 8
        }
        else
        {
            return false
        }
    }
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        print("failed to signup")
    }
    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController) {
        print("signup canceled")
    }

    // MARK: - Table view data source
    var storedOffsets = [Int: CGFloat]()

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TableViewCell
        cell.reloadCollectionView()
        return cell
    }
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? TableViewCell else{return}
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath:NSIndexPath) {
        
        guard let tableViewCell = cell as? TableViewCell else { return }
        
        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }
}

extension TableViewController: UICollectionViewDataSource, UICollectionViewDelegate
{
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return 2
    }
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as! CollectionViewCell
        
        if(collectionView.tag == 0 && self.playlists_location.count != 0)
        {
            let templist = self.playlists_location[indexPath.row] as! PFObject
            cell.label.text = templist["playlistName"] as? String
        }
        if(collectionView.tag == 1 && self.playlists_user.count != 0)
        {
            let templist = self.playlists_user[indexPath.row] as! PFObject
            cell.label.text = templist["createdbyuser"] as? String
        }
        
        return cell
    }
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //performSegueWithIdentifier("showPlaylist", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showPlaylist")
        {
            let upcoming = segue.destinationViewController as? SinglePlaylistViewController
            upcoming?.object = playlists_location[0] as! PFObject
        }
    }
}