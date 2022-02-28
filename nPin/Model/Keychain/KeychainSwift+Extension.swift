//
//  KeychainSwift+Extension.swift
//  nPin
//
//  Created by Hamza Nizameddin on 11/08/2021.
//

import Foundation
import KeychainSwift

/**
 Extension to the KeychainSwift class. Provides three new functions regarding managing the cloud synchronization of the KeychainSwift object.
  - Authors: Hamza Nizameddin
  - Note: This extension defines three function. 1) A convenience initializer that sets the value of synchronizable when the object is instantiated. 2) The activateSyncWithLocalValues() function that sets synchronizable to true wihle keeping the values of the local keychain. 3) the deactivateSyncDeleteCloudValues() function which deletes all the values stored in the cloud keychain before setting synchronizable to false.
 */
extension KeychainSwift
{
	/**
	 Convenience initializer that sets the value of the class variable synchronizable when the object is instantiated.
	  - Authors: Hamza Nizameddin
	  - Parameter iCloudSync: Boolean indicating the starting value of the class variable synchronizable.
	 */
	convenience init (iCloudSync: Bool)
	{
		self.init()
		synchronizable = iCloudSync
	}
	
	/**
	 Set class variable synchronizable to true while keeping the local values stored in the keychain.
	  - Authors: Hamza Nizameddin
	  - Note: If the synchronizable class variable is already true, this function will exit without doing anything. Otherwise, it will copy all the key-value pairs in the local keychain to a temporary dictionary. Then it will set synchronizable to true. Then it will copy all the values in the temporary dictionary back to the keychain which is now cloud-enabled.
	 */
	public func activateSyncWithLocalValues()
	{
		guard !self.synchronizable else {return}
		
		var localValues : [String: String] = [:]
		
		// save a copy of all the values stored in the local keychain
		for key in self.allKeys {
			if let value = self.get(key) {
				localValues[key] = value
			}
		}
		
		self.synchronizable = true
		
		// re-copy all the local values to the cloud keychain
		for key in localValues.keys {
			if let value = localValues[key] {
				self.set(value, forKey: key)
			}
		}
	}
	
	/**
	 Set class variable synchronizable to false while deleting all values stored in the cloud keychain so that they cannot be accessed by any other device anymore.
	  - Authors: Hamza Nizameddin
	  - Note: If the synchronizable class variable is already false, this function exits without doing anything. Otherwise, it will copy all the key-value pairs in the cloud keychain to a temporary dictionary. Then it will clear the keychain to delete all values from the cloud store. Then it will set synchronizable to false in order to activate the local store. Then it will copy all the values that were stored in the temporary dictionary back to the local keychain store. 
	 */
	public func deactivateSyncDeleteCloudValues()
	{
		guard self.synchronizable else {return}
		
		var cloudValues: [String: String] = [:]
		
		// save a copy of all the values stored in the cloud keychain
		for key in self.allKeys {
			if let value = self.get(key) {
				cloudValues[key] = value
			}
		}
		
		self.clear()
		
		self.synchronizable = false
		
		// re-copy all the keys in the local store
		for key in cloudValues.keys {
			if let value = cloudValues[key] {
				self.set(value, forKey: key)
			}
		}
	}
}
