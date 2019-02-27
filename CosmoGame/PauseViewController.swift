//
//  PauseViewController.swift
//  CosmoGame
//
//  Created by Andrew on 26/02/2019.
//  Copyright © 2019 Andrew. All rights reserved.
//

import UIKit

protocol PauseVCDelegate {
    func pauseViewControllerPlayButton(_ viewController: PauseViewController)
}

class PauseViewController: UIViewController {

    var delegate: PauseVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func playButtonPress(_ sender: Any) {
        delegate.pauseViewControllerPlayButton(self)
    }
    
}
