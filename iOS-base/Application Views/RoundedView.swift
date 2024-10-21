//
//  RoundedView.swift
//  iOS-base
//
//  Created by jon knight on 18/07/2023.
//  Copyright © 2023 ForgeRock. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedView: UIView {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet {
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }

}
