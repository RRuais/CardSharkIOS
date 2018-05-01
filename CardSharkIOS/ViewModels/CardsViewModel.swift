//
//  CardsViewModel.swift
//  CardSharkIOS
//
//  Created by Rich Ruais on 4/28/18.
//  Copyright © 2018 Rich Ruais. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage
import CoreData
import PromiseKit

class CardsViewModel {
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private var deckID: String?
    private var cards = [Card]()
    private var isLoading = false
    private let doneLoadingNotificationKey = "co.cardShark.isLoading"
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // Initial setup for Deck
    func setupDeck() {
        isLoading = true
    
        firstly {
            self.createDeck()
        }
        .then{ response in
            self.shuffleDeck()
        }
        .then{ response in
            self.fetchDeck()
        }
        .then{ response in
            self.fetchAndSaveImages()
        }
        .then{ response in
            self.postDoneLoadingNotification()
        }
        .catch{ error in
            print(error)
        }
    }
    
    func reshuffleAndFetch() {
        firstly {
            self.shuffleDeck()
        }
        .then{ response in
            self.fetchDeck()
        }
        .then{ response in
            self.postDoneLoadingNotification()
        }
        .catch{ error in
            print(error)
        }
    }
    
    private func createDeck() -> Promise<String> {
        
        return Promise<String>{ fulfill, reject in
            let urlString = "https://deckofcardsapi.com/api/deck/new/"
            let url = URL(string: urlString)
            
            Alamofire.request(url!).responseJSON { response in
                guard let json = response.result.value as? [String:Any] else { return }
                guard let id = json["deck_id"] as? String else { return }
                self.deckID = id
                fulfill("Success")
            }
        }
    }
    
    private func shuffleDeck() -> Promise<String> {
        
        return Promise<String>{ fulfill, reject in
            let urlString = "https://deckofcardsapi.com/api/deck/\(deckID!)/shuffle"
            let url = URL(string: urlString)
            Alamofire.request(url!).responseJSON { response in
                guard let json = response.result.value as? [String:Any] else { return }
                guard let shuffled = json["shuffled"] as? Bool else { return }
                if shuffled {
                    fulfill("success")
                } else {
                    reject(NetworkingErrors.errorLoadingData)
                }
            }
        }
       
    }
    
    private func fetchDeck() -> Promise<String> {
        
        return Promise<String>{ fulfill, reject in
            cards.removeAll()
            let urlString = "https://deckofcardsapi.com/api/deck/\(deckID!)/draw/?count=52"
            let url = URL(string: urlString)
            
            Alamofire.request(url!).responseJSON { response in
                guard let json = response.result.value as? [String:Any] else { return }
                guard let jsonData = json["cards"] as? [[String:Any]] else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let data = try JSONSerialization.data(withJSONObject: jsonData, options: JSONSerialization.WritingOptions.prettyPrinted)
                    let newCards = try! decoder.decode([Card].self, from: data)
                    self.cards.append(contentsOf: newCards)
                    fulfill("success")
                } catch {
                    reject(NetworkingErrors.errorLoadingData)
                }
            }
        }
    }
    
    // MARK: - CoreData Methods
    
    private func fetchAndSaveImages() -> Promise<String> {
        return Promise<String>{ fulfill, reject in
            for card in cards {
                Alamofire.request(card.image).responseImage { response in
                    if let image = response.result.value {
                        let imageData = UIImagePNGRepresentation(image) as! NSData
                        let context = self.appDelegate.persistentContainer.viewContext
                        let entity =
                            NSEntityDescription.entity(forEntityName: "Image",
                                                       in: context)!
                        let imageToSave = NSManagedObject(entity: entity,
                                                          insertInto: context)
                        imageToSave.setValue(card.code, forKeyPath: "name")
                        imageToSave.setValue(imageData, forKey: "data")
                        do {
                            try context.save()
                        } catch let error as NSError {
                            print("Could not save. \(error), \(error.userInfo)")
                        }
                        
                    }
                }
            }
            fulfill("success")
        }
    }
    
    func loadImages(name: String) -> UIImage? {
        let context =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Image")
        fetchRequest.predicate = NSPredicate(format: "name = %@", name)
        do {
            let images = try context.fetch(fetchRequest)
            guard let image: Image = images.first as? Image else { return nil }
            let newImage = UIImage(data: image.data!)
            return newImage
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        return nil
    }
    
    func removeImages() {
        let managedContext =
            appDelegate.persistentContainer.viewContext
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Image")
        do {
            let images = try managedContext.fetch(fetchRequest)
            if images.count > 0 {
                for image in images {
                    managedContext.delete(image)
                }
            }
            
        } catch {}
    }
    
    func rearrangeCards() {
        var tempCards = cards
        var newCards = [Card]()
        var suits = ["CLUBS", "HEARTS", "SPADES", "DIAMONDS" ]
        var index = 0
        while newCards.count < 52 {
            if index == suits.count {
                index = 0
            }
            for card in tempCards {
                if card.suit == suits[index] {
                    newCards.append(card)
                    let cardIndex = tempCards.index(of: card)
                    tempCards.remove(at: cardIndex!)
                    index += 1
                    break
                }
            }
        }
        cards = newCards
        customPrint()
    }
    
    // Custom Print excluding Kings, Queens, Jacks, Aces
    func customPrint() {
        var cardCodes = [String]()
        for card in cards {
            cardCodes.append(card.code)
        }
        let chars = ["K","J","Q","A"]
        for code in cardCodes {
            let index = cardCodes.index(of: code)
            for char in chars {
                if code.contains(char) {
                    cardCodes.remove(at: index!)
                }
            }
        }
        print("Rearranged Card Codes : \(cardCodes)")
    }
    
    func postDoneLoadingNotification() {
        self.isLoading = false
        let notificationName = Notification.Name(self.doneLoadingNotificationKey)
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
    
    // Getters
    
    func getCardCount() -> Int {
        return cards.count
    }
    
    func getCards() -> [Card] {
        return cards
    }
    
    func checkLoadingStatus() -> Bool {
        return isLoading
    }
    
    func getLoadingNotificationKey() -> String {
        return doneLoadingNotificationKey
    }
    
}
