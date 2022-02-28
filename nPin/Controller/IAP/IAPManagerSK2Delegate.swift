//
//  IAPManagerSK2Delegate.swift
//  nPin
//
//  Created by Hamza Nizameddin on 24/02/2022.
//

import Foundation
import StoreKit

/**
 Protocol to handle in-app purchase transaction result by a delegate.
 */
 protocol IAPManagerSK2Delegate
{
	 func handleBuyTransaction(isSuccessful: Bool)
	 func handleRestoreTransaction(isRestored: Bool)
}
