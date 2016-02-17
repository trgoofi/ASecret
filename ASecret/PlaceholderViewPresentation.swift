//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import AuntieKit


protocol PlaceholderViewPresentation: class {
    
    var placeholderView: PlaceholderView? { get set }
    
    func showPlaceholder(placeholder: Placeholder, inView view: UIView, animated: Bool, completion: ((PlaceholderView) -> Void)?) -> Void
    
    func hidePlaceholderViewAnimated(animated: Bool, completion: ((PlaceholderView?) -> Void)?) -> Void
    
}


extension PlaceholderViewPresentation {

    func showPlaceholder(placeholder: Placeholder, inView view: UIView, animated: Bool, completion: ((PlaceholderView) -> Void)? = nil) {
 
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let oldPlaceholderView = self.placeholderView
            let placeholderView = PlaceholderView(placeholder: placeholder)
            self.placeholderView = placeholderView

            placeholderView.alpha = 0.0
            placeholderView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(placeholderView)
            
            let constraints = [
                NSLayoutConstraint(item: placeholderView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1.0, constant: 0.0),
                NSLayoutConstraint(item: placeholderView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Height, multiplier: 1.0, constant: 0.0)
            ]
            view.addConstraints(constraints)
            
            if animated {
                UIView.animateWithDuration(0.25, animations: { () -> Void in
                    placeholderView.alpha = 1.0
                    oldPlaceholderView?.alpha = 0.0
                }, completion: { (finished) -> Void in
                    oldPlaceholderView?.removeFromSuperview()
                    completion?(placeholderView)
                })
            } else {
                UIView.performWithoutAnimation({ () -> Void in
                    placeholderView.alpha = 1.0
                    oldPlaceholderView?.alpha = 0.0
                    oldPlaceholderView?.removeFromSuperview()
                    completion?(placeholderView)
                })
            }
        }
    }
    
    func hidePlaceholderViewAnimated(animated: Bool, completion: ((PlaceholderView?) -> Void)? = nil) {
        guard let placeholderView = placeholderView else {
            completion?(nil)
            return
        }
        
        if animated {
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                placeholderView.alpha = 0.0
            }, completion: { (finished) -> Void in
                placeholderView.removeFromSuperview()
                if placeholderView === self.placeholderView {
                    self.placeholderView = nil
                }
                completion?(placeholderView)
            })
        } else {
            UIView.performWithoutAnimation({ () -> Void in
                placeholderView.removeFromSuperview()
                self.placeholderView = nil
                completion?(placeholderView)
            })
        }
    }
}
