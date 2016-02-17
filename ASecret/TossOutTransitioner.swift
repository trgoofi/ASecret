//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


class TossOutTransitioner: NSObject, UIViewControllerInteractiveTransitioning, UIViewControllerAnimatedTransitioning {
    
    weak var transitionContext: UIViewControllerContextTransitioning?
    weak var containerView: UIView?
    weak var fromView: UIView?
    weak var transitionToView: UIView?
    
    var isInteractive = false    
    var tossingView: UIView?
    
    var animator: UIDynamicAnimator?
    var originalLocation: CGPoint!
    var initialAnchorPoint: CGPoint!
    var attachmentBehavior: UIAttachmentBehavior?
    
    
    func prepareViewsForTransition(transitionContext: UIViewControllerContextTransitioning) {
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! ArtworkGalleryViewController
        let containerView = transitionContext.containerView()!
        
        fromVC.setNeedsStatusBarAppearanceUpdate()
        let transitionFromView = fromVC.transitionFromView
        let rect = CGRectIntegral(containerView.convertRect(transitionFromView.bounds, fromView: transitionFromView))
        
        let tossingView: UIView
        if isInteractive {
            tossingView = containerView.resizableSnapshotViewFromRect(rect, afterScreenUpdates: true, withCapInsets: UIEdgeInsetsZero)
        } else {
            let image: UIImage
            if let imageView = transitionFromView as? UIImageView {
                image = imageView.image!
            } else {
                UIGraphicsBeginImageContextWithOptions(transitionFromView.bounds.size, true, 0.0);
                transitionFromView.drawViewHierarchyInRect(transitionFromView.bounds, afterScreenUpdates: true)
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            
            let imageView = UIImageView(image: image)
            tossingView = imageView
            tossingView.clipsToBounds = true
            tossingView.contentMode = .ScaleAspectFill
        }
        tossingView.frame = rect
        containerView.addSubview(tossingView)
        
        fromView = transitionContext.viewForKey(UITransitionContextFromViewKey)
        fromView?.hidden = true
        
        self.transitionToView = fromVC.transitionToView
        self.transitionToView?.hidden = true
        
        self.containerView = containerView
        self.tossingView = tossingView
        self.transitionContext = transitionContext
    }
    
    func finalizeTransition() {
        animator?.removeAllBehaviors()
        
        let cancelled = transitionContext!.transitionWasCancelled()
        if cancelled {
            fromView?.hidden = false
        } else {
            fromView?.removeFromSuperview()
        }
        transitionToView?.hidden = false
        tossingView?.removeFromSuperview()
        
        transitionContext!.completeTransition(!cancelled)
        containerView?.userInteractionEnabled = true
        
        isInteractive = false
        animator = nil
        attachmentBehavior = nil
        
        transitionToView = nil
        fromView = nil
        tossingView = nil
        containerView = nil
        transitionContext = nil
    }

    
    func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {
        prepareViewsForTransition(transitionContext)
        guard isInteractive else {
            transitionContext.finishInteractiveTransition()
            animateTransition(transitionContext)
            return
        }
        
        guard let containerView = self.containerView else { return }
        guard let tossingView = self.tossingView  else { return }
        
        originalLocation = tossingView.center
        
        let touchPoint = containerView.convertPoint(initialAnchorPoint, toView: tossingView)
        // The offset value for attchment behavior to setup the attach point to match the touch point as attach point is relative to the item's center
        let offset = tossingView.offsetFromCenterForPoint(touchPoint)
        attachmentBehavior = UIAttachmentBehavior(item: tossingView, offsetFromCenter: offset, attachedToAnchor: initialAnchorPoint)
        
        animator = UIDynamicAnimator(referenceView: containerView)
        animator?.addBehavior(attachmentBehavior!)
        
        UIView.animateWithDuration(0.2) { () -> Void in
            let color = containerView.backgroundColor?.colorWithAlphaComponent(0.5)
            containerView.backgroundColor = color
        }
    }
    
    func cancelInteractiveTransition() {
        guard let tossingView = self.tossingView else { return }
        containerView?.userInteractionEnabled = false
        
        let originalLocation = self.originalLocation
        var previousLocation = tossingView.center
        let snapBehavior = UISnapBehavior(item: tossingView, snapToPoint: originalLocation)
        snapBehavior.action = { [unowned self] in
            let currentLocation = tossingView.center
            if currentLocation.equalTo(originalLocation, epsilon: 0.01)
                && currentLocation.equalTo(previousLocation, epsilon: 0.01) {
                self.finalizeTransition()
            } else {
                previousLocation = currentLocation
            }
        }
        animator?.addBehavior(snapBehavior)
        transitionContext?.cancelInteractiveTransition()
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            let color = self.containerView?.backgroundColor?.colorWithAlphaComponent(1.0)
            self.containerView?.backgroundColor = color
        })
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            isInteractive = true
            initialAnchorPoint = gesture.locationInView(containerView)

        case .Changed:
            let anchorPoint = gesture.locationInView(containerView)
            attachmentBehavior?.anchorPoint = anchorPoint
            
        case .Cancelled:
            cancelInteractiveTransition()
            
        case .Ended:
            animator?.removeAllBehaviors()
            let minmumVelocityRequired: CGFloat = 1000
            let velocity = gesture.velocityInView(containerView)
            
            guard velocity.magnitude > minmumVelocityRequired else {
                cancelInteractiveTransition()
                return
            }
            
            guard let tossingView = self.tossingView else { return }
            self.containerView?.userInteractionEnabled = false
            
            let pushBehavior = UIPushBehavior(items: [tossingView], mode: .Instantaneous)
            let velocityFactor: CGFloat = 6.5
            let pushDirection = CGVectorMake(velocity.x / velocityFactor, velocity.y / velocityFactor)
            pushBehavior.pushDirection = pushDirection
            pushBehavior.action = { [unowned self] in
                if !CGRectIntersectsRect(tossingView.frame, self.containerView!.frame) {
                    self.animator?.removeAllBehaviors()
                    self.transitionToView?.transform = CGAffineTransformMakeScale(0.0, 0.0)
                    UIView.animateWithDuration(0.3, delay: 0.1, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                        self.containerView?.backgroundColor = UIColor.clearColor()
                        self.transitionToView?.hidden = false
                        self.transitionToView?.transform = CGAffineTransformIdentity
                    }, completion: { _ in
                        self.finalizeTransition()
                    })
                }
            }
            
            let angularVelocity = calculateAngularVelocityFromGesture(gesture)
            let itemBehavior = UIDynamicItemBehavior(items: [tossingView])
            itemBehavior.addAngularVelocity(angularVelocity, forItem: tossingView)
            
            animator?.addBehavior(itemBehavior)
            animator?.addBehavior(pushBehavior)
            transitionContext?.finishInteractiveTransition()
        default: ()
        }
        
    }
    
    func calculateAngularVelocityFromGesture(gesture: UIPanGestureRecognizer) -> CGFloat {
        let tossingView = self.tossingView!
        
        let velocity = gesture.velocityInView(containerView)
        let velocityMagnitude = velocity.magnitude
        
        let touchPoint = gesture.locationInView(tossingView)
        let offset = tossingView.offsetFromCenterForPoint(touchPoint)
        let offsetMagnitude = offset.magnitude
        
        // Angle between two vector formula: A⋅B = |A||B|cos(𝜃)
        // See: https://en.wikipedia.org/wiki/Dot_product
        let cosineTheta = (velocity.x * offset.horizontal + velocity.y * offset.vertical) / (velocityMagnitude * offsetMagnitude)
        let theta = acos(cosineTheta)
        // Angular velocity formula: 𝜔|r| = |v|sin(𝜃)
        // See: https://en.wikipedia.org/wiki/Angular_velocity
        var angularVelocity = velocityMagnitude * sin(theta) / offsetMagnitude
        
        // The further away the center we impulse the larger angular velocity we should get for that we use `angularRation` to simulate that.
        let angularRatio: CGFloat
        let size = tossingView.bounds.size
        let viewMagnitude = sqrt(size.width * size.width + size.height * size.height)
        angularRatio = offsetMagnitude / viewMagnitude
        angularVelocity *= angularRatio
        
        // Rotation direction for angular velocity: positive = clockwise, negative = counter-clockwise.
        // Push down in the right side of the view its rotation direction is clockwise and up is counter-clockwise. Reverse for the left side.
        let rotationDirection: CGFloat = (velocity.y * offset.horizontal) > 0 ? 1.0 : -1.0
        angularVelocity *= rotationDirection
        
        return angularVelocity
    }
    
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return 0.3
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        guard !isInteractive else { return }
        
        guard let containerView = self.containerView else { return }
        guard let zoomToView = transitionToView else { return }
        guard let zoomingView = tossingView else { return }
        
        let zoomToRect = containerView.convertRect(zoomToView.bounds, fromView: zoomToView)
        
        let duration = transitionDuration(transitionContext)
        UIView.animateWithDuration(duration, delay: 0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
            zoomingView.frame = zoomToRect
            containerView.backgroundColor = UIColor.clearColor()
        }) { _ in
            self.finalizeTransition()
        }
    }
    
}



extension CGPoint {
    var magnitude: CGFloat {
        let magnitude = sqrt(x * x + y * y)
        return magnitude
    }
    
    func equalTo(point: CGPoint, epsilon: CGFloat) -> Bool {
        return (fabs(x - point.x) < epsilon) && (fabs(y - point.y) < epsilon)
    }
}

extension UIOffset {
    var magnitude: CGFloat {
        let magnitude = sqrt(horizontal * horizontal + vertical * vertical)
        return magnitude
    }
}

extension UIDynamicItem {
    func offsetFromCenterForPoint(point: CGPoint) -> UIOffset {
        let offset = UIOffset(horizontal: point.x - bounds.midX, vertical: point.y - bounds.midY)
        return offset
    }
}
