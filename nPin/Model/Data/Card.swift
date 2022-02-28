//
//  Card.swift
//  nPin
//
//  Created by Hamza Nizameddin on 29/08/2021.
//

import Foundation
import UIKit

/**
 Card class representing a credit card entry in the app.
  - Author: Hamza NIzameddin
  - Note: This class is used with both the cloud and local CoreData stores to handle all inputs from and displays to the view controllers. It has pointers to either the corresponding CoreData in the local DataCore store or the CloudCard in the cloud CoreData store depending on which store is currently in use. Can be initialized using either a LocalCard or a CloudCard.
 */
class Card
{
	var digits: String
	var pin: String
	var name: String?
	var fakePins: [String]?
	var order: Int16
	var lastAccessed: Date?
	var favorite: Bool
	var colorAsHex: String
	
	var cloudCard: CloudCard?
	var localCard: LocalCard?
	
	/**
	 Generic initializer. Sets all the parameters to empty strings or false.
	 */
	init()
	{
		digits = ""
		pin = ""
		order = 0
		favorite = false
		colorAsHex = HexColor.lightBlue.rawValue
	}
	
	/**
	 Initializer to be used with cloud CoreData store.
	 - Author: Hamza Nizameddin
	 - Parameter cloudCard: The CloudCard managed NSObject used to populate this Card object.
	 - Note: The initializer will copy all the parameters from the CloudCard to this Card object as well as a pointer to the original CloudCard.
	 */
	init(cloudCard: CloudCard)
	{
		digits = cloudCard.digits!
		pin = cloudCard.pin!
		name = cloudCard.name
		if let cloudFakePins = cloudCard.fakePins {
			fakePins = []
			for cloudFakePin in cloudFakePins {
				fakePins!.append(cloudFakePin as! String)
			}
		}
		order = cloudCard.order
		lastAccessed = cloudCard.lastAccessed
		favorite = cloudCard.favorite
		colorAsHex = cloudCard.colorAsHex ?? Card.HexColor.lightBlue.rawValue
		
		self.cloudCard = cloudCard
	}
	
	/**
	 Initializer to be used with local CoreData store.
	 - Author: Hamza Nizameddin
	 - Parameter localCard: The LocalCard managed NSObject used to populate this Card object.
	 - Note: The initializer will copy all the parameters from the LocalCard to this Card object as well as a pointer to the original LocalCard.
	 */
	init(localCard: LocalCard)
	{
		digits = localCard.digits!
		pin = localCard.pin!
		name = localCard.name
		if let localFakePins = localCard.fakePins {
			fakePins = []
			for localFakePin in localFakePins {
				fakePins!.append(localFakePin as! String)
			}
		}
		order = localCard.order
		lastAccessed = localCard.lastAccessed
		favorite = localCard.favorite
		if let safeColorAsHex = localCard.colorAsHex {
			colorAsHex = safeColorAsHex
		} else {
			colorAsHex = HexColor.lightBlue.rawValue
		}
		
		self.localCard = localCard
	}
	
	/**
	 Generate random pin code with specified length.
	  - Author: Hamza Nizameddin
	  - Parameter length: Defaults to 4. Length of the random pin code.
	 */
	static func generateRandomPin(_ length: Int = 4) -> String
	{
		var fakePin: String = ""
		for _ in 1...length {
			fakePin += String(Int.random(in: 0...9))
		}
		return fakePin
	}
	
	// MARK: - Colors
	enum HexColor: String, CaseIterable
	{
		case darkBlue = "#3b556e"
		case lightBlue = "#4fc1db"
		case red = "#df3512"
		case gold = "#eca11f"
		case silver = "#aaa9ad"
		case black = "#231f20"
		case green = "#629f86"
	}
	
	/**
	 Computer variable to get UIColor object from local class variable colorAsHex
	 */
	var color: UIColor {
		return UIColor(hex: colorAsHex)!
	}
}
