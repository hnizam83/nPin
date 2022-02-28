//
//  CloudUserDefaults.swift
//  nPin
//
//  Created by Hamza Nizameddin on 10/08/2021.
//

import Foundation

class CloudUserDefaults
{
	private let keyStore = NSUbiquitousKeyValueStore()
	private let userDefaults = UserDefaults.standard
	private var iCloudSync: Bool = false
	private var iCloudSyncKey: String = "iCloudSync"
	private let lastUpdateKey: String = "lastUpdate"
	public var userKeys: [String] = []
	
	public enum MergeOption {
		case keepCloudValues
		case keepLocalValues
	}
	
	public enum LastUpdateResult {
		case localIsNewer
		case cloudIsNewer
		case cloudDoesNotExist
		case error
	}
	
	init(iCloudSyncKey: String = "iCloudSync", userKeys: [String] = [])
	{
		if iCloudSyncKey.count > 0 {
			self.iCloudSyncKey = iCloudSyncKey
		}
		
		for userKey in userKeys {
			self.userKeys.append(userKey)
		}
		
		self.iCloudSync = self.userDefaults.bool(forKey: self.iCloudSyncKey)
		
		if self.iCloudSync == true {
			self.synchronizeCloudStore()
		}
		
		if self.userDefaults.object(forKey: self.lastUpdateKey) == nil {
			self.userDefaults.set(Date(), forKey: self.lastUpdateKey)
		}
	}
	
	public func bool(forKey defaultName: String) -> Bool
	{
		if self.iCloudSync {
			let result = self.keyStore.bool(forKey: defaultName)
			self.userDefaults.set(result, forKey: defaultName)
			return result
		} else {
			return self.userDefaults.bool(forKey: defaultName)
		}
	}
	
	public func integer(forKey defaultName: String) -> Int
	{
		if self.iCloudSync {
			let result = Int(truncatingIfNeeded: keyStore.longLong(forKey: defaultName))
			userDefaults.set(result, forKey: defaultName)
			return result
		} else {
			return self.userDefaults.integer(forKey: defaultName)
		}
	}
	
	public func object(forKey defaultName: String) -> Any?
	{
		if self.iCloudSync {
			let result = keyStore.object(forKey: defaultName)
			if let safeResult = result {
				self.userDefaults.set(safeResult, forKey: defaultName)
			}
			return result
		} else {
			return self.userDefaults.object(forKey: defaultName)
		}
	}
	
	public func removeObject(forKey defaultName: String)
	{
		let currentDate = Date()
		
		if self.iCloudSync {
			self.keyStore.removeObject(forKey: defaultName)
			self.keyStore.set(currentDate, forKey: self.lastUpdateKey)
		}
		self.userDefaults.removeObject(forKey: defaultName)
		self.userDefaults.set(currentDate, forKey: self.lastUpdateKey)
	}
	
	public func set(_ value: Any?, forKey: String)
	{
		let currentDate = Date()
		
		if self.iCloudSync {
			self.keyStore.set(value, forKey: forKey)
			self.keyStore.set(currentDate, forKey: self.lastUpdateKey)
			self.keyStore.synchronize()
		}
		self.userDefaults.set(value, forKey: forKey)
		self.userDefaults.set(currentDate, forKey: self.lastUpdateKey)
		
	}
	
	public func reset()
	{
		if self.iCloudSync {
			self.resetCloudStore()
		}
		self.resetLocalStore()
	}
	
	private func resetLocalStore()
	{
		for key in self.userDefaults.dictionaryRepresentation().keys {
			self.userDefaults.removeObject(forKey: key)
		}
	}
	
	private func resetCloudStore()
	{
		for key in self.keyStore.dictionaryRepresentation.keys {
			self.keyStore.removeObject(forKey: key)
			self.keyStore.synchronize()
		}
	}
	
	public func activateCloudSync(mergeOption: MergeOption)
	{
		if self.iCloudSync == true {
			return
		}
		
		self.iCloudSync = true
		self.userDefaults.set(true, forKey: self.iCloudSyncKey)
		self.keyStore.set(true, forKey: self.iCloudSyncKey)
		
		if mergeOption == .keepLocalValues {
			self.pushToCloudStore()
		} else if mergeOption == .keepCloudValues {
			self.pullFromCloudStore()
		}
	}
	
	public func deactivateCloudSync()
	{
		if self.iCloudSync == false {
			return
		}
		
		let currentDate = Date()
		
		self.iCloudSync = false
		self.userDefaults.set(false, forKey: self.iCloudSyncKey)
		self.userDefaults.set(currentDate, forKey: self.lastUpdateKey)
	}
	
	public func getLastUpdateResult() -> LastUpdateResult
	{
		let cloudLastUpdate: Date? = self.keyStore.object(forKey: self.lastUpdateKey) as? Date
		let localLastUpdate: Date? = self.userDefaults.object(forKey: self.lastUpdateKey) as? Date

		if cloudLastUpdate == nil {
			return .cloudDoesNotExist
		} else {
			if let safeCloudLastUpdate = cloudLastUpdate,
			   let safeLocalLastUpdate = localLastUpdate {
				if safeCloudLastUpdate > safeLocalLastUpdate {
					return .cloudIsNewer
				} else {
					return .localIsNewer
				}
			}
		}
		return .error
	}
	
	public func synchronizeCloudStore()
	{
		let cloudLastUpdate: Date? = self.keyStore.object(forKey: self.lastUpdateKey) as? Date
		let localLastUpdate: Date? = self.userDefaults.object(forKey: self.lastUpdateKey) as? Date
		
		if cloudLastUpdate == nil && localLastUpdate != nil {
			self.pushToCloudStore()
		}
		else if cloudLastUpdate != nil && localLastUpdate == nil {
			self.pullFromCloudStore()
		}
		else {
			if let safeCloudLastUpdate = cloudLastUpdate,
			   let safeLocalLastUpdate = cloudLastUpdate {
				if safeCloudLastUpdate > safeLocalLastUpdate {
					self.pullFromCloudStore()
				} else {
					self.pushToCloudStore()
				}
			}
		}
	}
	
	private func pullFromCloudStore()
	{
		self.resetLocalStore()
		self.keyStore.synchronize()
		for key in self.userKeys {
			self.userDefaults.set(self.keyStore.object(forKey: key), forKey: key)
		}
	}
	
	private func pushToCloudStore()
	{
		self.resetCloudStore()
		for key in self.userKeys {
			let value = self.userDefaults.object(forKey: key)
			switch value {
				case is String:
					self.keyStore.set(value as? String, forKey: key)
				case is Bool:
					self.keyStore.set(value as? Bool, forKey: key)
				case is Int:
					self.keyStore.set(value as? Int, forKey: key)
				case is Date:
					self.keyStore.set(value as? Date, forKey: key)
				default:
					print("Nothing")
			}
		}
		self.keyStore.synchronize()
	}
}
