//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import CoreData

class FetchedResultsUpdater: NSObject, NSFetchedResultsControllerDelegate {
    unowned let collectionView: UICollectionView
    
    struct ChangeObject {
        let indexPath: NSIndexPath?
        let newIndexPath: NSIndexPath?
    }
    
    private var changedObjects = [NSFetchedResultsChangeType: [ChangeObject]]()
    private var changedSections = [NSFetchedResultsChangeType: NSMutableIndexSet]()
    
    let finishedHandler: (() -> Void)?
    
    init(collectionView: UICollectionView, finishedHandler: (() -> Void)? = nil) {
        self.collectionView = collectionView
        self.finishedHandler = finishedHandler
    }
    
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        changedObjects = [NSFetchedResultsChangeType: [ChangeObject]]()
        changedSections = [NSFetchedResultsChangeType: NSMutableIndexSet]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        performUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        captureChangeSection(sectionInfo, atIndex: sectionIndex, forChangeType: type)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        captureChangeObject(anObject, atIndexPath: indexPath, forChangeType: type, newIndexPath: newIndexPath)
    }
    
    
    func captureChangeSection(sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if changedSections[type] == nil {
            changedSections[type] = NSMutableIndexSet()
        }
        changedSections[type]!.addIndex(sectionIndex)
    }
    
    func captureChangeObject(object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if changedObjects[type] == nil {
            changedObjects[type] = [ChangeObject]()
        }
        let changeObject = ChangeObject(indexPath: indexPath, newIndexPath: newIndexPath)
        changedObjects[type]!.append(changeObject)
    }
    

    func performUpdates() {
        let collectionView = self.collectionView
        var changedObjects = self.changedObjects
        var changedSections = self.changedSections
        
        collectionView.performBatchUpdates({
            if let deletedObjects = changedObjects[.Delete] {
                let indexPaths = deletedObjects.flatMap { $0.indexPath }
                collectionView.deleteItemsAtIndexPaths(indexPaths)
            }
            if let deletedSetions = changedSections[.Delete] {
                collectionView.deleteSections(deletedSetions)
            }
            
            if let insertedObjects = changedObjects[.Insert] {
                let indexPaths = insertedObjects.flatMap { $0.newIndexPath }
                collectionView.insertItemsAtIndexPaths(indexPaths)
            }
            if let insertedSections = changedSections[.Insert] {
                collectionView.insertSections(insertedSections)
            }
            
            if let updatedObjects = changedObjects[.Update] {
                let indexPaths = updatedObjects.flatMap { $0.indexPath }
                collectionView.reloadItemsAtIndexPaths(indexPaths)
            }
            
            if let movedObjects = changedObjects[.Move] {
                for movedObject in movedObjects {
                    collectionView.moveItemAtIndexPath(movedObject.indexPath!, toIndexPath: movedObject.newIndexPath!)
                }
            }
        }, completion: { _ in
            changedObjects.removeAll()
            changedSections.removeAll()
            self.finishedHandler?()
        })

    }
    
}