//
//  CubeContainerViewController.swift
//  ActivityLogger
//
//  Created by Magnus Eriksson on 31/12/15.
//  Copyright © 2015 Magnus Eriksson. All rights reserved.
//

import UIKit

public protocol CubeContainerDataSource {
    
    //Called to fetch the next view controller when there are no more view controllers in the 'future view controllers' stack
    func cubeContainerViewController(_ cubeContainerViewController: CubeContainerViewController,
                                     viewControllerAfter viewController: UIViewController) -> UIViewController?
}


public class CubeContainerViewController: UIViewController {
    
    //MARK: Properties
    
    public var dataSource: CubeContainerDataSource?
    
    fileprivate let containerView = UIView()
    
    //View controllers to be presented when navigating forward
    private var futureViewControllers: [UIViewController]
    
    //The currently presented side of the cube
    fileprivate var currentSide: CubeSide = .front
    
    //Called after a rotation animation has completed successfully
    fileprivate var rotationAnimationCompletionBlock: (() -> ())?
    
    private var rightScreenEdgeRecognizer, leftScreenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    
    //Rotation animation key-value keys
    fileprivate static let abortRotationAnimationIdentifier = "abortRotationAnimationIdentifier"
    fileprivate static let rotationAnimationIdentifier = "rotateCubeAnimation"
    fileprivate static let rotationAnimationKeyFinalSide = "rotateCubeAnimationFinalTransform"
    
    
    
    
    
    
    
    
    
    //MARK: Creation
    
    public convenience init(viewController: UIViewController) {
        self.init(viewControllers: [viewController])
    }
    
    public init(viewControllers: [UIViewController]) {
        guard !viewControllers.isEmpty else {
            fatalError("No view controllers provided!")
        }
        
        futureViewControllers = viewControllers.reversed()
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
        addChildViewController(popNextViewController()!,
                               superview: containerView,
                               transform: currentSide.viewTransform(in: containerView))
        applyCubeTransforms()
    }
    
    private func applyCameraPerspective() {
        var perspective = CATransform3DIdentity
        perspective.m34 = -1/500 //After testing, 500 seems to be a good value
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
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        //Apply cube transforms alongside the coordinator's transition so that 'self.view' has been updated to its new size
        coordinator.animate(alongsideTransition: { context in
            self.applyCubeTransforms()
        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func applyCubeTransforms() {
        containerView.layer.sublayerTransform = currentSide.perspectiveTransform(in: view)
        
        for (index, childViewController) in children.enumerated() {
            let cubeSide = CubeSide(index: index)
            childViewController.view.layer.transform = cubeSide.viewTransform(in: view)
        }
    }
    
    
    
    
    
    
    
    
    
    //MARK: Public
    
    /**
     Rotates the cube forward if possible.
     */
    @objc public func navigateToNextViewController() {
        navigateToNextViewController(isInteractive: false)
    }
    
    private func navigateToNextViewController(isInteractive: Bool) {
        guard !isRotationAnimationInProgress() else {
            return
        }
        guard let nextVc = popNextViewController() else {
            return
        }
        
        //Disable user interaction so that the newest view may receive touches.
        currentViewController().view.isUserInteractionEnabled = false

        //Disable interactive navigation during non-interactive animation
        if !isInteractive {
            leftScreenEdgeRecognizer.isEnabled = false
            rightScreenEdgeRecognizer.isEnabled = false
        }
        
        
        addChildViewController(nextVc, superview: containerView, transform: currentSide.nextSide().viewTransform(in: containerView))
        performRotationAnimation(from: currentSide, to: currentSide.nextSide(), isInteractive: isInteractive)
    }
    
    /**
     Rotates the cube backward and removes the latest view controller if rotation was successful.
     */
    @objc public func navigateToPreviousViewController() {
        navigateToPreviousViewController(isInteractive: false)
    }
    
    private func navigateToPreviousViewController(isInteractive: Bool) {
        let hasPreviousViewControllers = currentViewController() != children.first
        guard !isRotationAnimationInProgress(), hasPreviousViewControllers else {
            return
        }
        
        rotationAnimationCompletionBlock =  {
            let currentVc = self.currentViewController()
            self.pushViewControllerToFutureStack(currentVc)
        }
        
        //Disable interactive navigation during non-interactive animation
        if !isInteractive {
            leftScreenEdgeRecognizer.isEnabled = false
            rightScreenEdgeRecognizer.isEnabled = false
        }
        
        performRotationAnimation(from: currentSide, to: currentSide.prevSide(), isInteractive: isInteractive)
    }
    
    
    
    
    
    //MARK: Private
    
    /// Returns the currently presented view controller
    fileprivate func currentViewController() -> UIViewController {
        return children.last!
    }
    
    //Pops the stack of future view controllers, returning the next view controller to be presented
    private func popNextViewController() -> UIViewController? {
        if futureViewControllers.last != nil {
            return futureViewControllers.removeLast()
        }
        
        //No future view controllers in the stack - let's ask the delegate for one
        return dataSource?.cubeContainerViewController(self, viewControllerAfter: currentViewController())
    }
    
    
    fileprivate func pushViewControllerToFutureStack(_ viewController: UIViewController) {
        viewController.removeFromParentViewController()
        futureViewControllers.append(viewController)
    }
    
    
    
    
    
    
    //MARK: Interactive animation related
    
    @objc private func onEdgePanned(sender: UIScreenEdgePanGestureRecognizer) {
        
        //Calculate some data
        let minPercent = 0.0
        let maxPercent = 0.999
        let isRotatingBackward = sender == leftScreenEdgeRecognizer
        let containingView = sender.view!
        let delta = sender.translation(in: containingView)
        var percentPanned = Double(abs(delta.x/containingView.bounds.size.width))
        
        //Clamp percentPanned between 0.0 and 0.999
        percentPanned = min(maxPercent, max(minPercent, percentPanned))
        
        switch sender.state {
        case .began:
            //Freeze the layer and begin the animation
            containingView.layer.speed = 0
            
            if isRotatingBackward {
                navigateToPreviousViewController(isInteractive: true)
            } else {
                navigateToNextViewController(isInteractive: true)
            }
            
        case .changed:
            //Animation might not be in progress, e.g. if going backward from the initial view controller
            if isRotationAnimationInProgress() {
                //Update animation progress
                containingView.layer.timeOffset = percentPanned
            }
            
        case .ended, .cancelled, .failed:
            let userSwipeSpeed = abs(sender.velocity(in: containingView).x)
            let minimumVelocityRequired: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1700 : 500;

            let hasPannedFastEnoughToSwitch = userSwipeSpeed > minimumVelocityRequired;
            let hasPannedFarEnoughToSwitch = percentPanned > 0.5
            
            if !hasPannedFarEnoughToSwitch && !hasPannedFastEnoughToSwitch {
                //Has not panned enough to switch sides - animate restoration to originating side
                
                CATransaction.begin()
                CATransaction.setCompletionBlock({
                    self.removeRotationAnimation()
                    self.containerView.layer.removeAnimation(forKey: CubeContainerViewController.abortRotationAnimationIdentifier)
                })
                
                let restorationAnimation = CABasicAnimation(keyPath: "sublayerTransform")
                if let currentSublayerTransform = containerView.layer.presentation()?.sublayerTransform {
                    restorationAnimation.fromValue = currentSublayerTransform
                }
                restorationAnimation.toValue = containerView.layer.model().sublayerTransform
                
                /* WORKAROUND:
                 * Setting the "layer.sublayerTransform" model value prior to the animation and then restoring it after, results in a glitch.
                 * Therefore we use 'kCAFillModeForwards' combined with 'isRemovedOnCompletion = false' and explicitly remove animation when done.
                 */
                restorationAnimation.isRemovedOnCompletion = false
                restorationAnimation.fillMode = CAMediaTimingFillMode.forwards
                
                containerView.layer.add(restorationAnimation, forKey: CubeContainerViewController.abortRotationAnimationIdentifier)
                CATransaction.commit()
            }
            
            
            //Continue the animation with a similar speed to the user swipe speed.
            //Animation speed = 'velocity.x (points per second) / view.width (points)'. Minimum 1.5, maximum 2.
            let animationSpeed = max(1.5, min(2, userSwipeSpeed / max(1.0, containingView.bounds.size.width)))
            containingView.layer.speed = Float(animationSpeed)
            
            //Begin the animation now
            containingView.layer.beginTime = CACurrentMediaTime()
            
            
        default:
            return
        }
    }
    
    
    //MARK: Rotation Animation Related
    
    private func performRotationAnimation(from: CubeSide, to: CubeSide, isInteractive: Bool) {
        guard !isRotationAnimationInProgress() else {
            return
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            //Restore timeOffset for interactive animations upon completion
            self.containerView.layer.timeOffset = 0
        }
        
        
        let rotationAnimation = isInteractive ? makeLinearRotationAnimation(from: from, to: to) : makeKeyTimedRotationAnimation(from: from, to: to)
        rotationAnimation.duration = 1.0
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.fillMode = CAMediaTimingFillMode.forwards
        rotationAnimation.delegate = self
        //Add meta-data to the animation object, so that appropriate actions may performed in the delegate callback 'animationDidStop'
        rotationAnimation.setValue(to.rawValue, forKey: CubeContainerViewController.rotationAnimationKeyFinalSide)
        
        CATransaction.setAnimationDuration(rotationAnimation.duration)
        containerView.layer.add(rotationAnimation, forKey: CubeContainerViewController.rotationAnimationIdentifier)
        
        CATransaction.commit()
    }
    
    /// Returns true if the rotation animation is currently in progress
    private func isRotationAnimationInProgress() -> Bool {
        return containerView.layer.animation(forKey: CubeContainerViewController.rotationAnimationIdentifier) != nil
    }
    
    
    private func makeLinearRotationAnimation(from: CubeSide, to: CubeSide) -> CAAnimation {
        let startTransform = from.perspectiveTransform(in: containerView)
        let finalTransform = to.perspectiveTransform(in: containerView)
        
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "sublayerTransform")
        keyFrameAnimation.values = [
            startTransform,     //Begin from start transform
            finalTransform]     //Animate to original version of final transform
            .map { NSValue(caTransform3D: $0) }
        
        return keyFrameAnimation
    }
    
    private func makeKeyTimedRotationAnimation(from: CubeSide, to: CubeSide) -> CAAnimation {
        let startTransform = from.perspectiveTransform(in: containerView)
        let startDownScaled = CATransform3DScale(startTransform, 0.85, 0.85, 0.85)
        let finalTransform = to.perspectiveTransform(in: containerView)
        let finalDownScaled = CATransform3DScale(finalTransform, 0.85, 0.85, 0.85)
        
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "sublayerTransform")
        keyFrameAnimation.values = [
            startTransform,     //Begin from start transform
            startDownScaled,    //Animate to scaled down version of start transform
            finalDownScaled,    //Animate to scaled down version of final transform
            finalTransform]     //Animate to original version of final transform
            .map { NSValue(caTransform3D: $0) }
        
        keyFrameAnimation.timingFunctions = [
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut),
            CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut),
        ]
        keyFrameAnimation.keyTimes = [0, 0.15, 0.65, 1.0] //These values look good
        
        return keyFrameAnimation
    }
    
    
    fileprivate func removeRotationAnimation() {
        containerView.layer.removeAnimation(forKey: CubeContainerViewController.rotationAnimationIdentifier)
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
        let newSide = CubeSide(rawValue:anim.value(forKey: CubeContainerViewController.rotationAnimationKeyFinalSide) as! Int)!
        
        if successful {
            //Update current side
            currentSide = newSide
            
            //Update perspective of container view
            containerView.layer.sublayerTransform = newSide.perspectiveTransform(in: containerView)
            
            if let rotationAnimationCompletionBlock = rotationAnimationCompletionBlock {
                rotationAnimationCompletionBlock()
            }
            removeRotationAnimation()
        } else {
            //Interactive animation failed. Let's check what direction was attempted
            let oldSide = currentSide
            let isAnimationDirectionForward = oldSide.nextSide() == newSide
            
            if isAnimationDirectionForward {
                // Remove the newly added 'nextVc' since animation didn't complete
                let currentVc = currentViewController()
                pushViewControllerToFutureStack(currentVc)
            }
        }
        
        //Enable user interaction for the current view controller
        currentViewController().view.isUserInteractionEnabled = true
        
        //Restore interactive navigation
        leftScreenEdgeRecognizer.isEnabled = true
        rightScreenEdgeRecognizer.isEnabled = true
        
        //Restore layer speed in case it was interactive
        containerView.layer.speed = 1
        
        rotationAnimationCompletionBlock = nil
    }
}
