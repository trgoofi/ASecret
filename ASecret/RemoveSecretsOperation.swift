//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import CoreData
import PSOperations


class RemoveSecretsOperation: Operation {
    let context: NSManagedObjectContext
    let secrets: [Secret]
    
    
    init(secrets: [Secret], context: NSManagedObjectContext) {
        self.secrets = secrets
        self.context = context
    }
    
    
    override func execute() {
        context.performBlock {
            self.removeSecrets()
        }
    }
    
    private func removeSecrets() {
        let fileManager = NSFileManager.defaultManager()
        for secret in secrets {
            if let storedSecret = secret as? StoredSecret {
                do {
                    try fileManager.removeItemAtURL(storedSecret.URL())
                } catch let error as NSError {
                    finishWithError(error)
                }
            }
            context.deleteObject(secret)
        }
        
        let error = context.tryToSave()
        finishWithError(error)
    }
}
