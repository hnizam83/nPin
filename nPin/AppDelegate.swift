//
//  AppDelegate.swift
//  nPin
//
//  Created by Hamza Nizameddin on 17/07/2021.
//

import UIKit
import CoreData
import IQKeyboardManagerSwift
import KeychainSwift
import CardScan
import CoreSpotlight

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
	let orientationLock = UIInterfaceOrientationMask.portrait
	let userDefaults = UserDefaults.standard
	let data = DataStack(iCloudSync: UserDefaults.standard.bool(forKey: nPin.iCloudSyncKey))
	//let keychain = KeychainSwift(iCloudSync: UserDefaults.standard.bool(forKey: nPin.iCloudSyncKey))
	let keychainPassword = KeychainPasswordManager(keychain: KeychainSwift(iCloudSync: UserDefaults.standard.bool(forKey: nPin.iCloudSyncKey)), passwordKey: nPin.passcodeKey)
	let iapManager = IAPManager(productId: nPin.productId, keystoreKey: nPin.iapPurchasedKey, premiumAppIconKey: nPin.premiumAppIconKey)
	let iapManagerSK2 = IAPManagerSK2(productIds: [nPin.productId])
	let appIconManager = AppIconManager(premiumAppIconKey: nPin.premiumAppIconKey, premiumAppIconName: nPin.premiumAppIconName)
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		IQKeyboardManager.shared.enable = true
		ScanViewController.configure(apiKey: "UIO8AwVc1h8bhJqmtCqLs5POIKHXQvkY")
		
		return true
	}
	
	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
		return orientationLock
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
	}
}

