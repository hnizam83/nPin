import UIKit
import CoreData
import CoreSpotlight
import MobileCoreServices
import CryptoSwift

/**
 Data management class used by all the view controllers to create, read, update and delete pin code entries. Handles local and cloud storage.
  
  - Author: Hamza Nizameddin
  - Note: Provides a single management class for both cloud and local storage options. It achieves this by having two separate data stores for cloud and local storage. When the user toggles the iCloud Sync option in settings, this class handles the switch and copies or deletes data from one store to the other as instructed by the user.
 */
class DataStack
{
	
	// MARK: - Variables
	
	let cloudData = CloudCoreDataStack()
	let localData = LocalCoreDataStack()
	
	let indexDomainIdentifier: String = "com.nmash.nPin"
	
	var iCloudSync: Bool
	
	enum FetchType: String {
		case favorite = "favorite = YES"
		case nonFavorite = "favorite = NO"
		case all = ""
	}
	
	enum FetchSortKey: String {
		case lastAccessed = "lastAccessed"
		case order = "order"
		case none = ""
	}
	
	enum MergeOption {
		case keepLocalData
		case keepCloudData
	}
	
	// MARK: - Initializers
	
	/**
	 Class initializer. Must provide iCloudSync boolean to indicate whether local or cloud data is being used.
	  - Author: Hamza Nizameddin
	  - Parameter iCloudSync: Boolean indicating whether local or cloud data is being used.
	 */
	init(iCloudSync: Bool)
	{
		self.iCloudSync = iCloudSync
	}
	
	// MARK: - Save Context
	
	/**
	 Save CoreData context
	  - Author: Hamza Nizameddin
	 */
	func saveContext()
	{
		if iCloudSync {
			cloudData.saveContext()
		} else {
			localData.saveContext()
		}
	}
	
	// MARK: - CRUD
	/**
	 Retrieve list of cards.
	  - Author: Hamza Nizameddin
	  - Parameters:
	   - searchString: Optional. Defaults to empty string. String to search by name and digits.
	   - fetchType: Defaults to .all. Type of cards to fetch .favorite or .nonFavorite or .all.
	   - sortKey: Defaults to .none. Field to sort data, either .lastAccessed or .none or .none.
	  - Returns: List of Card objects.
	  - Note: Use as getCards() to retrieve a list of all stored card details. Use as getCards(searchString) with a search controller. Use as getCards(fetchType: .favorite, sortKey: .order) to get all the favorited card details as ordered by the user. Use as getCards(fetchType: .nonFavorite, sortKey: .lastAccessed) to get the non-favorited cards ordered by most to least recent.
	 */
	func getCards(with searchString: String? = "", type fetchType: FetchType = .all, orderBy sortKey: FetchSortKey = .none) -> [Card]
	{
		var cards = [Card]()

		let defaultAscending: [FetchSortKey:Bool] = [
			.lastAccessed: false,
			.order: true,
			.none: true
		]
		
		if iCloudSync
		{
			let cloudCards = cloudData.getCards(with: searchString, filter: fetchType.rawValue, sortKey: sortKey.rawValue, sortOrderAscending: defaultAscending[sortKey])
			for cloudCard in cloudCards {
				cards.append(Card(cloudCard: cloudCard))
			}
		}
		else
		{
			let localCards = localData.getCards(with: searchString, filter: fetchType.rawValue, sortKey: sortKey.rawValue, sortOrderAscending: defaultAscending[sortKey])
			for localCard in localCards {
				cards.append(Card(localCard: localCard))
			}
		}
		
		return cards
	}
		
/*	func getCards(with searchString: String?) -> [Card]
	{
		var cards = [Card]()
		if iCloudSync {
			let cloudCards = cloudData.getCards(with: searchString)
			for cloudCard in cloudCards {
				cards.append(Card(cloudCard: cloudCard))
			}
		} else {
			let localCards = localData.getCards(with: searchString)
			for localCard in localCards {
				cards.append(Card(localCard: localCard))
			}
		}
		return cards
	}*/
	
	/**
	 Delete specified card.
	  - Author: Hamza Nizameddin
	  - Parameter card: Card details to be deleted.
	  - Note: Uses either the card.cloudCard or cloud.localCard objects to delete the card from the proper CoreData container in use.
	 */
	func deleteCard(_ card: Card)
	{
		if iCloudSync {
			if let cloudCard = card.cloudCard {
				cloudData.deleteCard(cloudCard)
			}
		} else {
			if let localCard = card.localCard {
				localData.deleteCard(localCard)
			}
		}
		updateSpotlightIndex()
	}
	
	/**
	 Create new card details.
	  - Author: Hamza Nizameddin
	  - Parameters:
	   - digits: Requred. Last 4 digits of credit card.
	   - pin: Requred. 4-digit card pin code
	   - name: Optional. Card nickname for use when searching.
	   - lastAccessed: Optional. Defaults to nil. Last date time when card was accessed.
	   - favorite: Required.
	   - colorAsHex: Hex representation of card color stored as a string. For example, "#0F53A3"
	  - Returns: Boolean value indicating whether creating the card was successful or not. Discardable.
	 */
	@discardableResult
	func createCard(digits: String, pin: String, name: String?, order: Int16, lastAccessed: Date? = nil, favorite: Bool = false, colorAsHex: String? = Card.HexColor.lightBlue.rawValue) -> Bool
	{
		let safeColorAsHex = colorAsHex ?? Card.HexColor.lightBlue.rawValue
		let safeLastAccessed = lastAccessed ?? Date()
		var result: Bool = false
		if iCloudSync {
			result = cloudData.createCard(digits: digits, pin: pin, name: name, order: order, lastAccessed: safeLastAccessed, favorite: favorite, colorAsHex: safeColorAsHex) != nil
		} else {
			result = localData.createCard(digits: digits, pin: pin, name: name, order: order, lastAccessed: safeLastAccessed, favorite: favorite, colorAsHex: safeColorAsHex) != nil
		}
		updateSpotlightIndex()
		return result
	}
	
	/**
	 Update card details. Only specify the parameters that need to be updated.
	 - Author: Hamza Nizameddin
	 - Parameters:
	   - digits; Optional. Defaults to nil. Last 4 digits of credit card.
	   - pin: Optional. Defaults to nil. 4-digit pin code.
	   - name: Optionsl. Defaults to nil. Credit card nickname to be used when searching.
	   - order: Optional. Defaults to nil. Order in which the credit card should appear in the favorites list.
	   - lastAccessed: Optional. Defaults to nil. Date time when the card detail was last created, updated to accessed.
	   - favorite: Optional. Defaults to nil.
	   - colorAsHex: Optional. Defaults to nil. Hex representation of card color stored as a string. For example, "#0F53A3".
	 - Returns: Boolean value indicating whether update was successful or not. Discardable.
	 */
	@discardableResult
	func updateCard(card: Card, digits: String? = nil, pin: String? = nil, name: String? = nil, order: Int16? = nil, lastAccessed: Date? = nil, favorite: Bool? = nil, colorAsHex: String? = nil) -> Bool
	{
		var result: Bool = false
		
		if iCloudSync {
			if let cloudCard = card.cloudCard {
				result = cloudData.updateCard(card: cloudCard, digits: digits, pin: pin, name: name, order: order, lastAccessed: lastAccessed, favorite: favorite, colorAsHex: colorAsHex)
			}
		} else {
			if let localCard = card.localCard {
				result = localData.updateCard(card: localCard, digits: digits, pin: pin, name: name, order: order, lastAccessed: lastAccessed, favorite: favorite, colorAsHex: colorAsHex)
			}
		}
		updateSpotlightIndex()
		return result
	}
	
	// MARK: - Activate/Deactivate Cloud Sync
	/**
	 Activate iCloud synchronization.
	  - Author: Hamza Nizameddin
	  - Parameter mergeOption: Required. Either .keepLocalData or .keepCloudData.
	  - Note: The funciton will exit if the class variable iCloudSync is already set to true. It first sets class variable iCloudSync to true. If .keepCloudData is selected, all data from local CoreData store is deleted; the data from the cloud CoreData store is then used automatically. If .keepLocalData is selected then all data from the cloud CoreData store is deleted and all data from the local CoreData store is copied one by one to the cloud CoreData store. In the end, the Spotlight Index is updated.
	 */
	func activateCloudSync(mergeOption: MergeOption)
	{
		guard !iCloudSync else {return}
				
		if mergeOption == .keepCloudData
		{
			localData.reset()
			iCloudSync = true
		} else
		{
			let cards = self.getCards()
			iCloudSync = true
			cloudData.reset()
			for card in cards {
				cloudData.createCard(digits: card.digits, pin: card.pin, name: card.name, order: card.order, lastAccessed: card.lastAccessed ?? Date(), favorite: card.favorite, colorAsHex: card.colorAsHex)
			}
		}
		
		updateSpotlightIndex()
	}
	
	/**
	 Deactivate iCloud synchronization.
	  - Author: Hamza Nizameddin
	  - Parameter deleteCloudData: Required. Boolean value. If true, will delete all data in the cloud CoreData store.
	  - Note: This function will exit if the class variable iCloudSync is already set to false. It first gets a copy of all the data from the cloud CoreData store, then sets the class variable iCloudSync to false, then recopies all the entries one by one to the local DataStore. If deleteCloudData is set to true, it will delete all the data from the cloud CoreData store, making it inaccessible to any other devices logged into the same account. Finally, it will update the Spotlight Index.
	 */
	func deactivateCloudSync(deleteCloudData: Bool)
	{
		guard iCloudSync else {return}
		
		let cards = self.getCards()
		iCloudSync = false
		localData.reset()
		for card in cards {
			localData.createCard(digits: card.digits, pin: card.pin, name: card.name, order: card.order, lastAccessed: card.lastAccessed ?? Date(), favorite: card.favorite, colorAsHex: card.colorAsHex)
		}
		
		if deleteCloudData {
			cloudData.reset()
		}
		
		updateSpotlightIndex()
	}
	
	// MARK: - Spotlight Indexing Functions
	/**
	 Update the device Spotlight Index with all the entries that are favorited.
	  - Author: Hamza Nizameddin
	  - Note: This function will first delete all the old indexed entries. Then it will fetch all cards with the favorite attribute set to true and will add a new index entry for each card so that it can be searched by the digits or by its name.
	 */
	private func updateSpotlightIndex()
	{
		var items: [CSSearchableItem] = []
		
		CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [indexDomainIdentifier]) { error in
			if let error = error {
				print("Error deleting old index: \(error.localizedDescription)")
			} else {
				print("Successfully purged old index!")
			}
		}
		
		let cards = getCards(type: .favorite)
		for card in cards
		{
			if card.favorite
			{
				let attributeSet = CSSearchableItemAttributeSet(contentType: .text)
				attributeSet.title = card.digits
				attributeSet.contentDescription = card.name
				items.append(CSSearchableItem(uniqueIdentifier: card.digits, domainIdentifier: indexDomainIdentifier, attributeSet: attributeSet))
			}
		}
		
		CSSearchableIndex.default().indexSearchableItems(items) { error in
			if let error = error {
				print("Error indexing items: \(error.localizedDescription)")
			} else {
				print("Successfully created index!")
			}
		}
	}
	
	/**
	 Create a Spotlight Index entry for the specified card if it is favorited.
	  - Author: Hamza Nizameddin
	  - Parameter card: Card to be indexed.
	  - Note: The function will exit if the card is not favorited. Otherwise, it will create an index entry for the card using the last 4 digits and the name.
	 */
	private func index(card: Card)
	{
		//make sure that the card is a favorite
		guard card.favorite else {return}
		
		let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
		attributeSet.title = card.digits
		attributeSet.contentDescription = card.name
		
		let item = CSSearchableItem(uniqueIdentifier: card.digits, domainIdentifier: indexDomainIdentifier, attributeSet: attributeSet)
		CSSearchableIndex.default().indexSearchableItems([item]) { error in
			if let error = error {
				print("Indexing Error: \(error.localizedDescription)")
			} else {
				print("Search item successfully indexed!")
			}
		}
		
	}
	
	/**
	 Delete a Spotlight Index entry for the specified card if it is not favorited.
	  - Author: Hamza Nizameddin
	  - Parameter card: Card to be removed from index.
	  - Note: The function will exit if the card is favorited. Otherwise, it will delete the index entry for the card.
	 */
	private func deindex(card: Card)
	{
		//make sure the card isn't a favorite
		guard !card.favorite else {return}
		
		CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [card.digits]) { error in
			if let error = error {
				print("De-Indexing Error: \(error.localizedDescription)")
			} else {
				print("Search item successfully de-indexed!")
			}
		}
	}
	
	// MARK: - Helper Functions
	
	/**
	 Delete all data in the currently used CoreData store.
	  - Author: Hamza Nizameddin
	  - Note: If class variable iCloudSync is true, will reset the cloud CoreData store. Otherwise it will reset the local CoreData store. Finally, the Spotlight Index will be updated to delete all indexed entries.
	 */
	func reset()
	{
		if iCloudSync {
			cloudData.reset()
		} else {
			localData.reset()
		}
		updateSpotlightIndex()
	}
	
	/**
	 Delete all data in the cloud and local CoreData stores.
	  - Authod: Hamza Nizameddin
	  - Note: This function will delete all data from both local and cloud CoreData stores. Finally, the Spotlight Index will be updated to delete all indexed entries.
	 */
	func resetAll()
	{
		cloudData.reset()
		localData.reset()
		updateSpotlightIndex()
	}
	
	/**
	 Computed property. Return total number of stored entries.
	  - Author: Hamza Nizameddin
	 */
	var count: Int
	{
		get {
			return self.getCards().count
		}
	}
	
	/**
	 Tests whether a 4-digit card already exists in the database.
	  - Author: Hamza Nizameddin
	  - Parameter digits: Optional. 4-digit card ending to test.
	  - Returns: True if the 4-digit entry already exists in the database. False otherwise.
	  - Note: This digit first tests if the input is nil, in which case it immediately returns true. Otherwise, it retrieves a list of cards with the searchText = digits. Then it checks the results to see if there is a match to the input.
	 */
	func digitsExist(_ digits: String?) -> Bool
	{
		guard let digits = digits else {return true}
		let cards = self.getCards(with: digits)
		if cards.count > 0 {
			for card in cards {
				if card.digits == digits {return true}
			}
		}
		return false
	}
}
