//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


class ZoomInTransitioner: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.43
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! ArtworkGalleryViewController
        
        guard let zoomFromView = toViewController.transitionFormImageView else { return }
        guard let zoomToView = toViewController.transitionToImageView else { return }
        
        let toView = transitionContext.viewForKey(UITransitionContextToViewKey)!
        let containerView = transitionContext.containerView()!
        containerView.backgroundColor = UIColor(white: 0, alpha: 1)
        
        toView.hidden = true
        containerView.addSubview(toView)
        
        let image = zoomToView.image ?? zoomFromView.image!
        let zoomFromRect = containerView.convertRect(zoomFromView.bounds, fromView: zoomFromView)
        
        let zoomingView = UIImageView(image: image)
        zoomingView.frame = zoomFromRect
        zoomingView.clipsToBounds = true
        zoomingView.contentMode = .ScaleAspectFill
        containerView.addSubview(zoomingView)
        
        let sourceSize = image.size
        let targetSize = containerView.bounds.size
        
        let xScale = targetSize.width  / sourceSize.width
        let yScale = targetSize.height / sourceSize.height
        let scale = min(xScale, yScale)
        
        let width  = sourceSize.width  * scale
        let height = sourceSize.height * scale
        let center = containerView.center
        let x = center.x - (width  / 2)
        let y = center.y - (height / 2)
        let zoomToRect = CGRectMake(x, y, width, height)
        
        let duration = transitionDuration(transitionContext)
        let options = UIViewAnimationOptions.CurveEaseInOut
        UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 0.73, initialSpringVelocity: 0, options: options, animations: {
            zoomingView.frame = zoomToRect
        }) { _ in
            toView.hidden = false
            zoomingView.removeFromSuperview()
            transitionContext.completeTransition(true)
        }
    }
    
}
