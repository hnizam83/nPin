//
//  AccessViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 19/07/2021.
//

import UIKit
import CardScan

/**
View controller class to quickly access pin codes.
 
 - Author: Hamza Nizameddin
 - Note: View controller to quickly access pin codes. Provides a number pad to enter the last four digits of the card and displays pin code if the card exists. If the fake pin option is enabled in settings, will also display a fake pin code when only the last digit is incorrect. Also provides a button in the bottom left of the number pad to access pin code using the device camera. If there are no stored pin codes, will display CardViewController to allow user to create a new pin code entry.
*/

class AccessViewController: UIViewController
{
	/**Logout UIBarButtonItem displayed on the left of the navigation bar.*/
	@IBOutlet weak var logoutButton: UIBarButtonItem!
	/**Title UILabel displaying the "Enter last 4 digits" text.*/
	@IBOutlet weak var titleLabel: UILabel!
	/**Horizontal UIStackView containing the circle UIImageViews displaying how many digits were entered on the number pad so far.*/
	@IBOutlet weak var circlesStackView: UIStackView!
	/**Array of circle UIImageViews displaying how many digits were entered on the number pad so far.*/
	@IBOutlet var circles: [UIImageView]!
	
	/**Vertical UIStackView containing all the buttons of the number pad.*/
	@IBOutlet weak var numpadVerticalStackView: UIStackView!
	/**Constraint on verticalStackView to set its vertical center.*/
	@IBOutlet weak var numpadVerticalStackViewVerticalConstraint: NSLayoutConstraint!
	/**Array of horizontal UIStackViews containing the rows of buttons of the number pad.*/
	@IBOutlet var numpadHorizontalStackView: [UIStackView]!
	/**Array of UIButtons 0-9 of the number pad*/
	@IBOutlet var numpadButtons: [UIButton]!
	
	/**UIButton in the bottom right of the number pad used as a backspace.*/
	@IBOutlet weak var deleteButton: UIButton!
	/**UIButton in the bottom left of the number pad used to call the CardScan scanner to input digits using the device camera.*/
	@IBOutlet weak var scanButton: UIButton!
	
	/**Number entered so far by the user.**/
	private var numpadEntry: String = ""
	
	/**Dictionary of all the stored PIN codes indexed by the last 4 digits of the credit card populated every time the view controller is loaded.*/
	private var pinCodes: [String: String] = [String: String]()
	/**Dictionary of the stored fake PIN codes indexed by the fake last 4 digits populated every time the view controller is loaded.**/
	private var fakePinCodes: [String: String] = [String: String]()
	/**PIN code to be passed on to the Display View Controller*/
	private var pinCode: String = ""
	/**Length of the digits string.*/
	private let digitsSize: Int = nPin.digitsSize
	
	
	/**Shared application-wide DataStack.*/
	private let data = (UIApplication.shared.delegate as! AppDelegate).data
	/**UserDefaults.standard to store all application settings.*/
	private let defaults = UserDefaults.standard
	
	/**Credit card digits passed into the View Controller when the user searches for a pin code using the device Spotlight Search feature.*/
	var spotlightSearchDigits: String?
	
	// MARK: - View Controller Life Cycle
	
	/**
	 Overrides viewDidLoad function. Calls setupFormatting() function to format the number pad according to the size of the device display.
	  - Authors: Hamza Nizameddin
	 */
	override func viewDidLoad()
	{
        super.viewDidLoad()
		self.setupFormatting()
		
    }
	
	/**
	 Overrides viewWillAppear function. Calls resetNumpad() to reset the number pad. If there are no stored credit card PIN codes, automatically segues to the Card View Cotroller to create the first entry.
	  - Authors: Hamza Nizameddin
	 */
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(true)
		self.resetNumpad()
		if self.data.count == 0 {
			performSegue(withIdentifier: nPin.accessToEditSegue, sender: self)
		}
	}
	
	/**
	 Overrides viewDidAppear function. Retrieves all the data from the DataStack and loads it into the pinCodes and fakePinCodes dictionaries for fast serching when the user enters the digits. If digis were passed into the spotlightSearchDigits variable, will automatically segue to the Display View Controller to display the PIN code.
	  - Authors: Hamza Nizameddin
	 */
	override func viewDidAppear(_ animated: Bool)
	{
		super.viewDidAppear(true)
				
		let cards = self.data.getCards()
		
		// reload pin code data from data source every time it reappears 
		self.pinCodes = [String: String]()
		for card in cards {
			self.pinCodes[card.digits] = card.pin
		}
		
		// If fake pin is enabled, build another dictionary with keys one less than the original
		self.fakePinCodes = [String: String]()
		let fakePin: Bool = self.defaults.bool(forKey: nPin.fakePinKey)
		if fakePin == true {
			for card in cards {
				if let cardFakePins = card.fakePins {
					for i in 0..<card.fakePins!.count {
						let fakeDigits = String(card.digits.prefix(card.digits.count - 1)) + String(i)
						self.fakePinCodes[fakeDigits] = cardFakePins[i]
					}
				}
			}
		}
		
		if let spotlightSearchDigits = self.spotlightSearchDigits,
		   spotlightSearchDigits.count >= 4
		{
			if let pinCode = self.pinCodes[spotlightSearchDigits] {
				self.pinCode = pinCode
				performSegue(withIdentifier: nPin.accessToDisplaySegue, sender: self)
				self.spotlightSearchDigits = nil
		   }
		}
	}
	
	// MARK: - Event Handlers

	/**
	 Event handler for when the user presses athe logout bar button.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func logoutButtonPressed(_ sender: UIBarButtonItem)
	{
		dismiss(animated: true, completion: nil)
	}
	
	/**
	 Event handler for when the user presses athe add bar button. Performs the segue to Card View Controller.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func addButtonPressed(_ sender: UIButton)
	{
		performSegue(withIdentifier: nPin.accessToEditSegue, sender: self)
	}
	
	/**
	 Event handler for when the user presses any numpad numeric button.
	  - Authors: Hamza Nizameddin
	  - Note: If the digits are not fully entered, i.e. less than digitsSize, it will keep adding digits to the entry variable and filling in circles. If the digits is fully entered, it will test the entry to see if it matches the stored PIN codes in the pinCodes dictionary. If there is a match, it will perform the segue to the Display View Controller. Otherwise, it will test to see if it maches any fake PIN code entry in the fakePinCodes dictionary. If so, it will perform the segue to the Display View Controller using the fake PIN code. If there is no match, it will shake the circles and reset the number pad.
	 */
	@IBAction func numButtonPressed(_ sender: UIButton)
	{
		if(numpadEntry.count < 4)
		{
			circles[numpadEntry.count].image = UIImage(systemName: nPin.filledCircleImageName)
			numpadEntry += sender.titleLabel!.text!
		}
		
		if(numpadEntry.count >= 4)
		{
			if let pinCode = self.pinCodes[self.numpadEntry]
			{
				self.pinCode = pinCode
				performSegue(withIdentifier: nPin.accessToDisplaySegue, sender: self)
			}
			else if let fakePinCode = self.fakePinCodes[self.numpadEntry]
			{
				self.pinCode = fakePinCode
				performSegue(withIdentifier: nPin.accessToDisplaySegue, sender: self)
			}
			else
			{
				circlesStackView.shake(shakeCount: 5)
				resetNumpad()
			}
		}
	}
	
	/**
	 Event handler for when the camera scan button. Tests if the device supports CardScan, and if so presents the CardScanViewController to scan the credit card and read the last 4 digits.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func cameraButtonPressed(_ sender: UIButton)
	{
		guard let vc = ScanViewController.createViewController(withDelegate: self) else
		{
			print(NSLocalizedString("This device is incompatible with CardScan", comment: "Indicates that the device does not support camera card scanning functionality"))
			return
		}
		self.present(vc, animated: true)
	}
	
	/**
	 Event handler for the delete (backspace) button.
	  - Authors: Hamza Nizameddin
	  - Note: If there is any entry, deletes the last digit entered and empties a circle accordingly.
	 */
	@IBAction func deleteButtonPressed(_ sender: UIButton)
	{
		if self.numpadEntry.count > 0 {
			self.numpadEntry.removeLast()
			self.circles[self.numpadEntry.count].image = UIImage(systemName: nPin.emptyCircleImageName)
		}
	}
	
	
	// MARK: - Reset numpad
	
	/**
	 Resets the number pad for a new entry
	  - Authors: Hamza Nizameddin
	 */
	private func resetNumpad()
	{
		numpadEntry = ""
		for circle in circles {
			circle.image = UIImage(systemName: nPin.emptyCircleImageName)
		}
	}
	
	// MARK: - Formatting
	
	/**
	 Sets up the formatting of the View Controller based on the size of the display.
	  - Authors: Hamza Nizameddin
	 */
	private func setupFormatting()
	{
		// calculate the button size based on the view width
		let buttonSize: CGFloat = (self.view.frame.width - 20) * 0.20
		let titleLabelFontSize = buttonSize * 0.35
		let titleLabelWidth: CGFloat = (self.view.frame.width - 100)
		let buttonCornerRadius = buttonSize * 0.50
		let buttonLabelFontSize = buttonSize * 0.50
		let circleSize = buttonSize * 0.20
		let circleStackViewSpacing = buttonSize * 0.30
		let verticalStackViewSpacing = buttonSize * 0.25
		let verticalStackViewVerticalConstraintConstant = buttonSize * 0.50
		let horizontalStackViewSpacing = buttonSize * 0.30
		let deleteButtonPointSize = buttonSize * 0.30
		
		// set the proper font size for the label
		if let titleLabel = self.titleLabel {
			titleLabel.font = UIFont(name: titleLabel.font.fontName, size: titleLabelFontSize)
			let titleLabelWidthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: titleLabelWidth)
			NSLayoutConstraint.activate([titleLabelWidthConstraint])
			titleLabel.adjustsFontSizeToFitWidth = true
		}
		
		// set the stack view spacing based on the button size
		numpadVerticalStackView.spacing = verticalStackViewSpacing
		for horizontalStackView in numpadHorizontalStackView {
			horizontalStackView.spacing = horizontalStackViewSpacing
		}
		numpadVerticalStackViewVerticalConstraint.constant = verticalStackViewVerticalConstraintConstant
		
		// modify the button sizes by changing their width and height constraints
		// then make the buttons rounded
		for button in numpadButtons
		{
			for oldConstraint in button.constraints {
				button.removeConstraint(oldConstraint)
			}
			let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: buttonSize)
			let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: buttonSize)
			NSLayoutConstraint.activate([heightConstraint, widthConstraint])
			button.layer.cornerRadius = buttonCornerRadius
			button.titleLabel?.font = UIFont.systemFont(ofSize: buttonLabelFontSize)
		}
		
		// modify the circles sizes by changing their width and height constraints
		for circle in circles
		{
			for oldConstraint in circle.constraints {
				circle.removeConstraint(oldConstraint)
			}
			let widthConstraint = NSLayoutConstraint(item: circle, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: circleSize)
			let heightConstraint = NSLayoutConstraint(item: circle, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1.0, constant: circleSize)
			NSLayoutConstraint.activate([heightConstraint, widthConstraint])
		}
		
		circlesStackView.spacing = circleStackViewSpacing
		
		let largeConfiguration = UIImage.SymbolConfiguration(pointSize: deleteButtonPointSize, weight: .bold, scale: .large)
		self.deleteButton.setImage(UIImage(systemName: nPin.deleteButtonImageName, withConfiguration: largeConfiguration), for: .normal)
		self.scanButton.setImage(UIImage(systemName: nPin.scanButtonImageName, withConfiguration: largeConfiguration), for: .normal)
		
		self.setButtonConstraints(button: self.deleteButton, width: buttonSize, height: buttonSize)
		self.setButtonConstraints(button: self.scanButton, width: buttonSize, height: buttonSize)
	}
	
	private func setButtonConstraints(button: UIButton, width: CGFloat, height: CGFloat)
	{
		button.removeConstraints(button.constraints)
		
		let widthConstraint = NSLayoutConstraint(item: button, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: width)
		let heightConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: height)
		NSLayoutConstraint.activate([widthConstraint, heightConstraint])
	}
    
    // MARK: - Navigation
	/**
	 Overrides prepare function. Sets loginWithBiometricIdOnViewDidAppear to false. If the destination is the Access View Controller, provides it with the PIN code to be displayed. If the destination is to the Card View Controller, sets it up to create a new credit card PIN code entry.
	  - Authors: Hamza Nizameddin
	 */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
	{
		switch segue.identifier
		{
			case nPin.accessToDisplaySegue:
				if let displayVC = segue.destination as? DisplayViewContoller {
					displayVC.pinCode = self.pinCode
				}
			case nPin.accessToEditSegue:
				if let editVC = segue.destination as? CardViewController {
					editVC.card = nil
					editVC.order = 0
				}
			default:
				return
		}
    }
}
	
	
// MARK: - ScanDelegate
/**
 Implementation of the ScanDelegate for the ScanViewController delegate.
 - Authors: Hamza Nizameddin
 */
extension AccessViewController: ScanDelegate
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
	 Event handler if a card is successfully scanned. The function will read the last 4 digits for the credit card and serch for it in the pinCodes dictionary. If a match is found, the PIN code is displayed in a Display View Controller. Otherwise, the circle images are shaken and the number pad is reset.
	  - Authors: Hamza Nizameddin
	 */
	func userDidScanCard(_ scanViewController: ScanViewController, creditCard: CreditCard)
	{
		let digits = String(creditCard.number.suffix(4))
		if let pinCode = self.pinCodes[digits]
		{
			self.pinCode = pinCode
			self.dismiss(animated: true)
			performSegue(withIdentifier: nPin.accessToDisplaySegue, sender: self)
		} else {
			self.dismiss(animated: true, completion: nil)
			circlesStackView.shake(shakeCount: 5)
			resetNumpad()
		}
	}
}



