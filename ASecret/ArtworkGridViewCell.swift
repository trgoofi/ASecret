//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import Photos
import Haneke


class ArtworkGridViewCell: UICollectionViewCell  {
    var identifier: String?
    var imageView = UIImageView()

    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    private func initialSetup() {
        imageView.frame = contentView.bounds
        imageView.clipsToBounds = true
        imageView.contentMode = .ScaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        let views = ["imageView": imageView]
        let options = NSLayoutFormatOptions(rawValue: 0)
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: options, metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: options, metrics: nil, views: views))

        setNeedsUpdateConstraints()
    }
    
    // MARK: - Prepare Reuse
    
    override func prepareForReuse() {
        imageView.image = nil
        super.prepareForReuse()
    }
    
    
    // MARK: - Cell Highlighting
    
    override var highlighted: Bool {
        didSet {
            toggleHighlight()
        }
    }
    
    /// Only one cell can be highlighted at a time so we make it `static`
    static let highlightedView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0, alpha: 0.4)
        return view
    }()
    
    func toggleHighlight() {
        let highlightedView = ArtworkGridViewCell.highlightedView
        if highlighted {
            highlightedView.frame = contentView.bounds
            contentView.addSubview(highlightedView)
        } else {
            highlightedView.removeFromSuperview()
        }
    }

    
    // MARK: - Cell Selection
    
    class SelectedView: UIView {
        let imageView = UIImageView(image: UIImage(named: "artwork-selected"))
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(imageView)
            backgroundColor = UIColor(white: 1.0, alpha: 0.25)
            imageView.translatesAutoresizingMaskIntoConstraints = false
            let constraints = [
                NSLayoutConstraint(item: imageView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: imageView, attribute: .Trailing, relatedBy: .Equal, toItem: self, attribute: .Trailing, multiplier: 1.0, constant: 0.0)
            ]
            addConstraints(constraints)
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    lazy var selectedView: SelectedView = {
        return SelectedView()
    }()
    
    func showSelectedViewIfNeeded() {
        if selected {
            showSelectedView()
        } else {
            hideSelectedView()
        }
    }
    
    func hideSelectedView() {
        selectedView.removeFromSuperview()
    }
    
    func showSelectedView(animated animated: Bool = false) {
        selectedView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["selectedView": selectedView]
        let options = NSLayoutFormatOptions(rawValue: 0)
        contentView.addSubview(selectedView)
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[selectedView]|", options: options, metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[selectedView]|", options: options, metrics: nil, views: views))
        if animated {
            selectedView.imageView.transform = CGAffineTransformMakeScale(0.6, 0.6)
            let options = UIViewAnimationOptions.CurveEaseInOut
            UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0, options: options, animations: { () -> Void in
                self.selectedView.imageView.transform = CGAffineTransformIdentity
            }, completion: nil)
        }
    }
    
}


extension ArtworkGridViewCell: ReusableCollectionViewCell {
    
    typealias ReusableType = ArtworkGridViewCell

    class var reusableIdentifier: String {
        return "ArtworkGridViewCell"
    }
    
}


extension ArtworkGridViewCell {
    
    func configureViewWithArtwork(artwork: Artwork) {
        imageView.cancelSetImage()
        imageView.setImageFormURL(artwork.URL())
    }
    
}
