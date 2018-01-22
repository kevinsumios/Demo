//
//  ViewController.swift
//  SpinClock
//
//  Created by Kevin on 22/01/2018.
//  Copyright © 2018 Kevin Sum. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var clockFace: ClockFace!
    @IBOutlet weak var hourLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clockFace.didUpdateTime = { (hour, minute) in
            self.hourLabel.text = hour < 10 ? "0\(hour)" : String(hour)
            self.minuteLabel.text = minute < 10 ? "0\(minute)" : String(minute)
        }
        clockFace.setTime(Date())
    }


}

