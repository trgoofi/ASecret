//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import AVFoundation
import Haneke


class VideoCoverFetcher: Fetcher<UIImage> {
    let URL: NSURL
    var generator: AVAssetImageGenerator?
    
    var cancelled = false
    
    init(URL : NSURL) {
        self.URL = URL
        let key =  URL.absoluteString
        super.init(key: key)
    }
    
    override func fetch(failure fail: ((NSError?) -> ()), success succeed: (UIImage) -> ()) {
        cancelled = false
        fetchCover(failure: fail, success: succeed)
    }
    
    private func fetchCover(failure fail: ((NSError?) -> ()), success succeed: (UIImage) -> ()) {
        let asset = AVURLAsset(URL: URL)
        let generator = AVAssetImageGenerator(asset: asset)
        self.generator = generator
        
        let times = [NSValue(CMTime: CMTimeMakeWithSeconds(0, 60))]
        
        generator.generateCGImagesAsynchronouslyForTimes(times) { [weak self] (_, cgImage, _, _, error) in
            guard let strongSelf = self where !(strongSelf.cancelled) else {
                return
            }
            
            if let error = error {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    fail(error)
                })
                return
            }
            
            if let cgImage = cgImage {
                let image = UIImage(CGImage: cgImage)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    succeed(image)
                })
            }
        }
    }
    
    override func cancelFetch() {
        generator?.cancelAllCGImageGeneration()
        cancelled = true
    }
    
    
    static func fetch(URL URL: NSURL, failure fail: ((NSError?) -> ())? = nil, success succeed: ((UIImage) -> ())? = nil) {
        let fetcher = VideoCoverFetcher(URL: URL)
        Shared.imageCache.fetch(fetcher: fetcher, failure: fail, success: succeed)
    }
}