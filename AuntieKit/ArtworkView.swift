//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit


public class ArtworkView: UIScrollView {
    public let zoomingView = UIImageView()
    public weak var supplementaryView: UIView?
    public var zoomingEnabled = true
    var zoomingFactor = (UIScreen.mainScreen().scale + 0.4)
    var zoomingContentPixelSize = CGSizeZero
    private var lastTrackedChangingSize = CGSizeZero
    
    // MARK: - Initialization
    
    convenience public init() {
        self.init(frame: CGRectZero)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialSetup()
    }
    
    private func initialSetup() {
        lastTrackedChangingSize = frame.size
        delegate = self
        bouncesZoom = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        zoomingView.autoresizingMask = .None
        addSubview(zoomingView)
    }
    
    private func resetZoomScales() {
        minimumZoomScale = 1.0
        maximumZoomScale = 1.0
        zoomScale = 1.0
    }
    
    public func prepareForReuse() {
        zoomingView.image = nil
        resetZoomScales()
        zoomingEnabled = true
    }
    
    
    // MARK: - Display Artwort
    
    public func displayImage(image: UIImage?) {
        guard let image = image else { return }
        
        // reset zoom scales before setting a new frame for zoomingView
        // otherwise we might get a wrong frame affected by the staled zoom scale.
        resetZoomScales()
        let zoomingRect = CGRectMake(0, 0, image.size.width, image.size.height)
        zoomingView.frame = zoomingRect
        zoomingView.image = image
        
        zoomingContentPixelSize = image.size
        contentSize = image.size
        
        reconfigureZooming()
    }
    
    
    // MARK: - Zooming
    
    public typealias ArtworkViewZoomCompletionHandler = (artworkView: ArtworkView, zoomingView: UIView?, scale: CGFloat) -> Void
    
    private var zoomCompletionHandler: ArtworkViewZoomCompletionHandler?
    
    public func zoomOutToOriginal(animated: Bool = true, completion: ArtworkViewZoomCompletionHandler?) {
        guard zoomScale != minimumZoomScale && zoomingEnabled else {
            completion?(artworkView: self, zoomingView: zoomingView, scale: zoomScale)
            return
        }
        zoomCompletionHandler = completion
        setZoomScale(minimumZoomScale, animated: animated)
    }
    
    public func zoomInOrOutAtPoint(point: CGPoint, animated: Bool = true, completion: ArtworkViewZoomCompletionHandler?) {
        guard zoomingEnabled else {
            completion?(artworkView: self, zoomingView: zoomingView, scale: zoomScale)
            return
        }
        zoomCompletionHandler = completion
        if zoomScale == minimumZoomScale {
            let boundsSize = bounds.size
            let newZoomScale = zoomScale * zoomingFactor
            let width = boundsSize.width / newZoomScale
            let height = boundsSize.height / newZoomScale
            let x = point.x - (width / 2)
            let y = point.y - (height / 2)
            let zoomRect = CGRectMake(x, y, width, height)
            zoomToRect(zoomRect, animated: animated)
        } else {
            setZoomScale(minimumZoomScale, animated: animated)
        }
    }
    
    private func configureZoomScaleLimit() {
        let targetSize = bounds.size
        let pixelSize = zoomingContentPixelSize
        guard !CGSizeEqualToSize(pixelSize, CGSizeZero) && !CGSizeEqualToSize(targetSize, CGSizeZero) else {
            return
        }
        
        let xScale = targetSize.width  / pixelSize.width
        let yScale = targetSize.height / pixelSize.height
        let minScale = min(xScale, yScale)  // use the smaller one so that we can see the whole picture
        
        let maxImageScale = minScale * zoomingFactor
        let maxScreenScale  = 1.0 / UIScreen.mainScreen().scale
        // maxImageScale could be larger than the maxScreenScale if the image is smaller than the targetSize
        // we want to zoom the small image as well so we choose the larger scale as the maximumZoomScale
        let maxScale = max(maxImageScale, maxScreenScale)
        
        minimumZoomScale = minScale
        maximumZoomScale = maxScale
    }
    
    private func reconfigureZooming() {
        configureZoomScaleLimit()
        zoomScale = minimumZoomScale
        if !zoomingEnabled {
            minimumZoomScale = zoomScale
            maximumZoomScale = zoomScale
        }
        centerZoomingView()
    }
    
    private func reconfigureZoomingIfSizeChanged() {
        if !CGSizeEqualToSize(bounds.size, lastTrackedChangingSize) {
            lastTrackedChangingSize = bounds.size
            reconfigureZooming()
        }
    }
    
    
    // MARK: - Layout Views
    
    private func centerZoomingView() {
        let boundsSize = bounds.size
        var centerFrame = zoomingView.frame
        let width = CGRectGetWidth(centerFrame)
        let height = CGRectGetHeight(centerFrame)
        centerFrame.origin.x = width  < boundsSize.width  ? ((boundsSize.width  - width)  / 2.0) : 0
        centerFrame.origin.y = height < boundsSize.height ? ((boundsSize.height - height) / 2.0) : 0
        zoomingView.frame = centerFrame
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        reconfigureZoomingIfSizeChanged()
    }
    
}


// MARK: - UIScrollView Delegate

extension ArtworkView: UIScrollViewDelegate {
    
    public func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return zoomingView
    }
    
    public func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
        guard let handler = zoomCompletionHandler else { return }
        zoomCompletionHandler = nil
        handler(artworkView: self, zoomingView: view, scale: scale)
    }
    
    public func scrollViewDidZoom(scrollView: UIScrollView) {
        // jumpping issue while zooming since ios 8.
        // see http://stackoverflow.com/questions/25852883/uiscrollview-zoom-out-issue-ios-8-gm/26091731
        centerZoomingView()
    }
}