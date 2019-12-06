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

private let reuseIdentifier = "imageCell"

class ImageCollectionViewController: UICollectionViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var pin: Pin!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var blockOperations: [BlockOperation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchResultsController()
        setupLayout()
        addButton()
    }
    
    deinit {
        // Cancel all block operations when VC deallocates
        for operation: BlockOperation in blockOperations {
            operation.cancel()
        }

        blockOperations.removeAll(keepingCapacity: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (fetchedResultsController.sections?[0].objects!.isEmpty)! {
            API.requestPhotosUrl(lat: pin.latitude!, lon: pin.longitude!, completionHandler: urlsCompletionHandler(urls:error:))
        } else {
            activityIndicator.stopAnimating()
            let photo = fetchedResultsController.sections?[0].objects?[0] as! Photo
            let image = #imageLiteral(resourceName: "VirtualTourist_152")
            if image.jpegData(compressionQuality: 1) == photo.data {
                downloadImages()
            }
            try? DataController.shared.viewContext.save()
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
        button.setTitle("Button", for: UIControl.State.normal)
        button.setTitleColor(UIColor.black, for: UIControl.State.normal)
        self.view.addSubview(button)
        button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        button.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: #selector(removePhotos), for: .touchUpInside)
        
    }
    
    @objc func removePhotos() {
        let length = fetchedResultsController.sections?[0].objects?.count
        var index = 0
        while index < length! {
            let photo = fetchedResultsController.object(at: IndexPath.init(item: index, section: 0))
            DataController.shared.viewContext.delete(photo)
            index += 1
        }
        try? DataController.shared.viewContext.save()
        API.requestPhotosUrl(lat: pin.latitude!, lon: pin.longitude!, completionHandler: urlsCompletionHandler(urls:error:))
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
        
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[0].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photo = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ImageCollectionViewCell
        if let data = photo.data {
            cell.imageView.image = UIImage(data: data)
            cell.imageView.widthAnchor.constraint(equalToConstant: (view.frame.size.width - 2 * 2) / 2).isActive = true
            cell.imageView.heightAnchor.constraint(equalToConstant: (view.frame.size.width - 2 * 2) / 2).isActive = true
            cell.imageView.contentMode = .scaleAspectFit
        } else {
            let image = #imageLiteral(resourceName: "VirtualTourist_152")
            cell.imageView.image = image
            cell.imageView.widthAnchor.constraint(equalToConstant: (view.frame.size.width - 2 * 2) / 2).isActive = true
            cell.imageView.heightAnchor.constraint(equalToConstant: (view.frame.size.width - 2 * 2) / 2).isActive = true
            cell.imageView.contentMode = .scaleAspectFit
            photo.data = cell.imageView.image?.jpegData(compressionQuality: 1)
            try? DataController.shared.viewContext.save()
        }
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        DataController.shared.viewContext.delete(photoToDelete)
        try? DataController.shared.viewContext.save()
        if fetchedResultsController.sections?[0].numberOfObjects == 0 {
            API.requestPhotosUrl(lat: pin.latitude!, lon: pin.longitude!, completionHandler: urlsCompletionHandler(urls:error:))
        }
    }
    
}

// MARK: FetchedResultControllerDelegate

extension ImageCollectionViewController: NSFetchedResultsControllerDelegate {
    fileprivate func setupFetchResultsController() {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptors = NSSortDescriptor(key: "createdAt", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptors]
        let predicate = NSPredicate(format: "pin == %@", pin)
        fetchRequest.predicate = predicate

    
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: "pin: \(pin.latitude!)+\(pin.longitude!)")
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    
    

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(IndexSet(integer: sectionIndex))
                    }
                })
            )
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: BlockOperation in self.blockOperations {
                operation.start()
            }
        }, completion: { (finished) -> Void in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }


}

extension ImageCollectionViewController {
    func urlsCompletionHandler(urls: [URL], error: Error?) {
        activityIndicator.startAnimating()
        if !urls.isEmpty {
            var index = 0
            var photos: [Photo] = []
            while index < urls.count {
                photos.append(Photo(context: DataController.shared.viewContext))
                photos[index].createdAt = Date()
                photos[index].url = urls[index]
                photos[index].pin = pin
                index = index + 1
                try? DataController.shared.viewContext.save()
            }
            downloadImages()
            
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
    
    func downloadImages() {
        activityIndicator.stopAnimating()
        let length = fetchedResultsController.sections?[0].objects?.count
        var index = 0
        while index < length! {
            let photo = fetchedResultsController.object(at: IndexPath.init(item: index, section: 0))
            index += 1
            KingfisherManager.shared.retrieveImage(with: photo.url!) { result in
                switch result {
                    case .success(let value):
                        photo.data = value.image.jpegData(compressionQuality: 1)
                    case .failure(let error):
                        print(error)
                }
            }
        }

        try? DataController.shared.viewContext.save()
    }
}
