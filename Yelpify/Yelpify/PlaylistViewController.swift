//
//  PlaylistViewController.swift
//  Yelpify
//
//  Created by Ryan Yue on 2/14/16.
//  Copyright © 2016 Yelpify. All rights reserved.
//

import UIKit
import Parse
import ParseUI

class PlaylistViewController: UICollectionViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate, CLLocationManagerDelegate {

    var locationManager = CLLocationManager()
    let client = YelpAPIClient()
    var parameters = ["ll": "", "category_filter": "pizza", "radius_filter": "3000", "sort": "0"]
    var playlists = []
    var userlatitude: Double!
    var userlongitude: Double!
    
    
    func fetchAllObjectsFromDataStore()
    {
        let query:PFQuery = PFQuery(className: "Playlists")
        query.fromLocalDatastore()
        
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: userlatitude, longitude: userlongitude), withinMiles: 20.0)
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if ((error) == nil)
            {
                self.playlists = objects! as NSArray
            }
            else
            {
                print(error?.userInfo)
            }
        }
        
    }
    
    func fetchAllObjects()
    {
        PFObject.unpinAllObjectsInBackgroundWithBlock(nil)
        let query:PFQuery = PFQuery(className: (PFUser.currentUser()?.username)!)
        query.fromLocalDatastore()
        
        query.whereKey("location", nearGeoPoint: PFGeoPoint(latitude: userlatitude, longitude: userlongitude), withinMiles: 20.0)
        query.findObjectsInBackgroundWithBlock {(objects: [PFObject]?, error: NSError?) -> Void in
            if ((error) == nil)
            {
                PFObject.pinAllInBackground(objects, block: { (success, error) -> Void in
                    print(objects)
                    
                    if (error == nil)
                    {
                        self.fetchAllObjectsFromDataStore()
                    }
                })

            }
            else
            {
                print(error?.userInfo)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        print(userLocation.coordinate)
        userlatitude = latitude
        userlongitude = longitude
        parameters["ll"] = String(latitude) + "," + String(longitude)
        print(parameters)
    }
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print(error.description)
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse
        {
            print("Authorized")
        }
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 0
    }
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PlaylistCell", forIndexPath: indexPath)
        return cell
    }

}
