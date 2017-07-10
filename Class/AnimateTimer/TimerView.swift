//
//  TimerView.swift
//  Demo
//
//  Created by Kevin Sum on 10/07/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import UIKit

class TimerView: UIView {
    
    enum AnimateType {
        case linear
        case tiktok
    }

    var view: UIView!
    
    var didTimeout: ((Bool) -> ())?
    
    @IBOutlet weak var progressView: NeedleView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    convenience init(center: CGPoint, size: CGFloat) {
        let origin = CGPoint(x: center.x - size/2, y: center.y - size/2)
        self.init(frame: CGRect(origin: origin, size: CGSize(width: size, height: size)))
    }
    
    func setup() {
        view = loadViewFromNib()
        view.frame = bounds
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(view)
    }
    
    func start(second: TimeInterval, animate: AnimateType = .linear) {
        progressView.start(interval: second, animate: animate, completion: didTimeout)
    }
    
    func invalidate() {
        didTimeout = nil
        progressView.invalidate()
    }
    
    func loadViewFromNib() -> UIView {
        let view = Bundle.main.loadNibNamed("TimerView", owner: self, options: nil)?.first as! UIView
        return view
    }

}

class NeedleView: UIView {
    
    let beginAngle = -Double.pi/2
    let initFinishAngle = Double.pi/2*3
    var finishAngle = 0.0
    var timer: Timer?
    
    var needleView: UIImageView?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        needleView = self.viewWithTag(1) as? UIImageView
        backgroundColor = UIColor.clear
        finishAngle = initFinishAngle
    }
    
    override func draw(_ rect: CGRect) {
        // Draw progress view
        UIColor.red.set() // Set drawing color
        let center = CGPoint(x: rect.size.width/2, y: rect.size.height/2)
        let path = UIBezierPath(arcCenter: center, radius: rect.size.width/2-2, startAngle: (CGFloat)(beginAngle), endAngle: (CGFloat)(finishAngle), clockwise: true)
        path.addLine(to: center)
        path.close()
        path.fill()
        
        // Update needle transform
        needleView?.transform = CGAffineTransform(rotationAngle: CGFloat(finishAngle+Double.pi/2))
    }
    
    func start(interval: TimeInterval, animate: TimerView.AnimateType, completion: ((Bool) -> ())?) {
        var intervalAngle: Double
        var timerInterval: TimeInterval
        switch animate {
        case .linear:
            intervalAngle = (Double.pi/20)/interval
            timerInterval = 0.025
        case .tiktok:
            intervalAngle = (Double.pi*2)/interval
            timerInterval = 1
        }
        finishAngle = initFinishAngle
        var count = interval
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true, block: { (timer) in
            if count > 0 {
                self.setNeedsDisplay()
                count -= timerInterval
                NSLog("timer clock: %ds", abs(Int(ceil(count))))
                self.finishAngle -= intervalAngle
            } else {
                self.finishAngle = self.beginAngle
                self.setNeedsDisplay()
                timer.invalidate()
                completion?(true)
            }
        })
    }
    
    func invalidate() {
        timer?.invalidate()
        finishAngle = beginAngle
        self.setNeedsDisplay()
    }
    
}
