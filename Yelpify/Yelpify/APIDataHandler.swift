//
//  APIDataHandler.swift
//  Yelpify
//
//  Created by Jonathan Lam on 2/19/16.
//  Copyright © 2016 Yelpify. All rights reserved.
//


// Grab Data from Google API
// Save data to Business Object

import Foundation
import UIKit
import SwiftyJSON

struct debugPrint{
    static var RAW_GOOGLE_JSON = false
    static var RAW_JSON = false
    static var BUSINESS_ARRAY = false
    static var GRAND_BUSINESS_ARRAY = false
}

class APIDataHandler {
    
    // DEBUG OPTIONS
    let PRINT_JSON = true
    
    var gpClient = GooglePlacesAPIClient()
    //var yelpClient = YelpAPIClient()
    //var locuClient = LocuAPIClient()
    
    /*
    NEW FLOW
    1) Take parameters for Google Places API
    2) Pass parameters to search in Google Places API
    3) Parse data into array of business objects
    4) Return array
    
    */
    
    func performAPISearch(googleParameters: Dictionary<String, String>, completion:(businessObjectArray: [Business]) -> Void) {
        
        gpClient.searchPlacesWithParameters(googleParameters) { (result) -> Void in
            self.parseGPlacesJSON(result, completion: { (businessArray) -> Void in
                completion(businessObjectArray: businessArray)
            })
        }
        
    }
    
    func performDetailedSearch(googleID: String, completion: (detailedGPlace: GooglePlaceDetail) -> Void){
        self.gpClient.searchPlaceWithID(googleID) { (JSONdata) in
            self.parseGoogleDetailedData(JSONdata, completion: { (detailedGPlace) in
                completion(detailedGPlace: detailedGPlace)
            })
        }
    }
    
    // MARK: - DETAILED REQUEST HANDLING (for use when cell in searchBusinessVC is clicked)
    
    func updateBusinessObject(business: Business, completion: (updatedBusinessObject: Business) -> Void){
        
        // GOOGLE API
        // Step 1 - Request Data from Google API by ID
        gpClient.searchPlaceWithID(business.gPlaceID!) { (JSONdata) -> Void in
            // Step 2 - Parse Google Detailed JSON
            self.parseGoogleDetailedData(JSONdata, completion: { (detailedGPlaceDict) -> Void in
                
            })
        }
        
//        // YELP API
//        // Step 1 - Retrive Yelp ID
//        self.getYelpID(business) { (yelpID) -> Void in
//            // Step 2 - Request Data from Yelp API by ID
//            self.yelpClient.getBusinessInformationOf(yelpID, successSearch: { (data, response) -> Void in
//                // Step 3 - Parse Yelp Detailed JSON
//                
//                }, failureSearch: { (error) -> Void in
//                    print(error)
//            })
//        }
//        // YELP API
//        // Step 1 - Request Data from Yelp API
//        yelpClient.searchBusinessesWithCoordinateAndAddress(String(business.businessLatitude), longitude: String(business.businessLongitude), address: business.businessAddress!) { (JSONdata) -> Void in
//            
//            
//            // Step 2 - Parse Yelp JSON for first result
//            
//        }
//        
        // When finished, merge both
    }
    
    // Step 1 - Retrived Data
    // Handled in GoogleAPIClient

    // Step 2 - Parse Detailed Info // Returns a NSDictionary containing [phone, price, rating, reviews]
    func parseGoogleDetailedData(data: NSData, completion: (detailedGPlace: GooglePlaceDetail) -> Void){
        let json = JSON(data: data)
        if json.count > 0 {
            if let place = json["result"].dictionary{
                if place.count > 0{
                    
                    var DetailedObject = GooglePlaceDetail()
                    
                    if let address = place["address_components"]?.array{
                    }
                    if let formattedAddress = place["formatted_address"]?.string{
                        DetailedObject.address = formattedAddress
                    }
                    if let phone = place["formatted_phone_number"]!.string{
                        DetailedObject.phone = phone
                    }
                    if let intlPhone = place["international_phone_number"]?.string{
                        
                    }
                    
                    for (index,photo) : (String, JSON) in place["opening_hours"]!["weekday_text"] {
                        DetailedObject.hours.arrayByAddingObject(photo.string!)
                    }
                    
                    
                    for (index,photo):(String, JSON) in place["photos"]! {
                        if let photoDict = photo.dictionary{
                            if let ref = photoDict["photo_reference"]?.string{
                                DetailedObject.photos.addObject(ref)
                            }
                        }
                    }
                    
                    if let placePrice = place["price_level"]!.int{
                        DetailedObject.priceRating = placePrice
                    }
                    
                    
                    if let rating = place["rating"]?.double{
                        DetailedObject.rating = rating
                    }
                
                    for (index,review):(String, JSON) in place["reviews"]! {
                        if let reviewDict = review.dictionary{
                            
                            var resultDict = NSMutableDictionary()
                            if let time = reviewDict["time"]?.int{
                                resultDict["time"] = time
                            }
                            if let text = reviewDict["text"]?.string{
                                resultDict["text"] = text
                            }
                            if let author = reviewDict["author_name"]?.string{
                                resultDict["author"] = author
                            }
                            if let author_url = reviewDict["author_url"]?.string{
                                resultDict["author_url"] = author_url
                            }
                            if let profile_photo = reviewDict["profile_photo_url"]?.string{
                                resultDict["profile_photo"] = profile_photo
                            }
                            if let rating = reviewDict["rating"]?.double{
                                resultDict["rating"] = rating
                            }
                            DetailedObject.reviews.addObject(resultDict)
                        }
                    }
                    
                    if let types = place["types"]?.array{
                        var typeArray: [String] = []
                        for type in types{
                            if let t = type.string{
                                typeArray.append(t)
                            }
                        }
                    }
                    
                    if let website = place["url"]?.string{
                        DetailedObject.website = website
                    }
                    
                    completion(detailedGPlace: DetailedObject)
                }
            }
        
        }
    
    }
    


    
    func parseGPlacesJSON(data: NSData, completion: (businessArray: [Business]) -> Void){
        let json = JSON(data: data)
        if let places = json["results"].array{
            if places.count > 0{
                
                var arrayOfBusinesses: [Business] = []
                
                for place in places{
                    var businessObject = Business()
                    
                    if let id = place["place_id"].string{
                        businessObject.gPlaceID = id
                    }
                    if let name = place["name"].string{
                        businessObject.businessName = name
                    }
                    if let address = place["vicinity"].string{
                        businessObject.businessAddress = address
                    }
                    if let photoRef = place["photos"][0]["photo_reference"].string{
                        businessObject.businessPhotoReference = photoRef
                    }
                    if let rating = place["rating"].double{
                        businessObject.businessRating = rating
                    }
                    
                    if let placeLocation = place["geometry"]["location"].dictionary{
                        if let placeLat = placeLocation["lat"]!.double{
                            businessObject.businessLatitude = placeLat
                        }
                        if let placeLng = placeLocation["lng"]!.double{
                            businessObject.businessLongitude = placeLng
                        }
                    }
                    
                    arrayOfBusinesses.append(businessObject)
                }
                
                completion(businessArray: arrayOfBusinesses)
            }
        }
    }
    
    /*func parseGPlacesJSON(data: NSDictionary, completion: (businessArray: [Business]) -> Void){
        if data.count > 0 {
            //var arrayOfGPlaces: [GooglePlace] = []
            var arrayOfBusinesses: [Business] = []
            
            if let places = data["results"] as? NSArray{
                if places.count > 0 {
                    for place in places{
                        
                        let placeID = place["place_id"] as! String
                        let placeName = place["name"] as! String
                        let placeAddress = place["vicinity"] as! String
                        
                        var placePhotoRef = ""
                        if let photos = place["photos"] as? NSArray{
                            placePhotoRef = photos[0]["photo_reference"] as! String
                        }
                        
                        var placeRating = place["rating"] as? Double
                        
                        
                        var placeLat: Double?
                        var placeLng: Double?
                        if let placeGeometry = place["geometry"] as? NSDictionary{
                            if let placeLocation = placeGeometry["location"] as? NSDictionary{
                                placeLat = placeLocation["lat"] as? Double
                                placeLng = placeLocation["lng"] as? Double
                            }
                        }
                        
                        // Create GooglePlace Object
                        //let placeObject = GooglePlace(id: placeID, name: placeName, address: placeAddress, photoRef: placePhotoRef)
                        
                        // Create Business Object
                        let businessObject = Business(name: placeName, address: placeAddress, city: nil, zip: nil, phone: nil, imageURL: nil, photoRef: placePhotoRef, latitude: placeLat, longitude: placeLng, distance: nil, rating: placeRating, categories: nil, status: nil, businessID: nil, placeID: placeID)
                        
                        arrayOfBusinesses.append(businessObject)
                        
                        //arrayOfGPlaces.append(placeObject)
                    }
                }else{
                    // If there are no results
                    completion(businessArray: arrayOfBusinesses)
                }
                
                completion(businessArray: arrayOfBusinesses)
                
                //                if debugPrint.BUSINESS_ARRAY == true{
                //                    print(arrayOfGPlaces)
                //                }
                
            }else{
                // Do this if no places found in data
                completion(businessArray: arrayOfBusinesses)
            }
            
        }
        
    }*/
    
//    private func convertGooglePlaceObjectToBusinessObject(googlePlaceObject: GooglePlace) -> Business{
//        let placeID = googlePlaceObject.placeID
//        let placeAddress = googlePlaceObject.placeAddress
//        let placeName = googlePlaceObject.placeName
//        let photoRef = googlePlaceObject.placePhotoReference
//        
//        let businessObject = Business(name: placeName, address: placeAddress, city: nil, zip: nil, phone: nil, imageURL: nil, photoRef: photoRef, latitude: nil, longitude: nil, distance: nil, rating: nil, categories: nil, status: nil, businessID: nil, placeID: placeID)
//        
//        return businessObject
//    }
}