//
//  IAPManagerSK2.swift
//  nPin
//
//  Created by Hamza Nizameddin on 22/02/2022.
//

import Foundation
import UIKit
import StoreKit

class IAPManagerSK2: ObservableObject
{
	// MARK: - Private Variables
	/**App Store Connect Product ID*/
	private var productIds: [String] = []
	/**List of Products obtained from running fetchProducts*/
	private var products: [Product] = []
	
	// MARK: - Internal Variables
	/**Delegate to handle to result of a purchase or restore transaction*/
	var delegate: IAPManagerSK2Delegate?
	/**True if purchased, false otherwise*/
	var isPurchased: Bool = false
	
	// MARK: - Initializers
	/**
	 Class initializer
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - productIds: String array of the product IDs defined in AppStoreConnect
	 */
	init(productIds: [String])
	{
		for productId in productIds {
			self.productIds.append(productId)
		}
		self.fetchProducts()
	}
	
	// MARK: - In-app Purchase Functions
	/**
	 Fetches all the products in the App Store using the product IDs specified in productIds
	  - Authors: Hamza Nizameddin
	 */
	func fetchProducts()
	{
		Task.init(priority: .high) {
			do {
				let products = try await Product.products(for: self.productIds)
				self.products = products
				await updatePurchasedState()
			} catch {
				print(error.localizedDescription)
			}
		}
	}
	
	/**
	 Launch the transaction to buy the Premium version of the app.
	  - Authors: Hamza Nizameddin
	  - Note: First tests that user can make payments. Then adds a  payment request with the productId to the payment queue.
	 */
	func buyPremium()
	{
		guard let product = products.first else {
			print("Error retrieving premium version")
			return
		}
		
		guard let delegate = delegate else {
			return
		}
		
		Task.init(priority: .high) {
			do {
				let result = try await product.purchase()
				switch result {
					case .success(let verification):
						switch verification {
							case .unverified(_, _):
								delegate.handleBuyTransaction(isSuccessful: false)
								break
							case .verified(_):
								self.isPurchased = true
								delegate.handleBuyTransaction(isSuccessful: true)
								break
						}
					case .userCancelled:
						delegate.handleBuyTransaction(isSuccessful: false)
						break
					case .pending:
						delegate.handleBuyTransaction(isSuccessful: false)
						break
					@unknown default:
						fatalError()
						break
				}
			} catch {
				print(error.localizedDescription)
			}
		}
		
	}
	
	/**
	 Launch the transaction to restore a previous purchase.
	  - Authors: Hamza Nizameddin
	  - Note: Calls the restoreCompletedTransaction() function on the default SKPaymentQueue.
	 */
	func restorePremium()
	{
		guard let product = products.first else {
			print("Error retrieving premium version")
			return
		}
		
		guard let delegate = delegate else {
			return
		}
		
		Task.init(priority: .high) {
			guard let state = await product.currentEntitlement else {
				delegate.handleRestoreTransaction(isRestored: false)
				return
			}
			switch state {
				case .unverified(_, _):
					delegate.handleRestoreTransaction(isRestored: false)
					break
				case .verified(_):
					delegate.handleRestoreTransaction(isRestored: true)
					break
			}
		}
	}
	
	/**
	 Queries the User Defaults store to check if the Premium version is already purchased.
	  - Authors: Hamza Nizameddin
	  - Returns: True if already purchased, false otherwise.
	 */
	func updatePurchasedState() async
	{
		guard let product = products.first else {
			print("Error fetching products")
			return
		}
		
		guard let state = await product.currentEntitlement else {
			DispatchQueue.main.async {
				self.isPurchased = false
			}
			return
		}
		switch state {
			case .verified(_):
				DispatchQueue.main.async {
					self.isPurchased = true
				}
				break
			case .unverified(_,_):
				DispatchQueue.main.async {
					self.isPurchased = false
				}
				break
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
}
