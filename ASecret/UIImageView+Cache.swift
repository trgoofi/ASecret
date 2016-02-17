//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import Haneke
import AVFoundation


extension UIImageView {
    
    func setImageFormURL(URL: NSURL) {
//        hnk_setImageFromFile(URL.path!)
        hnk_setImageFromURL(URL)
    }
    
    func cancelSetImage(withoutNilingIt withoutNilingIt: Bool = false) {
        hnk_cancelSetImage()
        if !withoutNilingIt {
            image = nil
        }
    }
    
    func setImageFormVideoURL(URL: NSURL) {
        let fetcher = VideoCoverFetcher(URL: URL)
        hnk_setImageFromFetcher(fetcher)
    }
    
}

