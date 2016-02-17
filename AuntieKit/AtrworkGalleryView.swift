//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit



// MARK: - ArtworkGalleryViewDataSourceDelegate

public protocol ArtworkGalleryViewDataSourceDelegate: NSObjectProtocol {
    
    func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, viewAtIndex index: Int) -> UIView
    func numberOfArtworksInArtworkGalleryView(artworkGalleryView: ArtworkGalleryView) -> Int
    
}


// MARK: - ArtworkGalleryViewDelegate

@objc public protocol ArtworkGalleryViewDelegate: NSObjectProtocol {
    
    optional func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, didScrollToIndex index: Int)
    optional func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, singleTapDetectedByRecognizer recognizer: UITapGestureRecognizer, atIndex index: Int)
    optional func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, doubleTapDetectedByRecognizer recognizer: UITapGestureRecognizer, atIndex index: Int)
    
}


// MARK: -

public class ArtworkGalleryView: UIView {
    public let scrollView = UIScrollView()
    public var artworkPageGap: CGFloat = 20
    private var lastTrackedChangingSize = CGSizeZero
    
    
    // MARK: - Initialization
    
    public convenience init() {
        self.init(frame: CGRectZero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    private func initialSetup() {
        lastTrackedChangingSize = bounds.size
        
        // It's IMPORTANT to have `autoresizingMask` set to `.None` 
        // so that we can do the resizing manually in `layoutSubviews`.
        // Otherwise you might get a different behavior for the last page 
        // which autoresizing get applied in its call stack and
        // for other pages autoresizing not get applied while rotating.
        scrollView.autoresizingMask = .None
        scrollView.delegate = self
        scrollView.pagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        setupGesturesInView(self)
    }
    
    
    // MARK: - Handle Tap Gestures
    
    private func setupGesturesInView(view: UIView) {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: "handleSingleTapGesture:")
        singleTapGesture.numberOfTapsRequired = 1
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: "handleDoubleTapGesture:")
        doubleTapGesture.numberOfTapsRequired = 2
        singleTapGesture.requireGestureRecognizerToFail(doubleTapGesture)
        view.addGestureRecognizer(singleTapGesture)
        view.addGestureRecognizer(doubleTapGesture)
        view.userInteractionEnabled = true
    }
    
    
    func handleSingleTapGesture(recognizer: UITapGestureRecognizer) {
        delegate?.artworkGalleryView?(self, singleTapDetectedByRecognizer: recognizer, atIndex: currentArtworkIndex)
    }
    
    func handleDoubleTapGesture(recognizer: UITapGestureRecognizer) {
        delegate?.artworkGalleryView?(self, doubleTapDetectedByRecognizer: recognizer, atIndex: currentArtworkIndex)
    }
    
    
    // MARK: - Creating Reusable Views
    
    private var reuseableViewClass: UIView.Type?
    
    public func registerReuseableViewClass(viewClass: UIView.Type) {
        reuseableViewClass = viewClass
    }
    
    private var preparedViews = Set<UIView>()
    private var reusableViews = Set<UIView>()
    
    public func dequeueReusableView() -> UIView {
        assert(reuseableViewClass != nil, "[\(__FUNCTION__)]: Make sure you have register the reuseable view class first!")
        
        guard let view = reusableViews.popFirst() else {
            return reuseableViewClass!.init()
        }
        return view
    }

    
    // MARK: - Delegate and DataSource
    
    public var delegate: ArtworkGalleryViewDelegate?
    
    public var dataSource: ArtworkGalleryViewDataSourceDelegate? {
        didSet {
            if dataSource !== oldValue {
                self.reloadData()
            }
        }
    }
    
    public var currentArtworkIndex: Int = 0 {
        didSet {
            if currentArtworkIndex != oldValue {
                delegate?.artworkGalleryView?(self, didScrollToIndex: currentArtworkIndex)
            }
        }
    }
    
    private var _numberOfArtworks: Int?
    
    public var numberOfArtworks: Int {
        get {
            guard let numberOfArtworks = _numberOfArtworks else {
                _numberOfArtworks = dataSource?.numberOfArtworksInArtworkGalleryView(self) ?? 0
                return _numberOfArtworks!
            }
            return numberOfArtworks
        }
    }
    
    public func viewAtIndex(index: Int) -> UIView? {
        guard index >= 0 && index < numberOfArtworks else {
            return nil
        }
        for view in preparedViews {
            if index == view.tag {
                return view
            }
        }
        return nil
    }
    
    public func reloadData() {
        _numberOfArtworks = nil
        guard let _ = self.dataSource else {
            return
        }
        resizeScrollView()
        prepareArtworks()
        setNeedsDisplay()
    }
    
    
    // MARK: - Displaying Artwork
    
    public func displayArtworkAtIndex(index: Int) {
        currentArtworkIndex = index
        scrollToArtworkAtIndex(index, animated: false)
    }
    
    public func scrollToArtworkAtIndex(index: Int, animated: Bool) {
        let offset = contentOffsetForArtworkAtIndex(index)
        scrollView.setContentOffset(offset, animated: animated)
    }
    
    
    // MARK: - Prepare Artworks
    
    private func isViewPreparedAtIndex(index: Int) -> Bool {
        for view in preparedViews {
            if index == view.tag {
                return true
            }
        }
        return false
    }
    
    private func prepareArtworks() {
        guard let dataSource = dataSource else {
            return
        }
        
        let visibleBounds = scrollView.bounds
        var firstNeededIndex = Int(floor(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds)))
        var lastNeededIndex  = Int((floor(CGRectGetMaxX(visibleBounds) - 1) / CGRectGetWidth(visibleBounds)))
        firstNeededIndex = max(firstNeededIndex, 0)
        lastNeededIndex  = min(lastNeededIndex, numberOfArtworks - 1)
        
        for view in preparedViews {
            let index = view.tag
            if index < firstNeededIndex || index > lastNeededIndex {
                reusableViews.insert(view)
                view.removeFromSuperview()
            }
        }
        preparedViews.subtractInPlace(reusableViews)
        
        for var index = firstNeededIndex; index <= lastNeededIndex; index++ {
            if !isViewPreparedAtIndex(index) {
                let view = dataSource.artworkGalleryView(self, viewAtIndex: index)
                view.tag = index
                view.frame = frameForArtworkAtIndex(index)
                scrollView.addSubview(view)
                preparedViews.insert(view)
            }
        }
    }
    
    
    // MARK: - Layout Views
    
    private func layoutPreparedViews() {
        for view in preparedViews {
            let index = view.tag
            view.frame = frameForArtworkAtIndex(index)
        }
    }
    
    private func resizeIfNeeded() {
        guard !CGSizeEqualToSize(bounds.size, lastTrackedChangingSize) else { return }
        
        lastTrackedChangingSize = bounds.size
        resizeScrollView()
        layoutPreparedViews()
        let offset = contentOffsetForArtworkAtIndex(currentArtworkIndex)
        scrollView.contentOffset = offset
    }
    
    private var performingLayout = false
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        performingLayout = true
        resizeIfNeeded()
        performingLayout = false
    }
    
}


// MARK: - Frame Calculations

extension ArtworkGalleryView {
    
    private func resizeScrollView() {
        scrollView.frame = frameForScrollView()
        scrollView.contentSize = contentSizeForScrollView()
    }
    
    private func frameForScrollView() -> CGRect {
        var frame = bounds
        frame.size.width += artworkPageGap
        return frame
    }
    
    private func contentSizeForScrollView() -> CGSize {
        let frame = scrollView.bounds
        return CGSizeMake(CGRectGetWidth(frame) * CGFloat(numberOfArtworks), CGRectGetHeight(frame))
    }
    
    private func contentOffsetForArtworkAtIndex(index: Int) -> CGPoint {
        let offset = CGPointMake(CGRectGetWidth(scrollView.bounds) * CGFloat(index), 0)
        return offset
    }
    
    private func frameForArtworkAtIndex(index: Int) -> CGRect {
        let originX = CGFloat(index) * CGRectGetWidth(scrollView.bounds)
        let frame = CGRectMake(originX, 0, CGRectGetWidth(bounds), CGRectGetHeight(bounds))
        return frame
    }
}


// MARK: - UIScrollView Delegate

extension ArtworkGalleryView: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        if !performingLayout {
            prepareArtworks()
        }
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let index = Int(ceil(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds)))
        if index != currentArtworkIndex {
            currentArtworkIndex = index
        }
    }
}
