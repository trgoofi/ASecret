//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


@objc protocol ZoomInTossOutPresentationControllerDelegate: NSObjectProtocol {
    
    optional func tossOutDismissalGestureShouldBegin() -> Bool
    
}


class ZoomInTossOutPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
    
    var interactionDismissalAnimator = TossOutTransitioner()
    
    override init(presentedViewController: UIViewController, presentingViewController: UIViewController) {
        super.init(presentedViewController: presentedViewController, presentingViewController: presentingViewController)
    }
    
    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        
        guard let containerView = containerView else { return }
        let pan = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        pan.addTarget(interactionDismissalAnimator, action: "handlePanGesture:")
        pan.delegate = self
        containerView.addGestureRecognizer(pan)
    }
    
    func handlePanGesture(gesture: UIPanGestureRecognizer) {
        if gesture.state == .Began {
            presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let delegate = presentedViewController as? ZoomInTossOutPresentationControllerDelegate else { return true }
        guard let shouldBegin =  delegate.tossOutDismissalGestureShouldBegin?() else { return true }
        return shouldBegin
    }
    
}



class ZoomInTossOutTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    var presentationController: ZoomInTossOutPresentationController?
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        let controller = ZoomInTossOutPresentationController(presentedViewController: presented, presentingViewController: presenting)
        presentationController = controller
        return controller
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transition = ZoomInTransitioner()
        return transition
    }
    
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentationController?.interactionDismissalAnimator
    }
    
    func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return presentationController?.interactionDismissalAnimator
    }
    
}

