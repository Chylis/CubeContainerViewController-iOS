//
//  CubeSide.swift
//  CubeContainer
//
//  Created by Magnus Eriksson on 30/12/15.
//
//

import Foundation

enum CubeSide: Int {
    case front = 0
    case right
    case back
    case left
    case count
    
    init(index: Int) {
        let relativeIndex = index % CubeSide.count.rawValue
        self = CubeSide(rawValue: relativeIndex)!
    }
    
    func nextSide() -> CubeSide {
        switch self {
        case .front:    return .right
        case .right:    return .back
        case .back:     return .left
        case .left:     return .front
        default:        return .front
        }
    }
    
    func prevSide() -> CubeSide {
        switch self {
        case .front:    return .left
        case .right:    return .front
        case .back:     return .right
        case .left:     return .back
        default:        return .front
        }
    }
    
    /**
     Returns the cube-transform for the given cube side
     */
    func viewTransform(in parentView: UIView) -> CATransform3D {
        let horizontalDistance = parentView.bounds.size.width / 2.0
        
        switch self {
        case .front:
            return CATransform3DMakeTranslation(0, 0, horizontalDistance) //y 0 degrees, z 'distance' units (towards camera)
        case .right:
            let transform = CATransform3DMakeTranslation(horizontalDistance, 0, 0) //x 'distance' units (right)
            return CATransform3DRotate(transform, .pi / 2.0, 0, 1, 0) //y 90 degrees
        case .left:
            let transform = CATransform3DMakeTranslation(-horizontalDistance, 0, 0) //x -'distance' units (left)
            return CATransform3DRotate(transform, -(.pi / 2.0), 0, 1, 0) //y -90 degrees
        case .back:
            let transform = CATransform3DMakeTranslation(0, 0, -horizontalDistance) //z -'distance' units (away from camera)
            return CATransform3DRotate(transform, .pi, 0, 1, 0) //y 180 degrees (mirrored)
        default:
            return CATransform3DIdentity
        }
    }
    
    /**
     Returns the perspective transform required to see the view at each side
     */
    func perspectiveTransform() -> CATransform3D {
        switch self {
        case .front:
            return CATransform3DIdentity
        case .right:
            return CATransform3DMakeRotation(-(.pi / 2.0), 0, 1, 0) // y - 90 degrees
        case .left:
            return CATransform3DMakeRotation(.pi / 2.0, 0, 1, 0) //y 90 degrees
        case .back:
            return CATransform3DMakeRotation(.pi, 0, 1, 0) //y 180 degrees
        default:
            return CATransform3DIdentity
        }
    }
}
