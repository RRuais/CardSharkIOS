//
//  CardsViewController.swift
//  CardSharkIOS
//
//  Created by Rich Ruais on 4/28/18.
//  Copyright © 2018 Rich Ruais. All rights reserved.
//

import UIKit

class CardsViewController: UIViewController {

    @IBOutlet weak var cardsCollectionView: UICollectionView!
    @IBOutlet weak var shuffleBtn: UIButton!
    @IBOutlet weak var arrangeBtn: UIButton!
    
    var indicatorView: UIActivityIndicatorView?
    var darkBackgroundView = UIView()

    var viewModel: CardsViewModel! = nil
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupCollectionView()
        setupLoadingIndicator()
        setupLoadingObserver()
        checkViewModelLoading()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        shuffleBtn.layer.cornerRadius = 10
        arrangeBtn.layer.cornerRadius = 10
    }
    
    @IBAction func shuffle(_ sender: UIButton) {
        addIndicator()
        viewModel.reshuffleAndFetch()
    }
    
    @IBAction func arrange(_ sender: UIButton) {
        viewModel.rearrangeCards()
        cardsCollectionView.reloadData()
    }
    
    func checkViewModelLoading() {
        if viewModel.checkLoadingStatus() {
            addIndicator()
        }
    }
    
}

extension CardsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func setupCollectionView() {
        cardsCollectionView.delegate = self
        cardsCollectionView.dataSource = self
        cardsCollectionView.backgroundColor = UIColor.clear
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.getCardCount()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CardCollectionViewCell", for: indexPath) as? CardCollectionViewCell
        let cards = viewModel.getCards()
        let image = viewModel.loadImages(name: cards[indexPath.row].code)
        cell?.cardImageView.image = image ?? #imageLiteral(resourceName: "placeholder")
        
        return cell!
    }
    
}

// Loading Indicator Methods

extension CardsViewController {
    func setupLoadingIndicator() {
        // Setup BackgroundView
        darkBackgroundView.backgroundColor = UIColor.black
        darkBackgroundView.alpha = 0.5
        darkBackgroundView.frame = self.view.frame
        darkBackgroundView.isHidden = true
        cardsCollectionView.addSubview(darkBackgroundView)
        
        // Setup Indicator
        indicatorView = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        indicatorView?.frame = cardsCollectionView.frame
        indicatorView?.hidesWhenStopped = true
        indicatorView?.activityIndicatorViewStyle =
            UIActivityIndicatorViewStyle.whiteLarge
        cardsCollectionView.addSubview(self.indicatorView!)
        indicatorView?.isHidden = true
    }
    
    func addIndicator() {
        darkBackgroundView.isHidden = false
        indicatorView?.isHidden = false
        indicatorView?.startAnimating()
    }
    
    @objc func removeIndicator() {
        darkBackgroundView.isHidden = true
        indicatorView?.isHidden = true
        indicatorView?.stopAnimating()
        DispatchQueue.main.async {
            self.cardsCollectionView.reloadData()
        }
    }
    
    func setupLoadingObserver() {
        let notificationName = Notification.Name(viewModel.getLoadingNotificationKey())
        NotificationCenter.default.addObserver(self, selector: #selector(CardsViewController.removeIndicator), name: notificationName, object: nil)
    }
}
