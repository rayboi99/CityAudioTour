//
//  Attraction.swift
//  CityAudioTour
//
//  Created by Pichan Vasantakitkumjorn on 2/12/15.
//  Copyright (c) 2015 SE491-591. All rights reserved.
//

//
//  AttractionDetail.swift
//  DetailPage
//
//  Created by Pichan Vasantakitkumjorn on 2/6/15.
//  Copyright (c) 2015 Pichan Vasantakitkumjorn. All rights reserved.
//

import UIKit

class Attraction{
    
    var AttractionName = ""
    var AttractionAddress = ""
    var Detail = ""
    var Content = ""
    var AttractionID = 0
    var AttractionImage = UIImage()
    var Latitude = 0.0
    var Longitude = 0.0

    init(){}
        
    func setAddress(address:String, city:String, state:String, ZIP:String){
        self.AttractionAddress = address + "\n" + city + "," + state + " " + ZIP
    }
    
    
}

