//
//  ValidatedTextField.swift
//  nPin
//
//  Created by Hamza Nizameddin on 18/08/2021.
//

import UIKit

/**
 Child class of UITextField to validate a text field has a certain length.
 */
class ValidatedTextField: UITextField
{
	public var minCount = 0
	public var maxCount = 0
	
	/**
	 Tests if the input of the text field is of valid length.
	 - Author: Hamza Nizameddin
	 - Returns: True if length is valid, false otherwise.
	 */
	public func isValid() -> Bool
	{
		if let text = self.text {
			return (text.count <= maxCount && text.count >= minCount)
		} else {
			return false
		}
	}
	
	/**
	 Test if text field is empty
	 */
	public func isEmpty() -> Bool
	{
		if let text = self.text {
			return (text.count == 0)
		} else {
			return false
		}
	}
}
