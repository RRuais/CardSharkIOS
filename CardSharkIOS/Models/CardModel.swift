//
//  CardModel.swift
//  CardSharkIOS
//
//  Created by Rich Ruais on 4/28/18.
//  Copyright © 2018 Rich Ruais. All rights reserved.
//

import Foundation

struct Card: Codable {
    let image: String
    let suit: String
    let value: String
    let code: String
}

extension Card: Equatable {
    static func == (lhs: Card, rhs: Card) -> Bool {
        return
            lhs.suit == rhs.suit && lhs.value == rhs.value && lhs.code == rhs.code && lhs.image == rhs.image
    }
}
