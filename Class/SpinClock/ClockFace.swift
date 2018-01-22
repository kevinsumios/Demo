//
//  ClockFace.swift
//  Demo
//
//  Created by Kevin on 22/01/2018.
//  Copyright © 2018 Kevin Sum. All rights reserved.
//

import UIKit

@IBDesignable
class ClockFace: UIView {

    @IBOutlet weak var minuteView: UIView!
    @IBOutlet weak var minuteHand: ClockHand!
    @IBOutlet weak var hourView: UIView!
    @IBOutlet weak var hourHand: ClockHand!
    @IBOutlet var minuteRecognizer: UIPanGestureRecognizer!
    @IBOutlet var hourRecognizer: UIPanGestureRecognizer!
    
    var view: UIView!
    var beginPoints: [ClockHand: CGPoint] = [:]
    var hour: Int = 0
    var minute: Int = 0
    var didUpdateTime: ((_ hour: Int, _ minute: Int) -> ())?
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        self.layer.cornerRadius = self.frame.width/2
        self.layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func loadViewFromNib() -> UIView! {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        if (nib.instantiate(withOwner: self, options: nil).count > 0) {
            let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
            return view
        } else {
            return UIView(frame: .zero)
        }
    }
    
    func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [UIViewAutoresizing.flexibleWidth,
                                 UIViewAutoresizing.flexibleHeight]
        addSubview(view)
    }
    
    func updateTransform() -> (CGPoint, CGPoint) {
        let dayMinute = CGFloat(60*hour+minute)
        let hourAngle = dayMinute*CGFloat.pi/360.0
        let minuteAngle = CGFloat(minute)*CGFloat.pi/30
        let hourPoint = CGPoint(x: sin(hourAngle)*hourHand.long, y: cos(hourAngle)*hourHand.long)
        let minutePoint = CGPoint(x: sin(minuteAngle)*minuteHand.long, y: cos(minuteAngle)*minuteHand.long)
        hourView.transform = CGAffineTransform(rotationAngle: hourAngle)
        minuteView.transform = CGAffineTransform(rotationAngle: minuteAngle)
        
        return (hourPoint, minutePoint)
    }
    
    @IBAction func didPanView(_ sender: UIPanGestureRecognizer) {
        var translation = sender.translation(in: view);
        translation = CGPoint(x: translation.x, y: -translation.y)
        if let handView = sender.view as? ClockHand, let beginPoint = beginPoints[handView] {
            let touchPoint = CGPoint(x: beginPoint.x*handView.touchScale, y: beginPoint.y*handView.touchScale)
            let point = CGPoint(x: touchPoint.x+translation.x, y: touchPoint.y+translation.y)
            var angle = atan(point.x/point.y)
            if (point.y < 0) {
                angle = CGFloat.pi-atan(point.x/abs(point.y))
            } else if (point.x < 0) {
                angle = 2*CGFloat.pi-atan(abs(point.x)/point.y)
            }
            
            // Update time
            if (handView == hourHand) {
                let hourOld = hour
                let dayminute = Int(Double(angle)*360/Double.pi)
                hour = dayminute/60
                if 11 <= abs(hourOld-hour) && abs(hourOld-hour) <= 13 {
                    hour += 12
                }
                minute = dayminute%60
            } else {
                let minuteOld = minute
                minute = Int(angle*30/CGFloat.pi)
                if abs(minute-minuteOld) > 50 {
                    if minute > minuteOld {
                        hour -= 1
                    } else {
                        hour += 1
                    }
                }
                if hour >= 24 {
                    hour -= 24
                } else if hour < 0 {
                    hour += 24
                }
            }
            // Update transform
            let (hourPoint, minutePoint) = updateTransform()
            didUpdateTime?(hour, minute)
            if (sender.state == .ended) {
                beginPoints[hourHand] = hourPoint
                beginPoints[minuteHand] = minutePoint
            }
        }
    }
    
    func setTime(_ time: Date) {
        hour = Calendar.current.component(.hour, from: time)
        minute = Calendar.current.component(.minute, from: time)
        didUpdateTime?(hour, minute)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            let (hourPoint, minutePoint) = self.updateTransform()
            self.beginPoints = [self.minuteHand: minutePoint,
                                self.hourHand: hourPoint]
        }, completion: nil)
        
    }

}

class ClockHand: UIView {
    
    var touchY: CGFloat = 0
    var touchScale: CGFloat = 0
    var long: CGFloat {
        get {
            return frame.height
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        touchY = long - location.y
        touchScale = touchY/long
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchY = 0
        touchScale = 0
    }
    
}
