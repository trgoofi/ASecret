//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


class VideoArtworkGridViewCell: ArtworkGridViewCell {
    let videoMarkView = UIView()
    let videoMarkImageView = UIImageView(image: UIImage(named: "video-mark"))
    let durationLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    
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
        videoMarkView.translatesAutoresizingMaskIntoConstraints = false
        gradientLayer.colors = [UIColor(white: 0, alpha: 0.6).CGColor, UIColor(white: 0.0, alpha: 0.0).CGColor]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.0)
        videoMarkView.layer.addSublayer(gradientLayer)
        
        videoMarkImageView.contentMode = .Center
        videoMarkImageView.translatesAutoresizingMaskIntoConstraints = false
        videoMarkView.addSubview(videoMarkImageView)
        
        durationLabel.textAlignment = .Right
        durationLabel.textColor = UIColor.whiteColor()
        durationLabel.font = UIFont.systemFontOfSize(11.0)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        videoMarkView.addSubview(durationLabel)
        
        contentView.addSubview(videoMarkView)
        
        let views = ["videoMarkView": videoMarkView, "videoMarkImageView": videoMarkImageView, "durationLabel": durationLabel]
        let options = NSLayoutFormatOptions(rawValue: 0)
        var constraints = [NSLayoutConstraint]()
        
        videoMarkImageView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
        constraints.append(NSLayoutConstraint(item: videoMarkImageView, attribute: .Bottom, relatedBy: .Equal, toItem: videoMarkView, attribute: .Bottom, multiplier: 1.0, constant: -4))
        constraints.append(NSLayoutConstraint(item: durationLabel, attribute: .CenterY, relatedBy: .Equal, toItem: videoMarkImageView, attribute: .CenterY, multiplier: 1.0, constant: 0))
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|-(4)-[videoMarkImageView]-[durationLabel]-(4)-|", options: options, metrics: nil, views: views))
        videoMarkView.addConstraints(constraints)
        
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[videoMarkView]|", options: options, metrics: nil, views: views))
        contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[videoMarkView(20)]|", options: [.AlignAllBottom], metrics: nil, views: views))

        setNeedsUpdateConstraints()
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = videoMarkView.bounds
    }
}


extension VideoArtworkGridViewCell {
    
    typealias ReusableType = VideoArtworkGridViewCell
    
    override class var reusableIdentifier: String {
        return "VideoArtworkGridViewCell"
    }
    
}


extension VideoArtworkGridViewCell {
    
    @nonobjc static let durationFormatter: NSDateComponentsFormatter = {
        let formatter = NSDateComponentsFormatter()
        formatter.zeroFormattingBehavior = .Pad
        formatter.allowedUnits = [.Minute, .Second]
        return formatter
    }()
    
    func configureDurationLabelWithDuration(duration: NSTimeInterval) {
        durationLabel.text = VideoArtworkGridViewCell.durationFormatter.stringFromTimeInterval(duration)
    }
    
    override func configureViewWithArtwork(artwork: Artwork) {
        imageView.cancelSetImage()
        imageView.setImageFormVideoURL(artwork.URL())
        configureDurationLabelWithDuration(artwork.duration)
    }
}
