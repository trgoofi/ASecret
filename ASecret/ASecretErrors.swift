//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation


let ASecretErrorDomain = "ASecretErrorDomain"


enum ASecretErrorCode: Int {
    case DirectoryNotReady = -1000
}


extension NSError {
    convenience init(code: ASecretErrorCode, failureReason: String) {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        self.init(domain: ASecretErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}


func ==(lhs: Int, rhs: ASecretErrorCode) -> Bool {
    return lhs == rhs.rawValue
}

func ==(lhs: ASecretErrorCode, rhs: Int) -> Bool {
    return lhs.rawValue == rhs
}