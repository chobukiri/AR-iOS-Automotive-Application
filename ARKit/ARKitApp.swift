//
//  ARKitApp.swift
//  ARKit
//
//  Created by Gui Shi Jun on 16/04/2026.
//

import SwiftUI

@main
struct ARKitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Safe extension to re-enable the native swipe-to-go-back gesture
// without causing retroactive conformance warnings.
class SwipeBackDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return (navigationController?.viewControllers.count ?? 0) > 1
    }
}

extension UINavigationController {
    private struct AssociatedKeys {
        static var delegateKey: UInt8 = 0
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        let delegate = SwipeBackDelegate(navigationController: self)
        objc_setAssociatedObject(self, &AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        interactivePopGestureRecognizer?.delegate = delegate
    }
}
