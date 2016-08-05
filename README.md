# CubeContainerViewController

## Description:
- A container view controller that looks and acts like a 3D cube
- Interactive and/or automatic navigation
- API usage similar to UIPageViewController
- Written in Swift
- Supports both Portrait and Landscape

## Installation:
- Fetch with Carthage, e.g:
  - 'github "chylis/CubeContainerViewController-iOS"'

## Example usage:
```swift

import CubeContainer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  let vc1 = AppDelegate.makeViewController()
  let vc2 = AppDelegate.makeViewController()
  let vc3 = AppDelegate.makeViewController()

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let cubeCtrl = CubeContainerViewController(viewControllers: [vc1, vc2, vc3])
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
    return vc
  }
}

extension AppDelegate: CubeContainerDataSource {
  func cubeContainerViewController(_ cubeContainerViewController: CubeContainer.CubeContainerViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    return AppDelegate.makeViewController()
  }
}
```

## Restrictions:
- Must be instantiated from code

## Known Issues:

## -------------

Feel free to contribute!
