//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation


class Preferences {
    static let sharedPreferences = Preferences()
    
    init() { }
    
    private struct DefaultValues {
        static let documentDirectoryURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
        static let artworkFolderURL = documentDirectoryURL.URLByAppendingPathComponent("ASecret.Artwork")
        static let persistentStoreURL = documentDirectoryURL.URLByAppendingPathComponent("ASecret.sqlite")
    }
    
    var artworkFolderURL: NSURL {
        return DefaultValues.artworkFolderURL
    }
    
    var persistentStoreURL: NSURL {
        return DefaultValues.persistentStoreURL
    }
    
}