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
        addChildViewController(childViewController)
        superview.centerSubview(childViewController.view)
        childViewController.view.layer.transform = transform
        childViewController.didMove(toParentViewController: self)
    }
    
    func removeFromParent() {
        willMove(toParentViewController: nil)
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}
