//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import PSOperations
import AuntieKit


class ArtworksCollectionViewController: UICollectionViewController, PlaceholderViewPresentation {
    let operationQueue = OperationQueue()

    var resultsFetcher: NSFetchedResultsController?
    
    lazy var resultsFetcherUpdater: FetchedResultsUpdater = {
        let updater = FetchedResultsUpdater(collectionView: self.collectionView!, finishedHandler: { () -> Void in
            self.updatePlaceholderView()
            self.setEditing(false, animated: true)
        })
        return updater
    }()
    
    lazy var zoomTransitioningDelegate = ZoomInTossOutTransitioningDelegate()

    
    @IBOutlet var addButtonItem: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerReusableViewsWithCollectionView(collectionView!)
        collectionView?.allowsMultipleSelection = true
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        ConfigureLayout(layout, withSize: collectionView!.bounds.size)
        loadContent()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        ConfigureLayout(layout, withSize: size)
    }

    
    // MARK: - Editing Artworks
    
    func removeArtworks() {
        guard let indexPaths = self.collectionView?.indexPathsForSelectedItems() else { return }
        guard let resultsFetcher = self.resultsFetcher else { return }
        let context = resultsFetcher.managedObjectContext
        
        let items = indexPaths.flatMap { resultsFetcher.objectAtIndexPath($0) as? Artwork }
        let operation = RemoveSecretsOperation(secrets: items, context: context)
        operation.addObserver(BlockObserver { (_, errors) -> Void in
            print(errors)
        })
        operation.userInitiated = true
        operationQueue.addOperation(operation)
    }
    
    @IBAction func trashArtworks(sender: UIBarButtonItem) {
        let operation = BlockOperation {
            let cancelTitle = NSLocalizedString("Cancel", comment: "")
            let cancel = UIAlertAction(title: cancelTitle, style: .Cancel, handler: nil)
            
            let deleteTitle = NSLocalizedString("Delete", comment: "")
            let delete = UIAlertAction(title: deleteTitle, style: .Destructive, handler: { _ in
                self.removeArtworks()
            })
            
            let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            alertController.addAction(cancel)
            alertController.addAction(delete)
            alertController.popoverPresentationController?.barButtonItem = sender
            self.presentViewController(alertController, animated: true, completion: nil)
        }
        operation.userInitiated = true
        operation.addCondition(AlertPresentation())
        operation.addCondition(MutuallyExclusive<UIViewController>())
        operationQueue.addOperation(operation)
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateNavigationItems()
        updateTitleAndToolbar()
        if !editing {
            clearCollectionViewSelection()
        }
    }
    
    func clearCollectionViewSelection() {
        let selectedItemIndexPaths = collectionView?.indexPathsForSelectedItems()
        selectedItemIndexPaths?.forEach {
            collectionView?.deselectItemAtIndexPath($0, animated: false)
            collectionView?.delegate?.collectionView?(collectionView!, didDeselectItemAtIndexPath: $0)
        }
    }
    
    func updateNavigationItems() {
        let editItem = editButtonItem()
        // Spare the tedious duplication checking by create a new array each time.
        var rightBarButtonItems = [UIBarButtonItem]()
        if editing {
            editItem.title = NSLocalizedString("Cancel", comment: "")
        } else {
            rightBarButtonItems.append(addButtonItem)
            editItem.title = NSLocalizedString("Select", comment: "")
        }
        if let count = resultsFetcher?.sections?.count where count > 0 {
            rightBarButtonItems.insert(editItem, atIndex: 0)
        }
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    func updateTitleAndToolbar() {
        guard editing else {
            title = NSLocalizedString("Photos", comment: "")
            navigationController?.setToolbarHidden(true, animated: true)
            return
        }
        
        let items = collectionView?.indexPathsForSelectedItems()
        
        if (items?.count ?? 0) == 0 {
            title = NSLocalizedString("Select Items", comment: "")
            navigationController?.setToolbarHidden(true, animated: true)
        } else {
            let count = items!.count
            let format = count > 1 ? NSLocalizedString("%d Items Selected", comment: "")
                                   : NSLocalizedString("%d Item Selected", comment: "")
            title = String(format: format, arguments: [count])
            navigationController?.setToolbarHidden(false, animated: true)
        }
    }
    
    
    // MARK: - Placeholder
    
    var placeholderView: PlaceholderView?

    lazy var emptyPlaceholder: Placeholder = {
        let title = NSLocalizedString("You have no secret yet", comment: "")
        let message = NSLocalizedString("Tap + above to add photos or videos as secerts", comment: "")
        let placeholder = Placeholder(title: title, message: message, image: UIImage(named: "photos-empty"))
        return placeholder
    }()
    
    func updatePlaceholderView() {
        guard let resultsFetcher = self.resultsFetcher else { return }
        if (resultsFetcher.sections?.count ?? 0) == 0 {
            collectionView?.backgroundColor = Theme.sharedTheme.secondaryBackgroundColor
            showPlaceholder(emptyPlaceholder, inView: collectionView!, animated: true)
        } else {
            collectionView?.backgroundColor = Theme.sharedTheme.primaryBackgroundColor
            hidePlaceholderViewAnimated(false)
        }
    }
    
    
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
    
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotosPicker" {
            let controller: PhotosPickerViewController
            if let navigationController = segue.destinationViewController as? UINavigationController {
                controller = navigationController.topViewController as! PhotosPickerViewController
            } else {
                controller = segue.destinationViewController as! PhotosPickerViewController
            }
            controller.context = resultsFetcher?.managedObjectContext
        }
    }
}



// MARK: - Collection View DataSource

extension ArtworksCollectionViewController {
    
    func loadContent() {
        let operation = LoadModelContextOperation { (context) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let request = NSFetchRequest(entityName: Artwork.entityName)
                request.sortDescriptors = [NSSortDescriptor(key: "day", ascending: false), NSSortDescriptor(key: "createdAt", ascending: true)]
                request.fetchBatchSize = 50
                let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "day", cacheName: nil)
                controller.delegate = self.resultsFetcherUpdater
                self.resultsFetcher = controller

                do {
                    try controller.performFetch()
                } catch {
                    print("Faild to fetch result: \(error)")
                }
                self.collectionView?.reloadData()
                self.updateNavigationItems()
                self.updatePlaceholderView()
            })
        }
        operationQueue.addOperation(operation)
    }
    
    func registerReusableViewsWithCollectionView(collectionView: UICollectionView) {
        ArtworkGridViewCell.registerCellToCollectionView(collectionView)
        VideoArtworkGridViewCell.registerCellToCollectionView(collectionView)
        ArtworkHeaderReusableView.registerNibForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, toCollectionView: collectionView)
    }
    
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return resultsFetcher?.sections?.count ?? 0
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultsFetcher?.sections?[section].numberOfObjects ?? 0
    }
    
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: ArtworkGridViewCell

        let artwork = resultsFetcher?.objectAtIndexPath(indexPath) as! Artwork
        if artwork.mediaType == .Video {
            let videoCell = VideoArtworkGridViewCell.dequeueReusableCellFromCollectionView(collectionView, forIndexPath: indexPath)
            videoCell.configureViewWithArtwork(artwork)
            cell = videoCell
        } else {
            cell = ArtworkGridViewCell.dequeueReusableCellFromCollectionView(collectionView, forIndexPath: indexPath)
            cell.configureViewWithArtwork(artwork)
        }
        cell.showSelectedViewIfNeeded()
        return cell
    }
    
    @nonobjc static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "YYYY-MM-DD"
        return formatter
    }()
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        assert(UICollectionElementKindSectionHeader == kind, "For now we support UICollectionElementKindSectionHeader only!")
        
        let dateString = (resultsFetcher?.sections?[indexPath.section])!
        let dayString = dateString.name.componentsSeparatedByString(" ").first! // pick the YYYY-MM-DD form YYYY-MM-DD HH:MM:SS ±HHMM
        let date = ArtworksCollectionViewController.dateFormatter.dateFromString(dayString)!
        
        let header = ArtworkHeaderReusableView.dequeueReusableSupplementaryViewFromCollectionView(collectionView, ofKind: kind, forIndexPath: indexPath)
        header.configureDateLabelWithDate(date)
        return header
    }
    
}
 

// MARK: - Collection View Delegate

extension ArtworksCollectionViewController {
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ArtworkGridViewCell else { return }
        
        guard !editing else {
            updateTitleAndToolbar()
            cell.showSelectedView(animated: true)
            return
        }
        
        let controller = storyboard?.instantiateViewControllerWithIdentifier("ArtworkGalleryViewController") as! ArtworkGalleryViewController
        controller.resultsFetcher = resultsFetcher
        controller.showArtworkAtIndexPath = indexPath
        controller.delegate = self
        controller.transitionFormImageView = cell.imageView
        controller.modalPresentationStyle = .Custom
        controller.transitioningDelegate = zoomTransitioningDelegate
        controller.modalPresentationCapturesStatusBarAppearance = true
        presentViewController(controller, animated: true, completion: nil)
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ArtworkGridViewCell else { return }
        cell.hideSelectedView()
        updateTitleAndToolbar()
    }
    
}


// MARK: - ArtworkGalleryViewControllerDelegate

extension ArtworksCollectionViewController: ArtworkGalleryViewControllerDelegate {
    
    func artworkGalleryViewController(controller: ArtworkGalleryViewController, willDismissAtIndexPath indexPath: NSIndexPath) {
        collectionView?.scrollToItemAtIndexPath(indexPath, atScrollPosition: .CenteredVertically, animated: false)
        collectionView?.setNeedsLayout()
        collectionView?.layoutIfNeeded()
    }

    func viewForDismissToAtIndexPath(indexPath: NSIndexPath, artworkGalleryViewController: ArtworkGalleryViewController) -> UIView? {
        let cell = collectionView?.cellForItemAtIndexPath(indexPath)
        return cell
    }
}


// MARK: - Configure Artwork Item Layout
// TODO: Make it as a collection view layout.

func ConfigureLayout(layout: UICollectionViewFlowLayout, withSize size: CGSize) {
    let userInterfaceIdiom = layout.collectionView!.traitCollection.userInterfaceIdiom
    
    let minItemSpacing: CGFloat = 1
    let minNumberOfItems: CGFloat
    if userInterfaceIdiom == .Phone {
        minNumberOfItems = 4
    } else {
        minNumberOfItems = 5
    }
    
    let totalSpaces = min(size.width, size.height)
    let itemSize = floor((totalSpaces / minNumberOfItems) - minItemSpacing)
    let column = floor(size.width / itemSize)
    let surplus = size.width - (itemSize * column)
    var actualItemSpacing = surplus / (column - 1)
    var inset: CGFloat = 0.0
    if actualItemSpacing > (minItemSpacing + 1) {
        actualItemSpacing = surplus / (column + 1)
        inset = actualItemSpacing
    }
    
    layout.itemSize = CGSizeMake(itemSize, itemSize)
    layout.minimumLineSpacing = actualItemSpacing
    layout.minimumInteritemSpacing = minItemSpacing
    layout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 10, right: inset)
    layout.headerReferenceSize = CGSizeMake(size.width, 44)
    
    if #available(iOS 9.0, *) {
        layout.sectionHeadersPinToVisibleBounds = true
    } else {
        // TODO: implement pin header prior to iOS 9
    }
}



