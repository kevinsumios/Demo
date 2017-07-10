//
//  ViewController.swift
//  AnimateTimer
//
//  Created by Kevin Sum on 10/07/2017.
//  Copyright © 2017 Kevin Sum. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Basic usage of the timer view
        let timerView = TimerView(center: view.center, size: 150)
        view.addSubview(timerView)
        timerView.start(second: 5, animate: .linear) // try animate of .tiktok
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

