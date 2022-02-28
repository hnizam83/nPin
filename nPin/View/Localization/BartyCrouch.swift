//
//  BartyCrouch.swift
//  nPin
//
//  Created by Hamza Nizameddin on 07/09/2021.
//

import Foundation

enum BartyCrouch
{
	enum SupportedLanguage: String
	{
		case english = "en"
		case french = "fr"
	}
	
	static func translate(key: String, translations: [SupportedLanguage: String], comment: String? = nil) -> String
	{
		let typeName = String(describing: BartyCrouch.self)
		let methodName = #function
		
		print(
			"Warning: [BartyCrouch]",
			"Untransformed \(typeName).\(methodName) method call found with key '\(key)' and base translations '\(translations)'",
			"Please ensure that BartyCrouch is installed and configured properly."
		)
		
		return "BC: TRANSFORMATION FAILED!"
	}
}
