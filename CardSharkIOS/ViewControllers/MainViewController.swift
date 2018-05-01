//
//  MainViewController.swift
//  CardSharkIOS
//
//  Created by Rich Ruais on 4/28/18.
//  Copyright © 2018 Rich Ruais. All rights reserved.
//

import UIKit
import PromiseKit

class MainViewController: UIViewController {

    @IBOutlet weak var createDeckBtn: UIButton!
    
    let viewModel = CardsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        removeImagesFromDB()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func createDeck(_ sender: UIButton) {
        viewModel.setupDeck()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCards" {
            let vc = segue.destination as! CardsViewController
            vc.viewModel = viewModel
        }
    }
    
    func removeImagesFromDB() {
        viewModel.removeImages()
    }
    
    func setupView() {
        createDeckBtn.layer.cornerRadius = 10
    }

}
