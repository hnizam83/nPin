//
//  Passcode.swift
//  nPin
//
//  Created by Hamza Nizameddin on 11/09/2021.
//

import Foundation
import KeychainSwift
import CryptoSwift

/**
 Keychain password manager class. Handles the storage, hashing, testing and synchnization of an app password with KeychainSwift.
  - Authors: Hamza Nizameddin
  - Note: Depends on KeychainSwift, its extension and CryptoSwift libraries. This class provides functions to securely store a password in Keychain by salting and hashing. Also stores the salt and hash method along with the password. Provides support for clear, md5, sha1, sha256 and sha512 secure hashing.
 */
class KeychainPasswordManager
{
	// MARK: - Internal variables
	
	private var _keychain = KeychainSwift()
	/**
	 Key to access the password hash stored in the keychain. Defaults to "password".
	 */
	private let _passwordKey: String
	/**
	 Key to access the salt stored in the keychain. Defaults to "salt".
	 */
	private let _saltKey: String
	/**
	 Key to access the hash method stored in the keychain. Defaults to "clear". Available options are "clear", "md5", "sha1", "sha256" and "sha512".
	 */
	private let _hashTypeKey: String
	/**
	 Specifies the length of the salt used to hash the password.
	 */
	private var _saltLength: Int
	/**
	 Specifies the type of hash used to store the password. Defaults to .clear. Available options are .clear, .md5, .sha1, .sha256 and .sha512.
	 */
	private var _hashType: HashType
	
	/**
	 Sets the minimum length of the salt. Set to 4.
	 */
	private let _minSaltLength = 4
	
	// MARK: - External computed variables
	
	/**
	 Returns the key to access the password stored in the keychain. Default is "password".
	 */
	var passwordKey: String {
		return _passwordKey
	}
	/**
	 Returns the key to access the salt stored in the keychain. Default is "salt".
	 */
	var saltKey: String {
		return _saltKey
	}
	/**
	 Returns the key to access the hash type stored in the keychain. Default is "clear". Possible results are "clear", "md5", "sha1", "sha256" and "sha512".
	 */
	var hashTypeKey: String {
		return _hashTypeKey
	}
	/**
	 Returns the length of the salt used to hash the password.
	 */
	var saltLength: Int {
		return _saltLength
	}
	/**
	 Returns the hash method as a String. Possible values are "clear", "md5", "sha1", "sha256" and "sha512".
	 */
	var hashType: String {
		return _hashType.rawValue
	}
	/**
	 Returns the synchronizable variable state of the underlying KeychainSwift object.
	 */
	var synchronizable: Bool {
		return _keychain.synchronizable
	}
	/**
	 Returns the hashed password string if it is stored in the keychain. Otherwise, it will return an empty string.
	 */
	var password: String {
		return _keychain.get(_passwordKey) ?? ""
	}
	/**
	 Retruns the salt string if it is stored in the keychain. Otherwise, it will return an empty string.
	 */
	var salt: String {
		return _keychain.get(_saltKey) ?? ""
	}
	
	// MARK: - Enumerators
	
	/**
	 Enumerator for the supported hash method. Possible values are .clear, .md5, .sha1, .sha256 and .sha512. Possible raw values are "clear", "md5", "sha1", "sha256" and "sha512".
	 */
	enum HashType: String, CaseIterable
	{
		case clear = "clear"
		case md5 = "md5"
		case sha1 = "sha1"
		case sha256 = "sha256"
		case sha512 = "sha512"
	}
	
	/**
	 Enumerator for the selection of synchronization options when it is turned on and off. Possible values are .keepLocal and .keepCloud.
	 */
	enum SyncOption: CaseIterable
	{
		case keepLocal
		case keepCloud
	}
	
	// MARK: - Initializer
	
	/**
	 Initializer. All parameters are optional and have default values.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	    - keychain: KeychainSwift object used to handle requests to the keychain. Defaults to a new KeychainSwift object.
	    - passwordKey: Key to be used to store and retrieve hashed password to and from keychain. Defaults to "password".
	    - saltKey: Key to be used to store and retrieve salt string to and from keychain. Defaults to "salt".
	    - hashTypeKey: Key to be used to store and retrieve hash method string to and from keychain. Defaults to "hashType".
	    - hashType: Hash method used to hash the password before storing it. Defaults to .clear. If a hash method is already stored in the keychain, this parameter has no effect.
	    - saltLength: Length of the salt string to be generated and used to hash the password before storing it in the keychain. Defaults to 12. If a salt string string is already stored in the keychain, this parameter has no effect.
	 */
	init(keychain: KeychainSwift = KeychainSwift(), passwordKey: String = "password", saltKey: String = "salt", hashTypeKey: String = "hashType", hashType: HashType = .clear, saltLength: Int = 12)
	{
		self._keychain = keychain
		self._passwordKey = passwordKey
		self._saltKey = saltKey
		self._hashTypeKey = hashTypeKey
		self._hashType = hashType
		
		// if hash type already exists, use the current hash type
		if let storedHashType = self._keychain.get(self._hashTypeKey) {
			self._hashType = HashType(rawValue: storedHashType)!
		}
		
		// if there is alread a store salt, then use that to get the salt length
		if let storeSalt = self._keychain.get(self._saltKey) {
			self._saltLength = storeSalt.count
		} else {
			// otherwise, use the specified length
			self._saltLength = 12
		}
	}
	
	// MARK: Password Functions
	/**
	 Tests the input to verify if it matches the password stored in the keychain.
	  - Authors: Hamza Nizameddin
	  - Parameter input: String to be tested.
	  - Returns: True if the input matches the password stored in the keychain. False if the input does not match password store in the keychain or if no password is stored in the keychain.
	  - Note: This function will first test that there is a password stored in the keychain. If not, it will return false. If the hash method is clear, it will simply compare the input string to the stored password string and return true if they match. Otherwise, it will retrieve the salt string and the hash method from the keychain. It will hash the input using the retrieved salt string and hash method. If the hashed version of the input and the hashed password stored in the keychain match it will return true and false otherwise.
	 */
	func testPassword(_ input: String) -> Bool
	{
		guard input.count > 0 else {return false}
		guard let hashedPassword = _keychain.get(_passwordKey) else {return false}
		let salt = _keychain.get(_saltKey) ?? ""
		let hashTypeString = _keychain.get(_hashTypeKey) ?? "clear"
		let hashType = HashType(rawValue: hashTypeString)
		
		return hashedPassword == getHashedPassword(input: salt + input, hashType: hashType)
	}
	
	/**
	 Change the password stored in the keychain by providing the current password for verification. Can be used to modify the hash method and the salt length as well by specifying the new password the same as the stored password. Can also be used to reset or set initial password.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - newPassword: New password to be salted, hashed and stored in the keychain.
	   - currentPassword: Optional. Defaults to nil. Current password for verification. If it is provided and it doesn't match the password stored in the keychain, the function will return false.
	   - newHashType: Optional. Defaults to nil. New hash method to be used for the hashing the password. If it is nil then the old hash method will be used.
	   - newSaltLength: Optional. Defaults to nil. New salt string length. If it is nil then the old salt string length will be used.
	  - Returns: True if the new password was successfully set. False if the current password provided doesn't match the stored password, or if there was an error storing the new hashed password, salt and hash method to the keychain.
	  - Note: This function first checks if there is a password stored in the keychain. If so, it will verify that the current password supplied matches with the sotred password,  return false if they do not match or if they match, it will update the hash type and salt length if provided, hash and store the new password hash in the keychain. If there is no stored password, the function wil set a new password without verifying current password (used for resetting or initializing password). In order to change the hashType and/or the salt length, use this function with the new password the same as the old password.
	 */
	@discardableResult
	func setPassword(newPassword: String, currentPassword: String? = nil, newHashType: HashType? = nil, newSaltLength: Int? = nil) -> Bool
	{
		// in case there is already a stored password, test if the provided current password is valid
		if _keychain.get(_passwordKey) != nil
		{
			if let currentPassword = currentPassword {
				if !testPassword(currentPassword) {
					// supplied current password is incorrect
					return false
				}
			} else {
				// no current password supplied
				return false
			}
		}
		
		// if there is no previous password, or supplied current password is correct
		// go ahead and set a new password
		
		// if a new hash type is specified, then change it now so it is stored properly with the new password
		if let newHashType = newHashType {
			self._hashType = newHashType
		}
		
		// if a new salt length is specified, then change it now so it is stored properly with the new password
		if let newSaltLength = newSaltLength {
			self._saltLength = newSaltLength
		}
		
		// generate random 12
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		var salt = ""
		for _ in 1..._saltLength {
			salt.append(letters.randomElement()!)
		}
		
		let hashedPassword = getHashedPassword(input: salt + newPassword)

		var valid = true
		
		if !_keychain.set(hashedPassword, forKey: _passwordKey) {valid = false}
		if !_keychain.set(salt, forKey: _saltKey) {valid = false}
		if !_keychain.set(_hashType.rawValue, forKey: _hashTypeKey) {valid = false}

		return valid
	}
	
	/**
	 Reset the password stored in the keychain.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - newPassword: New password sttring.
	   - newHashType: Optional. Defaults to nil. New hash method to be used for the hashing the password. If it is nil then the old hash method will be used.
	   - newSaltLength: Optional. Defaults to nil. New salt string length. If it is nil then the old salt string length will be used.
	  - Returns: True if the password was successfully reset, false otherwise.
	  - Note: This function first deletes the hashed password, salt and hash method values stored in the keychain and then calls the setPassword method to set the new password.
	 */
	@discardableResult
	func resetPassword(newPassword: String, newHashType: HashType? = nil, newSaltLength: Int? = nil) -> Bool
	{
		_keychain.delete(_passwordKey)
		_keychain.delete(_saltKey)
		_keychain.delete(_hashTypeKey)
		return setPassword(newPassword: newPassword, newHashType: newHashType, newSaltLength: newSaltLength)
	}
	
	/**
	 Set the hash method. Current password must be provided.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - newHashType: The new hash method to be used to hash the password. Possible values are .clear, .md5, .sha1, .sha256 and .sha512.
	   - currentPassword: The password currently stored in the keychain.
	  - Returns: True if the new hash method is properly stored and the password was properly rehashed and stored in the keychain, false otherwise.
	  - Note: If a password is already stored in the keychain, this method will call on the setPassword method to verify the supplied current password, store the new hash method, hash the password with the new hash method and store it in the keychain. Otherwise, it will simply update the class variable hashType.
	 */
	@discardableResult
	func setHashType(newHashType: HashType, currentPassword: String) -> Bool
	{
		if _keychain.get(_passwordKey) != nil {
			return setPassword(newPassword: currentPassword, currentPassword: currentPassword, newHashType: newHashType)
		} else {
			self._hashType = newHashType
			return true
		}
	}
	
	/**
	 Set the hash method using a string description. Current password must be provided.
	 - Authors: Hamza Nizameddin
	 - Parameters:
	  - newHashTypeString: The new hash method to be used to hash the password as a string. Possible values are "clear", "md5"," sha1", "sha256" and "sha512".
	  - currentPassword: Current password to be checked against the password stored in the keychain.
	 - Returns: True if the new hash method is properly stored and the password was properly rehashed and stored in the keychain, false otherwise.
	 - Note: If a password is already stored in the keychain, this method will call on the setPassword method to verify the supplied current password, store the new hash method, hash the password with the new hash method and store it in the keychain. Otherwise, it will simply update the class variable hashType.
	*/
	@discardableResult
	func setHashType(newHashTypeString: String, currentPassword: String) -> Bool
	{
		guard let newHashType = HashType(rawValue: newHashTypeString) else {return false}
		return setHashType(newHashType: newHashType, currentPassword: currentPassword)
	}
	
	/**
	 Set the lenght of the salt string. Current password must be provided.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - newSaltLength: The new length of the random salt string.
	   - currentPassword; Current password to be checked against the password stored in the keychain.
	  - Returns:True if the new salt string length  is properly stored and the password was properly rehashed and stored in the keychain, false otherwise.
	  - Note: If a password is already stored in the keychain, this method will call on the setPassword method to verify the supplied current password, store the new salt length, generate a new random salt, hash the password  and store it in the keychain. Otherwise, it will simply update the class variable saltLength.
	 */
	@discardableResult
	func setSaltLength(newSaltLength: Int, currentPassword: String) -> Bool
	{
		guard newSaltLength >= _minSaltLength else {return false}
		if _keychain.get(_passwordKey) != nil {
			return setPassword(newPassword: currentPassword, currentPassword: currentPassword, newSaltLength: newSaltLength)
		} else {
			self._saltLength = newSaltLength
			return true
		}
	}
	
	/**
	 Check if a password is stored in the keychain.
	  - Authors: Hamza Nizameddin
	  - Returns:True if there is a password stored in the keychain. False otherwise.
	 */
	func passwordExists() -> Bool
	{
		return _keychain.get(_passwordKey) != nil
	}
	
	// MARK: - Keychain Management Functions
	
	/**
	 Clear the keychain of all its stores values.
	  - Authors: Hamza Nizameddin
	 */
	func clear()
	{
		_keychain.clear()
	}
	
	/**
	 De-activate keychain cloud synchronization with an option to delete the data in the cloud. If cloud synchronization is already de-activated, this function will exit.
	  - Authors: Hamza Nizameddin
	  - Parameter deleteCloudData: If true, will delete the data in the cloud keychain store.
	  - Note: The function works off of the synchronizable variable in the underlying KeychainSwift object keychain. If it detects that synchronizable is already false, it will exit without doing anything. Otherwise, if deleteCloudData is set to true, it will call the deactivateSyncDeleteCloudValues() function in the extension to KeychainSwift to delete all keychain data in the cloud before setting the synchronizable variable to false. Otherwise, it just sets the synchronizable variable to false.
	 */
	func deactivateSync(deleteCloudData: Bool)
	{
		guard _keychain.synchronizable else {return}
		
		if deleteCloudData {
			_keychain.deactivateSyncDeleteCloudValues()
		} else {
			_keychain.synchronizable = false
		}
	}
	
	/**
	 Activate keychain cloud synchronization with options on whether to keep local or cloud values..
	  - Authors: Hamza Nizameddin
	  - Parameter syncOption: Specifies the synchronization option. Possible values are .keepLocal or .keepCloud.
	  - Note: This function works off of the synchronizable variable in the underlying KeychainSwift object keychain. If it detects that synchnoizable is alreay true, it will exit without doing anything. Otherwise, if .keepLocalData is selected, it will call the activateSyncWithLocalValues() function in the extension to KeychainSwift to activate cloud synchronizaiton and copy all the local values to the cloud. Otherwise, it just sets the synchronizable variable to true, which authomatically keeps all the cloud data as the working data.
	 */
	func activateSync(syncOption: SyncOption)
	{
		guard !_keychain.synchronizable else {return}
		
		if syncOption == .keepLocal {
			_keychain.activateSyncWithLocalValues()
		} else {
			_keychain.synchronizable = true
		}
	}
	
	// MARK: - Helper functions
	/**
	 Hash an input using the provided hashType, or the class variable hashType if  none is detected.
	  - Authors: Hamza Nizameddin
	  - Parameters:
	   - input: Input string to be hashed. Usually this is salt + password.
	   - hashType: Optional. Defaults to nil. If set, the function will use this hash method. Otherwise, it will use the method it stored in the class variable hashType.
	  - Returns: The hashed string.
	 */
	private func getHashedPassword(input: String, hashType: HashType? = nil) -> String
	{
		let hashType = hashType ?? self._hashType
		
		var hashedPassword = ""
		
		switch hashType
		{
			case .clear:
				hashedPassword = input
			case .md5:
				hashedPassword = input.md5()
			case .sha1:
				hashedPassword = input.sha1()
			case .sha256:
				hashedPassword = input.sha256()
			case .sha512:
				hashedPassword = input.sha512()
		}
		
		return hashedPassword
	}
}
