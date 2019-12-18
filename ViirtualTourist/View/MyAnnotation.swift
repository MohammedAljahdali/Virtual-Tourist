//
//  MyAnnotation.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 05/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import Foundation
import MapKit

class MyAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
