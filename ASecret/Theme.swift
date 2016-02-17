//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import Foundation
import UIKit
import AuntieKit


struct Theme {
    static let sharedTheme = Theme()
    
    let tintColor = UIColor(hex: 0x737AF5)
    
    let primaryTextColor = UIColor(hex: 0x50525E)
    let secondaryTextColor = UIColor(hex: 0x9598AB)
    
    let primaryBackgroundColor = UIColor.whiteColor()
    let secondaryBackgroundColor = UIColor(hex: 0xFAFDFF)
}


extension Theme {
    
    static func applyTheme(theme: Theme) {
        // Setting Global Tint in the Interface Builder seems like making no difference for the toolbar item's tint color
        // and setting the `UIWindow`'s `tintColor` by using the appearance (not supported in iOS 7, tried in iOS 9) also won't work.
        // For that we have to set app's `window.tintColor` manually. See Using Tint Color: https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/TransitionGuide/AppearanceCustomization.html#//apple_ref/doc/uid/TP40013174-CH15-SW1
        let window = UIApplication.sharedApplication().delegate?.window
        window??.tintColor = theme.tintColor

        let navbar = UINavigationBar.appearance()
        navbar.titleTextAttributes = [NSForegroundColorAttributeName: theme.primaryTextColor]
        
        let placeholderView = PlaceholderView.appearance()
        placeholderView.backgroundColor  = theme.secondaryBackgroundColor
        placeholderView.titleTextColor   = theme.primaryTextColor
        placeholderView.messageTextColor = theme.secondaryTextColor
    }
    
}