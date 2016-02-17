//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import CoreLocation
import Photos
import MobileCoreServices


func TruncateTimeFromDate(date: NSDate) -> NSDate? {
    let calendar = NSCalendar.currentCalendar()
    let components = calendar.components([.Year, .Month, .Day], fromDate: date)
    let interval = NSTimeInterval(NSTimeZone.localTimeZone().secondsFromGMT)
    return calendar.dateFromComponents(components)?.dateByAddingTimeInterval(interval)
}



class Artwork: Secret {
    
    @NSManaged var altitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    
    @NSManaged var duration: NSTimeInterval
            
    @NSManaged var day: NSDate

    
    var location: CLLocation? {
        get {
            guard let latitude = latitude as? CLLocationDegrees, let longitude = longitude as? CLLocationDegrees else {
                return nil
            }
            var altitude: CLLocationDegrees = 0
            var verticalAccuracy: CLLocationAccuracy = -1
            if self.altitude != nil {
                verticalAccuracy = 0
                altitude = self.altitude as! CLLocationDegrees
            }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let location = CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: verticalAccuracy, timestamp: createdAt)
            return location
        }
        set {
            altitude  = newValue?.altitude
            latitude  = newValue?.coordinate.latitude
            longitude = newValue?.coordinate.longitude
        }
    }
    
    private(set) lazy var mediaType: PHAssetMediaType = {
        let mediaType = PHAssetMediaType(UTIType: self.type)
        return mediaType
    }()
    
}


extension Artwork: StoredSecret {
    
    func URL() -> NSURL {
        let artworkFolderURL = Preferences.sharedPreferences.artworkFolderURL
        let URL = artworkFolderURL.URLByAppendingPathComponent(filename)
        return URL
    }
    
}


extension PHAssetMediaType {
    init(UTIType: String) {
        if UTTypeConformsTo(UTIType, kUTTypeAudio) {
            self = .Audio
        } else if UTTypeConformsTo(UTIType, kUTTypeVideo) {
            self = .Video
        } else if UTTypeConformsTo(UTIType, kUTTypeMovie) {
            self = .Video
        } else if UTTypeConformsTo(UTIType, kUTTypeImage) {
            self = .Image
        } else {
            self = .Unknown
        }
    }
}


