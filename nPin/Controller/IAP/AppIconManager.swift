//
//  AppIconManager.swift
//  nPin
//
//  Created by Hamza Nizameddin on 22/02/2022.
//

import UIKit

class AppIconManager
{
	//MARK: - Private Variables
	/**User Defaults to store premium App Icon status**/
	private let keystore = UserDefaults.standard
	/**Key in User Defaults to store if premium App Icon is set**/
	private var premiumAppIconKey: String
	/**Name of the Premium App Icon image in XCAssets**/
	private var premiumAppIconName: String
	
	
	// MARK: - Initializers
	init(premiumAppIconKey: String, premiumAppIconName: String)
	{
		self.premiumAppIconKey = premiumAppIconKey
		self.premiumAppIconName = premiumAppIconName
	}
	
	/**
	 Sets the App icon with the premium version of the icon.
	  - Authors: Hamza Nizameddin
	 */
	func setPremiumAppIcon()
	{
		guard UIApplication.shared.supportsAlternateIcons else {
			keystore.set(false, forKey: premiumAppIconKey)
			return
		}
		
		
		UIApplication.shared.setAlternateIconName(premiumAppIconName) { error in
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
			setPremiumAppIcon()
		} else {
			setStandardAppIcon()
		}
	}
	
	func toggleAppIcon()
	{
		if keystore.bool(forKey: premiumAppIconKey) {
			setStandardAppIcon()
		} else {
			setPremiumAppIcon()
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
}
