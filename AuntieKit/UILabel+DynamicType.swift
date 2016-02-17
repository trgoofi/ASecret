//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


extension UILabel {
    
    public func invalidateDynamicTypeTextIfAppropriate() {
        guard let style = font.fontDescriptor().objectForKey(UIFontDescriptorTextStyleAttribute) as? String else { return }
        var styles: Set<String> = [
            UIFontTextStyleHeadline,
            UIFontTextStyleSubheadline,
            UIFontTextStyleBody,
            UIFontTextStyleFootnote,
            UIFontTextStyleCaption1,
            UIFontTextStyleCaption2
        ]
        if #available(iOS 9.0, *) {
            styles.insert(UIFontTextStyleTitle1)
            styles.insert(UIFontTextStyleTitle2)
            styles.insert(UIFontTextStyleTitle3)
            styles.insert(UIFontTextStyleCallout)
        }
        if styles.contains(style) {
            font = UIFont.preferredFontForTextStyle(style)
            invalidateIntrinsicContentSize()
        }
    }
    
}
