//
//  ViewController.swift
//  ViirtualTourist
//
//  Created by Mohammed Khakidaljahdali on 02/12/2019.
//  Copyright © 2019 Mohammed. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Kingfisher
import FirebaseUI



class MapViewController: UIViewController {
    
    var editingMode: Bool = false
    var sharingMode: Bool = false
    var pins2: [Pin2] = []
    var authUI: FUIAuth!
    var user: User!
    var db: Firestore!
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate func setUpGesture() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(gestureReconizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion)),
            UIBarButtonItem(title: "Share", style: .plain, target: self, action: #selector(shareMode)),
            UIBarButtonItem(title: "Shared Pins", style: .plain, target: self, action: #selector(presentSharedPins))
        ]
//        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion))
        navigationItem.title = "Virtual Tourist"
//        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setUpGesture()
        pinsListener()
        setAnnotationsLocations()
    }
    
}

extension MapViewController: MKMapViewDelegate, UIGestureRecognizerDelegate {
    @objc func handleGesture(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == .ended && !editingMode) {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            let annotation = MyAnnotation(coordinate: coordinate)
            savePin(annotation: annotation)
            mapView.addAnnotation(annotation)
        }
    }
    
    func setAnnotationsLocations() {
        mapView.removeAnnotations(mapView.annotations)
        for pin in pins2 {
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MyAnnotation(coordinate: coordinate)
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if editingMode {
            deletePin(annotation: view.annotation! as! MyAnnotation)
        } else if sharingMode {
            sharePin(annotation: view.annotation! as! MyAnnotation)
        } else {
            sendPin(annotation: view.annotation! as! MyAnnotation)
        }
    }
 
}

extension MapViewController {
    func savePin(annotation: MyAnnotation) {
        db.collection("users").document("\(user.email!)").collection("pins").document("\(annotation.coordinate.longitude)&\(annotation.coordinate.latitude)").setData([
            "longitude": annotation.coordinate.longitude,
            "latitude": annotation.coordinate.latitude,
            "pageNumber": 1
        ])
    }
    
    @objc func setUpPinDeletion() {
        if !sharingMode {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(stopDeletion))
            editingMode = true
        }
        
    }
    
    @objc func stopDeletion() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion))
        editingMode = false
    }
    
    @objc func shareMode() {
        if !editingMode {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion)),
                UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(stopShareMode)),
                UIBarButtonItem(title: "Shared Pins", style: .plain, target: self, action: #selector(presentSharedPins))
            ]
            sharingMode = true
        }
    }
    
    @objc func stopShareMode() {
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion)),
            UIBarButtonItem(title: "Share", style: .done, target: self, action: #selector(shareMode)),
            UIBarButtonItem(title: "Shared Pins", style: .plain, target: self, action: #selector(presentSharedPins))
        ]
        sharingMode = false
    }
    
    func deletePin(annotation: MyAnnotation) {
        db.collection("users").document("\(user.email!)").collection("pins").document("\(annotation.coordinate.longitude)&\(annotation.coordinate.latitude)").delete()
        pins2.removeAll()
        mapView.removeAnnotation(annotation)
    }
    
    func sendPin(annotation: MyAnnotation) {
        let vc = storyboard?.instantiateViewController(identifier: "imageCollectionView") as! ImageCollectionViewController
        vc.pin2 = Pin2(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
        vc.pinID = "\(annotation.coordinate.longitude)&\(annotation.coordinate.latitude)"
        vc.authUI = authUI
        vc.db = db
        vc.user = user
        present(vc, animated: true, completion: nil)
    }
    
    func sharePin(annotation: MyAnnotation) {
        let pinID = "\(annotation.coordinate.longitude)&\(annotation.coordinate.latitude)"
        let ref = db.collection("users").document("\(user.email!)").collection("pins").document(pinID)
        ref.getDocument { (document, error) in
            guard let document = document else {return}
            let longitude = document.data()!["longitude"] as! Double
            let latitude = document.data()!["latitude"] as! Double
            let pageNumber = document.data()!["pageNumber"] as! Int
            self.db.collection("sharedPins").document(pinID).setData([
                "longitude": longitude,
                "latitude": latitude,
                "pageNumber": pageNumber,
                "owner": self.user.displayName!
            ])
        }
        ref.collection("urls").getDocuments { (documents, error) in
            guard let documents = documents else {return}
            var index = 0
            for document in documents.documents {
                let urlString = document.data()["url"] as! String
                self.db.collection("sharedPins").document(pinID).collection("urls").document("\(index)").setData(["url":urlString])
                index = index + 1
            }
        }
    }
    
    @objc func presentSharedPins() {
        if !editingMode && !sharingMode {
            performSegue(withIdentifier: "sharedPinsView", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let vc = segue.destination as! SharedPinsTableViewController
        vc.db = db
        vc.user = user
    }
    
}

// MARK: Firebase Auth

extension MapViewController: FUIAuthDelegate {
    func pinsListener() {
        db.collection("users").document("\(user.email!)").collection("pins").addSnapshotListener { (document, error) in
            guard let document = document else {
              print("Error fetching document: \(error!)")
              return
            }
            for doc in document.documents {
                print("\(doc.data().description)+12131")
                let longitude = doc.data()["longitude"] as! Double
                let latitude = doc.data()["latitude"] as! Double
                let pin2 = Pin2(latitude: latitude, longitude: longitude)
                self.pins2.append(pin2)
            }
            self.setAnnotationsLocations()
        }
    }
    
}


