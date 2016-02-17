//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import CoreData

public extension NSManagedObjectContext {
    
    public func tryToSave() -> NSError? {
        var error: NSError?
        if self.hasChanges {
            do {
                try self.save()
            } catch let err as NSError {
                error = err
            }
        }
        return error
    }
    
    
    public func insertNewObjectForEntityForName(entityName: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: self)
    }
    
}