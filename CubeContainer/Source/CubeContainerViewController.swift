//
//  CubeContainerViewController.swift
//  ActivityLogger
//
//  Created by Magnus Eriksson on 31/12/15.
//  Copyright © 2015 Magnus Eriksson. All rights reserved.
//

import UIKit

public protocol CubeContainerDataSource {
    
    //Called during an interactive transition to fetch the next view controller
    func cubeContainerViewController(_ cubeContainerViewController: CubeContainerViewController,
                                     viewControllerAfter viewController: UIViewController) -> UIViewController?
}


public class CubeContainerViewController: UIViewController {
    
    //MARK: Properties
    
    public var dataSource: CubeContainerDataSource?
    
    private let containerView = UIView()
    
    //Initial view controller
    private let rootViewController: UIViewController
    
    //The currently presented side of the cube
    private var currentSide: CubeSide = .front
    
    //Called after a rotation animation has completed successfully
    private var rotationAnimationCompletionBlock: (() -> ())?
    
    private var rightScreenEdgeRecognizer, leftScreenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    //Rotation animation key-value keys
    private let rotationAnimationIdentifier = "rotateCubeAnimation"
    private let rotationAnimationKeyFinalSide = "rotateCubeAnimationFinalTransform"
    
    
    
    
    
    
    
    
    
    //MARK: Creation
    
    public init(viewController: UIViewController) {
        rootViewController = viewController
        super.init(nibName:nil, bundle:nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
    
    
    
    
    //MARK: Life cycle
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.centerSubview(containerView, topAnchor:topLayoutGuide.bottomAnchor)
        applyCameraPerspective()
        addGestureRecognizers()
        addChildViewController(rootViewController,
                               superview: containerView,
                               transform: currentSide.viewTransform(in: view))
    }
    
    private func applyCameraPerspective() {
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/50000 //After testing, 50000 seems to be a good value
        containerView.layer.sublayerTransform = perspective
    }
    
    private func addGestureRecognizers() {
        leftScreenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(CubeContainerViewController.onEdgePanned(sender:)))
        leftScreenEdgeRecognizer.edges = .left
        containerView.addGestureRecognizer(leftScreenEdgeRecognizer)
        
        rightScreenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(CubeContainerViewController.onEdgePanned(sender:)))
        rightScreenEdgeRecognizer.edges = .right
        containerView.addGestureRecognizer(rightScreenEdgeRecognizer)
    }
    
    
    
    
    
    
    
    
    //MARK: Rotation
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyCubeTransforms()
    }
    
    private func applyCubeTransforms() {
        for (index, childViewController) in childViewControllers.enumerated() {
            let cubeSide = CubeSide(rawValue: index)!
            childViewController.view.layer.transform = cubeSide.viewTransform(in: view)
        }
    }
    
    
    
    
    
    
    
    
    
    
    //MARK: Public
    
    /**
     Rotates the cube forward if possible.
     Disables user interaction so that the newest view may receive touches.
     */
    public func navigateToViewController(_ viewController: UIViewController) {
        let canAddMoreChildren = childViewControllers.count < CubeSide.count.rawValue
        
        if canAddMoreChildren {
            currentViewController().view.isUserInteractionEnabled = false
            addChildViewController(viewController, superview: containerView, transform: currentSide.nextSide().viewTransform(in: containerView))
            performRotationAnimation(from: currentSide, to: currentSide.nextSide())
        }
    }
    
    /**
     Rotates the cube backward and removes the latest view controller if rotation was successful.
     */
    public func navigateToPreviousViewController() {
        let hasPreviousChildren = childViewControllers.count > 1
        
        if hasPreviousChildren {
            rotationAnimationCompletionBlock =  {
                self.currentViewController().removeFromParent()
            }
            
            performRotationAnimation(from: currentSide, to: currentSide.prevSide())
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    //MARK: Interactive animation related
    
    func onEdgePanned(sender: UIScreenEdgePanGestureRecognizer) {
        
        //Calculate some data
        let minPercent = 0.0
        let maxPercent = 0.999
        let minPercentRequired = 0.25
        let isRotatingBackward = sender == leftScreenEdgeRecognizer
        let containingView = sender.view!
        let delta = sender.translation(in: containingView)
        var percentPanned = Double(fabs(delta.x/containingView.bounds.size.width))
        
        //Clamp percentPanned between 0.0 and 0.999
        percentPanned = min(maxPercent, max(minPercent, percentPanned))
        
        switch sender.state {
        case .began:
            //Freeze the layer and begin the animation
            containingView.layer.speed = 0
            
            if isRotatingBackward {
                navigateToPreviousViewController()
            }
            else if let nextVc = dataSource?.cubeContainerViewController(self, viewControllerAfter: currentViewController()) {
                navigateToViewController(nextVc)
            }
            
        case .changed:
            //Animation might not be in progress, e.g. if going backward from the initial view controller
            if isRotationAnimationInProgress() {
                //Update animation progress
                containingView.layer.timeOffset = percentPanned
            }
            
        case .ended, .cancelled, .failed:
            if percentPanned < minPercentRequired {
                removeRotationAnimation()
            }
            
            //Restore layer speed and begin the animation now
            containingView.layer.beginTime = CACurrentMediaTime()
            containingView.layer.speed = 1
        default:
            return
        }
    }
    
    
    
    
    
    
    
    
    
    
    //MARK: Rotation Animation Related
    
    private func performRotationAnimation(from: CubeSide, to: CubeSide) {
        guard !isRotationAnimationInProgress() else {
            return
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            //Restore timeOffset for interactive animations upon completion
            self.containerView.layer.timeOffset = 0
        }
        
        let rotationAnimation = makeRotationAnimation(from: from, to: to)
        CATransaction.setAnimationDuration(rotationAnimation.duration)
        containerView.layer.add(rotationAnimation, forKey: rotationAnimationIdentifier)
        
        CATransaction.commit()
    }
    
    /// Returns true if the rotation animation is currently in progress
    private func isRotationAnimationInProgress() -> Bool {
        return containerView.layer.animation(forKey: rotationAnimationIdentifier) != nil
    }
    
    /// Creates a new rotation animation
    /// Assigns self as delegate
    /// Adds meta-data to the animation, which can be retrieved and used in the delegate callback 'animationDidStop'
    private func makeRotationAnimation(from: CubeSide, to: CubeSide) -> CAAnimation {
        
        let startTransform = from.perspectiveTransform()
        let startDownScaled = CATransform3DScale(startTransform, 0.55, 0.55, 0.55)
        
        let finalTransform = to.perspectiveTransform()
        let finalDownScaled = CATransform3DScale(finalTransform, 0.55, 0.55, 0.55)
        
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "sublayerTransform")
        keyFrameAnimation.duration = 1.0
        keyFrameAnimation.isRemovedOnCompletion = false
        keyFrameAnimation.fillMode = kCAFillModeForwards
        
        keyFrameAnimation.values = [
            startTransform,     //Begin from start transform
            startDownScaled,    //Animate to scaled down version of start transform
            finalDownScaled,    //Animate to scaled down version of final transform
            finalTransform]     //Animate to original version of final transform
            .map { NSValue(caTransform3D: $0) }
        
        
        keyFrameAnimation.timingFunctions = [
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut),
            CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut),
        ]
        
        keyFrameAnimation.keyTimes = [0, 0.15, 0.65, 1.0] //These values look good
        keyFrameAnimation.delegate = self
        
        //Add meta-data to the animation object, so that appropriate actions may performed when the animation ends
        keyFrameAnimation.setValue(to.rawValue, forKey: rotationAnimationKeyFinalSide)
        
        return keyFrameAnimation
    }
    
    private func removeRotationAnimation() {
        containerView.layer.removeAnimation(forKey: rotationAnimationIdentifier)
    }
}








//MARK: CAAnimationDelegate

extension CubeContainerViewController: CAAnimationDelegate {
    
    
    /**
     Called when the rotation animation has stopped.
     
     Removes the animation from the layer since it has removeOnCompletion 'false' and fillmode 'forwards'
     
     If the animation was successful:
     - The current side is updated
     - The container view perspective is updated to show the new-current view controller's view
     - Call the rotationAnimationCompletionBlock
     
     If the animation failed: Remove the current view controller if the animation direction was forward,
     
     */
    public func animationDidStop(_ anim: CAAnimation, finished successful: Bool) {
        let newSide = CubeSide(rawValue:anim.value(forKey: rotationAnimationKeyFinalSide) as! Int)!
        
        if successful {
            //Update current side
            currentSide = newSide
            
            //Update perspective of container view
            containerView.layer.sublayerTransform = newSide.perspectiveTransform()
            
            if let rotationAnimationCompletionBlock = rotationAnimationCompletionBlock {
                rotationAnimationCompletionBlock()
            }
        } else {
            //Interactive animation failed. Let's check what direction was attempted
            let oldSide = currentSide
            let isAnimationDirectionForward = oldSide.nextSide() == newSide
            
            if isAnimationDirectionForward {
                // Remove the newly added 'nextVc' since animation didn't complete
                currentViewController().removeFromParent()
            }
        }
        
        //Enable user interaction for the current view controller
        currentViewController().view.isUserInteractionEnabled = true
        
        rotationAnimationCompletionBlock = nil
        removeRotationAnimation()
    }
}
