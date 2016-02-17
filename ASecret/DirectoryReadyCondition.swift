//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import PSOperations


struct DirectoryReadyCondition: OperationCondition {
    
    static let name = "DirectoryReadyCondition"
    static let isMutuallyExclusive = false
    
    let directory: String
    let shouldCreate: Bool
    
    init(directory: String, create: Bool = false) {
        self.directory = directory
        self.shouldCreate = create
    }
    
    func dependencyForOperation(operation: Operation) -> NSOperation? {
        return nil
    }
    
    func evaluateForOperation(operation: Operation, completion: OperationConditionResult -> Void) {
        let fileManager = NSFileManager.defaultManager()
        if shouldCreate {
            do {
                try fileManager.createDirectoryAtPath(directory, withIntermediateDirectories: true, attributes: nil)
            } catch let error as NSError {
                completion(.Failed(error))
                return
            }
        }
        
        var isDirectory = ObjCBool(false)
        let exists = fileManager.fileExistsAtPath(directory, isDirectory: &isDirectory)
        if isDirectory.boolValue {
            completion(.Satisfied)
        } else if exists {
            let failureReason = "[\(directory)] is not a directory."
            let error = NSError(code: .DirectoryNotReady, failureReason: failureReason)
            completion(.Failed(error))
        } else {
            let failureReason = "Nothing is there yet. [\(directory)]"
            let error = NSError(code: .DirectoryNotReady, failureReason: failureReason)
            completion(.Failed(error))
        }
        
    }

    
}

