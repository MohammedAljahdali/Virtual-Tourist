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
    var pins: [Pin] = []
    // TODO: Bool for sharing mode
    var authUI: FUIAuth!
    var user: User!
    var db: Firestore!
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate func setUpGesture() {
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleGesture(gestureReconizer:)))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion))
        navigationItem.title = "Virtual Tourist"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logout))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setUpGesture()
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sort = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sort]
        if let result = try? DataController.shared.viewContext.fetch(fetchRequest) {
            pins = result
        }
        setAnnotationsLocations()
        
        
    }
    
}

extension MapViewController: MKMapViewDelegate, UIGestureRecognizerDelegate {
    @objc func handleGesture(gestureReconizer: UILongPressGestureRecognizer) {
        if (gestureReconizer.state == .ended && !editingMode) {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            // Add annotation:
            let annotation = MyAnnotation(coordinate: coordinate)
            annotation.pin = savePin(annotation: annotation)
            mapView.addAnnotation(annotation)
        }
    }
    
    func setAnnotationsLocations() {
        mapView.removeAnnotations(mapView.annotations)
        for pin in pins {
            let latitude = CLLocationDegrees(Double(pin.latitude!)!)
            let longitude = CLLocationDegrees(Double(pin.longitude!)!)
            let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let annotation = MyAnnotation(coordinate: coordinate)
            annotation.coordinate = coordinate
            annotation.pin = pin
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if !editingMode {
            sendPin(annotation: view.annotation! as! MyAnnotation)
        } else {
            deletePin(annotation: view.annotation! as! MyAnnotation)
        }
    }
 
}

extension MapViewController {
    func savePin(annotation: MyAnnotation) -> Pin {
        
        db.collection("users").document("\(user.email!)").collection("pins").document("\(annotation.coordinate.longitude)&\(annotation.coordinate.latitude)").setData([
            "longitude": annotation.coordinate.longitude,
            "latitude": annotation.coordinate.latitude
        ])
        let latitudeString = "\(annotation.coordinate.latitude)"
        let longitudeString = "\(annotation.coordinate.longitude)"
        let pin = Pin(context: DataController.shared.viewContext)
        pin.latitude = latitudeString
        pin.longitude = longitudeString
        try? DataController.shared.viewContext.save()
        return pin
    }
    
    @objc func setUpPinDeletion() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(stopDeletion))
        editingMode = true
        
    }
    
    @objc func stopDeletion() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(setUpPinDeletion))
        editingMode = false
    }
    
    func deletePin(annotation: MyAnnotation) {
        let pinToDelete = annotation.pin
        if let pin = pinToDelete {
            mapView.removeAnnotation(annotation)
            DataController.shared.viewContext.delete(pin)
            try? DataController.shared.viewContext.save()
        }
    }
    
    func sendPin(annotation: MyAnnotation) {
        let vc = storyboard?.instantiateViewController(identifier: "imageCollectionView") as! ImageCollectionViewController
        let pinToSend = annotation.pin
        if let pin = pinToSend {
            vc.pin = pin
            vc.authUI = authUI
            vc.db = db
            vc.user = user
            present(vc, animated: true, completion: nil)
        }
    }
    
}

// MARK: Firebase Auth

extension MapViewController: FUIAuthDelegate {
    
    @objc func logout() {
        do {
            try authUI.signOut()
            user = nil
            let vc = storyboard?.instantiateViewController(identifier: "loginViewController") as! LoginViewController
            vc.user = nil
            vc.authUI = self.authUI
            // TODO: Fix user can enter after logout without re logging in
            navigationController?.popViewController(animated: true)
        } catch {
            let alertVC = UIAlertController(title: "Logout Failed", message: "Sorry Logout failled: \(error.localizedDescription)", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertVC, animated: true, completion: nil)
        }
    }
}


