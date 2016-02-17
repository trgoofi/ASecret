//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


public struct Placeholder {
    let title: String?
    let message: String?
    let image: UIImage?

    
    public init(title: String? = nil, message: String? = nil, image: UIImage? = nil) {
        self.title = title
        self.message = message
        self.image = image
    }
}


// MARK: -

public class PlaceholderView: UIView {
    
    public let contentView = UIView()
    public let imageView = UIImageView()
    public let titleLabel = UILabel()
    public let messageLable = UILabel()
    var placeholder: Placeholder
    
    
    // MARK: - Initialization

    public init(placeholder: Placeholder) {
        self.placeholder = placeholder
        super.init(frame: CGRectZero)
        initialSetup()
        updateViewsWithPlaceholder(placeholder)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initialSetup() {
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .Center
        titleLabel.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        messageLable.numberOfLines = 0
        messageLable.textAlignment = .Center
        messageLable.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
        messageLable.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(contentView)
        let options = NSLayoutFormatOptions(rawValue: 0)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: contentView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: contentView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0))
        constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|-30-[contentView]-30-|", options: options, metrics: nil, views: ["contentView": contentView]))
        addConstraints(constraints)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "textSizeDidChange", name: UIContentSizeCategoryDidChangeNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    // MARK: - Update Views and Constraints
    
    func textSizeDidChange() {
        titleLabel.invalidateDynamicTypeTextIfAppropriate()
        messageLable.invalidateDynamicTypeTextIfAppropriate()
    }
    
    
    private func updateViewsWithPlaceholder(placeholder: Placeholder) {
        
        imageView.removeFromSuperview()
        titleLabel.removeFromSuperview()
        messageLable.removeFromSuperview()
        
        if let image = placeholder.image {
            imageView.image = image
            contentView.addSubview(imageView)
        }
        
        if let title = placeholder.title {
            titleLabel.text = title
            contentView.addSubview(titleLabel)
        }
        
        if let message = placeholder.message {
            messageLable.text = message
            contentView.addSubview(messageLable)
        }
        
        setNeedsUpdateConstraints()
    }
    
    public override func updateConstraints() {
        var constraints = [NSLayoutConstraint]()
        let views = ["imageView": imageView, "titleLabel": titleLabel, "messageLable": messageLable]
        var lastView = contentView
        var lastAttribute = NSLayoutAttribute.Top
        var constant: CGFloat = 0
        let options = NSLayoutFormatOptions(rawValue: 0)
        
        if let _ = imageView.superview {
            constraints.append(NSLayoutConstraint(item: imageView, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0))
            constraints.append(NSLayoutConstraint(item: imageView, attribute: .Top, relatedBy: .Equal, toItem: contentView, attribute: .Top, multiplier: 1, constant: 0))
            constant = 25
            lastView = imageView
            lastAttribute = .Bottom
        }
        
        if let _ = titleLabel.superview {
            constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLabel]|", options: options, metrics: nil, views: views))
            constraints.append(NSLayoutConstraint(item: titleLabel, attribute: .Top, relatedBy: .Equal, toItem: lastView, attribute: lastAttribute, multiplier: 1, constant: constant))
            constant = 15
            lastView = titleLabel
            lastAttribute = .Baseline
        }
        
        if let _ = messageLable.superview {
            constraints.appendContentsOf(NSLayoutConstraint.constraintsWithVisualFormat("H:|[messageLable]|", options: options, metrics: nil, views: views))
            constraints.append(NSLayoutConstraint(item: messageLable, attribute: .Top, relatedBy: .Equal, toItem: lastView, attribute: lastAttribute, multiplier: 1, constant: constant))
            constant = 15
            lastView = messageLable
            lastAttribute = .Baseline
        }
        
        constraints.append(NSLayoutConstraint(item: lastView, attribute: .Bottom, relatedBy: .Equal, toItem: contentView, attribute: .Bottom, multiplier: 1.0, constant: 0))
        contentView.addConstraints(constraints)
        
        super.updateConstraints()
    }
    
}


// MARK: - UIAppearance

extension PlaceholderView {
    
    dynamic public var titleTextColor: UIColor {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }
    
    dynamic public var titleFont: UIFont {
        get { return titleLabel.font }
        set { titleLabel.font = newValue }
    }
    
    dynamic public var messageTextColor: UIColor {
        get { return messageLable.textColor }
        set { messageLable.textColor = newValue }
    }
    
    dynamic public var messageFont: UIFont {
        get { return messageLable.font }
        set { messageLable.font = newValue }
    }
    
}
