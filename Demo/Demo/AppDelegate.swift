//
//  AppDelegate.swift
//  Demo
//
//  Created by Magnus Eriksson on 2017-10-25.
//  Copyright © 2017 Magnus Eriksson. All rights reserved.
//

import CubeContainer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let vc1 = AppDelegate.makeViewController()
    let vc2 = AppDelegate.makeViewController()
    let vc3 = AppDelegate.makeViewController()
    let vc4 = AppDelegate.makeViewController()
    let vc5 = AppDelegate.makeViewController()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        vc1.view.centerSubview(UIImageView(image: UIImage(named: "polar")!))
        vc2.view.centerSubview(UIImageView(image: UIImage(named: "fox")!))
        vc3.view.centerSubview(UIImageView(image: UIImage(named: "pug")!))
        vc4.view.centerSubview(UIImageView(image: UIImage(named: "elephant")!))
        vc5.view.centerSubview(UIImageView(image: UIImage(named: "owl")!))
        let cubeCtrl = CubeContainerViewController(viewControllers: [vc1, vc2, vc3, vc4, vc5])
        cubeCtrl.dataSource = self
        
        cubeCtrl.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .rewind, target: cubeCtrl, action: #selector(CubeContainerViewController.navigateToPreviousViewController))
        cubeCtrl.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fastForward, target: cubeCtrl, action: #selector(CubeContainerViewController.navigateToNextViewController))
        
        window = UIWindow()
        window?.rootViewController = UINavigationController(rootViewController: cubeCtrl)
        window?.makeKeyAndVisible()
        return true
    }
    
    private static func makeViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
        vc.view.layer.borderWidth = 1.0
        vc.view.layer.borderColor = UIColor.magenta.cgColor
        return vc
    }
}

extension AppDelegate: CubeContainerDataSource {
    func cubeContainerViewController(_ cubeContainerViewController: CubeContainer.CubeContainerViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return AppDelegate.makeViewController()
    }
}

extension UIView {
    
    fileprivate func centerSubview(_ view: UIView) {
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        view.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        view.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        view.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    }
}
