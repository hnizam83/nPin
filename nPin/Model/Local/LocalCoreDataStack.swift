//
//  LocalCoreDataStack.swift
//  nPin
//
//  Created by Hamza Nizameddin on 01/09/2021.
//

import Foundation
import CoreData

/**
 Core Data Stack for the Cloud- based Core Data Store.
  - Authors: Hamza Nizameddin
 */
class LocalCoreDataStack
{
	
	// MARK: - Variables
	/**
	 Persistent Core Data container
	 */
	let container : NSPersistentContainer =
		{
			let container = NSPersistentContainer(name: "nPinLocal")
			container.loadPersistentStores(completionHandler: { (storeDescription, error) in
				if let error = error as NSError? {
					fatalError("Unresolved error \(error), \(error.userInfo)")
				}
			})
			container.viewContext.automaticallyMergesChangesFromParent = true
			return container
	}()
	
	/**pin attribute length.*/
	let pinSize = nPin.pinSize
	/**digits attribute length.*/
	let digitsSize = nPin.digitsSize
	
	// MARK: - Save Context
	/**
	 Save the Core Data context.
	 */
	public func saveContext()
	{
		let context = self.container.viewContext
		guard context.hasChanges else { return }
		do {
			try context.save()
		} catch {
			let nserror = error as NSError
			print("Error saving context: \(nserror), \(nserror.userInfo)")
		}
	}
		
	// MARK: - CRUD
	
	/**
	 Fetch cards from the Core Data store.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - searchString: String to be searched in the 'name' and 'digits' attributes.
	   - filter: Optional. Defaults to nil. Filter string to filter search results.
	   - sortKey: Optional. Defaults to nil. Attribute name to sort the results by.
	   - sortAscendingOrder: Optional. Defaults to nil. True to sort results in ascending order, false otherwise.
	  - Returns: List of CloudCard objects filtered by the search string, filter and sorted according to the sort key.
	 */
	public func getCards(with searchString: String? = nil, filter: String? = nil, sortKey: String? = nil, sortOrderAscending: Bool? = nil) -> [LocalCard]
	{
		let context = self.container.viewContext
		var cards = [LocalCard]()
		
		let request = NSFetchRequest<LocalCard>(entityName: "LocalCard")
		var predicates = [NSPredicate]()
		
		if let searchString = searchString, searchString.count > 0 {
			predicates.append(NSPredicate(format: "name CONTAINS[c] %@ || digits CONTAINS[c] %@", searchString, searchString))
		}
		
		if let filter = filter, filter.count > 0 {
			predicates.append(NSPredicate(format: filter))
		}
		
		if let sortKey = sortKey, sortKey.count > 0, let sortOrderAscending = sortOrderAscending {
			request.sortDescriptors = [NSSortDescriptor(key: sortKey, ascending: sortOrderAscending)]
		}
		
		request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
		
		do {
			cards = try context.fetch(request)
		} catch {
			print("Error fetching request!")
		}
		
		return cards
	}
	
	/**
	 Delete a card from the Core Data store.
	  - Authors: Hamza Nizameddin
	  - Parameter cloudCard: Card to be deleted
	 */
	public func deleteCard(_ localCard: LocalCard)
	{
		self.container.viewContext.delete(localCard)
		self.saveContext()
	}
	
	/**
	 Create a new card in the the Core Data store.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - digits: Last 4 digits of the credit card.
	   - pin: 4-digit PIN code.
	   - name: Optional. Card nickname.
	   - order: Display order in the favorite section.
	   - lastAccessed: Defaults to current Date(). Date the card was last accessed.
	   - favorite: Defaults to false. Indicates if the card is listed in the favorite section or not.
	   - colorAsHex: Color of the card represented as a hexadecimal string.
	  - Returns: Discardable. If the card is successfully created, returns the new CloudCard object instantiated. Otherwise returns nil.
	  - Note: The function first ensures that the digits don't already exist, that the length of digits and pin code is equal to digitSize and pinSize, and that the order is a positive integer. If all these conditions are met, a new CloudCard object is instantiated, stored in Core Data and returned, also calls saveContext(). Otherwise, it will return nil.
	 */
	@discardableResult
	public func createCard(digits: String, pin: String, name: String?, order: Int16, lastAccessed: Date = Date(), favorite: Bool = false, colorAsHex: String) -> LocalCard?
	{
		guard !digitsExist(digits) else {return nil}
		guard digits.count == digitsSize else {return nil}
		guard pin.count == pinSize else {return nil}
		guard order >= 0 else {return nil}
		
		let card = LocalCard(context: self.container.viewContext)
		
		card.digits = digits
		card.pin = pin
		card.name = name
		card.order = order
		card.lastAccessed = lastAccessed
		card.favorite = favorite
		card.colorAsHex = colorAsHex
		card.initializeFakePins()
		
		self.saveContext()
		return card
	}
	
	/**
	 Update a Cloud Card entity in the Core Data store. All parameters are optional and default to nil, so only the attributes that need to be modified need to be set.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - digits: Optional. Defaults to nil. Last 4 digits of the credit card.
	   - pin: Optional. Defaults to nil. 4-digit PIN code.
	   - name: Optional. Defaults to nil.  Card nickname.
	   - order: Optional. Defaults to nil. Display order in the favorite section.
	   - lastAccessed: Optional. Defaults to nil. Date the card was last accessed.
	   - favorite: Optional. Defaults to nil. Indicates if the card is listed in the favorite section or not.
	   - colorAsHex: Optional. Defaults to nil. Color of the card represented as a hexadecimal string.
	  - Returns: Discardable. True if the new values are correct and the card is successfully updated.
	  - Note: Any parameter that is not set defaults to nil and isn't modified. The function first ensures that the digits all the parameters set are correct; otherwise, it will return false. In the end, it will call saveContext.
	 */
	@discardableResult
	public func updateCard(card: LocalCard, digits: String? = nil, pin: String? = nil, name: String? = nil, order: Int16? = nil, lastAccessed: Date? = nil, favorite: Bool? = nil, colorAsHex: String? = nil) -> Bool
	{
		if let digits = digits, digits != card.digits && digitsExist(digits) {
			return false
		}
		
		if let digits = digits, !digitsExist(digits) && digits.count == nPin.digitsSize {
			card.digits = digits
		}
		
		if let pin = pin, pin.count == nPin.pinSize {
			card.pin = pin
		}
		
		card.name = name ?? card.name
		
		if let order = order, order >= 0 {
			card.order = order
		}
		
		card.lastAccessed = lastAccessed ?? card.lastAccessed
		
		card.favorite = favorite ?? card.favorite
		
		card.colorAsHex = colorAsHex ?? card.colorAsHex
		
		self.saveContext()
		return true
	}
	
	// MARK: - Reset
	/**
	 Delete all data in the Core Data store.
	  - Authors: Hamza Nizameddin
	 */
	public func reset()
	{
		let cards = self.getCards()
		for card in cards {
			self.container.viewContext.delete(card)
		}
		self.saveContext()
	}
	
	// MARK: - Helper Functions
	/**
	 Returns the total number of cards stored in the Core Data store.
	 */
	public var count: Int
	{
		get {
			return self.getCards().count
		}
	}
	
	/**
	 Check if the input digits already exists in the Core Data store.
	  - Authors: Hamza Nizameddin
	  - Parameter digits: Last 4-digits to be checked.
	  - Returns: True if the digits already belong to a card in the Core Data store. False otherwise.
	 */
	public func digitsExist(_ digits: String?) -> Bool
	{
		guard let digits = digits else {return false}
		guard digits.count > 0 else {return false}
		let cards = self.getCards(with: digits)
		for card in cards {
			if card.digits == digits {
				return true
			}
		}
		return false
	}
}
