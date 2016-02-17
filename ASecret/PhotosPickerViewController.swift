//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import Photos
import CoreData
import PSOperations
import AuntieKit
import PKHUD


class PhotosPickerViewController: UICollectionViewController, PlaceholderViewPresentation {
    let operationQueue = OperationQueue()
    var context: NSManagedObjectContext!
    var imageManager: PHCachingImageManager?
    var momentsResult: PHFetchResult?
    var assetResults = [PHFetchResult]()
    var thumbnailSize: CGSize!
    
    
    @IBOutlet weak var addActionBarItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerReusableViewsWithCollectionView(collectionView!)
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        ConfigureLayout(layout, withSize: collectionView!.bounds.size)
        
        updateThumbnailSize()
        collectionView?.allowsMultipleSelection = true
        loadContent()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        ConfigureLayout(layout, withSize: size)
        updateThumbnailSize()
    }
    
    private func updateThumbnailSize() {
        let layout = self.collectionViewLayout as! UICollectionViewFlowLayout
        let size = layout.itemSize
        let scale = UIScreen.mainScreen().scale
        thumbnailSize = CGSizeMake(size.width * scale, size.height * scale)
    }
    
    
    @IBAction func addArtworks(sender: AnyObject) {
        
        let selectedIndexPaths = collectionView?.indexPathsForSelectedItems()
        guard let assets = assetsAtIndexPaths(selectedIndexPaths) where !assets.isEmpty else {
            return
        }
        
        let observer = BlockObserver(
            startHandler: { _ -> Void in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    PKHUD.sharedHUD.contentView = PKHUDProgressView()
                    PKHUD.sharedHUD.dimsBackground = true
                    PKHUD.sharedHUD.show()
                }
            },
            produceHandler: nil,
            finishHandler: { _, errors -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let contentView = errors.isEmpty ? PKHUDSuccessView() : PKHUDErrorView()
                    PKHUD.sharedHUD.contentView = contentView
                    PKHUD.sharedHUD.hide(afterDelay: 0.1)
                })
                // Dismiss view controller after PKHUB finish hiding.
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        )
        
        let operation = ImportAssetsOperation(context: context, assets: assets, imageManager: imageManager!)
        operation.userInitiated = true
        operation.addObserver(observer)
        operationQueue.addOperation(operation)
    }
    
    @IBAction func dismissViewController(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - Placeholder

    var placeholderView: PlaceholderView?

    lazy var emptyPlaceholder: Placeholder = {
        let title = NSLocalizedString("You have no photos or videos", comment: "")
        let message = NSLocalizedString("", comment: "")
        let placeholder = Placeholder(title: title, message: message, image: UIImage(named: "photos-empty"))
        return placeholder
    }()
    
    lazy var errorPlaceholder: Placeholder = {
        let title = NSLocalizedString("Could not access to your Photos", comment: "")
        let message = NSLocalizedString("You can enable access through \"Settings - Privacy - Photos\"", comment: "")
        let placeholder = Placeholder(title: title, message: message, image: UIImage(named: "photos-permission"))
        return placeholder
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let placeholderView = placeholderView {
            // Neutralize the `automaticallyAdjustsScrollViewInsets` effect. 
            // As we want placeholderView extend to the top edge
            var frame = placeholderView.frame
            frame.origin.y = -(topLayoutGuide.length)
            placeholderView.frame = frame
            
        }
    }

}


// MARK: - Collection View DataSource

extension PhotosPickerViewController {
    
    func loadContent() {
        let observer = BlockObserver { _, errors in
            if !errors.isEmpty {
                self.collectionView?.backgroundColor = Theme.sharedTheme.secondaryBackgroundColor
                self.showPlaceholder(self.errorPlaceholder, inView: self.collectionView!, animated: true)
            }
        }
        
        let operation = BlockOperation {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
            self.momentsResult = PHAssetCollection.fetchMomentsWithOptions(options)
            
            guard let momentsResult = self.momentsResult where momentsResult.count > 0 else {
                self.collectionView?.backgroundColor = Theme.sharedTheme.secondaryBackgroundColor
                self.showPlaceholder(self.emptyPlaceholder, inView: self.collectionView!, animated: true)
                return
            }
            
            for i in 0 ..< momentsResult.count {
                let collection = momentsResult[i] as! PHAssetCollection
                let assets = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
                self.assetResults.append(assets)
            }
            
            self.imageManager = PHCachingImageManager()
            self.collectionView?.reloadData()
        }
        operation.userInitiated = true
        operation.addCondition(PhotosCondition())
        operation.addObserver(observer)
        
        operationQueue.addOperation(operation)
    }
    
    func registerReusableViewsWithCollectionView(collectionView: UICollectionView) {
        ArtworkGridViewCell.registerCellToCollectionView(collectionView)
        VideoArtworkGridViewCell.registerCellToCollectionView(collectionView)
        ArtworkHeaderReusableView.registerNibForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, toCollectionView: collectionView)
    }
    
    func assetsAtIndexPaths(indexPaths: [NSIndexPath]?) -> [PHAsset]? {
        guard let indexPaths = indexPaths where !assetResults.isEmpty else {
            return nil
        }

        var assets = [PHAsset]()
        for indexPath in indexPaths {
            let results = assetResults[indexPath.section]
            let asset = results[indexPath.item] as! PHAsset
            assets.append(asset)
        }
        return assets
    }
    

    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return momentsResult?.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetResults[section].count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: ArtworkGridViewCell
        let results = assetResults[indexPath.section]
        let asset = results[indexPath.item] as! PHAsset
        if asset.mediaType == .Video {
            let videoCell = VideoArtworkGridViewCell.dequeueReusableCellFromCollectionView(collectionView, forIndexPath: indexPath)
            videoCell.configureDurationLabelWithDuration(asset.duration)
            cell = videoCell
        } else {
            cell = ArtworkGridViewCell.dequeueReusableCellFromCollectionView(collectionView, forIndexPath: indexPath)
        }
        
        if let identifier = cell.identifier {
            imageManager?.cancelImageRequest(PHImageRequestID(identifier)!)
        }
        
        let identifier = self.imageManager!.requestImageForAsset(asset, targetSize: self.thumbnailSize, contentMode: .AspectFill, options: nil) { (image, info) -> Void in
            cell.imageView.image = image
        }
        cell.identifier = "\(identifier)"
        cell.showSelectedViewIfNeeded()
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        assert(UICollectionElementKindSectionHeader == kind, "For now we only support UICollectionElementKindSectionHeader")
        let header = ArtworkHeaderReusableView.dequeueReusableSupplementaryViewFromCollectionView(collectionView, ofKind: kind, forIndexPath: indexPath)
        let collection = momentsResult![indexPath.section] as! PHAssetCollection
        header.configureDateLabelWithDate(collection.startDate!)
        return header
    }

}


// MARK: - Collection View Delegate

extension PhotosPickerViewController {
    
    func updateUIAfterSelectionChanged() {
        let items = collectionView?.indexPathsForSelectedItems()
        if (items?.count ?? 0) == 0 {
            addActionBarItem.enabled = false
            title = ""
        } else {
            addActionBarItem.enabled = true
            let count = items!.count
            let format = count > 1 ? NSLocalizedString("%d Items Selected", comment: "") : NSLocalizedString("%d Item Selected", comment: "")
            title = String(format: format, arguments: [count])
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ArtworkGridViewCell
        cell.showSelectedView(animated: true)
        updateUIAfterSelectionChanged()
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ArtworkGridViewCell
        cell.hideSelectedView()
        updateUIAfterSelectionChanged()
    }
}
