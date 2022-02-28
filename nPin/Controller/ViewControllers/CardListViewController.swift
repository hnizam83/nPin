//
//  ListTableViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 19/07/2021.
//

import UIKit
import CoreData

/**
Table View controller class to display, delete and organize stored pin codes
 
 - Authors: Hamza Nizameddin
 - Note: Displays all pin code entries (nickname + last 4 digits), favorites in the first section and others in the second section. The entries in the favorite section can be arranged by the user. The entries in the second section are organized by most recently viewed/edited/created. If there are no favorite entries, then only one section is displayed. The search bar allows the user to search by name and last digits simultaneously and will return only one section with the search results. In non-editing mode, pressing on an entry will display its pin code using DisplayViewController. In editing mode, pressing on an entry will show a CarViewController to edit it. Right swipe toggles and entry's favorite status and left swipe deletes it. There is a bar button at the top right to create a new entry.
*/

class CardListViewController: UITableViewController
{
	// MARK: - IBOutlets
	/**Add new credit card UIBarButton displayed on the right side of the navigation bar.*/
	@IBOutlet weak var addButton: UIBarButtonItem!
	
	//MARK: - Variables
	/**UISearchController to display the search bar.*/
	private var searchController = UISearchController(searchResultsController: nil)
	/**Array of Arrays of credit card entries displayed in the TableView. If only one array is present, it is displayed under a single section titled "Cards" (in case there are not favorite cards, or listing search results). If there are two arrays present, the first one is the favorites array displayed in a section titled "Favorites" and ordered by the order attribute. The second array is displaced under a section titled "Recent" and ordered by the last time they were accessed.*/
	private var cards: [[Card]] = [[Card]]()
	/**Card selected in the TableView*/
	private var selectedCard: Card?
	
	/**Shared application-wide DataStack.*/
	private let data = (UIApplication.shared.delegate as! AppDelegate).data
	/**Computed variable. Returns true if there is text in the search bar.*/
	private var isSearching: Bool {
		return (searchController.searchBar.text?.isEmpty ?? false) && searchController.isActive
	}
	
	/**SFSymbol name for the delete left swipe action*/
	let trailingSwipeActionDeleteImageName = nPin.trailingSwipeActionDeleteImageName
	/**SFSymbol name for the favorite right swipe action*/
	let leadingSwipeActionFavoriteImageName = nPin.leadingSwipeActionFavoriteImageName
	/**SFSymbol name for the un-favorite right swipte action*/
	let leadingSwipeActionNonFavoriteImageName = nPin.leadingSwipeActionNonFavoriteImageName
		
	// MARK: - View Controller Life Cycle
	
	/**
	 Overrides viewDidLoad function.
	  - Authors: Hamza Nizameddin
	  - Note: Enables the left bar button item as the edit button. Allows selection during editing in order to edit a card when selected in Edit mode instead of displaying its PIN code. Sets up the searchController. Sets up the refreshControl.
	 */
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
        self.navigationItem.leftBarButtonItem = self.editButtonItem
		self.tableView.allowsSelectionDuringEditing = true
		
		self.searchController.searchResultsUpdater = self
		self.searchController.obscuresBackgroundDuringPresentation = false
		self.searchController.searchBar.placeholder = "Search Cards"
		navigationItem.searchController = searchController
		definesPresentationContext = true
		self.searchController.hidesNavigationBarDuringPresentation = false
		
		self.refreshControl = UIRefreshControl()
		self.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
    }
	
	/**
	 Overrides viewWillAppear function.
	  - Authors: Hamza Nizameddin
	  - Note: Sets the search bar text to an empty string. Loads the data from the data store to display it in the table view.
	 */
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		searchController.searchBar.text = ""
		loadData()
	}
	
	// MARK: - Data Management
	/**
	 Load the data from the data store into the cards array.
	  - Authors: Hamza Nizameddin
	  - Note: If there is no text in the search bar, this function will load all the favorite credit cards and then all the non-favorite ones in two lists in the cards variable. If there is text in the search bar, it will load only the credit cards whose digits or name match the search text into one list in the cards variable.
	 */
	func loadData()
	{
		guard let searchText = searchController.searchBar.text else {return}
		
		cards = [[Card]]()
		if searchText.count == 0 {
			cards.append(data.getCards(with: "", type: .favorite, orderBy: .order))
			cards.append(data.getCards(with: "", type: .nonFavorite, orderBy: .lastAccessed))
			if cards[0].isEmpty {
				cards.remove(at: 0)
			}
		} else {
			cards.append(data.getCards(with: searchText, type: .all, orderBy: .lastAccessed))
		}
		self.tableView.reloadData()
	}

	// MARK: - Event Handlers
	/**
	 Event handler for when the add bar button is pressed.
	  - Authors: Hamza Nizameddin
	  - Note: Sets the selectedCard variable to nil and performs the segue to the Card View Controller to create a new credit card entry.
	 */
	@IBAction func addButtonPressed(_ sender: Any)
	{
		selectedCard = nil
		performSegue(withIdentifier: nPin.listToEditSegue, sender: self)
	}
	/**
	 Event handler for when the table view is pulled down to refresh the data.
	  - Authors: Hamza Nizameddin
	  - Note: If the table is in editing mode, returns without doing anything. Otherwise, calls the refreshControl beginRefreshing() function, waits for a second and reloads the data and calls endRefreshing().
	 */
	@objc func pullToRefresh()
	{
		guard !tableView.isEditing else {return}
		self.refreshControl?.beginRefreshing()
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			self.loadData()
			self.refreshControl?.endRefreshing()
		}
	}
	
	
    // MARK: - Table view data source
	/**
	 Overrides the tableView numberOfSections function. Returns how many arrays are stored in the cards variable.
	  - Authors: Hamza Nizameddin
	  - If the cards variable contains just one array, as in the case of a search or no defined favorite credit cards, then only one section will be displayed titled "Cards". If two arrays are defined, two sections are displayed. The first is titled "Favorite" and lists all the favorite credit cards by the order set by the user. The second is titled "Recent" and lists all the non-favorite credit cards ordered by when they were last accessed.
	 */
    override func numberOfSections(in tableView: UITableView) -> Int
	{
		cards.count
    }
	
	/**
	 Overrides the tableView numberOfRowsInSection function. Returns the number of elements in each array store in the cards variable.
	  - Authors: Hamza Nizameddin
	 */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return cards[section].count
    }
    
	/**
	 Overrides the tableView cellForRowAt function. Retrieves the name and digits attributes from the card in the cards variable and displays them as a title and subtitle respectively.
	  - Authors: Hamza Nizameddin
	 */
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		let cell = tableView.dequeueReusableCell(withIdentifier: nPin.listCellId, for: indexPath)
				
		let card = cards[indexPath.section][indexPath.row]
		
		cell.textLabel?.text = card.name
		cell.detailTextLabel?.text = card.digits
		cell.imageView?.tintColor = UIColor(hex: card.colorAsHex)
		
        return cell
    }
    
    /**
	 Overrides the tableView canEditRowAt function. Always returns true to indicate all rows are editable.
	  - Authors: Hamza Nizameddin
	 */
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    /**
	 Overrides the tableView moveRowAt function. Only works for the favorites section in order to arrange the favorite cards in the order requested by the user.
	  - Authors: Hamza Nizameddin
	  - Note: First ensures that both the form the to rows are both in the favorites section; otherwise, it returns without doing anything. Then moves the rows in the table and store the new order for all the favorite cards in the data store.
	 */
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath)
	{
		guard fromIndexPath.section == 0 && to.section == 0 else {return}
		
		let temp = self.cards[fromIndexPath.section][fromIndexPath.row]
		self.cards[fromIndexPath.section].remove(at: fromIndexPath.row)
		self.cards[to.section].insert(temp, at: to.row)
		
		//update the order attribute in Card so that the ordering is stored in Core Data
		if cards.count > 0 {
			for i in 0..<self.cards[0].count {
				self.data.updateCard(card: cards[0][i], order: Int16(i))
			}
		}
		
		tableView.reloadData()
    }
	
	/**
	 Override the tableView targetIndexPathForMoveFromRowAt function. Called just before moveRowAt to prevent user from moving a row except if it is from the favorite section to the favorite section.
	  - Authors: Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath
	{
		if sourceIndexPath.section != 0 || proposedDestinationIndexPath.section != 0 {
			return sourceIndexPath
		} else {
			return proposedDestinationIndexPath
		}
	}
    
    /**
	 Overrides the tableView canMoreRowAt function. Prevents user from moving any row while a search is ongoing, or any row that isn't in the favorite section.
	 */
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
	{
		// cannot rearrange while searching
		if let searchText = searchController.searchBar.text, searchText.count > 0 {
			return false
		}
		
		// can only rearrange in the first section (favorite)
		if indexPath.section == 0 {
			return true
		} else {
			return false
		}
    }
	
	/**
	 Overrides the tableView trailingSwipeActionsConfigurationForRowAt function. Sets the swipe left action to delete and displays a trash SFSymbol for that action.
	  - Authors: Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		let deleteAction = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Title for delete action"))
		{[weak self] _, _, completionHandler in
			guard let self = self else {return}
			// Delete the row from the data source
			self.data.deleteCard(self.cards[indexPath.section][indexPath.row])
			self.cards[indexPath.section].remove(at: indexPath.row)
			
			// update the order attribute in the favorite cards so that the ordering is stored in Core Data
			for i in 0..<self.cards[0].count {
				self.cards[0][i].order = Int16(i)
			}
			
			// delete the row from the table view
			tableView.deleteRows(at: [indexPath], with: .fade)
			self.tableView.reloadData()
			
			completionHandler(true)
		}
		deleteAction.image = UIImage(systemName: trailingSwipeActionDeleteImageName)
		
		return UISwipeActionsConfiguration(actions: [deleteAction])
	}
	
	/**
	 Overrides the tableView leadingSwipeActionsConfigurationForRowAt function. Sets the swipe right action to toggle the favorite status of the selected card.
	  - Authors: Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
	{
		let card = cards[indexPath.section][indexPath.row]
		var title = ""
		var image: UIImage?
		
		if card.favorite {
			title = NSLocalizedString("Un-Favorite", comment: "Un-favorite action title")
			image = UIImage(systemName: leadingSwipeActionNonFavoriteImageName)
		} else {
			title = NSLocalizedString("Favorite", comment: "Favorite action title")
			image = UIImage(systemName: leadingSwipeActionFavoriteImageName)
		}
		
		let favoriteAction = UIContextualAction(style: .normal, title: title)
		{[weak self] _, _, completionHandler in
			guard let self = self else {return}
			
			self.data.updateCard(card: card, favorite: !card.favorite)
			self.loadData()
		}
		
		favoriteAction.image = image
		favoriteAction.backgroundColor = UIColor.blue
		
		return UISwipeActionsConfiguration(actions: [favoriteAction])
	}
	
	/**
	 Overrides the tableView shouldIndentWhileEditingRowAt function. Always returns false so that the rows are never indented in editing mode
	  - Authors: Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool
	{
		return false
	}
    
	/**
	 Overrides the tableView didSelectRowAt function. If editing mode is active, then go to edit the credit entry. If not, display the PIN code.
	  - Authors: Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
	{
		selectedCard = cards[indexPath.section][indexPath.row]
		if tableView.isEditing {
			performSegue(withIdentifier: nPin.listToEditSegue, sender: self)
		} else {
			performSegue(withIdentifier: nPin.listToDisplaySegue, sender: self)
		}
	}
	
	/**
	 Overrides the tableView titleForHeaderInSection function. If there are favorited credit cards and not currently in search mode, two sections will be displayed, the first one with the title "Favorite" and the second with the header "Recent". Otherwise, only one section is shown with the title "Cards".
	  - Authors: Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
	{
		if tableView.numberOfSections == 1 {
			return NSLocalizedString("Cards", comment: "Title for cards section when search is active")
		} else {
			if section == 0 {
				return NSLocalizedString("Favorite", comment: "Title for favorite cards section")
			} else {
				return NSLocalizedString("Recent", comment: "Title for recent cards section")
			}
		}
	}
	
	
    // MARK: - Navigation

    /**
	 Overrides the prepare for segue function. Tests if the destination is an edit Card View Controller or a Display View Controller and sends the appropriate information accordingly.
	  - Authors: Hamza Nizameddin
	 */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		if let editVC = segue.destination as? CardViewController {
			editVC.card = selectedCard
			editVC.order = cards[0].count
		} else if let showVC = segue.destination as? DisplayViewContoller {
			showVC.pinCode = selectedCard!.pin
			data.updateCard(card: selectedCard!, lastAccessed: Date())
		}
		
    }
    
}

// MARK: - UISearchBarDelegate
/**
 Extension to support the UISearchController.
  - Authors: Hamza Nizameddin
 */
extension CardListViewController: UISearchResultsUpdating
{
	/**
	 Overrides the updateSearchResults for searchController function. Calls the loadData() function which handles loading the data filtered by the text in the search bar.
	  - Authors: Hamza Nizameddin
	 */
	func updateSearchResults(for searchController: UISearchController) {
		self.loadData()
	}
}
