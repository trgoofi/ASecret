//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import AuntieKit


class ArtworkHeaderReusableView: UICollectionReusableView {

    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textSizeDidChange", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func textSizeDidChange() {
        dateLabel.invalidateDynamicTypeTextIfAppropriate()
    }
    
}


extension ArtworkHeaderReusableView: ReusableCollectionViewSupplementaryView {
    
    typealias ReusableType = ArtworkHeaderReusableView
    
    class var reusableIdentifier: String {
        return "ArtworkHeaderReusableView"
    }
    
    static func registerNibForSupplementaryViewOfKind(kind: String, toCollectionView collectionView: UICollectionView) {
        let nib = UINib(nibName: "ArtworkHeaderReusableView", bundle: nil)
        registerNib(nib, forSupplementaryViewOfKind: kind, toCollectionView: collectionView)
    }
    
}


extension ArtworkHeaderReusableView {
    
    @nonobjc static let dateFormatter: NSDateFormatter = {
        let formatter = NSDateFormatter()
        formatter.dateStyle = .MediumStyle
        return formatter
    }()
    
    func configureDateLabelWithDate(date: NSDate) {
        dateLabel.text = ArtworkHeaderReusableView.dateFormatter.stringFromDate(date)
    }
}