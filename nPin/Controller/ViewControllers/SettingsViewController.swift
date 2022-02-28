//
//  SettingsTableViewController.swift
//  nPin
//
//  Created by Hamza Nizameddin on 21/07/2021.
//

import UIKit
import KeychainSwift
import CoreData
import StoreKit

/**
Table view controller class to manage app settings
 
 - Author: Hamza Nizameddin
 - Note: Manages app settings and stores them in User Defaults. Uses custom children classes of UISwitch and UISegmentedControl to store the User Defaults key as a variable in those controls. Provides buttons to purchase premium version that unlocks unliimited entries or restore a previous purchase. Also provides buttons to change passcode or reset the app completely. All strings are localized.
*/
class SettingsViewController: UITableViewController, IAPManagerSK2Delegate
{
	
	// MARK: IBOutlets
	
	/**SettingsSwitch to enable/disable the  iCloud synchronization feature.*/
	@IBOutlet weak var iCloudSyncSwitch: SettingsSwitch!
	/**SettingsSwitch to enable/disable logging in with Biometric ID.**/
	@IBOutlet weak var biometricIdSwitch: SettingsSwitch!
	/**SettingsSwitch to enable/disable displaying a fake PIN code when an incorrect last digit is entered.*/
	@IBOutlet weak var fakePinSwitch: SettingsSwitch!
	/**SettingsSwitch to enable/disable locking the user out of the application for a certain time after several erroneous passcode attempts.*/
	@IBOutlet weak var timeoutLockSwitch: SettingsSwitch!
	/**TableView cell containing the SettingsSelector for the number of permitted erroneous passcode attempts before the user is locked out for a certain fime period. Used to hide/show the setting depending on the value of timeOutLockSwitch*/
	@IBOutlet weak var maxRetriesCell: UITableViewCell!
	/**SettingsSelector for the number of permitted erroneous passcode attempts before the user is locked out for a certain fime period.*/
	@IBOutlet weak var maxRetriesSelector: SettingsSelector!
	/**TableView cell containing the SettingsSelector for the number of minutes to lock the user out after too many erroneous passcode attempts. Used to hide/show the setting depending on the value of timeOutLockSwitch.*/
	@IBOutlet weak var timeoutLengthCell: UITableViewCell!
	/**SettingsSelector for the number of minutes to lock the user out after too many erroneous passcode attempts.*/
	@IBOutlet weak var timeoutLengthSelector: SettingsSelector!
	/**SettingsSwitch to enable/disable secured PIN code display settings.*/
	@IBOutlet weak var pinDisplaySecuritySwitch: SettingsSwitch!
	/**TableView cell containing the SettingsSwitch to enable/disable displaying the PIN code in reverse. Used to hid/show the reverse PIN settings depending on the value of pinDisplaySecurity.*/
	@IBOutlet weak var reversePinCell: UITableViewCell!
	/**SettingsSwitch to enable/disable displaying the PIN code in reverse.*/
	@IBOutlet weak var reversePinSwitch: SettingsSwitch!
	/**TableView cell containing the SettingsSwitch to enable/disable displaying 4 random PIN codess with the real PIN code. Used to hide/show the random PIN codes settings based on the value of pinDisplaySecuritySwitch.*/
	@IBOutlet weak var randomPinCell: UITableViewCell!
	/**SettingsSwitch to enable/disable displaying 4 random PIN codess with the real PIN code.*/
	@IBOutlet weak var randomPinSwitch: SettingsSwitch!
	/**UIButton to toggle between Premium and original App Icon.**/
	@IBOutlet weak var toggleAppIconButton: UIButton!
	
	/**UIButton to purchase premium version of the app.*/
	@IBOutlet weak var buyPremiumButton: UIButton!
	/**UIButton to restore previous purchase of the premium version.*/
	@IBOutlet weak var restorePurchaseButton: UIButton!
	
	
	/**UIButton to reset app passcode.*/
	@IBOutlet weak var resetPasscodeButton: UIButton!
	/**UIButton to reset all app data.*/
	@IBOutlet weak var resetAppDataButton: UIButton!
	
	// MARK: - Constants
	/**Row index of the SettingsSelector for the number of permitted erroneous passcode attempts before the user is locked out for a certain fime period.*/
	private let maxRetriesRow = 4
	/**Row index of the SettingsSelector for the number of minutes to lock the user out after too many erroneous passcode attempts.*/
	private let timeoutLengthRow = 5
	/**Row index of the SettingsSwitch to enable/disable displaying the PIN code in reverse.*/
	private let reversePinRow = 7
	/**Row index of the SettingsSwitch to enable/disable displaying 4 random PIN codess with the real PIN code.*/
	private let randomPinRow = 8
	/**Row index of the UIButton to initiate the In-App purchase of the premium version of the app.*/
	private let buyPremiumRow = 10
	/**Row index of the UIButton to initiate restoring a previous In-App purchase of the premium version of the app.*/
	private let restorePremiumRow = 11
	/**Row index of the UIButton to toggle App Icon from original to Premium. Only displayed once the app is purchased.**/
	private let toggleAppIconRow = 13
	/**Key in the cloud-based keystore for the iCloud synchronization option.*/
	let iCloudSyncKey = nPin.iCloudSyncKey
	
	// MARK: - Variables
	/**Array indicating if the cell at each index is hidden or visible. If the cell is hiddent, its height will be set to 0.*/
	private var cellIsHidden: [Bool] = []
	/**Dictionary containing a list of cell indeces to be hidden for the corresponding setting.*/
	private var hideCells: [String:[Int]] = [:]
	/**Dictionary of SettingsSwitches indexed by their title*/
	var switches: [String:SettingsSwitch] = [:]
	/**Dictionary of SettingsSelectors indexed by their title.*/
	var selectors: [String:SettingsSelector] = [:]
	
	// MARK: - Shared Application-Wide Constants
	/**Shared application-wide DataStack.*/
	private let data = (UIApplication.shared.delegate as! AppDelegate).data
	/**UserDefaults.standard to store all application settings.*/
	private let defaults = UserDefaults.standard
	/**Shared application-wide iCloud keystore.*/
	private let keystore = NSUbiquitousKeyValueStore.default
	/**Shared application-wide KeychainPasswordManager object to handle passcode storage and authentication.*/
	private let keychainPassword = (UIApplication.shared.delegate as! AppDelegate).keychainPassword
	/**Shared application-wide IAPManager object to manage in-app purchases.*/
	//private let iapManager = (UIApplication.shared.delegate as! AppDelegate).iapManager
	
	private let iapManagerSK2 = (UIApplication.shared.delegate as! AppDelegate).iapManagerSK2
	private let appIconManager = (UIApplication.shared.delegate as! AppDelegate).appIconManager
	
	// MARK: - View Controller Life Cycle
	/**
	 Overrides viewDidLoad function. Populates the cellIsHidden array and switches and selectors dictionaries. Sets the IAPManager deletegate as self.
	  - Authors: Hamza Nizameddin
	 */
    override func viewDidLoad()
	{
        super.viewDidLoad()
		
		for _ in 0...self.tableView.numberOfRows(inSection: 0) {
			cellIsHidden.append(false)
		}
		
		switches[nPin.iCloudSyncKey] = iCloudSyncSwitch
		switches[nPin.biometricIdKey] = biometricIdSwitch
		switches[nPin.fakePinKey] = fakePinSwitch
		switches[nPin.timeoutLockKey] = timeoutLockSwitch
		switches[nPin.pinDisplaySecurityKey] = pinDisplaySecuritySwitch
		switches[nPin.reversePinKey] = reversePinSwitch
		switches[nPin.randomPinKey] = randomPinSwitch
		
		selectors[nPin.maxRetriesKey] = maxRetriesSelector
		selectors[nPin.timeoutLengthKey] = timeoutLengthSelector

		hideCells[nPin.timeoutLockKey] = [maxRetriesRow, timeoutLengthRow]
		hideCells[nPin.pinDisplaySecurityKey] = [reversePinRow, randomPinRow]
		
		iapManagerSK2.delegate = self
		
    }
	
	/**
	 Overrides the viewWillAppear function. For each one of the switches and selectors, read the data stored in User Defaults to set their values properly. If no data exists, it will be created with the default value. Also, update cellIsHidden array to hide/show cells based on these values. Finally, call hideIapButtons() to hide In-App Purchase buttons if the premium version is already purchased and reload table view.
	  - Authors: Hamza Nizameddin
	 */
	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)
		
		for (key, _) in self.switches
		{
			// set the key property in the switch to be recalled in the Value Changed function
			self.switches[key]!.key = key
			//check if key exists, if so then read from it, else create it with false value
			if self.defaults.object(forKey: key) == nil {
				self.defaults.set(false, forKey: key)
			}
			self.switches[key]!.isOn = self.defaults.bool(forKey: key)
			if let safeHideCells = hideCells[key]
			{
				for row in safeHideCells {
					cellIsHidden[row] = !switches[key]!.isOn
				}
			}
		}
		
		for (key, _) in selectors
		{
			let selector = selectors[key]!
			// set the key property in the selector to be recalled in the Value Changed function
			selector.key = key
			
			//check if key exists, if so then read from it, else create it with value = 1
			if defaults.object(forKey: key) == nil {
				defaults.set(1, forKey: key)
			}
			let selectorValue = defaults.integer(forKey: key)
			for i in 0...selector.numberOfSegments {
				let segmentValue = Int(selector.titleForSegment(at: i)!)!
				if segmentValue == selectorValue {
					selector.selectedSegmentIndex = i
					break
				}
			}
		}
		
		iapManagerSK2.fetchProducts()
		updateIapButtons()
		
		tableView.reloadData()
	}
	
	// MARK: - Event Handlers
	/**
	 Event handler when user toggles the iCloud Synchrnoization switch. When switching on, offers the choice between keeping local data and uploading it to the cloud or keeping the cloud data and replacing the local entries. When switching off, offers the choice between keeping or deleting cloud data so they are no longer accessible on other synchronized devices.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func iCloudSyncSwitchValueChanged(_ sender: SettingsSwitch)
	{
		// if we are switching sync ON
		if sender.isOn
		{
			let alert = UIAlertController(
				title: NSLocalizedString("Activating iCloud Sync", comment: "Title text for alert when activating iCloud Sync"),
				message: nil,
				preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(
								title: NSLocalizedString("Keep Cloud Data", comment: "Label text for action to activate iCloud Sync and keep cloud data"),
								style: .destructive,
								handler: { [weak self] _ in
									guard let self = self else {return}
									// TODO: Switch to Cloud Data, delete local data and keep cloud data
									self.data.activateCloudSync(mergeOption: .keepCloudData)
									//self.keychain.synchronizable = true
									self.defaults.set(sender.isOn, forKey: self.iCloudSyncKey)
								}))
			
			alert.addAction(UIAlertAction(
								title: NSLocalizedString("Keep Local Data", comment: "Label text for action to activate iCloud Sync and keep local data"),
								style: .destructive,
								handler: { [weak self] _ in
									guard let self = self else {return}
									// TODO: Switch to Cloud Data, delete old cloud data and upload local data
									self.data.activateCloudSync(mergeOption: .keepLocalData)
									//self.keychain.activateSyncWithLocalValues()
									self.defaults.set(sender.isOn, forKey: self.iCloudSyncKey)
								}))
			
			alert.addAction(UIAlertAction(
								title: NSLocalizedString("Cancel", comment: "Cancel"),
								style: .cancel,
								handler: { _ in
									sender.isOn = false
								}))
			
			present(alert, animated: true)
		}
		else // if we are switching sync OFF
		{
			let alert = UIAlertController(
				title: NSLocalizedString("De-Activating iCloud Sync", comment: "Title text for alert when de-activating iCloud Sync"),
				message: nil,
				preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(
								title: NSLocalizedString("Keep Cloud Data", comment: "Label for action to de-activate iCloud Sync without deleting cloud data"),
								style: .default,
								handler: {[weak self] _ in
									guard let self = self else {return}
									// Switch to Local Data without deleting Cloud Data
									self.data.deactivateCloudSync(deleteCloudData: false)
									//self.keychain.synchronizable = false
									self.defaults.set(sender.isOn, forKey: self.iCloudSyncKey)
								}))
			
			alert.addAction(UIAlertAction(
								title: NSLocalizedString("Delete Cloud Data", comment: "Label for action to activate iCloud Sync and delete cloud data"),
								style: .destructive,
								handler: { [weak self] _ in
									guard let self = self else {return}
									// Switch to Local Data and delete Cloud Data
									self.data.deactivateCloudSync(deleteCloudData: true)
									//self.keychain.deactivateSyncDeleteCloudValues()
									self.defaults.set(sender.isOn, forKey: self.iCloudSyncKey)
								}))
			
			alert.addAction(UIAlertAction(
								title: NSLocalizedString("Cancel", comment: "Label for cancel action"),
								style: .cancel,
								handler: { _ in
									sender.isOn = true
								}))
			present(alert, animated: true)
		}
	}
	
	/**
	 Event handler for all switches except iCloud synchronization. If a setting is enabled, will display an alert box explaining the function of the setting.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func switchValueChanged(_ sender: SettingsSwitch)
	{
		let key = sender.key!
		
		// set the value in the User Defaults storage
		self.defaults.set(sender.isOn, forKey: key)
		
		if sender.isOn {
			if key == nPin.fakePinKey {
				// display alert box explaining Fake Pin feature
				self.displayInformationAlert(
					title: NSLocalizedString("Fake PIN Activated", comment: "Title for alert box explaining fake pin feature"),
					message: NSLocalizedString("Entering an incorrect final digit on the number pad will display a random fake PIN code to fool prying eyes.", comment: "Message for alert box explaining fake pin feature"))
			}
			else if key == nPin.randomPinKey {
				// display alert box explaining Random PIN feature
				self.displayInformationAlert(
					title: NSLocalizedString("Random PINs Activated", comment: "Title for alert box explaining random pins features"),
					message: NSLocalizedString("Real PIN code will be displayed with 4 other random PIN codes in order to confuse any prying eyes.", comment: "Message for alert box explaining random PIN feature"))
			}
			else if key == nPin.reversePinKey {
				// display alert box explaining Reverse PIN feature
				self.displayInformationAlert(
					title: NSLocalizedString("Reverse PINs Activated", comment: "Title for alert box explaining reverse pins features"),
					message: NSLocalizedString("Real PIN code will be displayed in reverse in order to confuse any prying eyes.", comment: "Message for alert box explaining reverse PIN feature"))
			}
			else if key == nPin.timeoutLockKey {
				// display alert box explaining Reverse PIN feature
				self.displayInformationAlert(
					title: NSLocalizedString("Timeout Activated", comment: "Title for alert box explaining timeout feature"),
					message: NSLocalizedString("App will lock for a few minutes after several failed attempts to enter the passcode.\nAdjust the length of the timeout and the maximum number of tries.", comment: "Message for alert box explaining timeout feature"))
			}
		}
		
		// check if there are cells to hide/unhide
		if let safeHideCells = self.hideCells[key] {
			for row in safeHideCells {
				self.cellIsHidden[row] = !sender.isOn
			}
			DispatchQueue.main.async {
				self.tableView.reloadData()
			}
		}
	}
	
	/**
	 Event handler for change for all selectors. Gets the new value from the selector and updates the relevant value in the User Defaults.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func selectorValueChanged(_ sender: SettingsSelector)
	{
		let key = sender.key!
		
		let selectedValue = Int(sender.titleForSegment(at: sender.selectedSegmentIndex)!)!
		
		//set the value in the User Defaults settings
		self.defaults.set(selectedValue, forKey: key)
	}
	
	/**
	 Event handler for when the logout button is pressed. Dismisses this view controller and returns to the login view controller.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func logoutButtonPressed(_ sender: UIBarButtonItem)
	{
		dismiss(animated: true, completion: nil)
	}
	
	/**
	 Event handler for when the Buy Premium Version button is pressed. Calls the iapManager buyPremium() function to launch the in-app purchase of the premium version. Then calls the hideIapButtons() functions to hide the buttons if the purchase is successful.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func buyPremiumButtonPressed(_ sender: UIButton)
	{
		iapManagerSK2.buyPremium()
//		iapManager.buyPremium()
//		updateIapButtons()
	}
	
	/**
	 Event handler for when the Restore Premium Version button is pressed. Call the iapManager restorePremium() function to launch the restoration process of the premium version. Then calls the hideIapButtons() function to hide the buttons if the purchase is successful.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func restoreButtonPressed(_ sender: UIButton)
	{
		iapManagerSK2.restorePremium()
	}
	
	/**
	 Event handler for when the Upgrade/Revert App Icon button is pressed.
	 */
	@IBAction func toggleAppIconButtonPressed(_ sender: UIButton)
	{
		guard iapManagerSK2.isPurchased else {
			return
		}
		appIconManager.toggleAppIcon()
		updateIapButtons()
		tableView.reloadData()
	}
	
	
	/**
	 Event handler for when the Reset Passcode button is pressed. Does nothing since the segue to the new passcode view controller is called from the storyboard.
	 */
	@IBAction func resetPasscodeButtonPressed(_ sender: UIButton)
	{
		performSegue(withIdentifier: nPin.settingsToResetPasscodeSegue, sender: self)
	}
	
	/**
	 Event handler for when the Reset App Data button is pressed. Presents the user with an alert box to delete all application data. Confirms the deletion by making th user type RESET in the textbox and then proceeds to delete everything in the local and cloud storage.
	  - Authors: Hamza Nizameddin
	 */
	@IBAction func resetAppDataButtonPressed(_ sender: UIButton)
	{
		var presentConfirmationAlert = false
		
		let alert = UIAlertController(title: NSLocalizedString("RESET", comment: "Reset alert box title"), message: NSLocalizedString("Are you sure you want to reset ALL app data?", comment: "Reset alert box message"), preferredStyle: .alert)
		let confirmationAlert = UIAlertController(title: NSLocalizedString("CONFIRM", comment: "Reset confirmation alert box title"), message: NSLocalizedString("Please type RESET in the box below to confirm App data reset", comment: "Reset confirmation alert box message"), preferredStyle: .alert)
		
		let resetAction = UIAlertAction (title: NSLocalizedString("RESET", comment: "Reset button label"), style: .destructive) { action in
			presentConfirmationAlert = true
			alert.dismiss(animated: true) {
				self.present(confirmationAlert, animated: true, completion: nil)
			}
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		alert.addAction(resetAction)
		alert.addAction(cancelAction)
		
		var confirmTextField = UITextField()
		confirmationAlert.addTextField { textField in
			confirmTextField = textField
			textField.placeholder = "RESET"
		}
		let confirmationResetAction = UIAlertAction(title: "RESET", style: .destructive) { action in
			if let text = confirmTextField.text,
			   text == "RESET" {
				self.resetAppData()
				self.dismiss(animated: true, completion: nil)
			}
		}
		let confirmationCancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		confirmationAlert.addAction(confirmationResetAction)
		confirmationAlert.addAction(confirmationCancelAction)
		
		DispatchQueue.main.async {
			self.present(alert, animated: true) {
				if presentConfirmationAlert == true {
					self.present(confirmationAlert, animated: true) {
						self.navigationController?.popToRootViewController(animated: true)
					}
				}
			}
		}
	}
	
	// MARK: - Table View Data Source
	/**
	 Overrides the table view heightForRowAt function. Used to hide the rows that are set to true in the cellIsHidden array by setting their height to 0.
	  - Authors:Hamza Nizameddin
	 */
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
	{
		//for hidden cells return 0
		if(cellIsHidden[indexPath.row]) {
			return 0
		}
		
		return 44
	}
	
	// MARK: - Reset App Data
	/**
	 Deletes all the application data. Removes all keys and values from User Defaults. Removes all keys and values from iCloud Keystore. Removes all keys and values from Keychain. Deletes all data from local and cloud stores.
	 */
	private func resetAppData()
	{
		// First delete all settings in UserDefaults
		for key in nPin.settingsKeyList {
			self.defaults.removeObject(forKey: key)
		}
		self.defaults.removeObject(forKey: nPin.timeoutExpiryDateKey)
		
		// Delete all settings in keystore
		keystore.removeObject(forKey: iCloudSyncKey)
		
		// Delete passcode from keychain
		keychainPassword.clear()
		
		// Delete all CoreData
		self.data.reset()
	}
	
	// MARK: - In-App Purchase
	/**
	 If the premium version is purchased, hides the In-App Purchase buttons, displays the app icon toggle button with the correct text based on the state of the app icon.
	 */
	private func updateIapButtons()
	{
		//if iapManager.isPurchased()
		if iapManagerSK2.isPurchased
		{
			cellIsHidden[buyPremiumRow - 1] = true
			cellIsHidden[buyPremiumRow] = true
			cellIsHidden[restorePremiumRow] = true
			
			cellIsHidden[toggleAppIconRow - 1] = false
			cellIsHidden[toggleAppIconRow] = false
			if appIconManager.isPremiumAppIcon() {
				toggleAppIconButton.setTitle(NSLocalizedString("Revert to original App Icon", comment: "Button label text to revert to original App Icon"), for: .normal)
			} else {
				toggleAppIconButton.setTitle(NSLocalizedString("Upgrade to Premium App Icon", comment: "Button label text to upgrade to Premium App Icon"), for: .normal)
			}
		}
		else
		{
			cellIsHidden[buyPremiumRow - 1] = false
			cellIsHidden[buyPremiumRow] = false
			cellIsHidden[restorePremiumRow] = false
			
			cellIsHidden[toggleAppIconRow - 1] = true
			cellIsHidden[toggleAppIconRow] = true
		}
	}
	
	/**
	 Handles the result of IAPManager purchase or restore transactions. Part of IAPManagerDelegate protocol.
	  - Authors: Hamza Nizameddin
	  - Parameter transactionResult: Result of the in-app purchase transaction. Can be .failed, .purchased or .restored.
	 */
	func handleTransactionResult(transactionResult: IAPManager.TransactionResult)
	{
		var alertText = ""
		
		switch transactionResult
		{
			case .failed:
				alertText = NSLocalizedString("Premium purchase transaction failed", comment: "Alert text for failed purchase transaction")
			case .purchased:
				alertText = NSLocalizedString("Premium purchase transaction successful", comment: "Alert text for successful purchase transaction")
			case .restored:
				alertText = NSLocalizedString("Premium features successfully restored", comment: "Alert text for successful restore transaction")
		}
		
		let alert = UIAlertController(title: alertText, message: nil, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
			guard self != nil else {return}
		}))
		
		updateIapButtons()
		tableView.reloadData()
		present(alert, animated: true)
	}
	
	func handleBuyTransaction(isSuccessful: Bool)
	{
		DispatchQueue.main.async {
			if isSuccessful {
				self.updateIapButtons()
				self.tableView.reloadData()
			}
		}
	}
	
	func handleRestoreTransaction(isRestored: Bool)
	{
		if isRestored
		{
			DispatchQueue.main.async {
				self.updateIapButtons()
				self.tableView.reloadData()
			}
		}
		else
		{
			let alertTitle = NSLocalizedString("You have not purchased the premium version yet", comment: "Alert title for when the user presses the restore button but hasn't purchased the premium version yet.")
			let alertMessage = NSLocalizedString("Would you like to purchase the premium version now?", comment: "Alert message for when the user presses the restore button asking if he wants to purchase the premium version now.")
			let okAction = UIAlertAction(title: "OK", style: .default) { _ in
				self.iapManagerSK2.buyPremium()
			}
			let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .destructive) { _ in
				
			}
			let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
			alertController.addAction(okAction)
			alertController.addAction(cancelAction)
			DispatchQueue.main.async {
				self.present(alertController, animated: true)
			}
		}
		
	}
	
	//MARK: Display Information Alert
	/**
	 Displays an alert box with the specified title and message and an "OK" button to dismiss it.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - title: Alert box title.
	   - message: Alert box message.
	 */
	private func displayInformationAlert(title: String, message: String)
	{
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		DispatchQueue.main.async {
			self.present(alert, animated: true)
		}
	}
}


// MARK: - Custom Switch and Segmented Control Classes
/**
 Custom class that is a child of the standard UISwitch. Adds a key string variable in order to store data in User Defaults.
 - Author: Hamza Nizameddin
 */
class SettingsSwitch: UISwitch
{
	/**Key of the associated value in User Defaults*/
	public var key: String?
}
/**
 Custom class that is a child of the standard UISegmentedControl. Adds a key string variable in order to store data in User Defaults.
 - Author: Hamza Nizameddin
 */
class SettingsSelector: UISegmentedControl
{
	/**Key of the associated value in User Defaults*/
	public var key: String?
}
