//
//  Card+Extension.swift
//  nPin
//
//  Created by Hamza Nizameddin on 13/08/2021.
//

import Foundation
import CoreData

/**
 CloudCard entity for storage in iCloud Core Data.
  - Authors: Hamza Nizameddin
 */
extension CloudCard
{
	static var size = 4
	
	/**
	 Get a fetch request with the input search string, sorted by the 'order' attribute.
	  - Authors: Hamza Nizameddin
	  - Parameter searchString: Optional. Search string to run a query based on the 'name' and 'digits' attributes.
	  - Returns: The fetch request.
	 */
	@nonobjc public class func fetchRequest(with searchString: String?) -> NSFetchRequest<CloudCard>
	{
		let request = NSFetchRequest<CloudCard>(entityName: "CloudCard")
		let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
		request.sortDescriptors = [sortDescriptor]
		if let safeSearchString = searchString,
		   safeSearchString.count > 0 {
			request.predicate = NSPredicate(format: "name CONTAINS[c] %@ || digits CONTAINS[c] %@", safeSearchString, safeSearchString)
		}
		return request
	}
	
	/**
	 Convenience Initializer that creates 9 random fake pins.
	 */
	convenience init()
	{
		self.init()
		initializeFakePins()
	}
	
	/**
	 Create random fake pins and add them as an array to the CloudCard entity.
	  - Authors: Hamza Nizameddin
	  - Parameter count: Number of fake pins to create. Defaults to 9.
	 */
	public func initializeFakePins(count: Int = 0)
	{
		if self.fakePins == nil {
			var fakePinsArray: [String] = []
			for _ in 0...count {
				fakePinsArray.append(CloudCard.generateRandomPin())
			}
			self.fakePins = NSArray(array: fakePinsArray)
		}
	}
	
	/**
	 Generate a random PIN code.
	  - Authors: Hamza NIzameddin
	  - Parameter length: Lenght of the random PIN code. Defaults to 4.
	 */
	static public func generateRandomPin(_ length: Int = 4) -> String
	{
		var fakePin: String = ""
		for _ in 1...length
		{
			fakePin += String(Int.random(in: 0...9))
		}
		return fakePin
	}
}
