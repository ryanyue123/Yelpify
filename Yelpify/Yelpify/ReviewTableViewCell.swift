//
//  ReviewTableViewCell.swift
//  Yelpify
//
//  Created by Jonathan Lam on 4/28/16.
//  Copyright © 2016 Yelpify. All rights reserved.
//

import UIKit
import Haneke
import SwiftyJSON
import Cosmos

class ReviewTableViewCell: UITableViewCell {
    @IBOutlet weak var reviewTextView: UITextView!
    @IBOutlet weak var reviewName: UILabel!
    @IBOutlet weak var reviewDate: UILabel!
    @IBOutlet weak var reviewProfileImage: UIImageView!
    @IBOutlet weak var CommentRating: CosmosView!
    
    let cache = Shared.dataCache
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(review: NSDictionary){
        
        // Set Review Text
        self.reviewTextView.text = review["text"] as? String
        
        // Set Review Author Name
        self.reviewName.text = review["author_name"] as? String
        
        // Set Review Rating
        if let ratingValue3 = review["rating"] as? Double{
            if ratingValue3 != -1{
                    self.CommentRating.rating = ratingValue3
                }
            }
        // Set Review Author Profile Picture
//        if let profilePhotoURL = review["profile_photo_url"] as? String{
//            
//            //let fetcher = NetworkFetcher<UIImage>(URL: NSURL(string: profilePhotoURL)!)
//            cache.fetch(URL: NSURL(string: profilePhotoURL)!).onSuccess({ (data) in
//                self.reviewProfileImage.image = UIImage(data: data)
//            })
//        }
        
        if let unixTime = review["time"] as? Double{
            let date = NSDate(timeIntervalSince1970: unixTime)
            let dateFormatter = NSDateFormatter()
            //dateFormatter.timeStyle = NSDateFormatterStyle.MediumStyle //Set time style
            dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle //Set date style
            dateFormatter.timeZone = NSTimeZone()
            let localDate = dateFormatter.stringFromDate(date)
            self.reviewDate.text = localDate
        }
        
    }

}