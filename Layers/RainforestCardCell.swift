//
//  RainforestCardCell.swift
//  Layers
//
//  Created by René Cacheaux on 9/1/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import UIKit

class RainforestCardCell: UICollectionViewCell {
  var featureImageSizeOptional: CGSize?
  var placeholderLayer: CALayer!
  var contentLayer: CALayer?
  var containerNode: ASDisplayNode?
  var nodeConstructionOperation: NSOperation?

  override func awakeFromNib() {
    super.awakeFromNib()

    placeholderLayer = CALayer()
    placeholderLayer.contents = UIImage(named: "cardPlaceholder")!.CGImage
    placeholderLayer.contentsGravity = kCAGravityCenter
    placeholderLayer.contentsScale = UIScreen.mainScreen().scale
    placeholderLayer.backgroundColor = UIColor(hue: 0, saturation: 0, brightness: 0.85, alpha: 1).CGColor
    contentView.layer.addSublayer(placeholderLayer)
  }

  //MARK: Layout
  override func sizeThatFits(size: CGSize) -> CGSize {
    if let featureImageSize = featureImageSizeOptional {
      return FrameCalculator.sizeThatFits(size, withImageSize: featureImageSize)
    } else {
      return CGSizeZero
    }
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()

    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    placeholderLayer?.frame = bounds
    CATransaction.commit()


  }
  
  //MARK: Cell Reuse
  override func prepareForReuse() {
    super.prepareForReuse()
    
    if let operation = nodeConstructionOperation {
        operation.cancel()
    }
    
    containerNode?.recursiveSetPreventOrCancelDisplay(true)
    contentLayer?.removeFromSuperlayer()
    contentLayer = nil
    containerNode = nil

  }
  
  //MARK: Cell Content
    func configureCellDisplayWithCardInfo(cardInfo: RainforestCardInfo, nodeConstructionQueue: NSOperationQueue) {
        
        if let oldNodeConstructionOperation = nodeConstructionOperation {
            oldNodeConstructionOperation.cancel()
        }
        
        //MARK: Image Size Section
        let image = UIImage(named: cardInfo.imageName)!
        featureImageSizeOptional = image.size
        
        let newNodeConstructionOperation = nodeConstructionOperationWithCardInfo(cardInfo, image: image)
        nodeConstructionOperation = newNodeConstructionOperation
        nodeConstructionQueue.addOperation(newNodeConstructionOperation)
    }

    func nodeConstructionOperationWithCardInfo(cardInfo: RainforestCardInfo, image: UIImage) -> NSOperation {
        let nodeConstructionOperation = NSBlockOperation()

        nodeConstructionOperation.addExecutionBlock {
            [weak self, unowned nodeConstructionOperation] in
            if nodeConstructionOperation.cancelled {
                return
            }
            if let strongSelf = self {
                //MARK: Node Creation Section
                let backgroundImageNode = ASImageNode()
                backgroundImageNode.image = image
                backgroundImageNode.contentMode = .ScaleAspectFill
                backgroundImageNode.layerBacked = true
                
                let featureImageNode = ASImageNode()
                featureImageNode.layerBacked = true
                featureImageNode.contentMode = .ScaleAspectFit
                featureImageNode.image = image
                
                let titleTextNode = ASTextNode()
                titleTextNode.layerBacked = true
                titleTextNode.backgroundColor = UIColor.clearColor()
                titleTextNode.attributedString = NSAttributedString.attributedStringForTitleText(cardInfo.name)
                
                let descriptionTextNode = ASTextNode()
                descriptionTextNode.layerBacked = true
                descriptionTextNode.backgroundColor = UIColor.clearColor()
                descriptionTextNode.attributedString = NSAttributedString.attributedStringForDescriptionText(cardInfo.description)
                
                let gradientNode = GradientNode()
                gradientNode.opaque = false
                gradientNode.layerBacked = true
                
                //MARK: Container Node Creation Section
                let containerNode = ASDisplayNode(layerClass: AnimatedContentsDisplayLayer.self)
                containerNode.layerBacked = true
                containerNode.shouldRasterizeDescendants = true
                containerNode.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.85, alpha: 0.2).CGColor
                containerNode.borderWidth = 1
                
                //MARK: Node Hierarchy Section
                containerNode.addSubnode(backgroundImageNode)
                containerNode.addSubnode(featureImageNode)
                containerNode.addSubnode(gradientNode)
                containerNode.addSubnode(titleTextNode)
                containerNode.addSubnode(descriptionTextNode)
                
                //MARK: Node Layout Section
                containerNode.frame = FrameCalculator.frameForContainer(featureImageSize: image.size)
                backgroundImageNode.frame = FrameCalculator.frameForBackgroundImage(
                    containerBounds: containerNode.bounds)
                featureImageNode.frame = FrameCalculator.frameForFeatureImage(
                    featureImageSize: image.size,
                    containerFrameWidth: containerNode.frame.size.width)
                titleTextNode.frame = FrameCalculator.frameForTitleText(
                    containerBounds: containerNode.bounds,
                    featureImageFrame: featureImageNode.frame)
                descriptionTextNode.frame = FrameCalculator.frameForDescriptionText(
                    containerBounds: containerNode.bounds,
                    featureImageFrame: featureImageNode.frame)
                gradientNode.frame = FrameCalculator.frameForGradient(
                    featureImageFrame: featureImageNode.frame)
                
                //MARK: Node Layer and Wrap Up Section
//                strongSelf.contentView.layer.addSublayer(containerNode.layer)
//                strongSelf.contentLayer = containerNode.layer
//                strongSelf.containerNode = containerNode
//                containerNode.setNeedsDisplay()

                
                dispatch_async(dispatch_get_main_queue()) { [weak nodeConstructionOperation] in
                    if let strongNodeConstructionOperation = nodeConstructionOperation {
                        // 2
                        if strongNodeConstructionOperation.cancelled {
                            return
                        }
                        
                        // 3
                        if strongSelf.nodeConstructionOperation !== strongNodeConstructionOperation {
                            return
                        }
                        
                        // 4
                        if containerNode.preventOrCancelDisplay {
                            return
                        }
                        
                        // 5
                        //MARK: Node Layer and Wrap Up Section
                        strongSelf.contentView.layer.addSublayer(containerNode.layer)
                        strongSelf.contentLayer = containerNode.layer
                        strongSelf.containerNode = containerNode
                        containerNode.setNeedsDisplay()

                    }
                }

                

                
                backgroundImageNode.imageModificationBlock = {  [weak backgroundImageNode] input in
                    if input == nil {
                        return input
                    }
                    
                    let didCancelBlur: () -> Bool = {
                        var isCancelled = true
                        if let strongBackgroundImageNode = backgroundImageNode {
                            let isCancelledClosure = {
                                isCancelled = strongBackgroundImageNode.preventOrCancelDisplay
                            }
                            
                            if NSThread.isMainThread() {
                                isCancelledClosure()
                            } else {
                                dispatch_sync(dispatch_get_main_queue(), isCancelledClosure)
                            }
                        }
                        return isCancelled
//                        return false
                    }
                    
                    
                    if let blurredImage = input.applyBlurWithRadius(
                        30,
                        tintColor: UIColor(white: 0.5, alpha: 0.3),
                        saturationDeltaFactor: 1.8,
                        maskImage: nil,
                        didCancel:didCancelBlur) {
                            return blurredImage
                    } else {
                        return image
                    }
                }
            }
        }
        
        return nodeConstructionOperation
    }

  
}
