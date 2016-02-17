//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit



protocol Reusable {
    
    typealias ReusableType
    static var reusableIdentifier: String { get }
    
}



protocol ReusableCollectionViewCell: Reusable {
    
    static func registerCellToCollectionView(collectionView: UICollectionView) -> Void
    static func dequeueReusableCellFromCollectionView(collectionView: UICollectionView, forIndexPath indexPath: NSIndexPath) -> ReusableType
    
}

extension ReusableCollectionViewCell where Self: UICollectionViewCell, ReusableType == Self {
    
    static func registerCellToCollectionView(collectionView: UICollectionView) {
        collectionView.registerClass(ReusableType.self, forCellWithReuseIdentifier: reusableIdentifier)
    }
    
    static func dequeueReusableCellFromCollectionView(collectionView: UICollectionView, forIndexPath indexPath: NSIndexPath) -> ReusableType {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reusableIdentifier, forIndexPath: indexPath)
        return cell as! ReusableType
    }
    
}



protocol ReusableCollectionViewSupplementaryView: Reusable {
    
    static func registerNib(nib: UINib?, forSupplementaryViewOfKind kind: String, toCollectionView collectionView: UICollectionView) -> Void
    static func dequeueReusableSupplementaryViewFromCollectionView(collectionView: UICollectionView, ofKind kind: String, forIndexPath indexPath: NSIndexPath) -> ReusableType
    
}

extension ReusableCollectionViewSupplementaryView where Self: UICollectionReusableView, ReusableType == Self {
    
    static func registerNib(nib: UINib?, forSupplementaryViewOfKind kind: String, toCollectionView collectionView: UICollectionView) {
        collectionView.registerNib(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: reusableIdentifier)
    }
    
    static func dequeueReusableSupplementaryViewFromCollectionView(collectionView: UICollectionView, ofKind kind: String, forIndexPath indexPath: NSIndexPath) -> ReusableType {
        let supplementaryView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: reusableIdentifier, forIndexPath: indexPath)
        return supplementaryView as! ReusableType
    }
    
}