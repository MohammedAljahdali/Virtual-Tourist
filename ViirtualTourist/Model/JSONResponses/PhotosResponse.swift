//
//  PhotosResponse.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 05/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import Foundation

struct PhotosResponse: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [PhotoResponse]
}
