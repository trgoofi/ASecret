//
//  Created by trgoofi.
//  Copyright © 2015 trgoofi. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import CoreData
import AuntieKit


@objc protocol ArtworkGalleryViewControllerDelegate: NSObjectProtocol {
    
    optional func artworkGalleryViewController(controller: ArtworkGalleryViewController, willDismissAtIndexPath indexPath: NSIndexPath) -> Void
    optional func viewForDismissToAtIndexPath(indexPath: NSIndexPath, artworkGalleryViewController: ArtworkGalleryViewController) -> UIView?
    
}


class ArtworkGalleryViewController: UIViewController, ZoomInTossOutPresentationControllerDelegate {
    
    weak var delegate: ArtworkGalleryViewControllerDelegate?
    
    var resultsFetcher: NSFetchedResultsController? {
        didSet {
            refreshFlatIndexMappings()
        }
    }
    var showArtworkAtIndexPath: NSIndexPath?
    
    var transitionFormImageView: UIImageView?
    var transitionToImageView:   UIImageView?
    
    var transitionFromView: UIView {
        let artworkView = currentArtworkView!
        return artworkView.zoomingView
    }
    
    var transitionToView: UIView? {
        let indexPath = indexPathForFlatIndex(artworkGalleryView.currentArtworkIndex)
        let view = delegate?.viewForDismissToAtIndexPath?(indexPath, artworkGalleryViewController: self)
        return view
    }
    
    func tossOutDismissalGestureShouldBegin() -> Bool {
        guard let artworkView = currentArtworkView else { return true }
        guard artworkView.zoomScale == artworkView.minimumZoomScale else { return false }
        return true
    }
    
    
    private var currentArtworkView: ArtworkView? {
        let index = artworkGalleryView.currentArtworkIndex
        let artworkView = artworkGalleryView.viewAtIndex(index) as? ArtworkView
        return artworkView
    }

    @IBOutlet var artworkGalleryView: ArtworkGalleryView!
    
    private var statusBarHidden = true
    override func prefersStatusBarHidden() -> Bool {
        return statusBarHidden
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        artworkGalleryView.registerReuseableViewClass(ArtworkView.self)
        artworkGalleryView.delegate = self
        artworkGalleryView.dataSource = self
        guard let indexPath = showArtworkAtIndexPath else { return }
        let index = flatIndexForIndexPath(indexPath)
        artworkGalleryView.displayArtworkAtIndex(index)
        
        let artworkView = artworkGalleryView.viewAtIndex(index) as? ArtworkView
        transitionToImageView = artworkView!.zoomingView
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        statusBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        statusBarHidden = false
        setNeedsStatusBarAppearanceUpdate()
        
        if isBeingDismissed() {
            let indexPath = indexPathForFlatIndex(artworkGalleryView.currentArtworkIndex)
            delegate?.artworkGalleryViewController?(self, willDismissAtIndexPath: indexPath)
        }
    }
    
    
    // MARK: - Flat IndexPath
    
    private var _flatIndexMappingIndexPath = [NSIndexPath]()
    private var _indexPathMappinpFlatIndex = [NSIndexPath: Int]()
    
    func refreshFlatIndexMappings() {
        guard let sectionInfo = self.resultsFetcher?.sections else {
            return
        }
        
        var flatIndex = 0
        var indexPaths = [NSIndexPath]()
        var indexMapping = [NSIndexPath: Int]()
        let sections = sectionInfo.count
        for section in 0 ..< sections {
            let items = sectionInfo[section].numberOfObjects
            for item in 0 ..< items {
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                indexPaths.append(indexPath)
                indexMapping[indexPath] = flatIndex
                ++flatIndex
            }
        }
        _flatIndexMappingIndexPath = indexPaths
        _indexPathMappinpFlatIndex = indexMapping
    }
    
    func flatIndexForIndexPath(indexPath: NSIndexPath) -> Int {
        return _indexPathMappinpFlatIndex[indexPath]!
    }
    
    func indexPathForFlatIndex(index: Int) -> NSIndexPath {
        return _flatIndexMappingIndexPath[index]
    }


}


// MARK: - Artwork Gallery DataSource

extension ArtworkGalleryViewController: ArtworkGalleryViewDataSourceDelegate {
    
    
    func numberOfArtworksInArtworkGalleryView(artworkGalleryView: ArtworkGalleryView) -> Int {
        return _flatIndexMappingIndexPath.count
    }
    
    func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, viewAtIndex index: Int) -> UIView {
        let artworkView = artworkGalleryView.dequeueReusableView() as! ArtworkView
        artworkView.prepareForReuse()
        artworkView.supplementaryView?.removeFromSuperview()
        
        let artwork = artworkAtIndex(index)
        if artwork.mediaType == .Video {
            artworkView.zoomingEnabled = false
            VideoCoverFetcher.fetch(URL: artwork.URL(), success: { (image) -> () in
                artworkView.displayImage(image)
            })
            assemblePlayActionToArtworkView(artworkView)
        } else {
            let image = UIImage(contentsOfFile: artwork.URL().path!)!
            artworkView.displayImage(image)
        }
        
        return artworkView
    }
    
    func artworkAtIndex(index: Int) -> Artwork {
        let indexPath = indexPathForFlatIndex(index)
        let artwork = resultsFetcher!.objectAtIndexPath(indexPath) as! Artwork
        return artwork
    }
    
    func playArtwork(sender: UIButton) {
        let index = artworkGalleryView.currentArtworkIndex
        let artwork = artworkAtIndex(index)
        let player = AVPlayer(URL: artwork.URL())
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        presentViewController(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }
    
    private func assemblePlayActionToArtworkView(artworkView: ArtworkView) {
        let playButton = UIButton(type: .Custom)
        let image = UIImage(named: "play-button")
        playButton.setImage(image, forState: .Normal)
        playButton.addTarget(self, action: "playArtwork:", forControlEvents: .TouchUpInside)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        artworkView.supplementaryView = playButton
        artworkView.addSubview(playButton)
        let constranints = [
            NSLayoutConstraint(item: playButton, attribute: .CenterX, relatedBy: .Equal, toItem: artworkView, attribute: .CenterX, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: playButton, attribute: .CenterY, relatedBy: .Equal, toItem: artworkView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        ]
        artworkView.addConstraints(constranints)
    }
}


// MARK: - Artwork Gallery Delegate

extension ArtworkGalleryViewController: ArtworkGalleryViewDelegate {
    
    func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, singleTapDetectedByRecognizer recognizer: UITapGestureRecognizer, atIndex index: Int) {
        let artworkView = artworkGalleryView.viewAtIndex(index) as! ArtworkView
        artworkView.zoomOutToOriginal { (artworkView, zoomingView, scale) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func artworkGalleryView(artworkGalleryView: ArtworkGalleryView, doubleTapDetectedByRecognizer recognizer: UITapGestureRecognizer, atIndex index: Int) {
        let artworkView = artworkGalleryView.viewAtIndex(index) as! ArtworkView
        let touchPoint = recognizer.locationInView(artworkView.zoomingView)
        if artworkView.zoomingView.pointInside(touchPoint, withEvent: nil) {
            artworkView.zoomInOrOutAtPoint(touchPoint, completion: nil)
        }
    }
    
}
