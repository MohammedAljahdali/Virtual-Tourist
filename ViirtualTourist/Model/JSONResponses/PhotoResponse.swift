//
//  PhotoResponse.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 05/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import Foundation

struct PhotoResponse: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
