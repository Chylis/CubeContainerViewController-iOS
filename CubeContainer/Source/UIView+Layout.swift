//
//  UIView+Layout.swift
//  CubeContainer
//
//  Created by Magnus Eriksson on 30/12/15.
//
//

import UIKit

extension UIView {
    
    func centerSubview(_ subview: UIView, topAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor>? = nil) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor),
            subview.topAnchor.constraint(equalTo: topAnchor ?? self.topAnchor)
            ])
    }
}
