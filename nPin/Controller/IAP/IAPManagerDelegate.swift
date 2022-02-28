//
//  IAPManagerDelegate.swift
//  nPin
//
//  Created by Hamza Nizameddin on 01/10/2021.
//

import Foundation
import StoreKit

/**
 Protocol to handle in-app purchase transaction result by a delegate.
 */
 protocol IAPManagerDelegate
{
	func handleTransactionResult(transactionResult: IAPManager.TransactionResult)
	 
	 func handleTransactionResult(transactionResult: Product.PurchaseResult)
}
