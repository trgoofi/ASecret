//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import CoreData


protocol StoredSecret {
    func URL() -> NSURL
}


class Secret: NSManagedObject {
    
    class var entityName: String {
        return NSStringFromClass(self).componentsSeparatedByString(".").last!
    }
    
    @NSManaged var filename: String
    @NSManaged var type: String
    @NSManaged var sizeInBytes: UInt64
    
    @NSManaged var createdAt: NSDate
    @NSManaged var updatedAt: NSDate
    @NSManaged var importedAt: NSDate
    
}
