//
//  Item.swift
//  drinkpulse
//
//  Created by Dawid Haniewicz on 16.05.26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
