//
//  IAPManager.swift
//  nPin
//
//  Created by Hamza Nizameddin on 27/09/2021.
//

import UIKit
import StoreKit

/**
In-App Purchase management class
 
 - Authors: Hamza Nizameddin
 - Note: Manages the in-app purchase functionality of the app. Stores the current status of the purchase in local User Defaults, meaning that if the app is deleted and re-installed, the user will need to restore the purchase of premium features.
*/

class IAPManager: NSObject, SKPaymentTransactionObserver
{
	// MARK: - Private Variables
	/**User Defaults keystore to store purchase status..*/
	private let keystore = UserDefaults.standard
	/**App Store Connect Product ID*/
	private var productId: String
	/**Key in User Defaults to store purchase status.*/
	private var keystoreKey: String
	
	// MARK: - Internal Variables
	/**Delegate to handle the result of a purchase or restore transaction.*/
	var delegate: IAPManagerDelegate?
	/**Enumerator for the possible transaction result sent to the delegate. Possible values are .failed, .purchased and .restored.*/
	enum TransactionResult
	{
		case failed
		case purchased
		case restored
	}
	
	//MARK: - App Icon Variables
	/**Key in User Defaults to store if premium  App Icon is set**/
	private var premiumAppIconKey: String
	
	/**
	 Class initializer
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - productId: ID of the premium content product as defined in AppStoreConnect
	   - keystoreKey: User Defaults key to store purchase status
	 */
	init(productId: String, keystoreKey: String, premiumAppIconKey: String)
	{
		self.productId = productId
		self.keystoreKey = keystoreKey
		self.premiumAppIconKey = premiumAppIconKey
		
		super.init()
		
		SKPaymentQueue.default().add(self)
	}
	
	/**
	 Launch the transaction to buy the Premium version of the app.
	  - Authors: Hamza Nizameddin
	  - Note: First tests that user can make payments. Then adds a  payment request with the productId to the payment queue.
	 */
	func buyPremium()
	{
		guard SKPaymentQueue.canMakePayments() else {return}
		
		let paymentRequest = SKMutablePayment()
		paymentRequest.productIdentifier = productId
		SKPaymentQueue.default().add(paymentRequest)
	}
	
	/**
	 Launch the transaction to restore a previous purchase.
	  - Authors: Hamza Nizameddin
	  - Note: Calls the restoreCompletedTransaction() function on the default SKPaymentQueue.
	 */
	func restorePremium()
	{
		SKPaymentQueue.default().restoreCompletedTransactions()
	}
	
	/**
	 Queries the User Defaults store to check if the Premium version is already purchased.
	  - Authors: Hamza Nizameddin
	  - Returns: True if already purchased, false otherwise.
	 */
	func isPurchased() -> Bool
	{
		return keystore.bool(forKey: keystoreKey)
	}
	
	/**
	 Defines the paymentQueue function in the SKPaymentTransactionObserver protocol. Prints the status of the transaction to the console, finishes the transaction in the default SKPaymentQueue, then calls the handleTransactionResult() function in the delegate to continue processing the result of the purchase in the app.
	 - Authors: Hamza Nizameddin
	 */
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction])
	{
		for transaction in transactions
		{
			let state = transaction.transactionState
			switch state
			{
				case .purchased:
					print("Purchase successful")
					keystore.set(true, forKey: keystoreKey)
					SKPaymentQueue.default().finishTransaction(transaction)
					delegate?.handleTransactionResult(transactionResult: .purchased)
				case .restored:
					print("Restore successful")
					keystore.set(true, forKey: keystoreKey)
					SKPaymentQueue.default().finishTransaction(transaction)
					delegate?.handleTransactionResult(transactionResult: .restored)
				case .failed:
					print("ERROR: Transaction failed!")
					SKPaymentQueue.default().finishTransaction(transaction)
					delegate?.handleTransactionResult(transactionResult: .failed)
				default:
					break
			}
		}
	}
	
	/**
	 Returns a UIAlertController prompting the user to purchase the premium version of the app.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - title: Optional. Defaults to nil. Custom title for the alert box. If nil, will use the predefined localized text "Premium Content".
	   - message: Optional. Defaults to nil. Custom message for the alert box. If nil, will use the predefined localized text "This feature is only available in the premium version".
	   - cancelHandler: Optional. Defaults to nil. Function to be called if the cancel button is pressed.
	  - Returns:UIAlertController with the specified title and message. Also, the alert box provides three buttons: "Buy Premium", "Restore Purchase" and "Cancel".
	  - Note: If the "Buy Premium" or "Restore Purchase" buttons are pressed, the corresponding buyPremium() or restorePremium() functions will be called. If the cancel button is pressed, the provided cancelHandler will be executed.
	 */
	func getPurchaseAlert(title: String? = nil, message: String? = nil, cancelHandler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController
	{
		let title = title ?? NSLocalizedString("Premium Content", comment: "Title text for alert when attempting to access premium content before purchasing")
		let message = message ?? NSLocalizedString("This feature is only available in the premium version", comment: "Generic message text for alert when activating premium feature without having purchased premium content")
		
		let alert = UIAlertController(
			title: title,
			message: message,
			preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Buy Premium", comment: "Title text for buying premium version action"),
			style: .default,
			handler: { [weak self] _ in
				guard let self = self else {return}
				self.buyPremium()
				//self.delegate?.handleTransactionResult(transactionResult: .purchased)
			}))
		
		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Restore Purchase", comment: "Title text for restoring premium version action"),
			style: .default,
			handler: { [weak self] _ in
				guard let self = self else {return}
				self.restorePremium()
				//self.delegate?.handleTransactionResult(transactionResult: .restored)
			}))
		
		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Cancel", comment: "Cancel action"),
			style: .cancel,
			handler: cancelHandler))
		
		return alert
	}
	
	/**
	 Sets the App icon with the premium version of the icon.
	  - Authors: Hamza Nizameddin
	 */
	func setPremiumAppIcon(premiumIconName: String)
	{
		guard UIApplication.shared.supportsAlternateIcons else {
			keystore.set(false, forKey: premiumAppIconKey)
			return
		}
		
		
		UIApplication.shared.setAlternateIconName(premiumIconName) { error in
			if error != nil {
				self.keystore.set(false, forKey: self.premiumAppIconKey)
				return
			} else {
				self.keystore.set(true, forKey: self.premiumAppIconKey)
			}
		}
		
		self.keystore.set(true, forKey: self.premiumAppIconKey)
	
	}
	
	/**
	 Reverts to the standard non-Premium version of the app icon.
	  - Authors: Hamza Nizameddin
	 */
	func setStandardAppIcon()
	{
		UIApplication.shared.setAlternateIconName(nil)
		keystore.set(false, forKey: premiumAppIconKey)
	}
	
	/**
	 Updates the app icon to reflect if the premium has been purchased.
	 - Authors: Hamza Nizameddin
	 */
	func updateAppIcon()
	{
		if keystore.bool(forKey: premiumAppIconKey) {
			setPremiumAppIcon(premiumIconName: "nPinPremium")
		} else {
			setStandardAppIcon()
		}
	}
	
	func toggleAppIcon()
	{
		if keystore.bool(forKey: premiumAppIconKey) {
			setStandardAppIcon()
		} else {
			setPremiumAppIcon(premiumIconName: "nPinPremium")
		}
	}
	
	/**
	 Returns the state of the app icon.
	  - Authors: Hamza Nizameddin
	  - Returns: True if premium app icon is set, false if the standard app icon is set.
	 */
	func isPremiumAppIcon() -> Bool
	{
		return keystore.bool(forKey: premiumAppIconKey)
	}
	
	/**
	 Deletes the entry in the User Defaults for the purchase status.
	  - Authors: Hamza Nizameddin
	 */
	func resetKeystore()
	{
		keystore.removeObject(forKey: keystoreKey)
	}
}
