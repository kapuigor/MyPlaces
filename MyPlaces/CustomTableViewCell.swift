//
//  CustomTableViewCell.swift
//  MyPlaces
//
//  Created by Игорь Капустин on 03.08.2021.
//

import UIKit
import Cosmos

class CustomTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var imageOfPlace: UIImageView! {
        didSet {
            imageOfPlace?.layer.cornerRadius = imageOfPlace.frame.size.height / 6
            imageOfPlace?.clipsToBounds = true
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet var cosmosView: CosmosView! {
        didSet {
            cosmosView.settings.updateOnTouch = false
        }
    }
    
}
