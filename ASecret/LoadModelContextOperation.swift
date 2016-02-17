//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import CoreData
import PSOperations


class LoadModelContextOperation: Operation {
    
    let completionHandler: NSManagedObjectContext -> Void
    
    init(completionHandler: NSManagedObjectContext -> Void) {
        self.completionHandler = completionHandler
        super.init()
        addCondition(MutuallyExclusive<LoadModelContextOperation>())
    }
    
    override func execute() {
        var error: NSError?
        
        let storeURL = Preferences.sharedPreferences.persistentStoreURL
        let model = NSManagedObjectModel.mergedModelFromBundles(nil)!
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil)
            let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            completionHandler(context)
        } catch let err as NSError {
            error = err
        }
        
        finishWithError(error)
    }
    
    override func finished(errors: [NSError]) {
        guard let error = errors.first where userInitiated else {
            return
        }
        
        let title = NSLocalizedString("Unable to load database", comment: "")
        let format = NSLocalizedString("An error occurred while loading the database. %@. Please try again later.", comment: "")
        let message = String(format: format, error.localizedDescription)
        let handler = completionHandler

        let alert = AlertOperation()
        alert.title = title
        alert.message = message
        alert.addAction(NSLocalizedString("Cancel", comment: ""), style: .Cancel)
        alert.addAction(NSLocalizedString("Retry", comment: "")) { alertOperation in
            let retryOperation = LoadModelContextOperation(completionHandler: handler)
            retryOperation.userInitiated = true
            alertOperation.produceOperation(retryOperation)
        }
        produceOperation(alert)
    }
}