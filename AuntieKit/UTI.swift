//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import MobileCoreServices


public func UTIFilenameExtensionForUTI(uti: String) -> String? {
    let ext = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension)?.takeRetainedValue() as String?
    return ext
}

public func UTIForFilenameExtension(filenameExtension: String) -> String? {
    let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, filenameExtension, nil)?.takeRetainedValue() as String?
    return uti
}