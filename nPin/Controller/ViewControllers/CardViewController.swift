//
//  EditViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 23/07/2021.
//

import UIKit
import CardScan

/**
View controller class to view, create and edit pin code entries.
 
 - Authors: Hamza Nizameddin
 - Note: View controller to view, create and edit pin code entries. The user must provide last 4 digits, pin code and card color as required fields. Name is an optional field. Favorite is set to false by default. User can also scan last 4 digits using camera. When saving a new card, this controller will verify that the total number of cards doesn't exceed the free limit set in nPin.freeCardLimit; otherwise, it will redirect user to purchase premium version of the app.
*/
class CardViewController: UIViewController
{
	//MARK: - IBOutlets
	/**UITextField to display/input the name of the card. Optional.*/
	@IBOutlet weak var nameTextField: UITextField!
	/**ValidatedTextField to display/input the last 4 digits of the credit card.*/
	@IBOutlet weak var digitsTextField: ValidatedTextField!
	/**ValidatedTextField to display/input the PIN code for the card.*/
	@IBOutlet weak var pinTextField: ValidatedTextField!
	/**UISwitch to display/input if the credit card is listed in the favorites section and accessible via the device Spotlight search feature.*/
	@IBOutlet weak var favoriteSwitch: UISwitch!
	/**Horizontal UIStackView containing all the buttons to display/select the color of the credit card.*/
	@IBOutlet weak var colorButtonsStackView: UIStackView!
	/**UIButton to scan the credit card details using CardScan.*/
	@IBOutlet weak var scanButton: UIButton!
	/**UILabel to display any error when attempting to save the entry.*/
	@IBOutlet weak var errorLabel: UILabel!
	
	//MARK: - Variables
	/**Optional Card object. If nil, then the view controller will create a new entry to the database. Otherwise, the existing entry will be edited.**/
	var card: Card?
	/**Optional. The order in which the card will appear in the favorites section.*/
	var order: Int?
	
	/**Array of ValidatedTextFields to be tested before the entry can be saved.*/
	var validatedTextFields: [ValidatedTextField] = []
	/**Array of UIButtons to select/display the color of the credit card.*/
	var colorButtons: [UIButton] = []
	/**Dictionary of hexadecimal color codes associated with the index of each color UIButton in colorButtons.*/
	var hexColorToIndex: [String: Int] = [:]
	/**Array of hexadecimal color codes indexed by the index of the color UIButton in colorButtons.*/
	var indexToHexColor: [String] = []
	
	/**UIImage SymbolConfiguration for the color UIButtons to display the SFSymbol image properly.*/
	let colorButtonImageConfig = UIImage.SymbolConfiguration(pointSize: UIFont.preferredFont(forTextStyle: .body).pointSize, weight: .regular, scale: .large)
	/**SFSymbol name for the credit card symbol displayed in the button to select the color of the credit card.*/
	let colorButtonImageName = nPin.creditCardcolorButtonImageName
	/**SFSymbol name for the credit card symbol displayed in the selected button for the color of the credit card.*/
	let colorButtonSelectedImageName = nPin.creditCardcolorButtonSelectedImageName
	/**Hexadecimal string representation of the selected credit card color.*/
	var selectedColorAsHex: String?
	
	/**Shared application-wide DataStack.*/
	private let data = (UIApplication.shared.delegate as! AppDelegate).data
	/**Shared application-wide IAPManager object to manage in-app purchases.*/
	private let iapManager = (UIApplication.shared.delegate as! AppDelegate).iapManager
	/**Limit of cards that can be stored in the free version of the app.*/
	private let freeCardLimit = nPin.freeCardLimit
	
	// MARK: - View Controller Life Cycle
	/**
	 Overrides viewDidLoad function.
	  - Authors: Hamza Nizameddin
	  - Note: Hides the error label. Adds the digitsTextField and pinTextFields to the validatedTextFields list so that they are validated every time the save button is pressed. Set the minimum and maximum lengths for the digits and the PIN code so they are properly validated. Sets up the horizontal stack view of the color buttons to display all colors available in the Card object. If a card object is provided, displays all the attributes of that object in the corresponding fields.
	 */
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		errorLabel.isHidden = true
		
		validatedTextFields.append(digitsTextField)
		validatedTextFields.append(pinTextField)
		
		
		digitsTextField.minCount = nPin.digitsSize
		digitsTextField.maxCount = nPin.digitsSize
		
		pinTextField.minCount = nPin.pinSize
		pinTextField.maxCount = nPin.pinSize
		
		digitsTextField.delegate = self
		pinTextField.delegate = self
		
		for subview in colorButtonsStackView.arrangedSubviews {
			colorButtonsStackView.removeArrangedSubview(subview)
			subview.removeFromSuperview()
		}
		NSLayoutConstraint.activate([NSLayoutConstraint(item: colorButtonsStackView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: UIFont.preferredFont(forTextStyle: .body).pointSize * 3.0)])
		
		var i = 0
		for hexColor in Card.HexColor.allCases
		{
			hexColorToIndex[hexColor.rawValue] = i
			indexToHexColor.append(hexColor.rawValue)
			i += 1
			let button = UIButton()
			let image = UIImage(systemName: colorButtonImageName, withConfiguration: colorButtonImageConfig)
			button.setImage(image, for: .normal)
			button.imageView?.tintColor = UIColor(hex: hexColor.rawValue)
			button.addTarget(self, action: #selector(colorButtonPressed(_:)), for: .touchUpInside)
			colorButtons.append(button)
			colorButtonsStackView.addArrangedSubview(button)
			colorButtonsStackView.alignment = .fill
		}
		
		if let safeCard = card
		{
			nameTextField.text = safeCard.name
			digitsTextField.text = safeCard.digits
			pinTextField.text = safeCard.pin
			favoriteSwitch.isOn = safeCard.favorite
			selectedColorAsHex = safeCard.colorAsHex
			if let selectedColorButtonIndex = hexColorToIndex[safeCard.colorAsHex] {
				let colorButton = colorButtons[selectedColorButtonIndex]
				colorButton.setImage(UIImage(systemName: colorButtonSelectedImageName, withConfiguration: colorButtonImageConfig), for: .normal)
				colorButton.layer.borderWidth = 3.0
				colorButton.layer.borderColor = UIColor.label.cgColor
			}
		} else {
			nameTextField.text = ""
			digitsTextField.text = ""
			pinTextField.text = ""
			favoriteSwitch.isOn = false
		}
		
		if !ScanViewController.isCompatible() {
			scanButton.isHidden = true
		}
    }
	
	/**
	 Overrides viewWillAppear function.
	  - Authors: Hamza Nizameddin
	  - Note: If not Card object is provided in the card variable, sets the title to "New Card"; otherwise, set the title to "Edit Card"
	 */
	override func viewWillAppear(_ animated: Bool)
	{
		if card == nil {
			self.navigationItem.title = NSLocalizedString("New Card", comment: "Navigation bar title for new card")
			scanButton.isHidden = false
		} else {
			self.navigationItem.title = NSLocalizedString("Edit Card", comment: "Navigation bar title for card editing")
			scanButton.isHidden = true
		}
	}
    
	// MARK: - Event Handlers
	/**
	 Event handler for when the user presses the save button
	  - Authors: Hamza Nizameddin
	  - Note: First, all the ValidatedTextField fields are validated to make sure the length of the input is valid. If any are invalid, they are highlighted in red. Then checks that a color was selected. If not, the color buttons stack view is highlighted in red. If some inputs are invalid the function exits without doing anything. If all inputs are valid, the function will either create a new card or edit the current one. If editing a card, it will first test that the new digits don't already exist in the database and then will proceed to update the card in the database. If creating a card, it will first check that the free card limit isn't reached for the free version of the app and will present an alert box to purchase the premium version accordingly. Otherwise, it will first test that the new digits don't already exist in the database and if not, it will create a new credit card entry and save it.
	 */
	@IBAction func saveButtonPressed(_ sender: UIBarButtonItem)
	{
		var inputValid = true
		errorLabel.isHidden = true
		
		for validatedTextField in self.validatedTextFields
		{
			let isValid = validatedTextField.isValid()
			if isValid {
				validatedTextField.layer.borderColor = UIColor.clear.cgColor
				validatedTextField.layer.borderWidth = 0.0
			} else {
				inputValid = false
				validatedTextField.layer.borderColor = UIColor.red.cgColor
				validatedTextField.layer.borderWidth = 3.0
			}
		}
		
		
		colorButtonsStackView.layer.borderColor = UIColor.clear.cgColor
		colorButtonsStackView.layer.borderWidth = 0.0
		if selectedColorAsHex == nil
		{
			inputValid = false
			colorButtonsStackView.layer.borderColor = UIColor.red.cgColor
			colorButtonsStackView.layer.borderWidth = 3.0
		}

		if inputValid == true
		{
			if let digits = self.digitsTextField.text,
			   let pin = self.pinTextField.text,
			   let name = self.nameTextField.text,
			   let order = self.order,
			   let colorAsHex = self.selectedColorAsHex
			{
				// if editing existing card
				if let card = self.card
				{
					if digits != card.digits && data.digitsExist(digits) {
						errorLabel.isHidden = false
						errorLabel.text = NSLocalizedString("Digits already exists", comment: "Error text warning that input digits already exists in database")
					} else {
						data.updateCard(card: card, digits: digits, pin: pin, name: name, order: card.order, favorite: favoriteSwitch.isOn, colorAsHex: colorAsHex)
						self.navigationController?.popViewController(animated: true)
					}
				}
				else
				{ // create new card in the list
					// first check if premium is purchased and limit is not reached
					guard data.count < freeCardLimit - 1 || iapManager.isPurchased() else
					{
						let message = NSLocalizedString("Free card limit reached, please purchase premium version to unlock unlimited number of cards", comment: "Message label for premium purchase alert when free card limit is reached")
						let alert = iapManager.getPurchaseAlert(message: message)
						present(alert, animated: true, completion: nil)
						return
					}
					if data.digitsExist(digits) {
						errorLabel.isHidden = false
						errorLabel.text = NSLocalizedString("Digits already exists", comment: "Error text warning that input digits already exists in database")
					} else {
						data.createCard(digits: digits, pin: pin, name: name, order: Int16(order), favorite: favoriteSwitch.isOn, colorAsHex: colorAsHex)
						self.navigationController?.popViewController(animated: true)
					}
				}
			}
		}
		
	}
	
	/**
	 Event handler when any of the color buttons are pressed.
	  - Authors: Hamza Nizameddin
	  - Note: First it will set the UIImageView image name for all the cards to to colorButtonImageName to indicate they are deselected. Then it will set the image name to colorButtonSelectedImageName for the one that was selected.
	 */
	@objc private func colorButtonPressed(_ sender: UIButton)
	{
		for i in 0..<colorButtons.count {
			if colorButtons[i] != sender {
				colorButtons[i].setImage(UIImage(systemName: colorButtonImageName, withConfiguration: colorButtonImageConfig), for: .normal)
				colorButtons[i].layer.borderWidth = 0.0
				colorButtons[i].layer.borderColor = UIColor.clear.cgColor
			} else {
				colorButtons[i].setImage(UIImage(systemName: colorButtonSelectedImageName, withConfiguration: colorButtonImageConfig), for: .normal)
				colorButtons[i].layer.borderWidth = 3.0
				colorButtons[i].layer.borderColor = UIColor.label.cgColor
				selectedColorAsHex = indexToHexColor[i]
			}
		}
	}
	
	/**
	 Event handler for when the camera scan button. Tests if the device supports CardScan, and if so presents the CardScanViewController to scan the credit card and read the last 4 digits and enter them in  digitsTextField.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func scanButtonPressed(_ sender: UIButton)
	{
		guard let vc = ScanViewController.createViewController(withDelegate: self) else
		{
			print("This device is incompatible with CardScan")
			return
		}
		self.present(vc, animated: true)
	}
}


// MARK: - ScanDelegate
/**
 Implementation of the ScanDelegate for the ScanViewController delegate.
 - Authors: Hamza Nizameddin
 */
extension CardViewController: ScanDelegate
{
	/**
	 Event handler if skip button is pressed. The view controller is dismissed and returns the the Access view controller.
	  - Authors: Hamza Nizameddin
	 */
	func userDidSkip(_ scanViewController: ScanViewController)
	{
		self.dismiss(animated: true)
	}
	/**
	 Event handler if cancel button is pressed. The view controller is dismissed and returns the the Access view controller.
	  - Authors: Hamza Nizameddin
	 */
	func userDidCancel(_ scanViewController: ScanViewController)
	{
		self.dismiss(animated: true)
	}
	/**
	 Event handler if a card is successfully scanned. The function will read the last 4 digits for the credit card and enter it into digitsTextField.
	  - Authors: Hamza Nizameddin
	 */
	func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard)
	{
		self.digitsTextField.text = String(creditCard.number.suffix(4))
		dismiss(animated: true, completion: nil)
	}
}

// MARK: - UITextFieldDelegate

/**
 Extension to limit the number of characters that can be inputted into digits and pin code field to the maximum set in nPin.digitsSize (4)
  - Authors: Hamza Nizameddin
 */
extension CardViewController: UITextFieldDelegate
{
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	{
		guard let text = textField.text,
			  let range = Range(range, in: text) else {
			return false
		}
		
		let substringToReplace = text[range]
		let count = text.count - substringToReplace.count + string.count
		return count <= nPin.digitsSize
	}
}
