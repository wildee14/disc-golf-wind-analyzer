//
//  ViewController+UI.swift
//  Starter Project
//
//  Created by Oscar de la Hera Gomez on 7/13/22.
//

import Foundation
import UIKit
import TinyConstraints
import SwiftUI

@available(iOS 16.0, *)
extension ViewController {
    private struct AssociatedKeys {
        static var customViewHostingController = "customViewHostingController"
    }
    @available(iOS 16.0, *)
    var customViewHostingController: UIHostingController<ContentView>? {
        get {
            objc_getAssociatedObject(self, &AssociatedKeys.customViewHostingController) as? UIHostingController<ContentView>
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.customViewHostingController, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func setupUI() {
        debugPrint("\(ViewController.identifier) \(DebuggingIdentifiers.actionOrEventInProgress) Setting Up UI.")
        self.setupCustomUIView()
        debugPrint("\(ViewController.identifier) \(DebuggingIdentifiers.actionOrEventSucceded) Setup UI.")
    }

    private func setupCustomUIView() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Initialize UIHostingController with rootView
            let hostingController = UIHostingController(rootView: self.customView)
            self.customViewHostingController = hostingController

            // Add hosting controller as child
            self.addChild(hostingController)
            // Add hosting controller's view as subview
            self.view.addSubview(hostingController.view)
            hostingController.didMove(toParent: self)

            // Edges to Superview, with Safe Area Insets
            self.customViewTopConstraint﻿ = hostingController.view.top(to: self.view, offset: ViewController.safeAreaInsets.top)
            self.customViewRightConstraint﻿ = hostingController.view.right(to: self.view, offset: -ViewController.safeAreaInsets.right)
            self.customViewBottomConstraint﻿ = hostingController.view.bottom(to: self.view, offset: -ViewController.safeAreaInsets.bottom)
            self.customViewLeftConstraint﻿ = hostingController.view.left(to: self.view, offset: ViewController.safeAreaInsets.left)

            debugPrint("\(ViewController.identifier) \(DebuggingIdentifiers.actionOrEventSucceded) Setup Custom View!")
        }
    }
}

