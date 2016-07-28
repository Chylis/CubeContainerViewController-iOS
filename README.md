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

class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    let cubeCtrl = DemoCubeViewController()
    cubeCtrl.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .rewind, target: cubeCtrl, action: #selector(DemoCubeViewController.navigateBackward(_:)))
    cubeCtrl.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fastForward, target: cubeCtrl, action: #selector(DemoCubeViewController.navigateForward(_:)))

    window = UIWindow()
    window?.rootViewController = UINavigationController(rootViewController: cubeCtrl)
    window?.makeKeyAndVisible()
    return true
  }
}

import CubeContainer
class DemoCubeViewController: CubeContainerViewController {

  let initialViewController = DemoCubeViewController.makeViewController()

  init(){
    super.init(viewController: initialViewController)
    dataSource = self
  }

  func navigateBackward(_: UIBarButtonItem) {
    navigateToPreviousViewController()
  }

  func navigateForward(_: UIBarButtonItem) {
    navigateToViewController(CubeViewController.makeViewController())
  }

  private class func makeViewController() -> UIViewController {
    let vc = UIViewController()
    vc.view.backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
    return vc
  }
}

//MARK: CubeContainerDataSource
extension CubeViewController: CubeContainerDataSource {
  func cubeContainerViewController(_ cubeContainerViewController: CubeContainer.CubeContainerViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    return CubeViewController.makeViewController()
  }
}

```

## Restrictions:
- CubeContainerViewController must be subclassed
- Must be instantiated from code

## Known Issues:

## -------------
Feel free to contribute!
