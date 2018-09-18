//
//  UIViewController+Utils.swift
//  CubeContainer
//
//  Created by Magnus Eriksson on 30/12/15.
//
//

import UIKit

extension UIViewController {
    
    func addChildViewController(_ childViewController: UIViewController, superview: UIView, transform: CATransform3D) {
        addChild(childViewController)
        superview.centerSubview(childViewController.view)
        childViewController.view.layer.transform = transform
        childViewController.didMove(toParent: self)
    }
    
    func removeFromParentViewController() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}
