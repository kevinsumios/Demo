//
//  RoundShadowButton.swift
//  Demo
//
//  Created by Kevin Sum on 9/3/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import UIKit
@IBDesignable
class RoundShadowButton: UIButton {
    
    var shadowLayer = CAShapeLayer()
    @IBInspectable var cornerRadius: CGFloat = 0
    @IBInspectable var fillColor: UIColor {
        get {
            if let color = shadowLayer.fillColor {
                return UIColor(cgColor: color)
            } else {
                return UIColor.white
            }
        }
        set {
            shadowLayer.fillColor = newValue.cgColor
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        sizeToFit()
        // Radius corner
        shadowLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
        // Shadow
        highlight(true)
        
        layer.insertSublayer(shadowLayer, at: 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addTarget(self, action: #selector(onTouchDown), for: .touchDown)
        self.addTarget(self, action: #selector(onTouchUp), for: .touchUpInside)
        self.addTarget(self, action: #selector(onTouchUp), for: .touchUpOutside)
    }
    
    func highlight(_ enable: Bool) {
        // Enable/Disable shadow in the layer
        
    }
    
    func enable(_ enable: Bool) {
        isEnabled = enable
        setNeedsDisplay()
    }
    
    func onTouchDown() {
        highlight(false)
    }
    
    func onTouchUp(sender: Any) {
        highlight(true)
    }
    
}

extension RoundShadowButton {
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(cgColor: shadowLayer.strokeColor!)
        }
        set {
            shadowLayer.strokeColor = newValue.cgColor
        }
    }
    @IBInspectable var borderWidth: CGFloat {
        get {
            return shadowLayer.lineWidth
        }
        set {
            shadowLayer.lineWidth = newValue
        }
    }
}

extension RoundShadowButton {
    @IBInspectable var shadowOffset: CGSize {
        get {
            return shadowLayer.shadowOffset
        }
        set {
            shadowLayer.shadowOffset = newValue
        }
    }
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return shadowLayer.shadowRadius
        }
        set {
            shadowLayer.shadowRadius = newValue
        }
    }
    @IBInspectable var shadowOpacity: Float {
        get {
            if isHighlighted {
            return shadowLayer.shadowOpacity
            } else {
                return 0
            }
        }
        set {
            shadowLayer.shadowOpacity = newValue
        }
    }
    @IBInspectable var shadowColor: UIColor {
        get {
            return UIColor(cgColor: shadowLayer.shadowColor!)
        }
        set {
            shadowLayer.shadowColor = newValue.cgColor
        }
    }
}
