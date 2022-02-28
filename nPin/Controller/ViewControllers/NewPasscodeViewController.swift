//
//  NewNewPasscodeViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 14/09/2021.
//

import UIKit


/**
View controller class to change app passcode.
 
 - Author: Hamza Nizameddin
 - Note: If this is displayed from the SettingsViewController, the old passcode is required to make the change. If it is displayed from LoginViewController it means this is either the first boot, or the passcode has been forgotten in which case there is no need to provide the old passcode.
*/
class NewPasscodeViewController: UIViewController
{
	// MARK: - IBOutlets
	/**ValidatedTextField to input current passcode.*/
	@IBOutlet weak var currentPasscodeTextField: ValidatedTextField!
	/**ValidatedTextField to input new passcode.*/
	@IBOutlet weak var newPasscodeTextField: ValidatedTextField!
	/**ValidatedTextField to confirm new passcode input.*/
	@IBOutlet weak var confirmPasscodeTextField: ValidatedTextField!
	/**UIButton to save new passcode*/
	@IBOutlet weak var savePasswordButton: UIButton!
	/**UILabel to display at the top of the view controller in case there is Navigation bar.*/
	@IBOutlet weak var newPasscodeLabel: UILabel!
	
	
	// MARK: - Internal Variables
	/**Shared application-wide KeychainPasswordManager object to handle passcode storage and authentication.*/
	private let keychainPassword = (UIApplication.shared.delegate as!AppDelegate).keychainPassword
	/**List of ValidatedTextFields to check whenever the save button is pressed.*/
	private var validatedTextFields: [ValidatedTextField] = []
	/**Length of the application passcode*/
	let passcodeSize = nPin.passcodeSize
	
	
	// MARK: - Public Variables
	/**Set to true to indicate that a the passcode is being reset and to hide the currentPasscodeTextField.*/
	var isResetPasscode = false
	
	
	// MARK: - Controller Life Cycle
	/**
	 Overrides the viewDidLoad function. If there is a password stored in the keychain and the isResetPasscode is not set to true, show the currentPasscodeTextField and add it to the validatedTextFields array; otherwise, hide it. If there is no navigation bar, show the newPasscodeLabel. Add both the newPasscodeTextField and the confirmPasscodeTextField to the array of validatedTextFields to be checked whenever the save button is pressed. Set the minimum and maximum size of the input in all text fields to the passcode size.
	  - Authors: Hamza Nizameddin
	 */
	override func viewDidLoad()
	{
        super.viewDidLoad()
		
		if keychainPassword.passwordExists() && !isResetPasscode{
			currentPasscodeTextField.isHidden = false
			validatedTextFields.append(currentPasscodeTextField)
		} else {
			currentPasscodeTextField.isHidden = true
		}
		
		if navigationController != nil {
			newPasscodeLabel.isHidden = true
		} else {
			newPasscodeLabel.isHidden = false
		}
		
		validatedTextFields.append(newPasscodeTextField)
		validatedTextFields.append(confirmPasscodeTextField)
		
		for validatedTextField in validatedTextFields {
			validatedTextField.minCount = passcodeSize
			validatedTextField.maxCount = passcodeSize
			validatedTextField.delegate = self
		}
    }
	
	// MARK: - Event Handlers
	/**
	 Event handler for when the save button is pressed. Calls the savePassword() function
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func saveButtonPressed(_ sender: UIButton)
	{
		savePassword()
	}
	
	/**
	 Save the password using the inputs in the text fields.
	  - Authors: Hamza Nizameddin
	  - Note: First, validates all the text fields. If any are invalid, they are highlighted in red and the function returns. Otherwise, if the new passcode and its confirmation do not match, an alert box will be displayed and the function returns. Otherwise,  if a passcode exists, and is provided, it will test it against the passcode stored in the keychain. If they match, the new passcode will be stored in the keychain; otherwise, an alert box will be displayed informing the user that the current password is a mismatch. If no current passcode exists, or the isResetPasscode variable is true, then the new passcode is saved and an alert text box is displayed to inform the user of the success.
	 */
	func savePassword()
	{
		var valid = true
		
		for validatedTextField in validatedTextFields
		{
			validatedTextField.layer.borderWidth = 0.0
			validatedTextField.layer.borderColor = UIColor.clear.cgColor
			
			if !validatedTextField.isValid() {
				validatedTextField.layer.borderWidth = 1.0
				validatedTextField.layer.borderColor = UIColor.red.cgColor
				valid = false
			}
		}
		
		guard valid else {return}
		
		if let newPasscode = newPasscodeTextField.text,
		   let confirmPasscode = confirmPasscodeTextField.text,
		   let currentPasscode = currentPasscodeTextField.text
		{
			if newPasscode != confirmPasscode
			{
				displayAlert(title: NSLocalizedString("Passwords do not match", comment: "Alert message indicating passwords do not match"))
				return
			}
			
			if keychainPassword.passwordExists() && !isResetPasscode
			{
				if !keychainPassword.testPassword(currentPasscode)
				{
					displayAlert(title: NSLocalizedString("Incorrect Passcode", comment: "Alert message for incorrect passcode when attempting to change passcode"))
				}
				else
				{
					if keychainPassword.setPassword(newPassword: newPasscode, currentPassword: currentPasscode)
					{
						displayAlert(title: NSLocalizedString("Successfully updated passcode", comment: "Alert message for successful passcode update")) { [weak self] _ in
							guard let self = self else {return}
							DispatchQueue.main.async {
								if let navigationController = self.navigationController {
									navigationController.popViewController(animated: true)
								} else {
									self.dismiss(animated: true, completion: nil)
								}
							}
						}
					} else {
						displayAlert(title: NSLocalizedString("Error updating passcode", comment: "Generic alert message for failed passcode update"))
					}
				}
			}
			else
			{
				if keychainPassword.resetPassword(newPassword: newPasscode)
				{
					displayAlert(title: NSLocalizedString("Successfully created passcode", comment: "Alert message for successful passcode creation")) {[weak self] _ in
						guard let self = self else {return}
						DispatchQueue.main.async {
							if let navigationController = self.navigationController {
								navigationController.popViewController(animated: true)
							} else {
								self.dismiss(animated: true, completion: nil)
							}
						}
					}
				}
			}
		}
	}
	
	// MARK: - Helper Functions
	/**
	 Displays an alert box with the title, message handler with an OK button to dismiss it
	 - Author: Hamza Nizameddin
	 - Parameters:
	  - title: Alert box title string (Required)
	  - message: Alert box message string (Optional defaults to nil)
	  - handler: Actions to be taken when OK button is pressed
	 - Warning: Must be called from the main thread
	 */
	private func displayAlert(title: String, message: String? = nil, handler: ((UIAlertAction) -> Void)? = nil)
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: handler))
		present(alert, animated: true)
	}
		
}

// MARK: - Extension: UITextFieldDelegate
/**
 Extension to limit the number of characters in the text fields to passcodeSize (6)
 */
extension NewPasscodeViewController: UITextFieldDelegate
{
	/**
	 Overrides the textField shouldChangeCharactersIn function to limit the length of the input to passcode size (6)
	 */
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
	{
		guard let text = textField.text,
			  let range = Range(range, in: text) else {
			return false
		}
		
		let substringToReplace = text[range]
		let count = text.count - substringToReplace.count + string.count
		return count <= passcodeSize
	}
}
