//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import Photos
import CoreData
import PSOperations
import AuntieKit


class ImportAssetsOperation: Operation {
    
    let context: NSManagedObjectContext
    
    let assets: [PHAsset]
    let imageManager: PHImageManager
    let artworkFolderURL = Preferences.sharedPreferences.artworkFolderURL
    
    init(context: NSManagedObjectContext, assets: [PHAsset], imageManager: PHImageManager) {
        self.context = context
        self.assets = assets
        self.imageManager = imageManager
        
        super.init()
        
        addCondition(DirectoryReadyCondition(directory: artworkFolderURL.path!, create: true))
    }
    
    
    override func execute() {        
        let context = self.context
        var errors = [NSError]()
        let assetGroup = dispatch_group_create()
        
        for asset in assets {
            dispatch_group_enter(assetGroup)
            imageManager.requestImageDataForAsset(asset, options: nil, resultHandler: { (data, dataUTI, orientation, info) -> Void in
                defer { dispatch_group_leave(assetGroup) }
                
                guard let data = data, let dataUTI = dataUTI else { return }
                
                let filenameExtension = UTIFilenameExtensionForUTI(dataUTI)
                let filename = filenameExtension != nil ? (NSUUID().UUIDString + "." + filenameExtension!) : (NSUUID().UUIDString)
                let fileURL = self.artworkFolderURL.URLByAppendingPathComponent(filename)
                
                do {
                    try data.writeToURL(fileURL, options: .DataWritingAtomic)
                } catch let error as NSError {
                    errors.append(error)
                    return
                }
        
                var uti = dataUTI
                if asset.mediaType == .Video {
                    // `dataUTI` is not the preferred UTI when comes to `.Video` type.
                    // Make a little detour to get the preferred UTI
                    uti = UTIForFilenameExtension(filenameExtension!)!
                }
                
                dispatch_group_enter(assetGroup)
                context.performBlock {
                    defer { dispatch_group_leave(assetGroup) }
                    let date = NSDate()
                    let artwork = context.insertNewObjectForEntityForName(Artwork.entityName) as! Artwork
                    artwork.filename = filename
                    artwork.type = uti
                    artwork.sizeInBytes = UInt64(data.length)
                    artwork.createdAt = asset.creationDate ?? date
                    artwork.updatedAt = asset.modificationDate ?? date
                    artwork.importedAt = date
                    artwork.duration = asset.duration
                    artwork.day = TruncateTimeFromDate(artwork.createdAt)!
                }
            })
        }
        
        dispatch_group_notify(assetGroup, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)) {
            context.performBlock {
                if let error = context.tryToSave() {
                    errors.append(error)
                }
                self.finish(errors)
            }
        }
    }
    
}
