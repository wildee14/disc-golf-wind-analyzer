//
//  UpdateSafeAreaInsets.swift
//  Starter Project
//
//  Created by Oscar de la Hera Gomez on 7/20/22.
//

import Foundation
import UIKit

@available(iOS 16.0, *)
func updateSafeAreaInsets(topConstraint: NSLayoutConstraint?, rightConstraint: NSLayoutConstraint?, bottomConstraint: NSLayoutConstraint?, leftConstraint: NSLayoutConstraint?) {
    DispatchQueue.main.async {
        if #available(iOS 16.0, *) {
            topConstraint?.constant = ViewController.safeAreaInsets.top
        } else {
            // Fallback on earlier versions
        }
        if #available(iOS 16.0, *) {
            rightConstraint?.constant = -ViewController.safeAreaInsets.right
        } else {
            // Fallback on earlier versions
        }
        bottomConstraint?.constant = -ViewController.safeAreaInsets.bottom
        leftConstraint?.constant = ViewController.safeAreaInsets.left
    }
}
