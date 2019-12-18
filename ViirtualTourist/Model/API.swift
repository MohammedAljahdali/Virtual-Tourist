//
//  API.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 05/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import Foundation
import UIKit
import Kingfisher

class API {
    static var pageNumber = 1
    static let baseURL = "https://api.flickr.com/services/rest"
    
    
    class func createURL(lat: Double, lon: Double) -> URL {
        return URL(string: "https://api.flickr.com/services/rest?api_key=732c918b7b0e1232e8c9dd9dc1257c4c&method=flickr.photos.search&format=json&lat=\(lat)&lon=\(lon)&per_page=9&accuracy=11&nojsoncallback=1&page=\(pageNumber)")!
    }
    
    
    class func requestPhotosUrl(lat: Double, lon: Double, page: Int, completionHandler: @escaping (Int, [URL], Error?) -> Void) {
        pageNumber = page
        let url = createURL(lat: lat, lon: lon)
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(0, [], error)
                }
                print("error DogAPI/requestDogImageUrl")
                return
            }
            let decode = JSONDecoder()
            do {
                let json = try decode.decode(Response.self, from: data)
                let pages = json.photos.pages
                let photos = json.photos.photo
                let urls = createPhotosURL(photos: photos)
                DispatchQueue.main.async {
                    completionHandler(pages, urls, nil)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completionHandler(0, [], error)
                }
            }
        }
        task.resume()
    }
    
    class func createPhotosURL(photos: [PhotoResponse]) -> [URL] {
        var urls: [URL] = []
        for photo in photos {
            urls.append(URL(string: "https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg")!)
        }
        return urls
    }
}
