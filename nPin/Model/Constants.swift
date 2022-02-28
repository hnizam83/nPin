//
//  Constants.swift
//  nPin
//
//  Created by Hamza Nizameddin on 18/08/2021.
//

import Foundation

/**
 Struct defined to set all the constants used throughout the nPin app.
  - Authors: Hamza Nizameddin
 */
struct nPin
{
	// MARK: - Settings keys
	
	/**Key in User Defaults for the Biometric ID boolean option.*/
	static let biometricIdKey = "biometricId"
	/**Key in User Defaults for the Fake Pin boolean option.*/
	static let fakePinKey = "fakePin"
	/**Key in User Defaults for the Timeout Lock boolean option.*/
	static let timeoutLockKey = "timeoutLock"
	/**Key in User Defaults for the PIN code display security boolean option.*/
	static let pinDisplaySecurityKey = "pinDisplaySecurity"
	/**Key in User Defaults for the reverse PIN code boolean option.*/
	static let reversePinKey = "reversePin"
	/**Key in User Defaults for the random PIN codes boolean option.*/
	static let randomPinKey = "randomPin"
	/**Key in User Defaults for the random maximum number of passcode tries before the user is locked out integer value.*/
	static let maxRetriesKey = "maxRetries"
	/**Key in User Defaults for the length in minutes of the time out in case the user types in the wrong passcode several times integer value.*/
	static let timeoutLengthKey = "timeoutLength"
	/**List of all the keys for the settings stored in User Defaults*/
	static let settingsKeyList = [
		biometricIdKey,
		fakePinKey,
		timeoutLockKey,
		pinDisplaySecurityKey,
		reversePinKey,
		randomPinKey,
		maxRetriesKey,
		timeoutLengthKey
	]
	
	/**Key in User Defaults for the timedate value of the time out lock if one is actualy in effect.*/
	static let timeoutExpiryDateKey = "timeoutExpiryDate"
	
	// MARK: - Keychain keys
	
	/**Key in keychain for the passcode*/
	static let passcodeKey = "passcode"
	
	// MARK: - Keystore keys
	
	/**Key in the cloud-based keystore for the iCloud synchronization option.*/
	static let iCloudSyncKey = "iCloudSync"
	
	// MARK: - Image names
	
	/**SFSymbol name for the empty circle displayed above the number pad*/
	static let emptyCircleImageName = "circle"
	/**SFSymbol name for the filled circle displayed above the number pad*/
	static let filledCircleImageName = "circle.fill"
	/**SFSymbol name for the FaceID symbol displayed in the login screen when FaceID is enabled.*/
	static let faceIdImageName = "faceid"
	/**SFSymbol name for the TouchID symbol displayed in the login screen when TouchID is enabled.*/
	static let touchIdImageName = "touchid"
	/**SFSymbol name for the backspace symbol displayed in the number pad.*/
	static let deleteButtonImageName = "delete.left.fill"
	/**SFSymbol name for the cameral symbol displayed in number pad which allows the user the scan the card instead of typing the last 4 digits.*/
	static let scanButtonImageName = "camera.fill"
	/**SFSymbol name for the credit card symbol displayed in the button to select the color of the credit card.*/
	static let creditCardcolorButtonImageName = "creditcard"
	/**SFSymbol name for the credit card symbol displayed in the selected button for the color of the credit card.*/
	static let creditCardcolorButtonSelectedImageName = "creditcard.fill"
	/**SFSymbol name for the delete left swipe action*/
	static let trailingSwipeActionDeleteImageName = "trash"
	/**SFSymbol name for the favorite right swipe action*/
	static let leadingSwipeActionFavoriteImageName = "heart"
	/**SFSymbol name for the un-favorite right swipte action*/
	static let leadingSwipeActionNonFavoriteImageName = "heart.slash"
	
	// MARK: - Segue identifiers
	
	/**Segue to navigate from Login to Access*/
	static let passcodeToAccessSegue = "passcodeToAccessSegue"
	/**Segue to navigate from List view to Edit card view*/
	static let listToEditSegue = "listToEditSegue"
	/**Segue to navigate from List view to Display PIN Code view*/
	static let listToDisplaySegue = "listToDisplaySegue"
	/**Segue to navigate from Access view to Display PIN Code view*/
	static let accessToDisplaySegue = "accessToDisplaySegue"
	/**Segue to navigate from Access view to New card view*/
	static let accessToEditSegue = "accessToEditSegue"
	/**Segue to navigate from Settings view to Change Passcode view*/
	static let settingsToResetPasscodeSegue = "settingsToResetPasscodeSegue"
	
	// MARK: - Storyboard
	
	/**Main storyboard name.*/
	static let mainStoryboardName = "Main"
	/**Name of New Passcode VC class. Used to navigate from login screen to new passcode screen on first launch or to reset passcode when forgotten.*/
	static let newPasscodeViewControllerId = "NewPasscodeViewController"
	
	// MARK: - Display Formatting
	/**Application wide font name*/
	static let fontName = "Arial Rounded MT Bold"
	
	// MARK: - Tableview
	/**Cell Identifier for the Card List View Controller Table View.*/
	static let listCellId = "listCell"
	
	// MARK: - Data Structure
	/**Size of the digits field of the card entity*/
	static let digitsSize = 4
	/**Size of the PIN code  field of the card entity*/
	static let pinSize = 4
	/**Number of fake pins generated for each card entity*/
	static let numberOfFakePins = 9
	/**Length of the application passcode*/
	static let passcodeSize = 6
	
	// MARK: - Colors
	
	// MARK: - In-App Purchases
	/**In-App Purchase Product ID for Premium features.*/
	static let productId = "com.nmash.nPin.Premium"
	/**Key in User Defaults to indicate the user has already purchased the Premium version of the app.*/
	static let iapPurchasedKey = "iapPurchased"
	/**Limit of cards that can be stored in the free version of the app.*/
	static let freeCardLimit = 3
	/**Key in User Defaults storing the App Icon state.*/
	static let premiumAppIconKey = "premiumAppIconKey"
	/**Name of the Premium App Icon image.*/
	static let premiumAppIconName = "nPinPremium"
}
