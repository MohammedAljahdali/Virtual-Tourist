//
//  ImageCollectionViewController.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 04/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import UIKit
import CoreData
import Kingfisher
import Firebase
import FirebaseUI

private let reuseIdentifier = "imageCell"

class ImageCollectionViewController: UICollectionViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    let placeholder: UIImage = #imageLiteral(resourceName: "VirtualTourist_120")
    var urls: [URL] = []
    var blockOperations: [BlockOperation] = []
    var db: Firestore!
    var user: User!
    var authUI: FUIAuth!
    var pinID: String!
    var pin2: Pin2!
    var pageNumber: Int! = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        addButton()
        getPageNumber()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewillappear")
        if urls.isEmpty {
            print("urls is empty")
            db.collection("users").document("\(user.email!)").collection("pins").document("\(pinID!)").collection("urls").getDocuments { (documents, error) in
                if let documents = documents {
                    if documents.count == 0 {
                        print("else of if let documents")
                        API.requestPhotosUrl(lat: self.pin2.latitude, lon: self.pin2.longitude, page: self.pageNumber, completionHandler: self.urlsCompletionHandler(pages:urls:error:))
                    } else {
                        print("else else appending urls")
                        for document in documents.documents {
                            let urlString = document.data()["url"] as! String
                            print(urlString)
                            self.urls.append(URL(string: urlString)!)
                        }
                        self.collectionView.reloadData()
//                        self.downloadImages()
                    }
                }
            }
        }
    }
    
    fileprivate func setupLayout() {
        let space: CGFloat = 1.5
        let width: CGFloat = (view.frame.size.width - space * 2) / 2
        let height: CGFloat = (view.frame.size.width - space * 2) / 2
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: width, height: height)
    }
    
    fileprivate func addButton(){
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Refresh", for: UIControl.State.normal)
        button.setTitleColor(UIColor.systemBlue, for: UIControl.State.normal)
        self.view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(removePhotos), for: .touchUpInside)
        
    }
    
    @objc func removePhotos() {
        urls.removeAll()
        API.requestPhotosUrl(lat: pin2!.latitude, lon: pin2!.longitude, page: pageNumber!, completionHandler: refreshUrlCompletionHnadler(pages:urls:error:))
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
        
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
//        let photo = photos[indexPath.row]
        if urls.isEmpty {
            cell.imageView.image = #imageLiteral(resourceName: "VirtualTourist_180")
        } else {
            cell.imageView.kf.setImage(with: urls[indexPath.row], placeholder: placeholder)
        }
        cell.imageView.widthAnchor.constraint(equalToConstant: (view.frame.size.width - 2 * 2) / 2).isActive = true
        cell.imageView.heightAnchor.constraint(equalToConstant: (view.frame.size.width - 2 * 2) / 2).isActive = true
        cell.imageView.contentMode = .scaleAspectFit
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
}



extension ImageCollectionViewController {
    
    func refreshUrlCompletionHnadler(pages: Int, urls: [URL], error: Error?) {
        activityIndicator.startAnimating()
        self.urls = urls
        var index = 0
        while index < urls.count {
            db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").collection("urls").document("\(index)").updateData(["url":urls[index].absoluteString])
            index = index + 1
        }
//        downloadImages()
        activityIndicator.stopAnimating()
        collectionView.reloadData()
        if pages > 2 {
            if pageNumber! < pages {
                pageNumber = pageNumber + 1
                db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").updateData(["pageNumber": pageNumber!])
            } else {
                pageNumber = 1
                db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").updateData(["pageNumber": pageNumber!])
            }
        }
    }
    
    func urlsCompletionHandler(pages: Int, urls: [URL], error: Error?) {
        activityIndicator.startAnimating()
        print("in urlscomp")
        if !urls.isEmpty {
            self.urls = urls
            var index = 0
            while index < urls.count {
                db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").collection("urls").document("\(index)").setData(["url":urls[index].absoluteString])
                index = index + 1
                
            }
//            downloadImages()
            activityIndicator.stopAnimating()
            collectionView.reloadData()
            if pages > 2 {
                if pageNumber! < pages {
                    pageNumber = pageNumber + 1
                    db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").updateData(["pageNumber": pageNumber!])
                } else {
                    pageNumber = 1
                    db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").updateData(["pageNumber": pageNumber!])
                }
            }
        } else {
            var message = ""
            if error == nil {
                message = "There is No Images in This Location"
            } else {
                message = "Failed to download Images, Try Again"
            }
            activityIndicator.stopAnimating()
            let alret = UIAlertController(title: "Failed", message: message, preferredStyle: .alert)
            alret.addAction(UIAlertAction(title: "Ok", style: .default) { [weak self] action in
                self?.dismiss(animated: true, completion: nil)
            })
            show(alret, sender: nil)
        }
    }
    
//    func downloadImages() {
//
//        var index = 0
//        while index < self.urls.count {
//            KingfisherManager.shared.retrieveImage(with: self.urls[index]) { result in
//                switch result {
//                    case .success(let value):
//                        self.photos.append(value.image)
//                    case .failure(let error):
//                        print(error)
//                }
//            }
//            index += 1
//        }
//        print("download finshed")
//        print(photos)
//        collectionView.reloadData()
//        activityIndicator.stopAnimating()
//    }
    
    func getPageNumber() {
        db.collection("users").document("\(user.email!)").collection("pins").document("\(self.pin2.longitude)&\(self.pin2.latitude)").addSnapshotListener { (document, error) in
            guard let document = document else {return}
            guard let data = document.data() else {return}
            self.pageNumber = (data["pageNumber"] as! Int)
        }
    }
}
